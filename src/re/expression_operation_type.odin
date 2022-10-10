package re

@(private)
ExpressionOperationType :: enum {
  // Note: Only .Concatenation and .Alternation have meaningful priorities
  Head            = 11, // beginning of an expression a special reference symbol only for use in the NFA
  Flag            = 10, // Reference - place holder to other expressions
  Token           = 9, // Token, (note: consecutive tokens with same value are not the same token)
  Concatenation   = 8, // implicit
  Alternation     = 7, // |
  ZeroOrOne       = 6, // ?
  ZeroOrMore      = 5, // *
  OneOrMore       = 4, // +
  NumericQuantity = 3, // other numeric quantity
  GroupingBegin   = 2, // (
  GroupingEnd     = 1, // ) must be balanced with .GroupingBegin
  Tail            = 0, // end of an expression, a null symbol only for use in the NFA (non-deterministic finite automata)

  // Note: {} numbered expressions are equivalent to combinations of others
  // example:
  // e{3} = eee
  // e{3,5} = eeee?e?
  // e{3,} = eee+
  // e{,3} = e?e?e?
}

@(private, require_results)
toShortHand_ExpressionOperationType :: proc(operation_type: ExpressionOperationType) -> string {
  // for debugging purposes only
  switch operation_type {
  case .Token:
    return ""
  case .Concatenation:
    return "."
  case .GroupingBegin:
    return "("
  case .GroupingEnd:
    return ")"
  case .Alternation:
    return "|"
  case .ZeroOrOne:
    return "?"
  case .ZeroOrMore:
    return "*"
  case .OneOrMore:
    return "+"
  case .NumericQuantity:
    return "{}"
  case .Head:
    return "<head>"
  case .Tail:
    return "<tail>"
  case .Flag:
    return "<flag>"
  }
  return "unknown"
}
