package re

import "core:fmt"
import "core:log"
import Q "core:container/queue"
import set "game:container/set"
import dg "game:digraph"
import "game:glog"

@(private)
KeyType :: int

TokenNfa :: struct {
  head_index, tail_index: int,
  tokens:                 [dynamic]Token,
  digraph:                dg.Digraph(KeyType),
}

@(require_results)
_makeTokenNfa :: proc(allocator := context.allocator) -> TokenNfa {
  out := TokenNfa {
    head_index = 0,
    tail_index = 1,
    tokens     = make([dynamic]Token, allocator),
    digraph    = dg.makeDigraph(KeyType, allocator),
  }
  // add head and tail to token list & digraph
  append(&out.tokens, SpecialNfaToken{.HEAD})
  dg.addNode(&out.digraph, len(out.tokens) - 1)
  append(&out.tokens, SpecialNfaToken{.TAIL})
  dg.addNode(&out.digraph, len(out.tokens) - 1)
  return out
}

deleteTokenNfa :: proc(nfa: ^TokenNfa) {
  deleteTokens(&nfa.tokens)
  dg.deleteDigraph(&nfa.digraph)
}

@(require_results)
_duplicateNfaToken :: proc(nfa: ^TokenNfa, key: KeyType) -> (out: KeyType, ok: bool) {
  out = -1
  ok = key < len(nfa.tokens)
  if !ok {
    return
  }
  out = len(nfa.tokens)
  append(&nfa.tokens, copy_Token(&nfa.tokens[key]))
  return
}

/////////////////////////
// Internal 

_Fragment :: struct {
  heads:      set.Set(KeyType),
  tails:      set.Set(KeyType),
  has_bypass: bool,
}

@(require_results)
_makeFragment :: proc(allocator := context.allocator) -> _Fragment {
  out := _Fragment {
    heads      = set.makeSet(KeyType),
    tails      = set.makeSet(KeyType),
    has_bypass = false,
  }
  return out
}

_deleteFragment :: proc(fragment: ^_Fragment) {
  set.deleteSet(&fragment.heads)
  set.deleteSet(&fragment.tails)
}

@(require_results)
_makeSingleTokenFragment :: proc(token_key: KeyType, allocator := context.allocator) -> _Fragment {
  out := _makeFragment(allocator)
  set.add(&out.heads, token_key)
  set.add(&out.tails, token_key)
  return out
}

@(require_results)
_makeBypassFragment :: proc(allocator := context.allocator) -> _Fragment {
  out := _makeFragment(allocator)
  out.has_bypass = true
  return out
}

@(require_results)
_copyFragment :: proc(self: ^_Fragment, allocator := context.allocator) -> _Fragment {
  // straight copies the fragment nodes/edges - this is NOT the same as duplication
  out := _Fragment {
    heads      = set.copy(&self.heads, allocator),
    tails      = set.copy(&self.tails, allocator),
    has_bypass = self.has_bypass,
  }
  return out
}

_appendFragment :: proc(self, other: ^_Fragment, digraph: ^dg.Digraph(KeyType)) {
  // appends other to self, by connecting self tails to all other heads
  // if tail has bypass, then initial tails are kept
  // other fragment can be discarded
  // initial:
  //  H       T    H       T
  // >-( self)->  >-(other)->
  // >-(     )    >-(     )
  // 
  // final:
  //  H                    T
  // >-[( self)->-->-(     )]->
  // >-[(     )  \->-(     )]
  //
  // >-[ new                ]->
  // >-[                    ]
  for prime_tail_key, _ in self.tails.set {
    for other_head_key, _ in other.heads.set {
      dg.addEdge(digraph, prime_tail_key, other_head_key)
    }
  }
  if self.has_bypass {
    // if self has bypass, add other heads to self heads, and remove bypass
    set.update(&self.heads, &other.heads)
    self.has_bypass = other.has_bypass // final frag only has bypass if both have bypass
  }
  if !other.has_bypass {
    // other does no have bypass, so clear self tails
    set.reset(&self.tails)
  }
  set.update(&self.tails, &other.tails)
}

_alternateFragment :: proc(self, other: ^_Fragment) {
  // joins other to self - alternation operation
  // if either has bypass, then new has bypass
  // other fragment can be discarded
  // initial:
  //  H       T 
  // >-( self)->
  // >-(     )   
  // >-(other)-> 
  // >-(     )->
  //
  // final:
  // >-[( self)]->
  // >-[(     )]   
  // >-[(other)]-> 
  // >-[(     )]->
  //
  // >-[new    ]->
  // >-[       ]->
  // >-[       ]->
  // >-[       ]
  set.update(&self.heads, &other.heads)
  set.update(&self.tails, &other.tails)
  self.has_bypass |= other.has_bypass
}

_zeroOrOneFragment :: proc(self: ^_Fragment) {
  // regex ?, simply adds bypass
  self.has_bypass = true
}

_oneOrMoreFragment :: proc(self: ^_Fragment, digraph: ^dg.Digraph(KeyType)) {
  // regex +, connects all tails to all heads
  for tail_key, _ in self.tails.set {
    for head_key, _ in self.heads.set {
      dg.addEdge(digraph, tail_key, head_key)
    }
  }
}

_zeroOrMoreFragment :: proc(self: ^_Fragment, digraph: ^dg.Digraph(KeyType)) {
  // regex *, is the same as (0 or 1) or (1 or more)
  // same as regex + with bypass
  _oneOrMoreFragment(self, digraph)
  self.has_bypass = true
}

@(require_results)
_duplicateFragment :: proc(self: ^_Fragment, nfa: ^TokenNfa, allocator := context.allocator) -> (new_frag: _Fragment, ok: bool) {
  // duplicating fragment makes new nodes for all the heads and tails of the original fragment
  new_frag = _makeFragment(allocator)
  new_frag.has_bypass = self.has_bypass
  duplicate_map := make(map[KeyType]KeyType, 1, context.temp_allocator) // ensure keys aren't duplicated twice
  ok = true
  for old_key, _ in self.heads.set {
    new_key: KeyType
    if old_key not_in duplicate_map {
      new_key, ok = _duplicateNfaToken(nfa, old_key)
      if !ok {
        log.errorf("Unable create duplicate NFA token for key:%v. NFA:%v", old_key, nfa)
        break
      }
      duplicate_map[old_key] = new_key
    } else {
      new_key = duplicate_map[old_key]
    }
    set.add(&new_frag.heads, new_key)
  }
  for old_key, _ in self.tails.set {
    new_key: KeyType
    if old_key not_in duplicate_map {
      new_key, ok = _duplicateNfaToken(nfa, old_key)
      if !ok {
        log.errorf("Unable create duplicate NFA token for key:%v. NFA:%v", old_key, nfa)
        break
      }
      duplicate_map[old_key] = new_key
    } else {
      new_key = duplicate_map[old_key]
    }
    set.add(&new_frag.tails, new_key)
  }
  if !ok {
    _deleteFragment(&new_frag)
  }
  return
}

@(require_results)
_repeatFragment :: proc(self: ^_Fragment, nfa: ^TokenNfa, lower: int, mupper: Maybe(int)) -> bool {
  log.debugf("Repeating fragment:%v; lower:%v; upper:%v; NFA:%v", self, lower, mupper, nfa.digraph)
  if lower < 0 {
    log.errorf("Cannot repeat a fragment with lower bound less than zero Got:%v", lower)
    return false
  }
  // repeat fragment lower # times
  digraph := &nfa.digraph
  initial_frag_copy := _copyFragment(self, context.temp_allocator) // fragments allocated here will not persist
  last_dup_added: ^_Fragment = nil
  for n in 1 ..< lower {
    dup_frag, dup_ok := _duplicateFragment(&initial_frag_copy, nfa, context.temp_allocator)
    if !dup_ok {
      log.errorf("Unable to duplicate fragment:%v", initial_frag_copy)
      return false
    }
    last_dup_added = &dup_frag
    _appendFragment(self, &dup_frag, digraph)
  }
  if upper, upper_ok := mupper.(int); upper_ok {
    // upper is a number, add optional tokens from lower+1 to upper
    if upper < lower {
      log.errorf("Cannot repeat fragment. Upper:%v is less than lower:%v", upper, lower)
      return false
    }
    initial_frag_copy.has_bypass = true
    for n in max(lower, 1) ..< upper {
      dup_frag, dup_ok := _duplicateFragment(&initial_frag_copy, nfa, context.temp_allocator)
      if !dup_ok {
        log.errorf("Unable to duplicate fragment:%v", initial_frag_copy)
        return false
      }
      _appendFragment(self, &dup_frag, digraph)
    }
  } else {
    // no upper bound
    if lower == 0 {   // *
      _zeroOrMoreFragment(self, digraph)
    } else if lower == 1 {   // +
      _oneOrMoreFragment(self, digraph)
    } else if last_dup_added != nil {
      // {#,} - one or more last duplicate created
      _oneOrMoreFragment(last_dup_added, digraph)
    } else {
      // last duplicate is nil? whatever
      log.errorf("Last duplicated fragment is nil, even though lower should be >1. This is odd.")
      return false
    }
  }
  if lower == 0 {
    // add final bypass at end - to prevent extra bypasses from showing up & unnecessarily complicating the nfa
    self.has_bypass = true
  }
  return true
}
/////////////////////////

_PostfixToNfaState :: struct {
  frag_stack: Q.Queue(_Fragment),
  nfa:        ^TokenNfa,
}

@(require_results)
_makePostfixToNfaState :: proc(nfa: ^TokenNfa, allocator := context.allocator) -> _PostfixToNfaState {
  out := _PostfixToNfaState {
    frag_stack = Q.Queue(_Fragment){data = make([dynamic]_Fragment, allocator)},
    nfa = nfa,
  }
  Q.init(&out.frag_stack)
  return out
}

_deletePostfixToNfaState :: proc(state: ^_PostfixToNfaState) {
  for state.frag_stack.len > 0 {
    frag := Q.pop_back(&state.frag_stack)
    _deleteFragment(&frag)
  }
  Q.destroy(&state.frag_stack)
  state.nfa = nil
}

/////////////////////////

@(require_results)
makeTokenNfaFromPostfixTokens :: proc(postfix_tokens: []Token, allocator := context.allocator) -> (out: TokenNfa, ok: bool) {
  // temp state
  out = _makeTokenNfa(allocator) // will persist, use regular allocator
  ok = true
  state := _makePostfixToNfaState(&out, context.temp_allocator)

  for _, idx in postfix_tokens {
    if !_processToken(&state, &postfix_tokens[idx]) {
      log.errorf("Error during processing tokens[%v]: %v. Unable to create NFA", idx, postfix_tokens[idx])
      ok = false
      break
    }
  }
  // top of frag stack should now be the expression
  if state.frag_stack.len < 1 {
    // not enough fragments, this is odd
    log.errorf("Not enough fragments after processing. This is odd. processing state:%v", state)
    ok = false
    deleteTokenNfa(&out)
    return
  }

  head_frag := _makeSingleTokenFragment(out.head_index, allocator)
  expr_frag := Q.peek_back(&state.frag_stack)
  _appendFragment(&head_frag, expr_frag, &state.nfa.digraph)
  tail_frag := _makeSingleTokenFragment(out.tail_index, allocator)
  _appendFragment(&head_frag, &tail_frag, &state.nfa.digraph)

  // Check if head -> head; 
  if ok && dg.hasEdge(&out.digraph, out.head_index, out.head_index) {
    log.errorf("Error during processing. Head token points to head token. This is invalid")
    ok = false
  }
  if !ok {
    deleteTokenNfa(&out)
  }
  return
}

//////////////////////

@(require_results)
_processSimpleToken :: proc(state: ^_PostfixToNfaState, token: ^Token, allocator := context.allocator) -> bool {
  if token != nil {
    index_key := len(state.nfa.tokens)
    append(&state.nfa.tokens, copy_Token(token, allocator))
    Q.push_back(&state.frag_stack, _makeSingleTokenFragment(index_key, allocator))
  } else {
    Q.push_back(&state.frag_stack, _makeBypassFragment(allocator))
  }
  return true
}

@(require_results)
_processConcatenateToken :: proc(state: ^_PostfixToNfaState) -> bool {
  if state.frag_stack.len < 2 {
    log.errorf(
      "Error during processing. Not enough tokens in stack to create proper NFA. Stack size:%v. processing state:%v. nfa:%v",
      state.frag_stack.len,
      state,
      state.nfa,
    )
    return false
  }
  frag_right, pop_ok := Q.pop_back_safe(&state.frag_stack)
  if !pop_ok {
    log.errorf(
      "Error during processing. Not enough tokens in stack to create proper NFA. Stack size:%v. processing state:%v. nfa:%v",
      state.frag_stack.len,
      state,
      state.nfa,
    )
    return false
  }
  frag_left := Q.peek_back(&state.frag_stack)
  if frag_left == nil {
    log.errorf(
      "Error during processing. Not enough tokens in stack to create proper NFA. Stack size:%v. processing state:%v. nfa:%v",
      state.frag_stack.len,
      state,
      state.nfa,
    )
    return false
  }
  _appendFragment(frag_left, &frag_right, &state.nfa.digraph)
  return true
}

@(require_results)
_processAlternationToken :: proc(state: ^_PostfixToNfaState) -> bool {
  if state.frag_stack.len < 2 {
    log.errorf(
      "Error during processing. Not enough tokens in stack to create proper NFA. Stack size:%v. processing state:%v. nfa:%v",
      state.frag_stack.len,
      state,
      state.nfa,
    )
    return false
  }
  frag_right, pop_ok := Q.pop_back_safe(&state.frag_stack)
  if !pop_ok {
    log.errorf(
      "Error during processing. Not enough tokens in stack to create proper NFA. Stack size:%v. processing state:%v. nfa:%v",
      state.frag_stack.len,
      state,
      state.nfa,
    )
    return false
  }
  frag_left := Q.peek_back(&state.frag_stack)
  if frag_left == nil {
    log.errorf(
      "Error during processing. Not enough tokens in stack to create proper NFA. Stack size:%v. processing state:%v. nfa:%v",
      state.frag_stack.len,
      state,
      state.nfa,
    )
    return false
  }
  _alternateFragment(frag_left, &frag_right)
  return true
}

@(require_results)
_processQuantityToken :: proc(state: ^_PostfixToNfaState, qtok: ^QuantityToken) -> bool {
  if state.frag_stack.len < 1 {
    log.errorf("Error during processing. Not enough tokens in stack to create proper NFA. processing state:%v", state)
    return false
  }
  pfrag := Q.peek_back(&state.frag_stack)
  if pfrag == nil {
    log.errorf("Error during processing. Not enough tokens in stack to create proper NFA. processing state:%v", state)
    return false
  }
  return _repeatFragment(pfrag, state.nfa, qtok.lower, qtok.upper)
}

@(require_results)
_processToken :: proc(state: ^_PostfixToNfaState, token: ^Token) -> bool {
  switch tok in token {
  case ImplicitToken:
    switch tok.op {
    case .CONCATENATION:
      return _processConcatenateToken(state)
    case .EMPTY:
      return _processSimpleToken(state, nil) // add as bypass fragment
    }
  case AlternationToken:
    return _processAlternationToken(state)
  case QuantityToken:
    qtok := &tok
    return _processQuantityToken(state, qtok)
  /////
  // add token as-is
  case SpecialNfaToken:
  case AssertionToken:
  case LiteralToken:
  case SetToken:
  case GroupBeginToken:
  case GroupEndToken:
  }
  return _processSimpleToken(state, token)
}

//////////////////////

@(require_results)
makeTokenNfaFromPattern :: proc(pattern: string, flags: RegexFlags = {}, allocator := context.allocator) -> (out: TokenNfa, ok: bool) {
  ok = false
  log.debugf("Pattern %q", pattern)
  infix_tokens, infix_ok := parseTokensFromString(pattern, flags, context.temp_allocator)
  if !infix_ok {
    return
  }
  log.debugf("Infix Tokens:")
  for tok, idx in infix_tokens {
    log.debugf(" % 2d: %v", idx, tok)
  }
  postfix_tokens, postfix_ok := convertInfixToPostfix(infix_tokens[:], context.temp_allocator)
  log.debugf("Postfix Tokens:")
  for tok, idx in postfix_tokens {
    log.debugf(" % 2d: %v", idx, tok)
  }
  if !postfix_ok {
    return
  }
  out, ok = makeTokenNfaFromPostfixTokens(postfix_tokens[:], allocator)
  if !ok {
    return
  }
  return
}
