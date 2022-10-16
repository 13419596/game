package re

import "core:log"
import Q "core:container/queue"

_InfixToPostfixState :: struct {
  // internal data
  out_tokens: [dynamic]^Token,
  op_stack:   Q.Queue(^Token),
}

@(require_results)
_makeInfixToPostfixState :: proc(allocator := context.allocator) -> _InfixToPostfixState {
  out := _InfixToPostfixState {
    out_tokens = make([dynamic]^Token, allocator),
    op_stack = Q.Queue(^Token){data = make([dynamic]^Token, allocator)},
  }
  Q.init(&out.op_stack)
  return out
}

@(private = "file")
_deleteInfixToPostfixState :: proc(token_stack: ^_InfixToPostfixState) {
  Q.destroy(&token_stack.op_stack)
  delete(token_stack.out_tokens)
  token_stack.out_tokens = nil
}

///////////////////


_getTokenPriorty :: proc(token: ^Token) -> int {
  top :: 5
  concat :: 3
  alternate :: concat - 1
  bottom :: 1
  switch tok in token {
  case LiteralToken:
    return top
  case SetToken:
    return top
  case SpecialNfaToken:
    return top
  case AlternationToken:
    return alternate
  case ImplicitToken:
    switch tok.op {
    case .CONCATENATION:
      return concat
    case .EMPTY:
      return top
    }
  case AssertionToken:
    return top
  case QuantityToken:
    return bottom
  case GroupBeginToken:
    return bottom
  case GroupEndToken:
    return bottom
  }
  return bottom
}

@(require_results)
_shouldAddImplicitConcatenation :: proc(tokens: []Token) -> bool {
  for token in tokens {
    switch tok in token {
    case LiteralToken:
      return true
    case SetToken:
      return true
    case GroupBeginToken:
      return true
    //////////
    case GroupEndToken:
      return false
    case AlternationToken:
      return false
    case ImplicitToken:
      switch tok.op {
      case .CONCATENATION:
        return false
      case .EMPTY:
        return true
      }
    case AssertionToken:
      switch tok.op {
      case .DOLLAR:
        return true
      case .CARET:
        return true
      }
    case QuantityToken:
      return false
    case SpecialNfaToken:
      // special tokens only appear in the NFA
      return false
    }
  }
  return false
}

@(private = "file")
_addOperator :: proc(self: ^_InfixToPostfixState, token: ^Token) {
  // Shunting-yard alg. compares precedence levels of operator to be added and stack.
  token_pri := _getTokenPriorty(token)
  for {
    if self.op_stack.len == 0 {
      Q.push_back(&self.op_stack, token)
      break
    }
    top_stack_token := Q.peek_back(&self.op_stack)^
    top_stack_pri := _getTokenPriorty(top_stack_token)
    if token_pri > top_stack_pri {
      Q.push_back(&self.op_stack, token)
      break
    } else {
      // op stack is guaranteed to not be empty here
      append(&self.out_tokens, Q.pop_back(&self.op_stack))
    }
  }
}

@(private = "file")
_pushTokenAndPossibleImplicitConcat :: proc(state: ^_InfixToPostfixState, token: ^Token, trailing_infix_tokens: []Token, concat_token: ^Token) {
  append(&state.out_tokens, token)
  should_add := _shouldAddImplicitConcatenation(trailing_infix_tokens)
  if should_add {
    log.debugf("Token:%v; adding implicit concat because of trailing token:%v", token, trailing_infix_tokens[0])
    _addOperator(state, concat_token)
  }
}

@(require_results)
convertInfixToPostfix :: proc(infix_tokens: []Token, allocator := context.allocator) -> (out_postfix_tokens: [dynamic]Token, ok: bool) {
  // converts infix tokens to postfix order. It assumes that the groupigns are balanced
  ok = true
  log.debugf("Processing infix list:%v", infix_tokens)
  if len(infix_tokens) == 0 {
    log.debugf("List of infix tokens is empty. Returning empty postfix token list.")
    return
  }
  // temporary state 
  state := _makeInfixToPostfixState(allocator = context.temp_allocator)

  concat_token: Token = ImplicitToken{.CONCATENATION}
  loop: for _, token_index in infix_tokens {
    token := &infix_tokens[token_index]
    switch tok in token {
    case SpecialNfaToken:
      // shouldn't appear in input stream, but treat it the same as a regular literal token
      log.infof("Got unexpected token:%v in infix list. Treating as a regular literal token", tok)
      _pushTokenAndPossibleImplicitConcat(&state, token, infix_tokens[token_index + 1:], &concat_token)
    case LiteralToken:
      _pushTokenAndPossibleImplicitConcat(&state, token, infix_tokens[token_index + 1:], &concat_token)
    case SetToken:
      _pushTokenAndPossibleImplicitConcat(&state, token, infix_tokens[token_index + 1:], &concat_token)
    case GroupBeginToken:
      // always push group begins
      append(&state.out_tokens, token)
      Q.push_back(&state.op_stack, token) // push group begin, so that group end knows how many symbols to pop
    case GroupEndToken:
      {
        // keep popping op stack till first group begin is found
        retrieved_begin := false
        for state.op_stack.len > 0 {
          back_token: ^Token = Q.pop_back(&state.op_stack)
          if _, is_group_begin := back_token.(GroupBeginToken); is_group_begin {
            retrieved_begin = true
            break
          }
          append(&state.out_tokens, back_token)
        }
        if token_index > 0 {
          // as long as previous token was not a group begin '(', add a concatenate
          if _, gbok := infix_tokens[token_index - 1].(GroupBeginToken); !gbok {
            append(&state.out_tokens, &concat_token)
          }
        }
        // always add ), concat
        append(&state.out_tokens, token)
        append(&state.out_tokens, &concat_token)
        if _shouldAddImplicitConcatenation(infix_tokens[token_index + 1:]) {
          _addOperator(&state, &concat_token)
        }
        if !retrieved_begin {
          log.warnf("Unbalanced group. Cannot create valid postfix expression.")
          ok = false
          break loop
        }
      }
    case AssertionToken:
      switch tok.op {
      case .CARET:
        _pushTokenAndPossibleImplicitConcat(&state, token, infix_tokens[token_index + 1:], &concat_token)
      case .DOLLAR:
        _pushTokenAndPossibleImplicitConcat(&state, token, infix_tokens[token_index + 1:], &concat_token)
      }
    case QuantityToken:
      // quantity tokens tightly binds to previous token, so push token to output now.
      _pushTokenAndPossibleImplicitConcat(&state, token, infix_tokens[token_index + 1:], &concat_token)
    case AlternationToken:
      _addOperator(&state, token)
    case ImplicitToken:
      switch tok.op {
      case .CONCATENATION:
        _addOperator(&state, token)
      case .EMPTY:
        _pushTokenAndPossibleImplicitConcat(&state, token, infix_tokens[token_index + 1:], &concat_token)
      }
    }
  }

  if !ok {
    //return
  }
  // finish it out by pushing all remaining ops to the output.
  for state.op_stack.len > 0 {
    append(&state.out_tokens, Q.pop_back(&state.op_stack))
  }

  // copy data referenced by pointers to output
  out_postfix_tokens = make([dynamic]Token, allocator)
  for token in state.out_tokens {
    append(&out_postfix_tokens, copy_Token(token))
  }
  return
}
