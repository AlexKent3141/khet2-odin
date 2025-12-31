package main

import "core:c"
import "core:fmt"
import "core:math"
import "core:time"
import "core:strings"
import "core:unicode"
import "core:container/small_array"

import rl "vendor:raylib"
import mu "vendor:microui"

ui_state := struct {
    mu_ctx: mu.Context,
    atlas_texture: rl.RenderTexture2D,
    screen_texture: rl.RenderTexture2D,
    bg: rl.Color,
    winner: Maybe(Player)
}{
    bg = rl.Color{0, 0, 0, 0}
}

WIDTH  :: 1280
HEIGHT :: 800
FPS :: 60
LASER_FRAMES :: 2 * FPS

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

Square :: struct {
  piece: Maybe(Piece),
  owner: Maybe(Player)
}

MoveType :: enum {
  UL, U, UR,
  L,     R,
  DL, D, DR,
  CW, ACW
}

MoveSet :: distinct bit_set[MoveType]

KHET_BOARD_WIDTH :: 10
KHET_BOARD_HEIGHT :: 8

Laser_Path :: distinct small_array.Small_Array(100, [2]int)

Board :: struct {
  player_to_move: Player,
  squares: [KHET_BOARD_HEIGHT][KHET_BOARD_WIDTH]Square,

  board_rect: rl.Rectangle,
  square_rects: [8][10]rl.Rectangle,
  selected: Maybe([2]int),
  current_moves: MoveSet,

  laser_path: Laser_Path,
  num_laser_frames: int,
  pending_dead_piece_loc: Maybe([2]int)
}

laser_in_progress :: proc(board: Board) -> bool {
  return small_array.len(board.laser_path) > 0 && board.num_laser_frames < LASER_FRAMES
}

remove_pending_dead_piece :: proc(board: ^Board) {
  if board^.pending_dead_piece_loc != nil {
    y := board^.pending_dead_piece_loc.?[0]
    x := board^.pending_dead_piece_loc.?[1]
    board^.squares[y][x].piece = nil
  }
}

khet_board: Board

UpdatePick :: proc(board: ^Board, click_pos: [2]f32) {

  hit_test :: proc(x, y: f32, rect: rl.Rectangle) -> bool {
    return x > rect.x && x < rect.x + rect.width &&
           y > rect.y && y < rect.y + rect.height
  }

  // If the click is not on the board then do not update the pick.
  if !hit_test(click_pos[0], click_pos[1], board^.board_rect) {
    return
  }

  selection: Maybe([2]int)
  for row in 0..<8 {
    for col in 0..<10 {
      sq := board^.squares[row][col]
      if sq.piece != nil &&
         sq.piece.?.owner == board^.player_to_move &&
         hit_test(click_pos[0], click_pos[1], board^.square_rects[row][col]) {

        selection = [2]int{row, col}
      }
    }
  }

  if selection != nil {
    board^.selected = selection.?

    // Update the current move set.
    board^.current_moves = MoveSet{}

    sel_y := selection.?[0]
    sel_x := selection.?[1]

    piece := board^.squares[sel_y][sel_x].piece
    pt := piece.?.type
    if pt != PieceType.SPHINX {

      can_move :: proc(source_piece: Piece, target_sq: Square) -> bool {
        target_piece := target_sq.piece
        if target_sq.owner != nil && source_piece.owner != target_sq.owner.? {
          return false
        }
        if target_piece == nil do return true
        return source_piece.type == PieceType.SCARAB &&
               target_piece.?.type != PieceType.SCARAB
      }

      if sel_x > 0 && can_move(piece.?, board^.squares[sel_y][sel_x - 1]) {
        board^.current_moves += {MoveType.L}
      }
      if sel_x < 9 && can_move(piece.?, board^.squares[sel_y][sel_x + 1]) {
        board^.current_moves += {MoveType.R}
      }
      if sel_y > 0 && can_move(piece.?, board^.squares[sel_y - 1][sel_x]) {
        board^.current_moves += {MoveType.U}
      }
      if sel_y < 7 && can_move(piece.?, board^.squares[sel_y + 1][sel_x]) {
        board^.current_moves += {MoveType.D}
      }
      if sel_x > 0 && sel_y > 0 &&
         can_move(piece.?, board^.squares[sel_y - 1][sel_x - 1]) {
        board^.current_moves += {MoveType.UL}
      }
      if sel_x > 0 && sel_y < 7 &&
         can_move(piece.?, board^.squares[sel_y + 1][sel_x - 1]) {
        board^.current_moves += {MoveType.DL}
      }
      if sel_x < 9 && sel_y > 0 &&
         can_move(piece.?, board^.squares[sel_y - 1][sel_x + 1]) {
        board^.current_moves += {MoveType.UR}
      }
      if sel_x < 9 && sel_y < 7 &&
         can_move(piece.?, board^.squares[sel_y + 1][sel_x + 1]) {
        board^.current_moves += {MoveType.DR}
      }

      // Check for rotations, avoiding duplicates due to symmetry.
      if pt == PieceType.SCARAB {
        board^.current_moves += {MoveType.CW}
      }
      else if pt != PieceType.PHARAOH {
        board^.current_moves += {MoveType.CW}
        board^.current_moves += {MoveType.ACW}
      }
    }
    else {
      // One rotation is available, just hardcode the cases.
      if piece.?.owner == Player.SILVER {
        board^.current_moves += {piece.?.rotation == 0 ? MoveType.ACW : MoveType.CW}
      }
      else {
        board^.current_moves += {piece.?.rotation == 2 ? MoveType.ACW : MoveType.CW}
      }
    }
  }

  if selection == nil {
    board^.selected = nil
    board^.current_moves = MoveSet{}
  }
}

MakeMove :: proc(type: MoveType) {

  x := khet_board.selected.?[1]
  y := khet_board.selected.?[0]

  // Deal with rotations first.
  sq := &khet_board.squares[y][x]
  piece := &khet_board.squares[y][x].piece.?
  #partial switch type {
    case .CW:
      piece^.rotation += 1
      piece^.rotation %= 4
    case .ACW:
      piece^.rotation -= 1
      if piece^.rotation < 0 do piece^.rotation += 4
  }

  // Swap the squares for the current selected piece and the targeted piece.
  target_x := x
  target_y := y

  #partial switch type {
    case .U: target_y -= 1
    case .D: target_y += 1
    case .L: target_x -= 1
    case .R: target_x += 1
    case .UL:
      target_x -= 1
      target_y -= 1
    case .UR:
      target_x += 1
      target_y -= 1
    case .DL:
      target_x -= 1
      target_y += 1
    case .DR:
      target_x += 1
      target_y += 1
  }

  if target_x != x || target_y != y {
    target_sq := &khet_board.squares[target_y][target_x]

    if target_sq^.piece == nil {
      target_sq^.piece = sq^.piece
      khet_board.squares[y][x].piece = nil
    }
    else {
      tmp := sq^.piece
      sq^.piece = target_sq^.piece
      target_sq^.piece = tmp
    }
  }

  // Calculate the laser path.
  loc := khet_board.player_to_move == .RED ? [2]int {0, 0} : [2]int {7, 9}
  sphinx := khet_board.squares[loc[0]][loc[1]].piece
  assert(sphinx != nil)
  direction := Direction.NONE
  if sphinx.?.rotation == 0 do direction = Direction.UP
  else if sphinx.?.rotation == 1 do direction = Direction.RIGHT
  else if sphinx.?.rotation == 2 do direction = Direction.DOWN
  else if sphinx.?.rotation == 3 do direction = Direction.LEFT

  khet_board.laser_path, khet_board.pending_dead_piece_loc =
    find_laser_path(loc, direction, khet_board.squares)
  khet_board.num_laser_frames = 0

  // Move to the next player.
  khet_board.selected = nil
  khet_board.current_moves = {}
  khet_board.player_to_move = khet_board.player_to_move == .RED ? .SILVER : .RED
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

        board.squares[row_index][col_index].piece = Piece{piece_type.?, player, orientation}
        col_index += 1
      }
      else {
        col_index = col_index + cast(int)c - '0'
      }

      i += 1
    }
  }

  // Set the ownership of special "owned" squares.
  for r in 0..<KHET_BOARD_HEIGHT {
    board.squares[r][0].owner = Player.RED
    board.squares[r][KHET_BOARD_WIDTH - 1].owner = Player.SILVER
  }

  board.squares[0][1].owner = Player.SILVER
  board.squares[KHET_BOARD_HEIGHT - 1][1].owner = Player.SILVER

  board.squares[0][KHET_BOARD_WIDTH - 2].owner = Player.RED
  board.squares[KHET_BOARD_HEIGHT - 1][KHET_BOARD_WIDTH - 2].owner = Player.RED

  // Figure out the size of each square.
  side := cast(int)math.min(rect.width / 10, rect.height / 8)

  for row in 0..<8 {
    row_offset := side * row
    for col in 0..<10 {
      col_offset := side * col

      board.square_rects[row][col] = rl.Rectangle{
          x = rect.x + cast(f32)col_offset,
          y = rect.y + cast(f32)row_offset,
          width = cast(f32)side,
          height = cast(f32)side}
    }
  }

  board.board_rect =
    rl.Rectangle{x = rect.x, y = rect.y, width = 10 * cast(f32)side, height = 8 * cast(f32)side}
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

UpdateUI :: proc(ctx: ^mu.Context) {
  @static opts := mu.Options{.NO_INTERACT, .NO_RESIZE, .NO_CLOSE}

  show_button :: proc(ctx: ^mu.Context, move_type: MoveType, moves: MoveSet) {
    if move_type in moves {
      caption, _ := fmt.enum_value_to_string(move_type)
      if .SUBMIT in mu.button(ctx, caption) {
        MakeMove(move_type)
      }
    }
    else {
      mu.label(ctx, "")
    }
  }

  if mu.window(ctx, "Controls", {WIDTH - 300, 0, 300, HEIGHT}, opts) {
    {
      mu.layout_row_items(ctx, 3, 0)

      show_button(ctx, MoveType.UL, khet_board.current_moves)
      show_button(ctx, MoveType.U, khet_board.current_moves)
      show_button(ctx, MoveType.UR, khet_board.current_moves)
    }

    {
      mu.layout_row_items(ctx, 3, 0)

      show_button(ctx, MoveType.L, khet_board.current_moves)

      mu.label(ctx, "")

      show_button(ctx, MoveType.R, khet_board.current_moves)
    }

    {
      mu.layout_row_items(ctx, 3, 0)

      show_button(ctx, MoveType.DL, khet_board.current_moves)
      show_button(ctx, MoveType.D, khet_board.current_moves)
      show_button(ctx, MoveType.DR, khet_board.current_moves)
    }

    {
      mu.layout_row_items(ctx, 1, 0)
      mu.label(ctx, "")
    }

    {
      mu.layout_row_items(ctx, 3, 0)

      show_button(ctx, MoveType.CW, khet_board.current_moves)

      mu.label(ctx, "")

      show_button(ctx, MoveType.ACW, khet_board.current_moves)
    }
  }

  if ui_state.winner != nil {
    if mu.window(ctx, "Game Over", {WIDTH / 2 - 100, HEIGHT / 2 - 50, 200, 100}, opts) {
      mu.layout_row(ctx, { 200 }, 0)
      if ui_state.winner.? == .RED do mu.label(ctx, "Player RED wins!")
      else do mu.label(ctx, "Player SILVER wins!")
    }
  }
}

main :: proc() {
  rl.InitWindow(WIDTH, HEIGHT, "Khet")
  defer rl.CloseWindow()

  mu.init(&ui_state.mu_ctx)

  ui_state.mu_ctx.text_width = mu.default_atlas_text_width
  ui_state.mu_ctx.text_height = mu.default_atlas_text_height
  
  rl.SetTargetFPS(FPS)

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

    khet_board.num_laser_frames += 1
    if khet_board.num_laser_frames == LASER_FRAMES {
      // Is the game over?
      if khet_board.pending_dead_piece_loc != nil {
        y := khet_board.pending_dead_piece_loc.?[0]
        x := khet_board.pending_dead_piece_loc.?[1]

        killed_piece := khet_board.squares[y][x].piece
        if killed_piece != nil && killed_piece.?.type == .PHARAOH {
          ui_state.winner = killed_piece.?.owner == .RED ? .SILVER : .RED
        }
      }

      remove_pending_dead_piece(&khet_board)
    }

    elapsed := rl.GetFrameTime()
    
    rl.BeginDrawing()
    
    rl.ClearBackground(rl.BLACK)

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

    RenderBoard(&khet_board, board_rect)
    RenderUI(&ui_state.mu_ctx)

    if ui_state.winner == nil {
      if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) && !laser_in_progress(khet_board) {
        UpdatePick(&khet_board, rl.GetMousePosition())
      }
    }

    free_all(context.temp_allocator)

    rl.EndDrawing()
  }
}
