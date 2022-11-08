// Tests "game:container/set"
// Must be run with `-collection:tests=` flag
package test_set

import "core:fmt"
import "core:io"
import rand "core:math/rand"
import "core:mem"
import "core:os"
import "core:runtime"
import "core:sort"
import "core:testing"
import tc "tests:common"
import container_set "game:container/set"

@(test)
test_set_construction :: proc(t: ^testing.T) {
  tests := [?]proc(_: ^testing.T){test_set_construction_types}
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    tracking_allocator := mem.Tracking_Allocator{}
    mem.tracking_allocator_init(&tracking_allocator, alloc)
    defer mem.tracking_allocator_destroy(&tracking_allocator)
    context.allocator = mem.tracking_allocator(&tracking_allocator)
    {
      for test in tests {
        test(t)
        tc.expect(
          t,
          len(tracking_allocator.allocation_map) == 0,
          fmt.tprintf("Expected no remaning allocations. Got: num:%v\n%v", len(tracking_allocator.allocation_map), tracking_allocator.allocation_map),
        )
      }
    }
    tc.expect(
      t,
      len(tracking_allocator.allocation_map) == 0,
      fmt.tprintf("Expected no remaning allocations. Got: num:%v\n%v", len(tracking_allocator.allocation_map), tracking_allocator.allocation_map),
    )
  }
}

@(test, private = "file")
test_set_construction_types :: proc(t: ^testing.T) {
  using container_set
  {
    set := makeSet(bool)
    tc.expect(t, set.set != nil, "Construction of Set(bool)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(bool)")
  }
  {
    set := makeSet(b8)
    tc.expect(t, set.set != nil, "Construction of Set(b8)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(b8)")
  }
  {
    set := makeSet(b16)
    tc.expect(t, set.set != nil, "Construction of Set(b16)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(b16)")
  }
  {
    set := makeSet(b32)
    tc.expect(t, set.set != nil, "Construction of Set(b32)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(b32)")
  }
  {
    set := makeSet(b64)
    tc.expect(t, set.set != nil, "Construction of Set(b64)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(b64)")
  }
  {
    set := makeSet(i8)
    tc.expect(t, set.set != nil, "Construction of Set(i8)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(i8)")
  }
  {
    set := makeSet(u8)
    tc.expect(t, set.set != nil, "Construction of Set(u8)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(u8)")
  }
  {
    set := makeSet(i16)
    tc.expect(t, set.set != nil, "Construction of Set(i16)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(i16)")
  }
  {
    set := makeSet(u16)
    tc.expect(t, set.set != nil, "Construction of Set(u16)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(u16)")
  }
  {
    set := makeSet(i32)
    tc.expect(t, set.set != nil, "Construction of Set(i32)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(i32)")
  }
  {
    set := makeSet(u32)
    tc.expect(t, set.set != nil, "Construction of Set(u32)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(u32)")
  }
  {
    set := makeSet(i64)
    tc.expect(t, set.set != nil, "Construction of Set(i64)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(i64)")
  }
  {
    set := makeSet(u64)
    tc.expect(t, set.set != nil, "Construction of Set(u64)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(u64)")
  }
  {
    set := makeSet(i128)
    tc.expect(t, set.set != nil, "Construction of Set(i128)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(i128)")
  }
  {
    set := makeSet(u128)
    tc.expect(t, set.set != nil, "Construction of Set(u128)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(u128)")
  }
  {
    set := makeSet(rune)
    tc.expect(t, set.set != nil, "Construction of Set(rune)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(rune)")
  }
  {
    set := makeSet(f16)
    tc.expect(t, set.set != nil, "Construction of Set(f16)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(f16)")
  }
  {
    set := makeSet(f32)
    tc.expect(t, set.set != nil, "Construction of Set(f32)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(f32)")
  }
  {
    set := makeSet(f64)
    tc.expect(t, set.set != nil, "Construction of Set(f64)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(f64)")
  }
  {
    set := makeSet(complex32)
    tc.expect(t, set.set != nil, "Construction of Set(complex32)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(complex32)")
  }
  {
    set := makeSet(complex64)
    tc.expect(t, set.set != nil, "Construction of Set(complex64)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(complex64)")
  }
  {
    set := makeSet(complex128)
    tc.expect(t, set.set != nil, "Construction of Set(complex128)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(complex128)")
  }
  {
    set := makeSet(quaternion64)
    tc.expect(t, set.set != nil, "Construction of Set(quaternion64)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(quaternion64)")
  }
  {
    set := makeSet(quaternion128)
    tc.expect(t, set.set != nil, "Construction of Set(quaternion128)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(quaternion128)")
  }
  {
    set := makeSet(quaternion256)
    tc.expect(t, set.set != nil, "Construction of Set(quaternion256)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(quaternion256)")
  }
  {
    set := makeSet(int)
    tc.expect(t, set.set != nil, "Construction of Set(int)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(int)")
  }
  {
    set := makeSet(uint)
    tc.expect(t, set.set != nil, "Construction of Set(uint)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(uint)")
  }
  {
    set := makeSet(uintptr)
    tc.expect(t, set.set != nil, "Construction of Set(uintptr)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(uintptr)")
  }
  {
    set := makeSet(rawptr)
    tc.expect(t, set.set != nil, "Construction of Set(rawptr)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(rawptr)")
  }
  {
    set := makeSet(string)
    tc.expect(t, set.set != nil, "Construction of Set(string)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(string)")
  }
  {
    set := makeSet(cstring)
    tc.expect(t, set.set != nil, "Construction of Set(cstring)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(cstring)")
  }
  when false {
    // `any` is not a hashable type
    set := makeSet(any)
    tc.expect(t, set.set != nil, "Construction of Set(any)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(any)")
  }
  when false {
    // `typeid` is not a hashable type
    set := makeSet(typeid)
    tc.expect(t, set.set != nil, "Construction of Set(typeid)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(typeid)")
  }
  {
    set := makeSet(i16le)
    tc.expect(t, set.set != nil, "Construction of Set(i16le)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(i16le)")
  }
  {
    set := makeSet(u16le)
    tc.expect(t, set.set != nil, "Construction of Set(u16le)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(u16le)")
  }
  {
    set := makeSet(i32le)
    tc.expect(t, set.set != nil, "Construction of Set(i32le)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(i32le)")
  }
  {
    set := makeSet(u32le)
    tc.expect(t, set.set != nil, "Construction of Set(u32le)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(u32le)")
  }
  {
    set := makeSet(i64le)
    tc.expect(t, set.set != nil, "Construction of Set(i64le)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(i64le)")
  }
  {
    set := makeSet(u64le)
    tc.expect(t, set.set != nil, "Construction of Set(u64le)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(u64le)")
  }
  {
    set := makeSet(i128le)
    tc.expect(t, set.set != nil, "Construction of Set(i128le)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(i128le)")
  }
  {
    set := makeSet(u128le)
    tc.expect(t, set.set != nil, "Construction of Set(u128le)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(u128le)")
  }
  {
    set := makeSet(i16be)
    tc.expect(t, set.set != nil, "Construction of Set(i16be)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(i16be)")
  }
  {
    set := makeSet(u16be)
    tc.expect(t, set.set != nil, "Construction of Set(u16be)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(u16be)")
  }
  {
    set := makeSet(i32be)
    tc.expect(t, set.set != nil, "Construction of Set(i32be)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(i32be)")
  }
  {
    set := makeSet(u32be)
    tc.expect(t, set.set != nil, "Construction of Set(u32be)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(u32be)")
  }
  {
    set := makeSet(i64be)
    tc.expect(t, set.set != nil, "Construction of Set(i64be)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(i64be)")
  }
  {
    set := makeSet(u64be)
    tc.expect(t, set.set != nil, "Construction of Set(u64be)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(u64be)")
  }
  {
    set := makeSet(i128be)
    tc.expect(t, set.set != nil, "Construction of Set(i128be)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(i128be)")
  }
  {
    set := makeSet(u128be)
    tc.expect(t, set.set != nil, "Construction of Set(u128be)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(u128be)")
  }
  {
    set := makeSet(f16le)
    tc.expect(t, set.set != nil, "Construction of Set(f16le)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(f16le)")
  }
  {
    set := makeSet(f32le)
    tc.expect(t, set.set != nil, "Construction of Set(f32le)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(f32le)")
  }
  {
    set := makeSet(f64le)
    tc.expect(t, set.set != nil, "Construction of Set(f64le)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(f64le)")
  }
  {
    set := makeSet(f16be)
    tc.expect(t, set.set != nil, "Construction of Set(f16be)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(f16be)")
  }
  {
    set := makeSet(f32be)
    tc.expect(t, set.set != nil, "Construction of Set(f32be)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(f32be)")
  }
  {
    set := makeSet(f64be)
    tc.expect(t, set.set != nil, "Construction of Set(f64be)")
    deleteSet(&set)
    tc.expect(t, set.set == nil, "Deletion of Set(f64be)")
  }
}
