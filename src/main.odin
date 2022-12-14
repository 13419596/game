package game

import rl "vendor:raylib"
import "core:fmt"
import "core:math"
import "core:intrinsics"
import "core:unicode/utf8"
import "game:re"

SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 800
BALL_RADIUS :: 20
GRAVITY :: 100

pause := false

score := 0
deltatime: f32 = 0

Verlet :: struct {
  positionOld:  [2]f32,
  position:     [2]f32,
  acceleration: [2]f32,
}

updateVerlet :: proc(verlet: $T/^Verlet, dt: f32) {
  velocity := verlet.position - verlet.positionOld
  verlet.positionOld = verlet.position
  verlet.position += velocity + verlet.acceleration * (dt * dt)
}

objects := make([dynamic]Verlet)

solve :: proc(dt: f32) {
  constraint: [2]f32 = {SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2}
  radius: f32 = 300

  for _, index in objects {
    updateVerlet(&objects[index], dt)
  }
}

main :: proc() {
  // window := makeGameWindow(title = "odin", width = SCREEN_WIDTH, height = SCREEN_HEIGHT)
  // defer deleteGameWindow(&window)
  // defer delete(objects)
  // init_game()
  // rl.SetTargetFPS(60)
  // for !rl.WindowShouldClose() {   // Detect window close button or ESC key
  //   update_game()
  //   draw_game()
  // }
  // {
  //   using re
  //   x := RegexFlag.DOTALL
  // }
  {
    using re
    n: int
    ss := [?]string{"12", "0", "444", "+3", "-3", "a", "33a", "--", "00", "09"}
    for s in ss {
      value, ok := parseUnprefixedInt(s, &n)
      fmt.printf("s=%q; value=%v, ok=%v; n=%v\n", s, value, ok, n)
    }
  }
  {
    using re
    patterns := [?]string{
      "^",
      "$",
      "|",
      "?",
      "+",
      "*",
      ".",
      "\\b",
      "\\B",
      "\\d",
      "\\D",
      "\\w",
      "\\W",
      "\\s",
      "\\S",
      "\\{",
      "\\}",
      "\\[",
      "\\]",
      "\\.",
      "\\\\",
      "\\",
      "{3}",
      "{3,}",
      "{,3}",
      "{3,4}",
      "{0,0}",
      "{0,000}",
      "{,000}",
      "{000,}",
      "{1,3}",
      "{1,3000000}",
      "a",
      "AA",
      "[a]",
      "[^a]",
      "[-]",
      "[^-]",
      "[abc]",
      "[a-z]",
      "[a-z89]",
      "[a-c89A-C]",
      "[a-c89A-C-]",
      "[a-c89A-C-]g",
      "[a-c89A-C\\d\\w\\s.\\.\\D\\W\\S-]g",
      "[^-a-c89A-C\\d\\w\\s.\\.\\D\\W\\S-]g",
      "()",
      ")",
      "(?",
      "(?hello)",
      "(?:hello)",
      "(",
      "{",
      "{f",
      "{,",
      "{,1",
      "{}f",
      "{,}",
      "{0",
      "{0,",
      "{0,}",
      "}",
    }
    for pattern in patterns {
      s, n, ok := makeTokenFromString(pattern)
      fmt.printf("pattern:%q s:%q n:%v  ok:%v\n", pattern, s, n, ok)
      defer deleteLiteralToken(&s)
    }
  }
}

addBall :: proc(position: [2]f32) {
  ball: Verlet = {
    positionOld = position,
    position = position,
    acceleration = {0, GRAVITY},
  }
  append(&objects, ball)
}

init_game :: proc() {
  pause = false
}

update_game :: proc() {
  deltatime = rl.GetFrameTime()

  if rl.IsKeyPressed(.P) {
    pause = !pause
  }

  if pause {
    return
  }

  if (rl.IsMouseButtonPressed(.LEFT)) {
    t := rl.GetMousePosition()
    pos: [2]f32 = {t.x, t.y}
    addBall(pos)
  }

  solve(deltatime)
}

draw_game :: proc() {
  rl.BeginDrawing()
  defer rl.EndDrawing()

  rl.ClearBackground(rl.BLACK)

  rl.DrawCircle(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2, 300, rl.GRAY)

  for object in objects {
    rl.DrawCircle(i32(object.position.x), i32(object.position.y), BALL_RADIUS, rl.WHITE)
  }

  rl.DrawText(rl.TextFormat("%d", score), 5, 5, 40, rl.WHITE)

  if pause {
    text :: "GAME PAUSED"
    rl.DrawText(text, SCREEN_WIDTH / 2 - rl.MeasureText(text, 40) / 2, SCREEN_WIDTH / 2 - 40, 40, rl.GRAY)
  }
}
