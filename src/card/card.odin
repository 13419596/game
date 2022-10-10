package card

Suit :: enum {
  Heart,
  Spade,
  Diamond,
  Club,
  Joker,
}

Card :: struct {
  suit:  Suit,
  value: int,
}

cmpCard :: proc(lhs: Card, rhs: Card) -> int {
  // <  : negative,
  // == : zero
  // >  : positive
  cmp := lhs.suit < rhs.suit ? -1 : (lhs.suit > rhs.suit ? +1 : (lhs.value < rhs.value ? -1 : (lhs.value > rhs.value ? +1 : 0)))
  return cmp
}
