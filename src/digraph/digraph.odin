package glog

import set "game:container/set"

Digraph :: struct($T: typeid) {
  NodeType: T,
  data:     map[T]set.Set(T),
}
