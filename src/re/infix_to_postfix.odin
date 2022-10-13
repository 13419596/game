package re

import queue "core:container/queue"

_InfixToPostfixState :: struct {
  // internal data
  out_tokens: [dynamic]^Token,
  stack:      queue.Queue(^Token),
}

@(require_results)
_makeInfixToPostfixState :: proc(allocator := context.allocator) -> _InfixToPostfixState {
  out := _InfixToPostfixState {
    out_tokens = make([dynamic]^Token, allocator),
    stack = queue.Queue(^Token){data = make([dynamic]^Token, allocator)},
  }
  queue.init(&out.stack)
  return out
}

@(private = "file")
_deleteInfixToPostfixState :: proc(token_stack: ^_InfixToPostfixState) {
  queue.destroy(&token_stack.stack)
  delete(token_stack.out_tokens)
  token_stack.out_tokens = nil
}

///////////////////


_getTokenPriorty :: proc(token: ^Token) -> int {
  top :: 4
  concat :: 3
  below_concat :: 2
  bottom :: 1
  switch tok in token {
  case LiteralToken:
    return top
  case SetToken:
    return top
  case SpecialToken:
    switch tok.op {
    case .HEAD:
      return top
    case .TAIL:
      return top
    case .CONCATENATION:
      return concat
    }
  case OperationToken:
    switch tok.op {
    case .ALTERNATION:
      return below_concat
    case .DOLLAR:
      return bottom
    case .CARET:
      return bottom
    }
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
    case OperationToken:
      return false
    case QuantityToken:
      return false
    case SpecialToken:
      // special tokens only appear in the NFA
      return false
    }
  }
  return false
}

@(private = "file")
_addOperator :: proc(self: ^_InfixToPostfixState, token: ^Token) {
  // Shunting-yard alg. compares precedence levels of operator to be added and stack.
  for {
    if self.stack.len == 0 || _getTokenPriorty(token) > _getTokenPriorty(queue.peek_back(&self.stack)^) {
      queue.push_back(&self.stack, token)
      break
    } else {
      // op stack is guaranteed to not be empty here
      append(&self.out_tokens, queue.pop_back(&self.stack))
    }
  }
}


////////////////////////////////

@(require_results)
convertInfixToPostfix :: proc(infix_tokens: []Token, allocator := context.allocator) -> (out_postfix_tokens: [dynamic]Token, ok: bool) {
  // converts infix tokens to postfix order. It assumes that the groupigns are balanced
  ok = true
  if len(infix_tokens) == 0 {
    return
  }
  // temporary state 
  state := _makeInfixToPostfixState(allocator = context.temp_allocator)

  concat_token: Token = SpecialToken{.CONCATENATION}
  loop: for _, token_index in infix_tokens {
    token := &infix_tokens[token_index]

    switch tok in token {
    case SpecialToken:
      // shouldn't appear in input stream, but treat it the same as a regular literal token
      append(&state.out_tokens, token)
      if _shouldAddImplicitConcatenation(infix_tokens[token_index + 1:]) {
        _addOperator(&state, &concat_token)
      }
    case LiteralToken:
      append(&state.out_tokens, token)
      if _shouldAddImplicitConcatenation(infix_tokens[token_index + 1:]) {
        _addOperator(&state, &concat_token)
      }
    case SetToken:
      append(&state.out_tokens, token)
      if _shouldAddImplicitConcatenation(infix_tokens[token_index + 1:]) {
        _addOperator(&state, &concat_token)
      }
    case GroupBeginToken:
      // always push group begins
      append(&state.out_tokens, token)
      queue.push_back(&state.stack, token)
    case GroupEndToken:
      {
        // keep popping op stack till group end is found
        retrieved_begin := false
        for state.stack.len > 0 {
          back_token: ^Token = queue.pop_back(&state.stack)
          if _, is_group_begin := back_token.(GroupBeginToken); is_group_begin {
            retrieved_begin = true
            break
          }
          append(&state.out_tokens, back_token)
        }
        append(&state.out_tokens, token)
        if !retrieved_begin {
          // "Unbalanced parenthesis in expression. Cannot compute postfix expression.";
          ok = false
          break loop
        }
        if _shouldAddImplicitConcatenation(infix_tokens[token_index + 1:]) {
          _addOperator(&state, &concat_token)
        }
      }
    case OperationToken:
      switch tok.op {
      case .ALTERNATION:
        _addOperator(&state, token)
      case .CARET:
        // may be correct, not sure
        _addOperator(&state, token)
      case .DOLLAR:
        // may be correct, not sure
        _addOperator(&state, token)
      }
    case QuantityToken:
      // quantity tokens tightly binds to previous token, so push token to output now.
      append(&state.out_tokens, token)
      if _shouldAddImplicitConcatenation(infix_tokens[token_index + 1:]) {
        _addOperator(&state, &concat_token)
      }
    }
  }

  // finish it out by pushing all remaining ops to the output.
  for state.stack.len > 0 {
    append(&state.out_tokens, queue.pop_back(&state.stack))
  }

  // copy data referenced by pointers to output
  out_postfix_tokens = make([dynamic]Token, allocator)
  for token in state.out_tokens {
    append(&out_postfix_tokens, copy_Token(token))
  }
  return
}
