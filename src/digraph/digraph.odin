package digraph

import "core:runtime"
import set "game:container/set"

Digraph :: struct($T: typeid) {
  data: map[T]set.Set(T),
}

makeDigraph :: proc($T: typeid, allocator := context.allocator) -> Digraph(T) {
  out := Digraph(T) {
    data = make(map[T]set.Set(T), 1, allocator),
  }
  return out
}

makeDigraphFromEdges :: proc(edges: [][2]$T, allocator := context.allocator) -> Digraph(T) {
  out := makeDigraph(T, allocator)
  addEdges(&out, edges)
  return out
}

deleteDigraph :: proc(dg: ^$T/Digraph($S)) {
  for k, v in &dg.data {
    set.deleteSet(&v)
  }
  delete(dg.data)
  dg.data = {}
}

addNode :: proc(self: ^Digraph($T), node: T) {
  if node not_in self.data {
    self.data[node] = set.makeSet(T)
  }
}

addEdge :: proc(self: ^Digraph($T), start, end: T) {
  addNode(self, start)
  addNode(self, end)
  set.add(&self.data[start], end)
}

addEdges :: proc(self: ^Digraph($T), edges: [][2]T) {
  for edge in edges {
    addNode(self, edge[0])
    addNode(self, edge[1])
    set.add(&self.data[edge[0]], edge[1])
  }
}

removeNode :: proc(self: ^Digraph($T), node: T) {
  if node not_in self.data {
    return
  }
  for _, out_nodes in &self.data {
    set.discard(&out_nodes, node)
  }
  delete_key(&self.data, node)
}

removeEdge :: proc(self: ^Digraph($T), start, end: T) {
  if start not_in self.data || end not_in self.data {
    return
  }
  set.discard(&self.data[start], end)
}

getNumNodes :: proc(self: ^Digraph($T)) -> int {
  return len(self.data)
}

hasNode :: proc(self: ^Digraph($T), node: T) -> bool {
  return node in self.data
}

hasEdge :: proc(self: ^Digraph($T), start, end: T) -> bool {
  if start not_in self.data || end not_in self.data {
    return false
  }
  return set.contains(&self.data[start], end)
}
