package main

import "core:fmt"
import "core:math"
import "core:math/rand"
import "core:time"
import "core:strings"
import "core:unicode"

import rl "vendor:raylib"

WIDTH  :: 1280
HEIGHT :: 800

BORDER_COLOR :: rl.Color { 108, 122, 137, 255 }

KINGLY :: rl.Color { 0, 255, 0, 255 }

LIGHT_RED :: rl.Color { 200, 0, 0, 255 }
DARK_RED :: rl.Color { 100, 0, 0, 255 }

LIGHT_SILVER :: rl.Color { 200, 200, 200, 255 }
DARK_SILVER :: rl.Color { 100, 100, 100, 255 }

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

Board :: struct {
  player_to_move: Player,
  squares: [8][10]Square,

  rects: [8][10]rl.Rectangle,
  selected: Maybe([2]int)
}

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

  return board
}

main :: proc() {
  rl.InitWindow(WIDTH, HEIGHT, "Khet")
  defer rl.CloseWindow()
  
  rl.SetTargetFPS(60)

  board_rect := rl.Rectangle{50, 50, WIDTH - 100, HEIGHT - 100}

  board := InitialKhetBoard(board_rect)
  
  for !rl.WindowShouldClose() {
    elapsed := rl.GetFrameTime()
    
    rl.BeginDrawing()
    
    rl.ClearBackground(rl.BLACK)

    RenderBoard(board, board_rect)

    if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
      UpdatePick(&board, rl.GetMousePosition())
    }

    rl.EndDrawing()
  }
}
