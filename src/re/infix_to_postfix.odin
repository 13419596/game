package re

import queue "core:container/queue"

/*
@(private = "file")
PostfixTokens :: struct($T: typeid) {
  out_tokens: [dynamic]ExpressionToken(T),
  stack:      queue.Queue(ExpressionToken(T)), // make this hold pointers instead..
}

@(private = "file", require_results)
makePostfixTokens :: proc($T: typeid) -> PostfixTokens(T) {
  out := PostfixTokens(T) {
    out_tokens = make([dynamic]ExpressionToken(T)),
    stack = queue.Queue(ExpressionToken(T)){data = make([dynamic]ExpressionToken(T))},
  }
  queue.init(&out.stack)
  return out
}

@(private = "file")
deletePostfixTokens :: proc(token_stack: ^PostfixTokens($T)) {
  queue.destroy(&token_stack.stack)
  delete(token_stack.out_tokens)
  token_stack.out_tokens = {}
}

//////////////

@(private = "file")
addOperator :: proc(self: ^PostfixTokens($T), token: ExpressionToken(T)) {
  // Shunting-yard alg. compares precedence levels of operator to be added and stack.
  for {
    if self.stack.len == 0 || token.operation_type > queue.peek_back(&self.stack).operation_type {
      queue.push_back(&self.stack, token)
      break
    } else {
      // op stack is guaranteed to not be empty here
      append(&self.out_tokens, queue.pop_back(&self.stack))
    }
  }
}

@(private = "file", require_results)
shouldAddImplicitConcatenation :: proc(self: ^PostfixTokens($T), expr_tokens: []ExpressionToken(T)) -> bool {
  for expr_token in expr_tokens {
    switch expr_token.operation_type {
    case .Token:
      fallthrough
    case .GroupingBegin:
      fallthrough
    case .Head:
      fallthrough
    case .Flag:
      return true
    case .GroupingEnd:
      fallthrough
    case .Alternation:
      fallthrough
    case .ZeroOrOne:
      fallthrough
    case .ZeroOrMore:
      fallthrough
    case .OneOrMore:
      return false
    case .Concatenation:
      fallthrough
    case .Tail:
      // should not encounter
      break
    }
  }
  return false
}

////////////////////////////////

@(require_results)
convertInfixToPostfix :: proc(infix_tokens: []ExpressionToken($T)) -> (out_postfix_tokens: [dynamic]ExpressionToken(T), ok: bool) {
  ok = false
  if len(infix_tokens) == 0 {
    ok = true
    // todo - should anything be allocated here? can I just return nil?
    out_postfix_tokens = make([dynamic]ExpressionToken(T))
    return
  }
  state := makePostfixTokens(T)
  defer {
    // At the end, swap the tokens from state, and then delete state
    out_postfix_tokens = state.out_tokens
    state.out_tokens = {}
    deletePostfixTokens(&state)
  }

  for token, token_index in infix_tokens {
    switch token.operation_type {
    case .Head:
      // TODO remove head and just treat as regular flag.
      // if (!isValidRecursiveHeadAddition(itr + 1, end)) {
      //     log_warning << "Not adding invalid recursive head token.";
      //     return {};
      // }
      // out.push_back(val);
      continue
    case .Flag:
      fallthrough
    case .Token:
      append(&state.out_tokens, token)
      if shouldAddImplicitConcatenation(&state, infix_tokens[token_index + 1:]) {
        addOperator(&state, ExpressionToken(T){operation_type = .Concatenation})
      }
    case .GroupingBegin:
      // always push group begins
      queue.push_back(&state.stack, token)
    case .GroupingEnd:
      {
        // keep popping op stack till group end is found
        retrieved_begin := false
        for state.stack.len > 0 {
          back_token := queue.pop_back(&state.stack)
          if back_token.operation_type == .GroupingBegin {
            retrieved_begin = true
            break
          }
          append(&state.out_tokens, back_token)
        }
        if !retrieved_begin {
          // "Unbalanced parenthesis in expression. Cannot compute postfix expression.";
          ok = false
          return
        }
        if shouldAddImplicitConcatenation(&state, infix_tokens[token_index + 1:]) {
          addOperator(&state, ExpressionToken(T){operation_type = .Concatenation})
        }
      }
    case .Alternation:
      addOperator(&state, token)
    case .ZeroOrOne:
      fallthrough
    case .ZeroOrMore:
      fallthrough
    case .OneOrMore:
      // ?*+ tightly binds to previous token, so push token to output now.
      append(&state.out_tokens, token)
      if shouldAddImplicitConcatenation(&state, infix_tokens[token_index + 1:]) {
        addOperator(&state, ExpressionToken(T){operation_type = .Concatenation})
      }
    case .Tail:
    case .Concatenation:
      // all other cases should not happen
      // Incoming stream should not have a tail, or a concatenation symbol (they are implicit)
      break
    }
  }
  // finish it out by pushing all remaining ops to the output.
  for state.stack.len > 0 {
    back_token := queue.pop_back(&state.stack)
    if back_token.operation_type == .GroupingBegin {
      // "Unbalanced parenthesis in expression. Cannot compute postfix expression."
      ok = false
      return
    }
    append(&state.out_tokens, back_token)
  }
  ok = true
  return
}
*/
