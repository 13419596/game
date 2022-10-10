package card

import "core:math/rand"
import "core:sort"

CardDeck :: struct {
  top_card_index: int,
  cards:          [dynamic]Card,
}

makeDeck :: proc(num_cards_per_suit: int = 13, num_jokers: int = 0, shuffle: bool = false, r: ^rand.Rand = nil) -> CardDeck {
  num_cards_per_suit := num_cards_per_suit > 0 ? num_cards_per_suit : 0
  num_jokers := num_jokers > 0 ? num_jokers : 0
  suits := [?]Suit{.Heart, .Spade, .Diamond, .Club}
  deck := CardDeck {
    cards = make([dynamic]Card, 0, len(suits) * num_cards_per_suit + num_jokers),
  }
  for n in 0 ..< (len(suits) * num_cards_per_suit) {
    append(&deck.cards, Card{suit = suits[n / num_cards_per_suit], value = (n % num_cards_per_suit + 1)})
  }
  for n in 0 ..< num_jokers {
    append(&deck.cards, Card{suit = .Joker, value = 0})
  }
  deck.top_card_index = len(deck.cards) - 1
  if shuffle {
    shuffleDeck(&deck, r)
  }
  return deck
}

deleteDeck :: proc(deck: ^CardDeck) {
  delete(deck.cards)
}

shuffleDeck :: proc(deck: ^CardDeck, r: ^rand.Rand = nil) {
  rand.shuffle(deck.cards[:deck.top_card_index + 1], r)
}

sortDeck :: proc(deck: ^CardDeck, r: ^rand.Rand = nil) {
  sort.quick_sort_proc(deck.cards[:deck.top_card_index + 1], cmpCard)
}

popCardsFromDeck :: proc(deck: ^CardDeck, num_cards: int = 1) -> []Card {
  num_cards := num_cards > 0 ? num_cards : 0
  num_cards = min(num_cards, deck.top_card_index + 1)
  out := deck.cards[deck.top_card_index - num_cards:deck.top_card_index + 1]
  deck.top_card_index -= num_cards
  return out
}

peekRemainingCards :: proc(deck: ^CardDeck) -> []Card {
  return deck.cards[:deck.top_card_index + 1]
}

getNumRemainingCards :: proc(deck: ^CardDeck) -> int {
  return deck.top_card_index + 1
}


resetDeck :: proc(deck: ^CardDeck) {
  deck.top_card_index = len(deck.cards) + 1
}
