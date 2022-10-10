package game

import rl "vendor:raylib"
import "core:strings"

GameWindow :: struct {
  title:  string,
  width:  i32,
  height: i32,
}

makeGameWindow :: proc(width, height: i32, title: string) -> GameWindow {
  using strings
  out := GameWindow {
    title  = title,
    width  = width,
    height = height,
  }
  ctitle := clone_to_cstring(s = out.title, allocator = context.temp_allocator)
  rl.InitWindow(out.width, out.height, ctitle)
  return out
}

deleteGameWindow :: proc(window: ^GameWindow) {
  defer rl.CloseWindow()
}
