package container_set

@(private = "file")
DEFAULT_RESERVE_CAPACITY :: 16

Set :: struct($T: typeid) {
  // no built-in set type, so use a map instead
  set: map[T]any,
}

@(require_results)
makeSet :: proc($T: typeid, allocator := context.allocator, loc := #caller_location) -> Set(T) {
  out := Set(T) {
    set = make(map[T]any, DEFAULT_RESERVE_CAPACITY, allocator, loc),
  }
  return out
}

deleteSet :: proc(set: ^$S/Set($T)) {
  if set.set != nil {
    delete(set.set)
    set.set = nil
  }
}

//////////////////////////////////////////////

@(private, require_results)
fromArray_slice :: proc(arr: $A/[]$T, allocator := context.allocator) -> Set(T) {
  out := makeSet(T = T, allocator = allocator)
  update(&out, arr)
  return out
}

@(private, require_results)
fromArray_array :: proc(arr: $A/[$N]$T, allocator := context.allocator) -> Set(T) {
  arr := arr // make addressable
  return fromArray_slice(arr = arr[:], allocator = allocator)
}

@(require_results)
fromArray :: proc {
  fromArray_slice,
  fromArray_array,
}

//////////////////////////////////////////////

reset :: proc(self: ^$S/Set($T)) {
  clear(&self.set)
}

@(require_results)
copy :: proc(self: ^$S/Set($T), allocator := context.allocator) -> Set(T) {
  out := makeSet(T = T, allocator = context.allocator)
  reserve(&out.set, len(self.set))
  for item, val in self.set {
    out.set[item] = val
  }
  return out
}

@(require_results)
asArray :: proc(self: ^$S/Set($T), allocator := context.allocator, loc := #caller_location) -> [dynamic]T {
  out := make([dynamic]T, 0, len(self.set), context.allocator, loc)
  for item, _ in self.set {
    append(&out, item)
  }
  return out
}

size :: proc(self: ^$S/Set($T)) -> int {
  return len(self.set)
}

//////////////////////////////////////////////

add :: proc(self: ^$S/Set($T), item: T) {
  self.set[item] = nil
}

// removes an element from the list, returns True if discarded, false if element was not present
discard :: proc(self: ^$S/Set($T), item: T) -> bool {
  out := item in self.set
  delete_key(&self.set, item)
  return out
}

// Pop an element from the set
@(require_results)
pop :: proc(self: ^$S/Set($T), loc := #caller_location) -> (elem: T) {
  assert(condition = len(self.set) > 0, loc = loc)
  for item, _ in self.set {
    elem = item
    break
  }
  delete_key(&self.set, elem)
  return
}

// Safely pop an element from the set
@(require_results)
pop_safe :: proc(self: ^$S/Set($T)) -> (elem: T, ok: bool) {
  ok = false
  for item, _ in self.set {
    elem = item
    ok = true
    break
  }
  if ok {
    delete_key(&self.set, elem)
  }
  return
}

//////////////////////////////////////////////

@(private)
update_set :: proc(self, other: ^$S/Set($T)) {
  for item, _ in other.set {
    self.set[item] = nil // add item
  }
}

@(private)
update_slice :: proc(self: ^$S/Set($T), items: $A/[]T) {
  for item in items {
    self.set[item] = nil // add item
  }
}

@(private)
update_array :: proc(self: ^$S/Set($T), items: $A/[$N]T) {
  for item in items {
    self.set[item] = nil // add item
  }
}

@(require_results)
update :: proc {
  update_set,
  update_slice,
  update_array,
}

//////////////////////////////////////////////

contains :: proc(self: ^$S/Set($T), item: T) -> bool {
  return item in self.set
}

//////////////////////////////////////////////

@(private)
issuperset_set_set :: proc(lhs: ^$S1/Set($T), rhs: ^$S2/Set(T)) -> bool {
  // Evaluates: lhs ⊇ rhs
  // if length of rhs is greater than lhs, then cannot be a superset
  if len(lhs.set) < len(rhs.set) {
    return false
  }
  // true if all elements in rhs are in lhs
  for item, _ in rhs.set {
    if !(item in lhs.set) {
      return false
    }
  }
  return true
}

@(private)
issuperset_set_slice :: proc(lhs: ^$S1/Set($T), rhs: $A/[]T) -> bool {
  // Evaluates: lhs ⊇ rhs
  // true if all elements in rhs are in lhs
  for item in rhs {
    if !(item in lhs.set) {
      return false
    }
  }
  return true
}

@(private)
issuperset_set_array :: proc(lhs: ^$S1/Set($T), rhs: $A/[$N]T) -> bool {
  // Evaluates: lhs ⊇ rhs
  rhs := rhs // make addressable
  return issuperset_set_slice(lhs, rhs[:])
}

@(private)
issuperset_slice_set :: proc(lhs: $A/[]$T, rhs: ^$S1/Set(T)) -> bool {
  // Evaluates: lhs ⊇ rhs
  return issubset(rhs, lhs) // swap so first arg is set
}

@(private)
issuperset_array_set :: proc(lhs: $A/[$N]$T, rhs: ^$S1/Set(T)) -> bool {
  // Evaluates: lhs ⊇ rhs
  lhs := lhs // make addressable
  return issubset(rhs, lhs[:]) // swap so first arg is set
}

@(private)
issuperset_slice_slice :: proc(lhs, rhs: $A/[]$T) -> bool {
  // Evaluates: lhs ⊇ rhs
  lhs_set := fromArray(arr = lhs, allocator = context.temp_allocator) // Convert first to set
  return issuperset(&lhs_set, rhs)
}

@(private)
issuperset_slice_array :: proc(lhs: $A1/[]$T, rhs: $A2/[$N]T) -> bool {
  // Evaluates: lhs ⊇ rhs
  lhs_set := fromArray(arr = lhs, allocator = context.temp_allocator)
  rhs := rhs // make addressable
  return issuperset(&lhs_set, rhs[:])
}

@(private)
issuperset_array_slice :: proc(lhs: $A1/[$N]$T, rhs: $A2/[]T) -> bool {
  // Evaluates: lhs ⊇ rhs
  lhs := lhs // make addressable
  lhs_set := fromArray(arr = lhs[:], allocator = context.temp_allocator) // Convert first to set
  return issuperset(&lhs_set, rhs)
}

@(private)
issuperset_array_array :: proc(lhs: $A1/[$N]$T, rhs: $A2/[$M]T) -> bool {
  // Evaluates: lhs ⊇ rhs
  lhs := lhs // make addressable
  lhs_set := fromArray(arr = lhs[:], allocator = context.temp_allocator) // Convert first to set
  rhs := rhs // make addressable
  return issuperset(&lhs_set, rhs[:])
}

issuperset :: proc {
  issuperset_set_set,
  issuperset_set_slice,
  issuperset_set_array,
  issuperset_slice_set,
  issuperset_slice_slice,
  issuperset_slice_array,
  issuperset_array_set,
  issuperset_array_slice,
  issuperset_array_array,
}

//////////////////////////////////////////////

@(private)
issubset_set_set :: proc(lhs: ^$S1/Set($T), rhs: ^$S2/Set(T)) -> bool {
  // Evaluates: lhs ⊆ rhs
  // if length of lhs is greater than rhs, then cannot be a superset
  if len(lhs.set) > len(rhs.set) {
    return false
  }
  // true if all elements in lhs are in rhs
  for item, _ in lhs.set {
    if !(item in rhs.set) {
      return false
    }
  }
  return true
}

@(private)
issubset_set_slice :: proc(lhs: ^$S1/Set($T), rhs: $A/[]T) -> bool {
  // Evaluates: lhs ⊆ rhs
  // if length of lhs is greater than rhs, then cannot be a superset
  if len(lhs.set) > len(rhs) {
    return false
  }
  // convert rhs to set, so membership function is available
  rhs_set := fromArray(arr = rhs, allocator = context.temp_allocator)
  return issubset(lhs, &rhs_set)
}

@(private)
issubset_set_array :: proc(lhs: ^$S1/Set($T), rhs: $A/[$N]T) -> bool {
  // Evaluates: lhs ⊆ rhs
  rhs := rhs // make addressable
  return issubset_set_slice(lhs, rhs[:])
}

@(private)
issubset_slice_set :: proc(lhs: $A/[]$T, rhs: ^$S1/Set(T)) -> bool {
  // Evaluates: lhs ⊆ rhs
  return issuperset(rhs, lhs) // swap so first arg is set
}

@(private)
issubset_array_set :: proc(lhs: $A/[$N]$T, rhs: ^$S1/Set(T)) -> bool {
  // Evaluates: lhs ⊆ rhs
  return issuperset(rhs, lhs) // swap so first arg is set
}

@(private)
issubset_slice_slice :: proc(lhs, rhs: $A/[]$T) -> bool {
  // Evaluates: lhs ⊆ rhs
  lhs_set := fromArray(arr = lhs, allocator = context.temp_allocator) // Convert first to set
  return issubset(&lhs_set, rhs)
}

@(private)
issubset_slice_array :: proc(lhs: $A1/[]$T, rhs: $A2/[$N]T) -> bool {
  // Evaluates: lhs ⊆ rhs
  lhs_set := fromArray(arr = lhs, allocator = context.temp_allocator)
  rhs := rhs // make addressable
  return issubset(&lhs_set, rhs[:])
}

@(private)
issubset_array_slice :: proc(lhs: $A1/[$N]$T, rhs: $A2/[]T) -> bool {
  // Evaluates: lhs ⊆ rhs
  lhs := lhs // make addressable
  lhs_set := fromArray(arr = lhs[:], allocator = context.temp_allocator) // Convert first to set
  return issubset(&lhs_set, rhs)
}

@(private)
issubset_array_array :: proc(lhs: $A1/[$N]$T, rhs: $A2/[$M]T) -> bool {
  // Evaluates: lhs ⊆ rhs
  lhs := lhs // make addressable
  lhs_set := fromArray(arr = lhs[:], allocator = context.temp_allocator) // Convert first to set
  rhs := rhs // make addressable
  return issubset(&lhs_set, rhs[:])
}


issubset :: proc {
  issubset_set_set,
  issubset_set_slice,
  issubset_set_array,
  issubset_slice_set,
  issubset_slice_slice,
  issubset_slice_array,
  issubset_array_set,
  issubset_array_slice,
  issubset_array_array,
}

//////////////////////////////////////////////

@(private)
isequal_set_set :: proc(lhs: ^$S1/Set($T), rhs: ^$S2/Set(T)) -> bool {
  // if same length and is super/subset, then must be equal
  if len(lhs.set) != len(rhs.set) {
    return false
  }
  for item, _ in lhs.set {
    if item not_in rhs.set {
      return false
    }
  }
  return true
}

@(private)
isequal_set_slice :: proc(lhs: ^$S/Set($T), rhs: $A/[]T) -> bool {
  rhs_set := fromArray(arr = rhs, allocator = context.temp_allocator)
  return isequal(lhs, &rhs_set)
}

@(private)
isequal_set_array :: proc(lhs: ^$S/Set($T), rhs: $A/[$N]T) -> bool {
  rhs := rhs // make addressable
  rhs_set := fromArray(arr = rhs[:], allocator = context.temp_allocator)
  return isequal(lhs, &rhs_set)
}

@(private)
isequal_slice_set :: proc(lhs: $A/[]$T, rhs: ^$S/Set(T)) -> bool {
  lhs_set := fromArray(arr = lhs, allocator = context.temp_allocator)
  return isequal(&lhs_set, rhs)
}

@(private)
isequal_array_set :: proc(lhs: $A/[$N]$T, rhs: ^$S/Set(T)) -> bool {
  lhs := lhs // make addressable
  lhs_set := fromArray(arr = lhs[:], allocator = context.temp_allocator)
  return isequal(&lhs_set, rhs)
}

@(private)
isequal_slice_slice :: proc(lhs, rhs: $A/[]$T) -> bool {
  lhs_set := fromArray(arr = lhs, allocator = context.temp_allocator)
  rhs_set := fromArray(arr = rhs, allocator = context.temp_allocator)
  return isequal(&lhs_set, &rhs_set)
}

@(private)
isequal_slice_array :: proc(lhs: $A1/[]$T, rhs: $A2/[$N]T) -> bool {
  lhs_set := fromArray(arr = lhs, allocator = context.temp_allocator)
  rhs := rhs // make addressable
  rhs_set := fromArray(arr = rhs, allocator = context.temp_allocator)
  return isequal(&lhs_set, &rhs_set)
}

@(private)
isequal_array_slice :: proc(lhs: $A1/[$N]$T, rhs: $A2/[]T) -> bool {
  lhs := lhs // make addressable
  lhs_set := fromArray(arr = lhs, allocator = context.temp_allocator)
  rhs_set := fromArray(arr = rhs, allocator = context.temp_allocator)
  return isequal(&lhs_set, &rhs_set)
}

@(private)
isequal_array_array :: proc(lhs: $A1/[$M]$T, rhs: $A2/[$N]T) -> bool {
  lhs := lhs // make addressable
  lhs_set := fromArray(arr = lhs, allocator = context.temp_allocator)
  rhs := rhs // make addressable
  rhs_set := fromArray(arr = rhs[:], allocator = context.temp_allocator)
  return isequal(&lhs_set, &rhs_set)
}

isequal :: proc {
  isequal_set_set,
  isequal_set_slice,
  isequal_set_array,
  isequal_slice_set,
  isequal_slice_slice,
  isequal_slice_array,
  isequal_array_set,
  isequal_array_slice,
  isequal_array_array,
}

//////////////////////////////////////////////

@(private)
isdisjoint_set_set :: proc(lhs: ^$S1/Set($T), rhs: ^$S2/Set(T)) -> bool {
  // (lhs ∩ rhs) == ∅
  for item, _ in lhs.set {
    if item in rhs.set {
      return false
    }
  }
  for item, _ in rhs.set {
    if item in lhs.set {
      return false
    }
  }
  return true
}

@(private)
isdisjoint_set_slice :: proc(lhs: ^$S/Set($T), rhs: $A/[]T) -> bool {
  rhs_set := fromArray(arr = rhs, allocator = context.temp_allocator)
  return isdisjoint(lhs, &rhs_set)
}

@(private)
isdisjoint_set_array :: proc(lhs: ^$S/Set($T), rhs: $A/[$N]T) -> bool {
  rhs := rhs // make addressable
  rhs_set := fromArray(arr = rhs[:], allocator = context.temp_allocator)
  return isdisjoint(lhs, &rhs_set)
}

@(private)
isdisjoint_slice_set :: proc(lhs: $A/[]$T, rhs: ^$S/Set(T)) -> bool {
  lhs_set := fromArray(arr = lhs, allocator = context.temp_allocator)
  return isdisjoint(&lhs_set, rhs)
}

@(private)
isdisjoint_array_set :: proc(lhs: $A/[$N]$T, rhs: ^$S/Set(T)) -> bool {
  lhs := lhs // make addressable
  lhs_set := fromArray(arr = lhs[:], allocator = context.temp_allocator)
  return isdisjoint(&lhs_set, rhs)
}

@(private)
isdisjoint_slice_slice :: proc(lhs, rhs: $A/[]$T) -> bool {
  lhs_set := fromArray(arr = lhs, allocator = context.temp_allocator)
  rhs_set := fromArray(arr = rhs, allocator = context.temp_allocator)
  return isdisjoint(&lhs_set, &rhs_set)
}

@(private)
isdisjoint_slice_array :: proc(lhs: $A1/[]$T, rhs: $A2/[$N]T) -> bool {
  lhs_set := fromArray(arr = lhs, allocator = context.temp_allocator)
  rhs := rhs // make addressable
  rhs_set := fromArray(arr = rhs[:], allocator = context.temp_allocator)
  return isdisjoint(&lhs_set, &rhs_set)
}

@(private)
isdisjoint_array_slice :: proc(lhs: $A1/[$N]$T, rhs: $A2/[]T) -> bool {
  lhs := lhs // make addressable
  lhs_set := fromArray(arr = lhs[:], allocator = context.temp_allocator)
  rhs_set := fromArray(arr = rhs, allocator = context.temp_allocator)
  return isdisjoint(&lhs_set, &rhs_set)
}

@(private)
isdisjoint_array_array :: proc(lhs: $A1/[$M]$T, rhs: $A2/[$N]T) -> bool {
  lhs := lhs // make addressable
  lhs_set := fromArray(arr = lhs[:], allocator = context.temp_allocator)
  rhs := rhs // make addressable
  rhs_set := fromArray(arr = rhs[:], allocator = context.temp_allocator)
  return isdisjoint(&lhs_set, &rhs_set)
}

isdisjoint :: proc {
  isdisjoint_set_set,
  isdisjoint_set_slice,
  isdisjoint_set_array,
  isdisjoint_slice_set,
  isdisjoint_slice_slice,
  isdisjoint_slice_array,
  isdisjoint_array_set,
  isdisjoint_array_slice,
  isdisjoint_array_array,
}

//////////////////////////////////////////////

@(private)
difference_update_set :: proc(self: ^$S1/Set($T), other: ^$S2/Set(T)) {
  // lhs -= rhs
  for item, _ in other.set {
    delete_key(&self.set, item) // remove item
  }
}

@(private)
difference_update_slice :: proc(self: ^$S/Set($T), items: $A/[]T) {
  // lhs -= rhs
  for item in items {
    delete_key(&self.set, item) // remove item
  }
}

@(private)
difference_update_array :: proc(self: ^$S/Set($T), items: $A/[$N]T) {
  // lhs -= rhs
  for item in items {
    delete_key(&self.set, item) // remove item
  }
}

difference_update :: proc {// lhs -= rhs
  difference_update_set,
  difference_update_slice,
  difference_update_array,
}

//////////////////////////////////////////////

@(private, require_results)
difference_set_set :: proc(lhs: ^$S1/Set($T), rhs: ^$S2/Set(T), allocator := context.allocator) -> Set(T) {
  // out = lhs - rhs
  out := copy(self = lhs, allocator = allocator)
  difference_update(&out, rhs)
  return out
}

@(private, require_results)
difference_set_slice :: proc(lhs: ^$S/Set($T), rhs: []T, allocator := context.allocator) -> Set(T) {
  // out = lhs - rhs
  out := copy(self = lhs, allocator = allocator)
  difference_update(&out, rhs)
  return out
}

@(private, require_results)
difference_set_array :: proc(lhs: ^$S/Set($T), rhs: [$N]T, allocator := context.allocator) -> Set(T) {
  // out = lhs - rhs
  out := copy(self = lhs, allocator = allocator)
  rhs := rhs // make addressable
  difference_update(&out, rhs[:])
  return out
}

@(private, require_results)
difference_slice_set :: proc(lhs: $A/[]$T, rhs: ^$S/Set(T), allocator := context.allocator) -> Set(T) {
  // out = lhs - rhs
  out := fromArray(arr = lhs, allocator = allocator)
  difference_update(&out, rhs)
  return out
}

@(private, require_results)
difference_slice_slice :: proc(lhs, rhs: $A/[]$T, allocator := context.allocator) -> Set(T) {
  // out = lhs - rhs
  out := fromArray(arr = lhs, allocator = allocator)
  difference_update(&out, rhs)
  return out
}

@(private, require_results)
difference_slice_array :: proc(lhs: $A/[]$T, rhs: $A2/[$N]T, allocator := context.allocator) -> Set(T) {
  // out = lhs - rhs
  out := fromArray(lhs)
  rhs := rhs // make addressable
  difference_update(&out, rhs[:])
  return out
}

@(private, require_results)
difference_array_set :: proc(lhs: $A/[$N]$T, rhs: ^$S/Set(T), allocator := context.allocator) -> Set(T) {
  // out = lhs - rhs
  lhs := lhs // make addressable
  out := fromArray(arr = lhs[:], allocator = allocator)
  difference_update(&out, rhs)
  return out
}

@(private, require_results)
difference_array_slice :: proc(lhs: $A1/[$N]$T, rhs: $A2/[]T, allocator := context.allocator) -> Set(T) {
  // out = lhs - rhs
  lhs := lhs // make addressable
  out := fromArray(arr = lhs[:], allocator = allocator)
  difference_update(&out, rhs)
  return out
}

@(private, require_results)
difference_array_array :: proc(lhs: $A1/[$M]$T, rhs: $A2/[$N]T, allocator := context.allocator) -> Set(T) {
  // out = lhs - rhs
  lhs := lhs // make addressable
  out := fromArray(arr = lhs[:], allocator = allocator)
  rhs := rhs // make addressable
  difference_update(&out, rhs[:])
  return out
}

@(require_results)
difference :: proc {// out = lhs - rhs
  difference_set_set,
  difference_set_slice,
  difference_set_array,
  difference_slice_set,
  difference_slice_slice,
  difference_slice_array,
  difference_array_set,
  difference_array_slice,
  difference_array_array,
}

//////////////////////////////////////////////

@(private)
intersection_update_set :: proc(self: ^$S1/Set($T), other: ^$S2/Set(T), allocator := context.allocator) {
  // lhs &= rhs
  for item, _ in other.set {
    if !(item in self.set) {
      discard(self, item)
    }
  }
  items_to_delete := makeSet(T = T, allocator = context.temp_allocator)
  for item, _ in self.set {
    if !(item in other.set) {
      items_to_delete.set[item] = nil // add item
    }
  }
  for item, _ in items_to_delete.set {
    delete_key(&self.set, item) // remove item
  }
}

@(private)
intersection_update_slice :: proc(self: ^$S/Set($T), items: $A/[]T) {
  // lhs &= rhs
  other := fromArray(arr = items, allocator = context.temp_allocator)
  intersection_update(self, &other)
}

@(private)
intersection_update_array :: proc(self: ^$S/Set($T), items: $A/[$N]T) {
  // lhs &= rhs
  items := items // make addressable
  other := fromArray(arr = items[:], allocator = context.temp_allocator)
  intersection_update(self, &other)
}

intersection_update :: proc {// lhs &= rhs
  intersection_update_set,
  intersection_update_slice,
  intersection_update_array,
}

//////////////////////////////////////////////

@(private, require_results)
intersection_set_set :: proc(lhs: ^$S1/Set($T), rhs: ^$S2/Set(T), allocator := context.allocator) -> Set(T) {
  // out = lhs ∩ rhs
  out := copy(self = lhs, allocator = allocator)
  intersection_update(&out, rhs)
  return out
}

@(private, require_results)
intersection_set_slice :: proc(lhs: ^$S/Set($T), rhs: $A/[]T, allocator := context.allocator) -> Set(T) {
  // out = lhs ∩ rhs
  out := copy(self = lhs, allocator = allocator)
  intersection_update(&out, rhs)
  return out
}

@(private, require_results)
intersection_set_array :: proc(lhs: ^$S/Set($T), rhs: $A/[$N]T, allocator := context.allocator) -> Set(T) {
  // out = lhs ∩ rhs
  out := copy(self = lhs, allocator = allocator)
  rhs := rhs // make addressable
  intersection_update(&out, rhs[:])
  return out
}

@(private, require_results)
intersection_slice_set :: proc(lhs: $A/[]$T, rhs: ^$S2/Set(T), allocator := context.allocator) -> Set(T) {
  // out = lhs ∩ rhs
  out := fromArray(arr = lhs, allocator = allocator)
  intersection_update(&out, rhs)
  return out
}

@(private, require_results)
intersection_slice_slice :: proc(lhs, rhs: $A/[]$T, allocator := context.allocator) -> Set(T) {
  // out = lhs ∩ rhs
  out := fromArray(arr = lhs, allocator = allocator)
  intersection_update(&out, rhs)
  return out
}

@(private, require_results)
intersection_slice_array :: proc(lhs: $A1/[]$T, rhs: $A2/[$N]T, allocator := context.allocator) -> Set(T) {
  // out = lhs ∩ rhs
  out := fromArray(arr = lhs, allocator = allocator)
  rhs := rhs // make addressable
  intersection_update(&out, rhs[:])
  return out
}

@(private, require_results)
intersection_array_set :: proc(lhs: $A/[$N]$T, rhs: ^$S2/Set(T), allocator := context.allocator) -> Set(T) {
  // out = lhs ∩ rhs
  lhs := lhs // make addressable
  out := fromArray(arr = lhs[:], allocator = allocator)
  intersection_update(&out, rhs)
  return out
}

@(private, require_results)
intersection_array_slice :: proc(lhs: $A1/[$N]$T, rhs: $A2/[]T, allocator := context.allocator) -> Set(T) {
  // out = lhs ∩ rhs
  lhs := lhs // make addressable
  out := fromArray(arr = lhs[:], allocator = allocator)
  intersection_update(&out, rhs)
  return out
}

@(private, require_results)
intersection_array_array :: proc(lhs: $A1/[$M]$T, rhs: $A2/[$N]T, allocator := context.allocator) -> Set(T) {
  // out = lhs ∩ rhs
  lhs := lhs // make addressable
  out := fromArray(arr = lhs[:], allocator = allocator)
  rhs := rhs // make addressable
  intersection_update(&out, rhs[:])
  return out
}

@(require_results)
intersection :: proc {// out = lhs ∩ rhs
  intersection_set_set,
  intersection_set_slice,
  intersection_set_array,
  intersection_slice_set,
  intersection_slice_slice,
  intersection_slice_array,
  intersection_array_set,
  intersection_array_slice,
  intersection_array_array,
}

//////////////////////////////////////////////
// note: union is a reserved word, what would be `union` is declared as `conjunction` instead

@(private, require_results)
conjunction_set_set :: proc(lhs: ^$S1/Set($T), rhs: ^$S2/Set(T), allocator := context.allocator) -> Set(T) {
  // out = lhs ∪ set
  out := copy(self = lhs, allocator = allocator)
  update(&out, rhs)
  return out
}

@(private, require_results)
conjunction_set_slice :: proc(lhs: ^$S/Set($T), rhs: $A/[]T, allocator := context.allocator) -> Set(T) {
  // out = lhs ∪ set
  out := copy(self = lhs, allocator = allocator)
  update(&out, rhs)
  return out
}

@(private, require_results)
conjunction_set_array :: proc(lhs: ^$S/Set($T), rhs: $A/[$N]T, allocator := context.allocator) -> Set(T) {
  // out = lhs ∪ set
  out := copy(self = lhs, allocator = allocator)
  rhs := rhs // make addressable
  update(&out, rhs[:])
  return out
}

@(private, require_results)
conjunction_slice_set :: proc(lhs: $A/[]$T, rhs: ^$S2/Set(T), allocator := context.allocator) -> Set(T) {
  // out = lhs ∪ set
  out := fromArray(arr = lhs, allocator = allocator)
  update(&out, rhs)
  return out
}

@(private, require_results)
conjunction_slice_slice :: proc(lhs, rhs: $A/[]$T, allocator := context.allocator) -> Set(T) {
  // out = lhs ∪ set
  out := fromArray(arr = lhs, allocator = allocator)
  update(&out, rhs)
  return out
}

@(private, require_results)
conjunction_slice_array :: proc(lhs: $A/[]$T, rhs: [$N]T, allocator := context.allocator) -> Set(T) {
  // out = lhs ∪ set
  out := fromArray(arr = lhs, allocator = allocator)
  rhs := rhs // make addressable
  update(&out, rhs[:])
  return out
}

@(private, require_results)
conjunction_array_set :: proc(lhs: $A/[$N]$T, rhs: ^$S2/Set(T), allocator := context.allocator) -> Set(T) {
  // out = lhs ∪ set
  lhs := lhs // make addressable
  out := fromArray(arr = lhs[:], allocator = allocator)
  update(&out, rhs)
  return out
}

@(private, require_results)
conjunction_array_slice :: proc(lhs: $A1/[$N]$T, rhs: $A2/[]T, allocator := context.allocator) -> Set(T) {
  // out = lhs ∪ set
  lhs := lhs // make addressable
  out := fromArray(arr = lhs, allocator = allocator)
  update(&out, rhs)
  return out
}

@(private, require_results)
conjunction_array_array :: proc(lhs: $A1/[$M]$T, rhs: $A2/[$N]T, allocator := context.allocator) -> Set(T) {
  // out = lhs ∪ set
  lhs := lhs // make addressable
  out := fromArray(arr = lhs, allocator = allocator)
  rhs := rhs // make addressable
  update(&out, rhs[:])
  return out
}

@(require_results)
conjunction :: proc {// out = lhs ∪ set
  conjunction_set_set,
  conjunction_set_slice,
  conjunction_set_array,
  conjunction_slice_set,
  conjunction_slice_slice,
  conjunction_slice_array,
  conjunction_array_set,
  conjunction_array_slice,
  conjunction_array_array,
}

//////////////////////////////////////////////

@(private)
symmetric_difference_update_set :: proc(self: ^$S1/Set($T), other: ^$S2/Set(T)) {
  // lhs △= rhs
  // lhs = (lhs - rhs) ∪ (rhs - lhs) = (lhs ∪ rhs) - (lhs ∩ rhs)
  inter := intersection(self, other, context.temp_allocator)
  for item, _ in other.set {
    if !(item in inter.set) {
      self.set[item] = nil // add item
    }
  }
  for item, _ in inter.set {
    delete_key(&self.set, item) // remove item
  }
}

@(private)
symmetric_difference_update_slice :: proc(self: ^$S/Set($T), items: $A/[]T) {
  // lhs △= rhs
  // lhs = (lhs - rhs) ∪ (rhs - lhs) = (lhs ∪ rhs) - (lhs ∩ rhs)
  other := fromArray(arr = items, allocator = context.temp_allocator)
  symmetric_difference_update(self, &other)
}

@(private)
symmetric_difference_update_array :: proc(self: ^$S/Set($T), items: $A/[$N]T) {
  // lhs △= rhs
  // lhs = (lhs - rhs) ∪ (rhs - lhs) = (lhs ∪ rhs) - (lhs ∩ rhs)
  items := items // make addressable
  other := fromArray(arr = items[:], allocator = context.temp_allocator)
  symmetric_difference_update(self, &other)
}

symmetric_difference_update :: proc {// lhs △= rhs
  // lhs = (lhs - rhs) ∪ (rhs - lhs) = (lhs ∪ rhs) - (lhs ∩ rhs)
  symmetric_difference_update_set,
  symmetric_difference_update_slice,
  symmetric_difference_update_array,
}

//////////////////////////////////////////////

@(private, require_results)
symmetric_difference_set_set :: proc(lhs: ^$S1/Set($T), rhs: ^$S2/Set(T), allocator := context.allocator) -> Set(T) {
  // out = lhs △ rhs
  // out = (lhs - rhs) ∪ (rhs - lhs) = (lhs ∪ rhs) - (lhs ∩ rhs)
  out := copy(self = lhs, allocator = allocator)
  symmetric_difference_update(&out, rhs)
  return out
}

@(private, require_results)
symmetric_difference_set_slice :: proc(lhs: ^$S/Set($T), rhs: $A/[]T, allocator := context.allocator) -> Set(T) {
  // out = lhs △ rhs
  // out = (lhs - rhs) ∪ (rhs - lhs) = (lhs ∪ rhs) - (lhs ∩ rhs)
  out := copy(self = lhs, allocator = allocator)
  symmetric_difference_update(&out, rhs)
  return out
}

@(private, require_results)
symmetric_difference_set_array :: proc(lhs: ^$S/Set($T), rhs: $A/[$N]T, allocator := context.allocator) -> Set(T) {
  // out = lhs △ rhs
  // out = (lhs - rhs) ∪ (rhs - lhs) = (lhs ∪ rhs) - (lhs ∩ rhs)
  out := copy(self = lhs, allocator = allocator)
  rhs := rhs // make addressable
  symmetric_difference_update(&out, rhs[:])
  return out
}

@(private, require_results)
symmetric_difference_slice_set :: proc(lhs: $A/[]$T, rhs: ^$S2/Set(T), allocator := context.allocator) -> Set(T) {
  // out = lhs △ rhs
  // out = (lhs - rhs) ∪ (rhs - lhs) = (lhs ∪ rhs) - (lhs ∩ rhs)
  out := fromArray(arr = lhs, allocator = allocator)
  symmetric_difference_update(&out, rhs)
  return out
}

@(private, require_results)
symmetric_difference_slice_slice :: proc(lhs, rhs: $A/[]$T, allocator := context.allocator) -> Set(T) {
  // out = lhs △ rhs
  // out = (lhs - rhs) ∪ (rhs - lhs) = (lhs ∪ rhs) - (lhs ∩ rhs)
  out := fromArray(arr = lhs, allocator = allocator)
  symmetric_difference_update(&out, rhs)
  return out
}

@(private, require_results)
symmetric_difference_slice_array :: proc(lhs: $A1/[]$T, rhs: $A2/[$N]T, allocator := context.allocator) -> Set(T) {
  // out = lhs △ rhs
  // out = (lhs - rhs) ∪ (rhs - lhs) = (lhs ∪ rhs) - (lhs ∩ rhs)
  out := fromArray(arr = lhs, allocator = allocator)
  rhs := rhs // make addressable
  symmetric_difference_update(&out, rhs[:])
  return out
}

@(private, require_results)
symmetric_difference_array_set :: proc(lhs: $A/[$N]$T, rhs: ^$S2/Set(T), allocator := context.allocator) -> Set(T) {
  // out = lhs △ rhs
  // out = (lhs - rhs) ∪ (rhs - lhs) = (lhs ∪ rhs) - (lhs ∩ rhs)
  lhs := lhs // make addressable
  out := fromArray(arr = lhs[:], allocator = allocator)
  symmetric_difference_update(&out, rhs)
  return out
}

@(private, require_results)
symmetric_difference_array_slice :: proc(lhs: $A1/[$N]$T, rhs: $A2/[]T, allocator := context.allocator) -> Set(T) {
  // out = lhs △ rhs
  // out = (lhs - rhs) ∪ (rhs - lhs) = (lhs ∪ rhs) - (lhs ∩ rhs)
  lhs := lhs // make addressable
  out := fromArray(arr = lhs[:], allocator = allocator)
  symmetric_difference_update(&out, rhs)
  return out
}

@(private, require_results)
symmetric_difference_array_array :: proc(lhs: $A1/[$M]$T, rhs: $A2/[$N]T, allocator := context.allocator) -> Set(T) {
  // out = lhs △ rhs
  // out = (lhs - rhs) ∪ (rhs - lhs) = (lhs ∪ rhs) - (lhs ∩ rhs)
  lhs := lhs // make addressable
  out := fromArray(arr = lhs[:], allocator = allocator)
  rhs := rhs // make addressable
  symmetric_difference_update(&out, rhs[:])
  return out
}

@(require_results)
symmetric_difference :: proc {// out = lhs △ rhs
  // out = (lhs - rhs) ∪ (rhs - lhs) = (lhs ∪ rhs) - (lhs ∩ rhs)
  symmetric_difference_set_set,
  symmetric_difference_set_slice,
  symmetric_difference_set_array,
  symmetric_difference_slice_set,
  symmetric_difference_slice_slice,
  symmetric_difference_slice_array,
  symmetric_difference_array_set,
  symmetric_difference_array_slice,
  symmetric_difference_array_array,
}

//////////////////////////////////////////////
