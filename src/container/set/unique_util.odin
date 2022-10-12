package container_set

@(private, require_results)
getUnique_slice :: proc(arr: []$T) -> [dynamic]T {
  tmp_set := fromArray(arr = arr, allocator = context.temp_allocator)
  return asArray(&tmp_set)
}

@(private, require_results)
getUnique_array :: proc(arr: [$N]$T) -> [dynamic]T {
  arr := arr // make addressable
  return getUnique(arr[:])
}

@(require_results)
getUnique :: proc {
  getUnique_slice,
  getUnique_array,
}
