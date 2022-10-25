package main

import "core:fmt"

Node :: struct($T:typeid) {
  data : map[T]Node(T),
}

testNode :: proc($T:typeid) {
  root := Node(T){data=make(map[T]Node(T))}
  root.data[T(65)] = Node(T){}
  root.data[T(66)] = Node(T){}
  root.data[T(67)] = Node(T){}
  fmt.printf("\nNode Type: %T\n", T{})
  fmt.printf("root:%v\n", root)
  for k, v in root.data {
    fmt.printf("k:%v; int(k):%v v:%v\n", k, int(k),v)
  }
}

main :: proc() {
  testNode(rune)
  testNode(int)
}
