package argparse

import "core:fmt"
import "core:log"
import "core:runtime"
import "core:strings"
import "core:unicode/utf8"
import "game:trie"

@(private = "file")
_FLAG_EQUALITY_STRING := fmt.aprintf("%v", _FLAG_EQUALITY_RUNE)

@(private = "file")
_FLAG_EQUALITY_LENGTH := len(fmt.tprintf("%v", _FLAG_EQUALITY_RUNE))

_FoundKeywordOption :: struct($V: typeid) {
  arg:                  string,
  flag_type:            _ArgumentFlagType,
  value:                V,
  head:                 string, // includes prefix
  tail:                 Maybe(string), // arg = head . tail, or head . = . tail
  removed_equal_prefix: bool,
}

_isequal_FoundKeywordOption :: proc(lhs: $T1/^_FoundKeywordOption($V), rhs: $T2/^_FoundKeywordOption(V)) -> bool {
  lhs_nil := lhs == nil
  rhs_nil := rhs == nil
  if lhs_nil || rhs_nil {
    return lhs_nil && rhs_nil
  }
  out :=
    ((lhs.arg == rhs.arg) &&
      (lhs.flag_type == rhs.flag_type) &&
      (lhs.value == rhs.value) &&
      (lhs.head == rhs.head) &&
      ((lhs.tail == rhs.tail) || (lhs.tail == nil && rhs.tail == nil)) &&
      (lhs.removed_equal_prefix == rhs.removed_equal_prefix))
  return out
}

_determineKeywordOption :: proc(kw_trie: $T/^trie.Trie(int, $V), arg: string) -> (out: _FoundKeywordOption(V), ok: bool) {
  using strings
  using trie
  context.allocator = context.temp_allocator
  ok = false
  out.arg = arg
  out.flag_type = _getFlagType(arg)
  out.removed_equal_prefix = false

  switch out.flag_type {
  case .Positional:
    fallthrough
  case .Invalid:
    ok = false
    return
  ///////
  case .Short:
  case .Long:
  }

  // Find longest prefix, if it exists (if not then not a keyword argument)
  longest_prefix_key, longest_prefix_mvalue := getLongestPrefix(kw_trie, arg)
  longest_prefix_value := longest_prefix_mvalue.? or_return

  // Now confirm that longest prefix is unambiguous, either:
  // - there is only one key with given prefix
  // - or the is given key is exact e.g. {--arg} is unambiguous with keywords {--arg,--arg-long}
  kvs_with_prefix := getAllKeyValuesWithPrefix(kw_trie, longest_prefix_key)

  switch len(kvs_with_prefix) {
  case 0:
    // invalid state, should not happen
    log.warnf("Found longest prefix:%v, but kv with prefix was empty. This is odd", longest_prefix_key, kvs_with_prefix)
    return
  case 1:
    // unambiguous
    out.value = longest_prefix_value
    out.head = arg[:len(longest_prefix_key)]
    if len(arg[len(longest_prefix_key):]) > 0 {
      tail := arg[len(longest_prefix_key):]
      if _FLAG_EQUALITY_LENGTH <= len(tail) && tail[:_FLAG_EQUALITY_LENGTH] == _FLAG_EQUALITY_STRING {
        //remove equals
        tail = tail[_FLAG_EQUALITY_LENGTH:]
        out.removed_equal_prefix = true
      }
      out.tail = tail
    }
    ok = true
  }

  if !ok {
    // check for exact match, or if (prefix.key.=) matches
    len_prefix := len(longest_prefix_key)
    for kv, idx in kvs_with_prefix {
      len_prefix_key := len_prefix + len(kv.key)
      if len_prefix_key == len(arg) {
        // if lengths are same then key is same, (same prefix)
        out.value = kv.value
        out.head = arg
        ok = true
        break
      }
      len_prefix_key_eq := len_prefix_key + _FLAG_EQUALITY_LENGTH
      str_after_key := arg[len_prefix_key:len_prefix_key + _FLAG_EQUALITY_LENGTH]
      if len_prefix_key_eq <= len(arg) && str_after_key == _FLAG_EQUALITY_STRING {
        // matches key, but has = afterwards, good match
        out.value = kv.value
        out.head = arg[:len_prefix_key]
        if len(arg[len_prefix_key + _FLAG_EQUALITY_LENGTH:]) > 0 {
          out.tail = arg[len_prefix_key + _FLAG_EQUALITY_LENGTH:]
        }
        out.removed_equal_prefix = true
        ok = true
        break
      }
    }
  }
  return
}


_OptionProcessingStateData :: union {
  bool, // store true / false
  int, // count
  any, // store const
  string, // store (nargs=1)
  [dynamic]any, // append const
  [dynamic]string, // store(nargs=*), extend, append(nargs=1)
  [dynamic][]string, // append(nargs=*)
}

_OptionProcessingState :: struct {
  data:       _OptionProcessingStateData,
  _allocator: runtime.Allocator,
}


@(require_results)
_makeOptionProcessingState :: proc(action: ArgumentAction, num_tokens: _NumTokens, allocator := context.allocator) -> _OptionProcessingState {
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
      out.data = ""
    } else {
      // bounded list or unbounded list
      out.data = make([dynamic]string)
    }
  case .Append:
    if upper, upper_ok := num_tokens.upper.?; upper_ok && (num_tokens.lower == 1 && upper == 1) {
      out.data = make([dynamic]string)
    } else {
      // list of lists
      out.data = make([dynamic][]string, allocator)
    }
  case .Extend:
    out.data = make([dynamic]string, allocator)
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

_deleteOptionProcessingState :: proc(self: ^_OptionProcessingState) {
  if self == nil {
    return
  }
  switch data in &self.data {
  case bool:
    data = {}
  case any:
    data = {}
  case int:
    data = {}
  case string:
    data = {}
  case [dynamic]string:
    delete(data)
    data = {}
  case [dynamic]any:
    delete(data)
    data = {}
  case [dynamic][]string:
    for v in &data {
      delete(v)
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
        append(vals, trail)
        out.trailer = nil // consume trailer
      } else if len(args) < 1 {
        log.errorf("Insufficient arguments for option:%q expected at least num %v arguments", option.dest, option.num_tokens.lower)
        break
      } else {
        append(vals, args[0])
        out.num_consumed = 1
      }
      ok = true
      break
    }
    if vvals, vvals_ok := &state.data.([dynamic][]string); vvals_ok {
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
        new_list[0] = trail
        append(vvals, new_list[:])
        out.trailer = nil // consume trailer
      } else {
        if len(args) < option.num_tokens.lower {
          log.errorf("Insufficient arguments for option:%q expected at least num %v arguments", option.dest, option.num_tokens.lower)
          break
        }
        out.num_consumed = min(option.num_tokens.upper.? or_else len(args), len(args))
        new_list := make([dynamic]string, out.num_consumed, state._allocator)
        for idx in 0 ..< out.num_consumed {
          new_list[idx] = args[idx]
        }
        append(vvals, new_list[:])
      }
      ok = true
    }
  case .Store:
    if s, s_ok := &state.data.(string); s_ok {
      if trail, trail_ok := out.trailer.?; trail_ok {
        s^ = trail
        out.trailer = nil // consume trailer
        ok = true
      } else if len(args) < 1 {
        log.errorf("Insufficient arguments for option:%q expected at least num %v arguments", option.dest, option.num_tokens.lower)
        break
      } else {
        s^ = args[0]
        out.num_consumed = 1
      }
      ok = true
      break
    }
    if val, val_ok := &state.data.([dynamic]string); val_ok {
      // same as extend, but clear previously stored list
      delete(val^)
      val^ = make([dynamic]string, state._allocator)
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
        append(vals, trail)
        out.trailer = nil // consume trailer
      } else {
        if len(args) < option.num_tokens.lower {
          log.errorf("Insufficient arguments for option:%q expected at least num %v arguments", option.dest, option.num_tokens.lower)
          break
        }
        out.num_consumed = min(option.num_tokens.upper.? or_else len(args), len(args))
        for idx in 0 ..< out.num_consumed {
          append(vals, args[idx])
        }
      }
      ok = true
    }
  }
  return
}
