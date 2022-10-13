package re

import queue "core:container/queue"

_PostfixTokens :: struct {
  // internal data
  out_tokens: [dynamic]^Token,
  stack:      queue.Queue(^Token),
}

@(require_results)
_makePostfixTokens :: proc(allocator := context.allocator) -> _PostfixTokens {
  using queue
  out := _PostfixTokens {
    out_tokens = make([dynamic]^Token, allocator),
    stack = Queue(^Token){data = make([dynamic]^Token, allocator)},
  }
  init(&out.stack)
  return out
}

@(private = "file")
_deletePostfixTokens :: proc(token_stack: ^_PostfixTokens) {
  queue.destroy(&token_stack.stack)
  delete(token_stack.out_tokens)
  token_stack.out_tokens = nil
}

///////////////////

_getTokenPriorty :: proc(token: ^Token) -> int {
  switch tok in token {
  case LiteralToken:
    return 10
  case SetToken:
    return 10
  case ZeroWidthToken:
    switch tok.op {
    case .CONCATENATION:
      return 8
    case .ALTERNATION:
      return 7
    case .BEGINNING:
      fallthrough
    case .END:
      return 6
    }
  case QuantityToken:
    return 5
  case GroupBeginToken:
    return 2
  case GroupEndToken:
    return 1
  }
  return 0
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
    case ZeroWidthToken:
      return false
    case QuantityToken:
      return false
    }
  }
  return false
}

@(private = "file")
_addOperator :: proc(self: ^_PostfixTokens, token: ^Token) {
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
  state := _makePostfixTokens(allocator = context.temp_allocator)

  concat_token: Token = ZeroWidthToken{.CONCATENATION}
  loop: for _, token_index in infix_tokens {
    token := &infix_tokens[token_index]

    switch tok in token {
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
    case ZeroWidthToken:
      switch tok.op {
      case .ALTERNATION:
        _addOperator(&state, token)
      case .BEGINNING:
        // may be correct, not sure
        _addOperator(&state, token)
      case .END:
        // may be correct, not sure
        _addOperator(&state, token)
      case .CONCATENATION:
      // not sure what to do here, shouldn't happen
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
