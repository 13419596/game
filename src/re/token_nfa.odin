package re

import "core:fmt"
import "core:log"
import Q "core:container/queue"
import set "game:container/set"
import "game:glog"

@(private)
KeyType :: int

@(private)
DigraphType :: map[KeyType]set.Set(KeyType)

TokenNfa :: struct {
  head_index, tail_index: int,
  tokens:                 [dynamic]Token,
  digraph:                DigraphType, // digraph of indices
}

@(require_results)
_makeTokenNfa :: proc(allocator := context.allocator) -> TokenNfa {
  out := TokenNfa {
    head_index = 0,
    tail_index = 1,
    tokens     = make([dynamic]Token, allocator),
    digraph    = make(DigraphType, 2, allocator),
  }
  // add head and tail to token list & digraph
  append(&out.tokens, SpecialNfaToken{.HEAD})
  out.digraph[len(out.tokens) - 1] = set.makeSet(KeyType)
  append(&out.tokens, SpecialNfaToken{.TAIL})
  out.digraph[len(out.tokens) - 1] = set.makeSet(KeyType)
  return out
}

deleteTokenNfa :: proc(nfa: ^TokenNfa) {
  deleteTokens(&nfa.tokens)
  for k, v in &nfa.digraph {
    set.deleteSet(&v)
  }
  delete(nfa.digraph)
}

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

_addDigraphEdge :: proc(dg: ^DigraphType, node_start, node_end: KeyType) {
  // Adds a one way edge from (node_start) -> (node_end)
  // creates nodes if they do not exist 
  if node_start not_in dg {
    dg[node_start] = set.makeSet(KeyType)
  }
  if node_end not_in dg {
    dg[node_end] = set.makeSet(KeyType)
  }
  set.add(&dg[node_start], node_end)
}

/////////////////////////
// Internal 

_Fragment :: struct {
  heads:      set.Set(KeyType),
  tails:      set.Set(KeyType),
  has_bypass: bool,
}

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
_makeInitialFragment :: proc(token_key: KeyType, allocator := context.allocator) -> _Fragment {
  out := _makeFragment(allocator)
  set.add(&out.heads, token_key)
  set.add(&out.tails, token_key)
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

_appendFragment :: proc(self, other: ^_Fragment, dg: ^DigraphType) {
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
      _addDigraphEdge(dg, prime_tail_key, other_head_key)
    }
  }
  if self.has_bypass {
    // if self has bypass, add other heads to self heads, and remove bypass
    set.update(&self.heads, &other.heads)
    self.has_bypass = false
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

_oneOrMoreFragment :: proc(self: ^_Fragment, dg: ^DigraphType) {
  // regex +, connects all tails to all heads
  for tail_key, _ in self.tails.set {
    for head_key, _ in self.heads.set {
      _addDigraphEdge(dg, tail_key, head_key)
    }
  }
}

_zeroOrManyragment :: proc(self: ^_Fragment, dg: ^DigraphType) {
  // regex *, is the same as (0 or 1) or (1 or more)
  // same as regex + with bypass
  _oneOrMoreFragment(self, dg)
  self.has_bypass = true
}

@(require_results)
_duplicateFragment :: proc(self: ^_Fragment, nfa: ^TokenNfa, allocator := context.allocator) -> (new_frag: _Fragment, ok: bool) {
  // duplicating fragment requires making new tokens/nodes
  new_frag = _makeFragment(allocator)
  ok = true
  for head_key, _ in self.heads.set {
    new_key, new_ok := _duplicateNfaToken(nfa, head_key)
    if !new_ok {
      ok = false
      break
    }
    set.add(&new_frag.heads, new_key)
  }
  for tail_key, _ in self.heads.set {
    new_key, new_ok := _duplicateNfaToken(nfa, tail_key)
    if !new_ok {
      ok = false
      break
    }
    set.add(&new_frag.heads, new_key)
  }
  if !ok {
    _deleteFragment(&new_frag)
  }
  return
}

_repeatFragment :: proc(self: ^_Fragment, nfa: ^TokenNfa, num_copies: int, num_trailing_bypass_copies: int) -> bool {
  if num_copies == 0 {
    self.has_bypass = true
  }
  log.logf(
    glog.DEBUG5,
    "Repeating fragment:%v\nnum copies:%v; num trailing optional copies:%v\ncurrent NFA:%v",
    self,
    num_copies,
    num_trailing_bypass_copies,
    nfa.digraph,
  )
  dg := &nfa.digraph
  initial_fragment := _copyFragment(self, context.temp_allocator)
  // note: if num_copies ==1 then don't add any copies
  for n in 1 ..< num_copies {
    dup_frag, dup_ok := _duplicateFragment(&initial_fragment, nfa, context.temp_allocator)
    if !dup_ok {
      return false
    }
    _appendFragment(self, &dup_frag, dg)
  }
  initial_fragment.has_bypass = true
  if num_trailing_bypass_copies <= 0 {
    // infinite trailing copies - add zero more to end
    if num_copies == 1 {
      _oneOrMoreFragment(self, dg)
    } else {
      _oneOrMoreFragment(&initial_fragment, dg)
      _appendFragment(self, &initial_fragment, dg)
    }
  } else if num_trailing_bypass_copies >= 1 {
    for n in 0 ..< num_trailing_bypass_copies {
      dup_frag, dup_ok := _duplicateFragment(&initial_fragment, nfa, context.temp_allocator)
      if !dup_ok {
        return false
      }
      _appendFragment(self, &dup_frag, dg)
    }
  }
  log.debugf("Final repeated fragment:%v", self)
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

  head_frag := _makeInitialFragment(out.head_index)
  expr_frag := Q.peek_back(&state.frag_stack)
  _appendFragment(&head_frag, expr_frag, &state.nfa.digraph)
  tail_frag := _makeInitialFragment(out.tail_index)
  _appendFragment(&head_frag, &tail_frag, &state.nfa.digraph)

  // Check if head -> head; 
  if ok && set.contains(&out.digraph[out.head_index], out.head_index) {
    log.errorf("Error during processing. Head token points to head token. This is invalid")
    ok = false
  }
  if !ok {
    deleteTokenNfa(&out)
  }
  return
}

_addTokenToStack :: proc(state: ^_PostfixToNfaState, token: ^Token, allocator := context.allocator) {
  index_key := len(state.nfa.tokens)
  append(&state.nfa.tokens, copy_Token(token, allocator))
  Q.push_back(&state.frag_stack, _makeInitialFragment(index_key))
}

_processToken :: proc(state: ^_PostfixToNfaState, token: ^Token) -> bool {
  switch tok in token {
  // add token as-is
  case LiteralToken:
    _addTokenToStack(state, token, context.temp_allocator)
  case SetToken:
    _addTokenToStack(state, token, context.temp_allocator)
  case GroupBeginToken:
    _addTokenToStack(state, token, context.temp_allocator)
  case GroupEndToken:
    _addTokenToStack(state, token, context.temp_allocator)
  case ImplicitToken:
    switch tok.op {
    case .CONCATENATION:
      if state.frag_stack.len < 2 {
        log.errorf("Error during processing. Not enough tokens in stack to create proper NFA. processing state:%v", state)
        return false
      }
      frag_right, pop_ok := Q.pop_back_safe(&state.frag_stack)
      if !pop_ok {
        log.errorf("Error during processing. Not enough tokens in stack to create proper NFA. processing state:%v", state)
        return false
      }
      frag_left := Q.peek_back(&state.frag_stack)
      if frag_left == nil {
        log.errorf("Error during processing. Not enough tokens in stack to create proper NFA. processing state:%v", state)
        return false
      }
      _appendFragment(frag_left, &frag_right, &state.nfa.digraph)
    case .EMPTY:
      _addTokenToStack(state, token, context.temp_allocator)
    }
  case SpecialNfaToken:
    switch tok.op {
    case .HEAD:
      fallthrough
    case .TAIL:
      _addTokenToStack(state, token, context.temp_allocator)
    }
  case AlternationToken:
    if state.frag_stack.len < 2 {
      log.errorf("Error during processing. Not enough tokens in stack to create proper NFA. processing state:%v", state)
      return false
    }
    frag_right, pop_ok := Q.pop_back_safe(&state.frag_stack)
    if !pop_ok {
      log.errorf("Error during processing. Not enough tokens in stack to create proper NFA. processing state:%v", state)
      return false
    }
    frag_left := Q.peek_back(&state.frag_stack)
    if frag_left == nil {
      log.errorf("Error during processing. Not enough tokens in stack to create proper NFA. processing state:%v", state)
      return false
    }
    _alternateFragment(frag_left, &frag_right)
  case AssertionToken:
    switch tok.op {
    case .CARET:
      fallthrough
    case .DOLLAR:
      _addTokenToStack(state, token, context.temp_allocator)
    }
  case QuantityToken:
    if state.frag_stack.len < 1 {
      log.errorf("Error during processing. Not enough tokens in stack to create proper NFA. processing state:%v", state)
      return false
    }
    pfrag := Q.peek_back(&state.frag_stack)
    if pfrag == nil {
      log.errorf("Error during processing. Not enough tokens in stack to create proper NFA. processing state:%v", state)
      return false
    }
    return _repeatFragment(pfrag, state.nfa, tok.lower, (tok.upper.? or_else -1) - tok.lower)
  }
  return true
}

@(require_results)
makeTokenNfaFromPattern :: proc(pattern: string, flags: RegexFlags = {}, allocator := context.allocator) -> (out: TokenNfa, ok: bool) {
  ok = false
  infix_tokens, infix_ok := parseTokensFromString(pattern, flags, context.temp_allocator)
  if !infix_ok {
    return
  }
  postfix_tokens, postfix_ok := convertInfixToPostfix(infix_tokens[:], context.temp_allocator)
  log.debugf("postfix toks:")
  for tok, idx in postfix_tokens {
    log.debugf("% 2d: %v", idx, tok)
  }
  if !postfix_ok {
    return
  }
  out, ok = makeTokenNfaFromPostfixTokens(postfix_tokens[:], allocator)
  if !ok {
    return
  }
  ok = true
  return
}
