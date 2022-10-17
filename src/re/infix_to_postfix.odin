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

//
// append(&state.out_tokens, token)

@(require_results)
convertInfixToPostfix :: proc(infix_tokens: []Token, allocator := context.allocator) -> (out_postfix_tokens: [dynamic]Token, ok: bool) {
  // converts infix tokens to postfix order. It assumes that the groupigns are balanced
  ok = true
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
      append(&state.out_tokens, token)
    case LiteralToken:
      append(&state.out_tokens, token)
    case SetToken:
      append(&state.out_tokens, token)
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
        if !retrieved_begin || len(state.out_tokens) < 1 {
          log.warnf("Unbalanced group. Cannot create valid postfix expression.")
          ok = false
          break loop
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
      }
    case AssertionToken:
      append(&state.out_tokens, token)
    case QuantityToken:
      // quantity tokens tightly binds to previous token, so push token to output now.
      append(&state.out_tokens, token)
    case AlternationToken:
      _addOperator(&state, token)
    case ImplicitToken:
      switch tok.op {
      case .CONCATENATION:
        _addOperator(&state, token)
      case .EMPTY:
        append(&state.out_tokens, token)
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
