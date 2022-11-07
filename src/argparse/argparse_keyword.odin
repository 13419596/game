package argparse

import "core:fmt"
import "core:log"
import "core:runtime"
import "core:sort"
import "core:strings"
import "core:unicode/utf8"
import "game:trie"

@(private = "file")
_FLAG_EQUALITY_STRING := fmt.aprintf("%v", _DEFAULT_EQUALITY_RUNE)

@(private = "file")
_FLAG_EQUALITY_LENGTH := len(fmt.tprintf("%v", _DEFAULT_EQUALITY_RUNE))

_FoundKeywordOption :: struct($V: typeid) {
  // arg:                  string,
  flag_type:            _ArgumentFlagType,
  value:                V,
  trailer:              Maybe(string),
  removed_equal_prefix: bool,
}

_isequal_FoundKeywordOption :: proc(lhs: $T1/^_FoundKeywordOption($V), rhs: $T2/^_FoundKeywordOption(V)) -> bool {
  lhs_nil := lhs == nil
  rhs_nil := rhs == nil
  if lhs_nil || rhs_nil {
    return lhs_nil && rhs_nil
  }
  out :=
    ((lhs.flag_type == rhs.flag_type) &&
      (lhs.value == rhs.value) &&
      ((lhs.trailer == rhs.trailer) || (lhs.trailer == nil && rhs.trailer == nil)) &&
      (lhs.removed_equal_prefix == rhs.removed_equal_prefix))
  return out
}

_getOptionTrailer :: proc(arg, matched_option: string) -> Maybe(string) {
  // returns slice or arg or nil
  // (-a,-a) -> nil
  // (-ar,-arg) -> nil
  // (-long=3,-long) -> =3
  prev_idx := 0
  len_arg := len(arg)
  len_matched := len(matched_option)
  for idx in 0 ..< min(len_arg, len_matched) {
    if arg[prev_idx:idx] != matched_option[prev_idx:idx] {
      // reached end of match
      out := arg[prev_idx:]
      return out
    }
    prev_idx = idx
  }
  if len_arg <= len_matched {
    return nil
  }
  out := arg[len(matched_option):]
  return out
}

_removeEqualityPrefix :: proc(trailer: Maybe(string), equal_rune: rune) -> (out: Maybe(string), removed_equal_prefix: bool) {
  out = nil
  removed_equal_prefix = false
  if s, s_ok := trailer.?; s_ok {
    out = s
    len_equal_rune := utf8.rune_size(equal_rune)
    if len(s) >= len_equal_rune {
      for rn in s {
        if rn == equal_rune {
          out = s[len_equal_rune:]
          removed_equal_prefix = true
        }
        break
      }
    }
  }
  return
}

_determineKeywordOption :: proc(
  kw_trie: $T/^trie.Trie(int, $V),
  arg: string,
  prefix_rune: rune,
  equality_rune: rune,
) -> (
  out: _FoundKeywordOption(V),
  ok: bool,
) {
  // Get parts of a keyword option if it is in the trie.
  // - keyword options can be abbreviated if unambiguous
  // - multiple options can match only if there is an exacdt match or an exact prefix match with an =
  using strings
  using trie
  context.allocator = context.temp_allocator
  ok = false
  clean_arg := _cleanFlag(arg, prefix_rune) // temp allocate
  out.flag_type = _getFlagType(clean_arg, prefix_rune)
  out.removed_equal_prefix = false

  arg_prefix_len := 0
  switch out.flag_type {
  case .Positional:
    // Positional arguments are not handled this way. 
    fallthrough
  case .Invalid:
    log.debugf("%q is not a keyword argument. Got flag type:%v", arg, out.flag_type)
    ok = false
    return
  ///////
  case .Short:
    arg_prefix_len = utf8.rune_size(prefix_rune)
  case .Long:
    arg_prefix_len = 2 * utf8.rune_size(prefix_rune)
  }

  // Find longest prefix, if it exists and that it is longer than the keyword flag prefix (eg. - or --)
  longest_prefix_key := findLongestPrefix(kw_trie, clean_arg)
  if len_longest_prefix_key := len(longest_prefix_key); len_longest_prefix_key == 0 {
    // not in trie
    log.debugf("%q did not match any arguments.", arg)
    ok = false
    return
  } else if len_longest_prefix_key <= arg_prefix_len {
    // Check that longest prefix match is at least longer than the keyword flag prefix
    log.debugf("%q, flag type %v, did not match any arguments.", arg, out.flag_type)
    ok = false
    return
  }

  // Now confirm that longest prefix is unambiguous, either:
  // - there is only one key with given prefix
  // - there are multiple keys with same prefix and all map to the same dest
  kvs_with_prefix := getAllKeyValuesWithPrefix(kw_trie, longest_prefix_key)

  if len(kvs_with_prefix) == 0 {
    // invalid state, should not happen
    log.warnf("Found longest prefix:%q, but no values were found with this prefix. This is odd", longest_prefix_key, kvs_with_prefix)
    ok = false
    return
  }
  {
    // see if there is 1 kv or all kv's point to same dest. 
    // In that case the result is unambiguous even though there are multiple continuations
    dest := kvs_with_prefix[0].value
    all_same_dest := true
    for kv in kvs_with_prefix {
      if kv.value != dest {
        all_same_dest = false
        break
      }
    }
    if all_same_dest {
      // Unambiguous
      kv := &kvs_with_prefix[0]
      out.value = kv.value
      matched_option := concatenate({longest_prefix_key, _stringFromRunes(kv.key[:])[:]}) // temp allocate
      out.trailer, out.removed_equal_prefix = _removeEqualityPrefix(_getOptionTrailer(clean_arg, matched_option), equality_rune)
      ok = true
      return
    }
  }

  // check for exact match, or if (prefix.key.=) matches
  // Failure if the above criteria matches multiple kvs 
  kv_idx_matches := make([dynamic]int) // temp allocate
  matched_options := make([dynamic]string, len(kvs_with_prefix)) // temp allocate
  for kv, idx in kvs_with_prefix {
    matched_options[idx] = concatenate({longest_prefix_key, _stringFromRunes(kv.key[:])[:]}) // temp allocate
    trailer, removed_equal := _removeEqualityPrefix(_getOptionTrailer(clean_arg, matched_options[idx]), equality_rune)
    clean_arg_starts_with_match := (len(clean_arg) >= len(matched_options[idx])) && (clean_arg[:len(matched_options[idx])] == matched_options[idx])
    // log.infof("kvs[%v]:%v ;; \n\t%q ; %q ; %v ; startswith:%v", idx, kv, matched_options[idx], trailer, removed_equal, clean_arg_starts_with_match)
    if clean_arg_starts_with_match && (trailer == nil || removed_equal) {
      append(&kv_idx_matches, idx)
    }
  }

  if num_kv_idx_matches := len(kv_idx_matches); num_kv_idx_matches == 0 {
    // no exact matches or arg= matches, log message about all possible matches
    sort.quick_sort(matched_options[:])
    log.errorf("Ambiguous option: %q could match %v", arg, matched_options)
    ok = false
    return
  } else if num_kv_idx_matches > 1 {
    // multiple matches, but could still be unambiguous if all kvs point to same dest
    dest := kvs_with_prefix[kv_idx_matches[0]].value
    all_same_dest := true
    for kv in kvs_with_prefix {
      if kv.value != dest {
        all_same_dest = false
        break
      }
    }
    if !all_same_dest {
      // ambiguous, but more specific
      specific_matched_options := make([dynamic]string)
      for kv_idx in kv_idx_matches {
        append(&specific_matched_options, matched_options[kv_idx])
      }
      sort.quick_sort(specific_matched_options[:])
      log.errorf("Ambiguous option: %q could match %v", arg, specific_matched_options)
      ok = false
      return
    }
  }

  // unambiguous
  kv := &kvs_with_prefix[kv_idx_matches[0]]
  out.value = kv.value
  matched_option := concatenate({longest_prefix_key, _stringFromRunes(kv.key[:])[:]}) // temp allocate
  out.trailer, out.removed_equal_prefix = _removeEqualityPrefix(_getOptionTrailer(clean_arg, matched_option), equality_rune)
  ok = true
  return
}

////////////////////////////////////////////////////////////////

_OptionProcessingStateData :: union {
  // Holds cloned copies of strings
  bool, // store true / false
  int, // count
  string, // store (nargs=1)
  [dynamic]string, // store(nargs=*), extend, append(nargs=1)
  [dynamic][dynamic]string, // append(nargs=*)
}

_OptionProcessingState :: struct {
  data:       _OptionProcessingStateData,
  _allocator: runtime.Allocator,
}


@(require_results)
_makeOptionProcessingState :: proc(action: ArgumentAction, num_tokens: _NumTokens, allocator := context.allocator) -> _OptionProcessingState {
  using strings
  out := _OptionProcessingState {
    _allocator = allocator,
  }
  context.allocator = allocator
  switch action {
  case .Version:
  case .Help:
  case .Count:
    out.data = int(0)
  case .StoreTrue:
    out.data = false
  case .StoreFalse:
    out.data = true
  case .Store:
    if upper, upper_ok := num_tokens.upper.?; upper_ok && (num_tokens.lower == 1 && upper == 1) {
      out.data = clone("")
    } else {
      // bounded list or unbounded list
      out.data = make([dynamic]string)
    }
  case .Append:
    if upper, upper_ok := num_tokens.upper.?; upper_ok && (num_tokens.lower == 1 && upper == 1) {
      out.data = make([dynamic]string)
    } else {
      // list of lists
      out.data = make([dynamic][dynamic]string)
    }
  case .Extend:
    out.data = make([dynamic]string)
  }
  return out
}

@(require_results)
_makeOptionProcessingState_fromArgumentOption :: proc(option: $T/^ArgumentOption, allocator := context.allocator) -> (out: _OptionProcessingState, ok: bool) {
  if option == nil {
    log.errorf("Unable to create processing state. option is nil")
    return
  }
  out = _makeOptionProcessingState(action = option.action, num_tokens = option.num_tokens, allocator = allocator)
  ok = true
  return
}

@(require_results)
_cloneOptionProcessingState :: proc(self: ^_OptionProcessingState, allocator := context.allocator) -> _OptionProcessingState {
  using strings
  context.allocator = allocator
  out := _OptionProcessingState {
    _allocator = allocator,
  }
  if self == nil {
    log.errorf("Unable to clone %T because it is nil", self)
    return out
  }
  switch data in &self.data {
  case bool:
    out.data = data
  case int:
    out.data = data
  case string:
    out.data = clone(data)
  case [dynamic]string:
    out_data := make([dynamic]string, len(data))
    for str, idx in data {
      out_data[idx] = clone(str)
    }
    out.data = out_data
  case [dynamic][dynamic]string:
    out_data := make([dynamic][dynamic]string, len(data))
    for strs, strs_idx in &data {
      out_data[strs_idx] = make([dynamic]string, len(strs))
      out_strs := &out_data[strs_idx]
      for str, idx in strs {
        out_strs[idx] = clone(str)
      }
    }
    out.data = out_data
  }
  return out
}

_deleteOptionProcessingState :: proc(self: ^_OptionProcessingState) {
  if self == nil {
    return
  }
  switch data in &self.data {
  case bool:
    data = {}
  case int:
    data = {}
  case string:
    delete(data, self._allocator)
  case [dynamic]string:
    for str in &data {
      delete(str, self._allocator)
    }
    delete(data)
    data = {}
  case [dynamic][dynamic]string:
    for strs in &data {
      for str in &strs {
        delete(str, self._allocator)
      }
      delete(strs)
    }
    delete(data)
  }
  self.data = nil
}

ProcessOutput :: struct {
  num_consumed: int,
  trailer:      Maybe(string),
}

_processKeywordOption :: proc(
  option: $T/^ArgumentOption,
  state: $S/^_OptionProcessingState,
  trailer: Maybe(string),
  args: []string,
) -> (
  out: ProcessOutput,
  ok: bool,
) {
  using strings
  ok = false
  if state == nil {
    log.errorf("Expected processing state to be not nil.")
    return
  }
  out.trailer = trailer
  out.num_consumed = 0
  switch option.action {
  case .Version:
    fallthrough
  case .Help:
    ok = true
  case .Count:
    if count, count_ok := &state.data.(int); count_ok {
      count^ += 1
      ok = true
    }
  case .StoreTrue:
    if tf, tf_ok := &state.data.(bool); tf_ok {
      tf^ = true
      ok = true
    }
  case .StoreFalse:
    if tf, tf_ok := &state.data.(bool); tf_ok {
      tf^ = false
      ok = true
    }
  case .Append:
    if vals, vals_ok := &state.data.([dynamic]string); vals_ok {
      // append single
      if trail, trail_ok := out.trailer.?; trail_ok {
        append(vals, clone(trail, state._allocator))
        out.trailer = nil // consume trailer
      } else if len(args) < 1 {
        log.errorf("Insufficient arguments for option:%q expected at least num %v arguments", option.dest, option.num_tokens.lower)
        break
      } else {
        append(vals, clone(args[0], state._allocator))
        out.num_consumed = 1
      }
      ok = true
      break
    }
    if vvals, vvals_ok := &state.data.([dynamic][dynamic]string); vvals_ok {
      // append list
      if trail, trail_ok := out.trailer.?; trail_ok {
        if upper, upper_ok := option.num_tokens.upper.?; upper_ok {
          need_consume := max(1, option.num_tokens.lower)
          if need_consume != 1 {
            // expected multiple arguments, but got a trailer, invalid
            log.errorf("Insufficient arguments for option:%q expected at least num %v arguments", option.dest, need_consume)
            break
          }
        }
        // unbounded is fine
        new_list := make([dynamic]string, 1, state._allocator)
        new_list[0] = clone(trail, state._allocator)
        append(vvals, new_list)
        out.trailer = nil // consume trailer
      } else {
        if len(args) < option.num_tokens.lower {
          log.errorf("Insufficient arguments for option:%q expected at least num %v arguments", option.dest, option.num_tokens.lower)
          break
        }
        out.num_consumed = min(option.num_tokens.upper.? or_else len(args), len(args))
        new_list := make([dynamic]string, out.num_consumed, state._allocator)
        for idx in 0 ..< out.num_consumed {
          new_list[idx] = clone(args[idx], state._allocator)
        }
        append(vvals, new_list)
      }
      ok = true
    }
  case .Store:
    if s, s_ok := &state.data.(string); s_ok {
      if trail, trail_ok := out.trailer.?; trail_ok {
        s^ = clone(trail, state._allocator)
        out.trailer = nil // consume trailer
        ok = true
      } else if len(args) < 1 {
        log.errorf("Insufficient arguments for option:%q expected at least num %v arguments", option.dest, option.num_tokens.lower)
        break
      } else {
        s^ = clone(args[0], state._allocator)
        out.num_consumed = 1
      }
      ok = true
      break
    }
    if strs, strs_ok := &state.data.([dynamic]string); strs_ok {
      // same as extend, but clear previously stored list
      for str in strs {
        delete(str, state._allocator)
      }
      delete(strs^)
      strs^ = make([dynamic]string, state._allocator)
    }
    fallthrough
  case .Extend:
    if vals, vals_ok := &state.data.([dynamic]string); vals_ok {
      if trail, trail_ok := out.trailer.?; trail_ok {
        if upper, upper_ok := option.num_tokens.upper.?; upper_ok {
          need_consume := max(1, option.num_tokens.lower)
          if need_consume != 1 {
            // expected multiple arguments, but got a trailer, invalid
            log.errorf("Insufficient arguments for option:%q expected at least num %v arguments", option.dest, need_consume)
            break
          }
        }
        // unbounded is fine
        append(vals, clone(trail, state._allocator))
        out.trailer = nil // consume trailer
      } else {
        if len(args) < option.num_tokens.lower {
          log.errorf("Insufficient arguments for option:%q expected at least num %v arguments", option.dest, option.num_tokens.lower)
          break
        }
        out.num_consumed = min(option.num_tokens.upper.? or_else len(args), len(args))
        for idx in 0 ..< out.num_consumed {
          append(vals, clone(args[idx], state._allocator))
        }
      }
      ok = true
    }
  }
  return
}
