package main

import "core:c"
import "core:fmt"
import "core:math"
import "core:math/rand"
import "core:time"
import "core:strings"
import "core:unicode"

import rl "vendor:raylib"
import mu "vendor:microui"

ui_state := struct {
    mu_ctx: mu.Context,
    atlas_texture: rl.RenderTexture2D,
    screen_texture: rl.RenderTexture2D,
    bg: rl.Color
}{
    bg = rl.Color{0, 0, 0, 0}
}

WIDTH  :: 1280
HEIGHT :: 800

BORDER_COLOR :: rl.Color { 108, 122, 137, 255 }

KINGLY :: rl.Color { 0, 255, 0, 255 }

LIGHT_RED :: rl.Color { 200, 0, 0, 255 }
DARK_RED :: rl.Color { 100, 0, 0, 255 }

LIGHT_SILVER :: rl.Color { 200, 200, 200, 255 }
DARK_SILVER :: rl.Color { 100, 100, 100, 255 }

mouse_buttons_map := [mu.Mouse]rl.MouseButton{
  .LEFT    = .LEFT,
  .RIGHT   = .RIGHT,
  .MIDDLE  = .MIDDLE,
}

Corners :: proc(rect: rl.Rectangle) -> ([2]f32, [2]f32, [2]f32, [2]f32) {
  tl := [2]f32 { rect.x, rect.y }
  tr := [2]f32 { rect.x + rect.width, rect.y }
  bl := [2]f32 { rect.x, rect.y + rect.height }
  br := [2]f32 { rect.x + rect.width, rect.y + rect.height }

  return tl, bl, br, tr 
}

DiagLength :: proc(rect: rl.Rectangle) -> f32 {
  return math.sqrt(math.pow(rect.width, 2) + math.pow(rect.height, 2))
}

DrawPyramid :: proc(rect: rl.Rectangle, p: Piece) {
  // Corners
  tl, bl, br, tr := Corners(rect)

  // Centre
  c := (tl + bl + br + tr) / 4

  corners := [4][2]f32 { tl, bl, br, tr }

  // Do a little transformation to ensure that 0-rotation corresponds to what we expect
  // and also ensure that positive rotation direction == clockwise.
  r := p.rotation * -1
  if r < 0 do r += 4

  current := (r + 1) % 4

  next_clock, next_anti_clock := current - 1, (current + 1) % 4
  if next_clock < 0 do next_clock = next_clock + 4

  rl.DrawTriangle(
    corners[current],
    corners[next_anti_clock],
    c,
    p.owner == Player.RED ? LIGHT_RED : LIGHT_SILVER)

  rl.DrawTriangle(
    corners[current],
    c,
    corners[next_clock],
    p.owner == Player.RED ? DARK_RED : DARK_SILVER)

  rl.DrawLineEx(corners[next_clock], corners[next_anti_clock], 1, rl.WHITE)

  rl.DrawRectangleLinesEx(rect, 4, BORDER_COLOR)
}

DrawScarab :: proc(rect: rl.Rectangle, p: Piece) {
  // Corners
  tl, bl, br, tr := Corners(rect)

  corners := [4][2]f32 { tl, bl, br, tr }

  // Do a little transformation to ensure that 0-rotation corresponds to what we expect
  // and also ensure that positive rotation direction == clockwise.
  r := p.rotation * -1
  if r < 0 do r += 4

  current := (r + 1) % 4

  next_clock, next_anti_clock := current - 1, (current + 1) % 4
  if next_clock < 0 do next_clock = next_clock + 4

  opposite := (current + 2) % 4

  diag := corners[next_clock] + 0.55 * (corners[next_anti_clock] - corners[next_clock])
  side1 := corners[current] + 0.55 * (corners[next_anti_clock] - corners[current])
  side2 := corners[next_anti_clock] + 0.45 * (corners[opposite] - corners[next_anti_clock])

  rl.DrawTriangle(
    side1,
    corners[next_anti_clock],
    diag,
    p.owner == Player.RED ? LIGHT_RED : LIGHT_SILVER)

  rl.DrawTriangle(
    corners[next_anti_clock],
    side2,
    diag,
    p.owner == Player.RED ? DARK_RED : DARK_SILVER)

  diag = corners[next_anti_clock] + 0.55 * (corners[next_clock] - corners[next_anti_clock])
  side1 = corners[current] + 0.55 * (corners[next_clock] - corners[current])
  side2 = corners[next_clock] + 0.45 * (corners[opposite] - corners[next_clock])

  rl.DrawTriangle(
    side1,
    diag,
    corners[next_clock],
    p.owner == Player.RED ? DARK_RED : DARK_SILVER)

  rl.DrawTriangle(
    corners[next_clock],
    diag,
    side2,
    p.owner == Player.RED ? LIGHT_RED : LIGHT_SILVER)

  rl.DrawLineEx(corners[next_clock], corners[next_anti_clock], 1, rl.WHITE)

  rl.DrawRectangleLinesEx(rect, 4, BORDER_COLOR)
}

DrawAnubis :: proc(rect: rl.Rectangle, p: Piece) {
  // Corners
  tl, bl, br, tr := Corners(rect)

  // Centre
  c := (tl + bl + br + tr) / 4

  corners := [4][2]f32 { tl, bl, br, tr }

  inner_corners, inner_corners2: [4][2]f32
  for i in 0..<4 {
    inner_corners[i] = c + 0.6 * (corners[i] - c)
    inner_corners2[i] = c + 0.5 * (corners[i] - c)
  }

  // Do a little transformation to ensure that 0-rotation corresponds to what we expect
  // and also ensure that positive rotation direction == clockwise.
  current := p.rotation * -1
  if current  < 0 do current += 4

  next_clock, next_anti_clock := current - 1, (current + 1) % 4
  if next_clock < 0 do next_clock = next_clock + 4

  opposite := (current + 2) % 4

  rl.DrawRectangle(
    cast(i32)rect.x,
    cast(i32)rect.y,
    cast(i32)rect.width,
    cast(i32)rect.height,
    p.owner == Player.RED ? DARK_RED : DARK_SILVER)

  rl.DrawTriangle(
    inner_corners[current],
    inner_corners[next_anti_clock],
    inner_corners[next_clock],
    p.owner == Player.RED ? LIGHT_RED : LIGHT_SILVER)

  rl.DrawTriangle(
    inner_corners[next_anti_clock],
    inner_corners[opposite],
    inner_corners[next_clock],
    p.owner == Player.RED ? LIGHT_RED : LIGHT_SILVER)

  rl.DrawTriangle(
    inner_corners2[current],
    c,
    inner_corners2[next_clock],
    rl.BLACK)

  rl.DrawRectangleLinesEx(rect, 4, BORDER_COLOR)
}

DrawPharaoh :: proc(rect: rl.Rectangle, p: Piece) {
  // Corners
  tl, bl, br, tr := Corners(rect)

  // Centre
  c := (tl + bl + br + tr) / 4

  corners := [4][2]f32 { tl, bl, br, tr }

  inner_corners, inner_corners2: [4][2]f32
  for i in 0..<4 {
    inner_corners[i] = c + 0.6 * (corners[i] - c)
    inner_corners2[i] = c + 0.5 * (corners[i] - c)
  }

  current := p.rotation
  next_clock, next_anti_clock := current - 1, (current + 1) % 4
  if next_clock < 0 do next_clock = next_clock + 4

  opposite := (current + 2) % 4

  rl.DrawRectangle(
    cast(i32)rect.x,
    cast(i32)rect.y,
    cast(i32)rect.width,
    cast(i32)rect.height,
    p.owner == Player.RED ? DARK_RED : DARK_SILVER)

  rl.DrawCircle(
    cast(i32)c[0],
    cast(i32)c[1],
    rect.width / 3,
    p.owner == Player.RED ? LIGHT_RED : LIGHT_SILVER)

  rl.DrawCircle(cast(i32)c[0], cast(i32)c[1], rect.width / 6, KINGLY)

  rl.DrawRectangleLinesEx(rect, 4, BORDER_COLOR)
}

DrawSphinx :: proc(rect: rl.Rectangle, p: Piece) {
  // Corners
  tl, bl, br, tr := Corners(rect)

  // Centre
  c := (tl + bl + br + tr) / 4

  corners := [4][2]f32 { tl, bl, br, tr }

  inner_corners: [4][2]f32
  for i in 0..<4 {
    inner_corners[i] = c + 0.6 * (corners[i] - c)
  }

  rl.DrawRectangle(
    cast(i32)rect.x,
    cast(i32)rect.y,
    cast(i32)rect.width,
    cast(i32)rect.height,
    p.owner == Player.RED ? DARK_RED : DARK_SILVER)

  inner_tl := inner_corners[0]
  rl.DrawRectangle(cast(i32)inner_tl[0], cast(i32)inner_tl[1], cast(i32)(0.6 * rect.width), cast(i32)(0.6 * rect.height), rl.BLACK);

  // Draw the laser "gun".
  // Do a little transformation to ensure that 0-rotation corresponds to what we expect
  // and also ensure that positive rotation direction == clockwise.
  current := (p.rotation * -1) - 1
  if current  < 0 do current += 4

  next_clock, next_anti_clock := current - 1, (current + 1) % 4
  if next_clock < 0 do next_clock = next_clock + 4

  laser_centre := (corners[current] + corners[next_anti_clock]) / 2
  laser_centre = laser_centre + 0.25 * (c - laser_centre)
  rl.DrawPoly(laser_centre, 4, rect.width / 10.0, 45, KINGLY)

  rl.DrawRectangleLinesEx(rect, 4, BORDER_COLOR)
}

PieceType :: enum {
  PYRAMID,
  ANUBIS,
  SCARAB,
  PHARAOH,
  SPHINX
}

Player :: enum {
  RED,
  SILVER
}

Piece :: struct {
  type: PieceType,
  owner: Player,
  rotation: int
}

Square :: distinct Maybe(Piece)

MoveType :: enum {
  UL, U, UR,
  L,     R,
  DL, D, DR,
  CW, ACW
}

MoveSet :: distinct bit_set[MoveType]

Board :: struct {
  player_to_move: Player,
  squares: [8][10]Square,

  rects: [8][10]rl.Rectangle,
  selected: Maybe([2]int),
  current_moves: MoveSet
}

khet_board: Board

UpdatePick :: proc(board: ^Board, click_pos: [2]f32) {
  fmt.println(click_pos)

  hit_test :: proc(x, y: f32, rect: rl.Rectangle) -> bool {
    return x > rect.x && x < rect.x + rect.width &&
           y > rect.y && y < rect.y + rect.height
  }

  has_selection := false
  for row in 0..<8 {
    for col in 0..<10 {
      sq := board^.squares[row][col]
      if sq != nil &&
         sq.?.owner == board^.player_to_move &&
         hit_test(click_pos[0], click_pos[1], board^.rects[row][col]) {

        board^.selected = [2]int { row, col }
        has_selection = true
      }
    }
  }

  if !has_selection {
    board^.selected = nil
  }
}

RenderBoard :: proc(board: Board, rect: rl.Rectangle) {
  // Figure out the size of each square.
  side := cast(int)math.min(rect.width / 10, rect.height / 8)

  rl.DrawRectangle(cast(i32)rect.x, cast(i32)rect.y, cast(i32)rect.width, cast(i32)rect.height, rl.BLACK)

  // Draw the pieces.
  for row in 0..<8 {
    for col in 0..<10 {
      sq := board.squares[row][col]
      if sq != nil {
        r := board.rects[row][col]
        pt := sq.?.type

        switch pt {
          case PieceType.PYRAMID: DrawPyramid(r, sq.?)
          case PieceType.ANUBIS: DrawAnubis(r, sq.?)
          case PieceType.SCARAB: DrawScarab(r, sq.?)
          case PieceType.PHARAOH: DrawPharaoh(r, sq.?)
          case PieceType.SPHINX: DrawSphinx(r, sq.?)
        }
      }
    }
  }

  // Draw the grid.
  for row in 0..=8 {
    row_offset := side * row
    rl.DrawLine(
      cast(i32)rect.x, cast(i32)rect.y + cast(i32)row_offset,
      cast(i32)rect.x + 10 * cast(i32)side, cast(i32)rect.y + cast(i32)row_offset,
      rl.GREEN)
  }

  for col in 0..=10 {
    col_offset := side * col
    rl.DrawLine(
      cast(i32)rect.x + cast(i32)col_offset, cast(i32)rect.y,
      cast(i32)rect.x + cast(i32)col_offset, cast(i32)rect.y + 8 * cast(i32)side,
      rl.GREEN)
  }

  // Draw the move pick.
  pick_maybe := board.selected
  if pick_maybe != nil {
    pick: [2]int = pick_maybe.?
    rect := board.rects[pick[0]][pick[1]]
    rl.DrawRectangleLinesEx(rect, 4, rl.BLUE)
  }
}

InitialKhetBoard :: proc(rect: rl.Rectangle) -> Board {

  BOARD_STR ::
    "x33a3ka3p22/2p37/3P46/p11P31s1s21p21P4/p21P41S2S11p11P3/6p23/7P12/2P4A1KA13X1 0"

  piece_type_from_char :: proc(c: rune) -> Maybe(PieceType) {
    l := unicode.to_lower(c)
    switch l {
      case 'a': return PieceType.ANUBIS
      case 'p': return PieceType.PYRAMID
      case 's': return PieceType.SCARAB
      case 'k': return PieceType.PHARAOH
      case 'x': return PieceType.SPHINX
    }

    return nil
  }

  board := Board{}

  tokens := strings.split(BOARD_STR, " ")
  defer delete(tokens)

  board.player_to_move = tokens[1] == "0" ? Player.SILVER : Player.RED

  lines := strings.split(tokens[0], "/")
  defer delete(lines)

  for line, row_index in lines {
    col_index, i := 0, 0
    for i < len(line) {
      c := cast(rune)line[i]
      if unicode.is_alpha(c) {
        player := unicode.is_upper(c) ? Player.SILVER : Player.RED
        piece_type := piece_type_from_char(c)
        assert(piece_type != nil)
        orientation := 0
        if piece_type != PieceType.PHARAOH {
          i += 1
          orientation = cast(int)line[i] - 1 - '0'
        }

        board.squares[row_index][col_index] = Piece{piece_type.?, player, orientation}
        col_index += 1
      }
      else {
        col_index = col_index + cast(int)c - '0'
      }

      i += 1
    }
  }

  // Figure out the size of each square.
  side := cast(int)math.min(rect.width / 10, rect.height / 8)

  for row in 0..<8 {
    row_offset := side * row
    for col in 0..<10 {
      col_offset := side * col

      board.rects[row][col] = rl.Rectangle{
          x = rect.x + cast(f32)col_offset,
          y = rect.y + cast(f32)row_offset,
          width = cast(f32)side,
          height = cast(f32)side}
    }
  }

  board.selected = nil
  board.current_moves = MoveSet{}

  return board
}

RenderUI :: proc(ctx: ^mu.Context) {
  render_texture :: proc "contextless" (renderer: rl.RenderTexture2D, dst: ^rl.Rectangle, src: mu.Rect, color: rl.Color) {
    dst.width = f32(src.w)
    dst.height = f32(src.h)

    rl.DrawTextureRec(
      texture  = ui_state.atlas_texture.texture,
      source   = {f32(src.x), f32(src.y), f32(src.w), f32(src.h)},
      position = {dst.x, dst.y},
      tint     = color,
    )
  }

  to_rl_color :: proc "contextless" (in_color: mu.Color) -> (out_color: rl.Color) {
    return {in_color.r, in_color.g, in_color.b, in_color.a}
  }

  height := rl.GetScreenHeight()

  rl.BeginTextureMode(ui_state.screen_texture)
  rl.EndScissorMode()
  rl.ClearBackground(ui_state.bg)

  command_backing: ^mu.Command
  for variant in mu.next_command_iterator(ctx, &command_backing) {
    switch cmd in variant {
    case ^mu.Command_Text:
      dst := rl.Rectangle{f32(cmd.pos.x), f32(cmd.pos.y), 0, 0}
      for ch in cmd.str {
        if ch&0xc0 != 0x80 {
          r := min(int(ch), 127)
          src := mu.default_atlas[mu.DEFAULT_ATLAS_FONT + r]
          render_texture(ui_state.screen_texture, &dst, src, to_rl_color(cmd.color))
          dst.x += dst.width
        }
      }
    case ^mu.Command_Rect:
      rl.DrawRectangle(cmd.rect.x, cmd.rect.y, cmd.rect.w, cmd.rect.h, to_rl_color(cmd.color))
    case ^mu.Command_Icon:
      src := mu.default_atlas[cmd.id]
      x := cmd.rect.x + (cmd.rect.w - src.w)/2
      y := cmd.rect.y + (cmd.rect.h - src.h)/2
      render_texture(ui_state.screen_texture, &rl.Rectangle {f32(x), f32(y), 0, 0}, src, to_rl_color(cmd.color))
    case ^mu.Command_Clip:
      rl.BeginScissorMode(cmd.rect.x, height - (cmd.rect.y + cmd.rect.h), cmd.rect.w, cmd.rect.h)
    case ^mu.Command_Jump:
      unreachable()
    }
  }
  rl.EndTextureMode()
  rl.DrawTextureRec(
    texture  = ui_state.screen_texture.texture,
    source   = {0, 0, f32(WIDTH), -f32(HEIGHT)},
    position = {0, 0},
    tint     = rl.WHITE,
  )
}

write_log :: proc(s: string) {
  fmt.println(s)
}

UpdateUI :: proc(ctx: ^mu.Context) {
  @static opts := mu.Options{.NO_CLOSE}

  if mu.window(ctx, "Controls", {0, 0, 300, 450}, opts) {

    {
      mu.layout_row_items(ctx, 3, 0)
      opts := MoveType.UL in khet_board.current_moves ? mu.Options{mu.Opt.ALIGN_CENTER} : mu.Options{mu.Opt.ALIGN_CENTER, mu.Opt.NO_INTERACT}

      if .SUBMIT in mu.button(ctx, "UL", mu.Icon.NONE, opts) { write_log("Pressed UL") }

      opts = MoveType.U in khet_board.current_moves ? mu.Options{mu.Opt.ALIGN_CENTER} : mu.Options{mu.Opt.ALIGN_CENTER, mu.Opt.NO_INTERACT}
      if .SUBMIT in mu.button(ctx, "U", mu.Icon.NONE, opts) { write_log("Pressed U") }

      opts = MoveType.UR in khet_board.current_moves ? mu.Options{mu.Opt.ALIGN_CENTER} : mu.Options{mu.Opt.ALIGN_CENTER, mu.Opt.NO_INTERACT}
      if .SUBMIT in mu.button(ctx, "UR", mu.Icon.NONE, opts) { write_log("Pressed UR") }
    }

    {
      mu.layout_row_items(ctx, 3, 0)
      opts := MoveType.L in khet_board.current_moves ? mu.Options{mu.Opt.ALIGN_CENTER} : mu.Options{mu.Opt.ALIGN_CENTER, mu.Opt.NO_INTERACT}
      if .SUBMIT in mu.button(ctx, "L", mu.Icon.NONE, opts) { write_log("Pressed L") }

      mu.label(ctx, "")

      opts = MoveType.R in khet_board.current_moves ? mu.Options{mu.Opt.ALIGN_CENTER} : mu.Options{mu.Opt.ALIGN_CENTER, mu.Opt.NO_INTERACT}
      if .SUBMIT in mu.button(ctx, "R", mu.Icon.NONE, opts) { write_log("Pressed R") }
    }

    {
      mu.layout_row_items(ctx, 3, 0)
      opts := MoveType.DL in khet_board.current_moves ? mu.Options{mu.Opt.ALIGN_CENTER} : mu.Options{mu.Opt.ALIGN_CENTER, mu.Opt.NO_INTERACT}
      if .SUBMIT in mu.button(ctx, "DL", mu.Icon.NONE, opts) { write_log("Pressed DL") }

      opts = MoveType.D in khet_board.current_moves ? mu.Options{mu.Opt.ALIGN_CENTER} : mu.Options{mu.Opt.ALIGN_CENTER, mu.Opt.NO_INTERACT}
      if .SUBMIT in mu.button(ctx, "D", mu.Icon.NONE, opts) { write_log("Pressed D") }

      opts = MoveType.DR in khet_board.current_moves ? mu.Options{mu.Opt.ALIGN_CENTER} : mu.Options{mu.Opt.ALIGN_CENTER, mu.Opt.NO_INTERACT}
      if .SUBMIT in mu.button(ctx, "DR", mu.Icon.NONE, opts) { write_log("Pressed DR") }
    }

    {
      mu.layout_row_items(ctx, 1, 0)
      mu.label(ctx, "")
    }

    {
      mu.layout_row_items(ctx, 3, 0)
      opts := MoveType.CW in khet_board.current_moves ? mu.Options{mu.Opt.ALIGN_CENTER} : mu.Options{mu.Opt.ALIGN_CENTER, mu.Opt.NO_INTERACT}
      if .SUBMIT in mu.button(ctx, "Rotate CW", mu.Icon.NONE, opts) { write_log("Pressed CW") }

      mu.label(ctx, "")

      opts = MoveType.ACW in khet_board.current_moves ? mu.Options{mu.Opt.ALIGN_CENTER} : mu.Options{mu.Opt.ALIGN_CENTER, mu.Opt.NO_INTERACT}
      if .SUBMIT in mu.button(ctx, "Rotate ACW", mu.Icon.NONE, opts) { write_log("Pressed ACW") }
    }
  }
}

main :: proc() {
  rl.InitWindow(WIDTH, HEIGHT, "Khet")
  defer rl.CloseWindow()

  mu.init(&ui_state.mu_ctx)

  ui_state.mu_ctx.text_width = mu.default_atlas_text_width
  ui_state.mu_ctx.text_height = mu.default_atlas_text_height
  
  rl.SetTargetFPS(60)

  board_rect := rl.Rectangle{50, 50, WIDTH - 100, HEIGHT - 100}

  khet_board = InitialKhetBoard(board_rect)

  ui_state.atlas_texture = rl.LoadRenderTexture(c.int(mu.DEFAULT_ATLAS_WIDTH), c.int(mu.DEFAULT_ATLAS_HEIGHT))
  defer rl.UnloadRenderTexture(ui_state.atlas_texture)

  image := rl.GenImageColor(c.int(mu.DEFAULT_ATLAS_WIDTH), c.int(mu.DEFAULT_ATLAS_HEIGHT), rl.Color{0, 0, 0, 0})
  defer rl.UnloadImage(image)

  for alpha, i in mu.default_atlas_alpha {
    x := i % mu.DEFAULT_ATLAS_WIDTH
    y := i / mu.DEFAULT_ATLAS_WIDTH
    color := rl.Color{255, 255, 255, alpha}
    rl.ImageDrawPixel(&image, c.int(x), c.int(y), color)
  }

  rl.BeginTextureMode(ui_state.atlas_texture)
  rl.UpdateTexture(ui_state.atlas_texture.texture, rl.LoadImageColors(image))
  rl.EndTextureMode()

  ui_state.screen_texture = rl.LoadRenderTexture(WIDTH, HEIGHT)
  defer rl.UnloadRenderTexture(ui_state.screen_texture)
  
  for !rl.WindowShouldClose() {
    elapsed := rl.GetFrameTime()
    
    rl.BeginDrawing()
    
    rl.ClearBackground(rl.BLACK)

    RenderBoard(khet_board, board_rect)

    if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
      UpdatePick(&khet_board, rl.GetMousePosition())
    }

    free_all(context.temp_allocator)

    mouse_pos := rl.GetMousePosition()
    mouse_x, mouse_y := i32(mouse_pos.x), i32(mouse_pos.y)
    mu.input_mouse_move(&ui_state.mu_ctx, mouse_x, mouse_y)

    for button_rl, button_mu in mouse_buttons_map {
      switch {
      case rl.IsMouseButtonPressed(button_rl):
        mu.input_mouse_down(&ui_state.mu_ctx, mouse_x, mouse_y, button_mu)
      case rl.IsMouseButtonReleased(button_rl):
        mu.input_mouse_up(&ui_state.mu_ctx, mouse_x, mouse_y, button_mu)
      }
    }

    mu.begin(&ui_state.mu_ctx)
    UpdateUI(&ui_state.mu_ctx)
    mu.end(&ui_state.mu_ctx)

    RenderUI(&ui_state.mu_ctx)

    rl.EndDrawing()
  }
}
