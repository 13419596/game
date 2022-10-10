package util

IndexIter :: struct($N: int) {
  indices:  [N]int,
  lengths:  [N]int,
  overflow: int,
}

makeIndexIter :: proc(lengths: [$N]int) -> IndexIter(N) {
  out := IndexIter(N){{}, lengths, {}}
  return out
}

incrementIndexIter :: proc(index: ^IndexIter($N)) {
  n := N
  overflow := true
  for ; n > 0; n -= 1 {
    idx := n - 1
    index.indices[idx] += 1
    if index.indices[idx] < index.lengths[idx] {
      overflow = false
      break
    }
    index.indices[idx] = 0
  }
  if overflow {
    index.overflow += 1
  }
}

decrementIndexIter :: proc(index: ^IndexIter($N)) {
  n := N
  underflow := true
  for ; n > 0; n -= 1 {
    idx := n - 1
    if index.indices[idx] > 0 {
      index.indices[idx] -= 1
      underflow = false
      break
    }
    index.indices[idx] = index.lengths[idx] - 1
  }
  if underflow {
    index.overflow -= 1
  }
}
