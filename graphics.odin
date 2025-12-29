package main

import "core:math"
import "core:container/small_array"

import rl "vendor:raylib"

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

RenderBoard :: proc(board: ^Board, rect: rl.Rectangle) {
  // Figure out the size of each square.
  side := cast(int)math.min(rect.width / 10, rect.height / 8)

  // Draw the pieces.
  for row in 0..<8 {
    for col in 0..<10 {
      sq := board.squares[row][col]
      if sq != nil {
        r := board.square_rects[row][col]
        pt := sq.?.type

        switch pt {
          case .PYRAMID: DrawPyramid(r, sq.?)
          case .ANUBIS: DrawAnubis(r, sq.?)
          case .SCARAB: DrawScarab(r, sq.?)
          case .PHARAOH: DrawPharaoh(r, sq.?)
          case .SPHINX: DrawSphinx(r, sq.?)
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

  // Draw the laser.
  if board.num_laser_frames < 120 && small_array.len(board.laser_path) > 0 {
    rect_centre :: proc(r: rl.Rectangle) -> [2]f32 {
      centre_x := r.x + r.width / 2
      centre_y := r.y + r.height / 2
      return {centre_x, centre_y}
    }

    prev := small_array.get(board.laser_path, 0)
    for next in small_array.slice(&board.laser_path)[1:] {
      prev_centre := rect_centre(board.square_rects[prev[0]][prev[1]])
      next_centre := rect_centre(board.square_rects[next[0]][next[1]])

      rl.DrawLineEx(
        {prev_centre[0], prev_centre[1]},
        {next_centre[0], next_centre[1]},
        5,
        rl.RED)

      prev = next
    }
  }

  // Draw the move pick.
  pick_maybe := board.selected
  if pick_maybe != nil {
    pick: [2]int = pick_maybe.?
    rect := board.square_rects[pick[0]][pick[1]]
    rl.DrawRectangleLinesEx(rect, 4, rl.BLUE)
  }
}

