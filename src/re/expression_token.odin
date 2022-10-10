package re

import "core:fmt"

ExpressionToken :: struct {
  index:          int,
  operation_type: ExpressionOperationType,
}

@(require_results)
toShortHand_ExpressionToken :: proc(token: $T/ExpressionToken) -> string {
  // for debugging purposes only
  return fmt.aprintf("(%v:%v)", token.index, token.operation_type)
  if val, ok := token.value.(T); ok {
    if token.operation_type != .Token {
      return fmt.aprintf("%v%v", val, toShortHand_ExpressionOperationType(token.operation_type))
    } else {
      return fmt.aprint(val)
    }
  } else {
    return toShortHand_ExpressionOperationType(token.operation_type)
  }
}
