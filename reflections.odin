package main

import "core:container/small_array"

// Laser travels in orthogonal directions.
Direction :: enum {
  UP,
  DOWN,
  LEFT,
  RIGHT,
  NONE
}

Hit_Type :: enum {
  REFLECTED,
  ABSORBED,
  DEAD
}

// The entries in this array describe what happens when a piece is hit by the
// laser. The `Hit_Type` describes the outcome, and if it was reflection then
// we also keep track of the direction afterwards.
Reflection_Entry :: struct {
  type: Hit_Type,
  reflected_direction: Direction
}

// Indexed by:
// 1) Incoming direction index
// 2) Piece type
// 3) Piece orientation
NUM_ORIENTATIONS :: 4

REFLECTIONS :: [len(Direction) - 1][len(PieceType)][NUM_ORIENTATIONS]Reflection_Entry {
  { // UP
    { // PYRAMID
      Reflection_Entry { Hit_Type.DEAD, Direction.NONE },
      Reflection_Entry { Hit_Type.REFLECTED, Direction.RIGHT },
      Reflection_Entry { Hit_Type.REFLECTED, Direction.LEFT },
      Reflection_Entry { Hit_Type.DEAD, Direction.NONE }
    },
    { // ANUBIS
      Reflection_Entry { Hit_Type.DEAD, Direction.NONE },
      Reflection_Entry { Hit_Type.DEAD, Direction.NONE },
      Reflection_Entry { Hit_Type.ABSORBED, Direction.NONE },
      Reflection_Entry { Hit_Type.DEAD, Direction.NONE }
    },
    { // SCARAB
      Reflection_Entry { Hit_Type.REFLECTED, Direction.LEFT },
      Reflection_Entry { Hit_Type.REFLECTED, Direction.RIGHT },
      Reflection_Entry { Hit_Type.REFLECTED, Direction.LEFT },
      Reflection_Entry { Hit_Type.REFLECTED, Direction.RIGHT }
    },
    { // PHARAOH
      Reflection_Entry { Hit_Type.DEAD, Direction.NONE },
      Reflection_Entry { Hit_Type.DEAD, Direction.NONE },
      Reflection_Entry { Hit_Type.DEAD, Direction.NONE },
      Reflection_Entry { Hit_Type.DEAD, Direction.NONE }
    },
    { // SPHINX
      Reflection_Entry { Hit_Type.ABSORBED, Direction.NONE },
      Reflection_Entry { Hit_Type.ABSORBED, Direction.NONE },
      Reflection_Entry { Hit_Type.ABSORBED, Direction.NONE },
      Reflection_Entry { Hit_Type.ABSORBED, Direction.NONE }
    }
  },
  { // DOWN
    { // PYRAMID
      Reflection_Entry { Hit_Type.REFLECTED, Direction.RIGHT },
      Reflection_Entry { Hit_Type.DEAD, Direction.NONE },
      Reflection_Entry { Hit_Type.DEAD, Direction.NONE },
      Reflection_Entry { Hit_Type.REFLECTED, Direction.LEFT }
    },
    { // ANUBIS
      Reflection_Entry { Hit_Type.ABSORBED, Direction.NONE },
      Reflection_Entry { Hit_Type.DEAD, Direction.NONE },
      Reflection_Entry { Hit_Type.DEAD, Direction.NONE },
      Reflection_Entry { Hit_Type.DEAD, Direction.NONE }
    },
    { // SCARAB
      Reflection_Entry { Hit_Type.REFLECTED, Direction.RIGHT },
      Reflection_Entry { Hit_Type.REFLECTED, Direction.LEFT },
      Reflection_Entry { Hit_Type.REFLECTED, Direction.RIGHT },
      Reflection_Entry { Hit_Type.REFLECTED, Direction.LEFT }
    },
    { // PHARAOH
      Reflection_Entry { Hit_Type.DEAD, Direction.NONE },
      Reflection_Entry { Hit_Type.DEAD, Direction.NONE },
      Reflection_Entry { Hit_Type.DEAD, Direction.NONE },
      Reflection_Entry { Hit_Type.DEAD, Direction.NONE }
    },
    { // SPHINX
      Reflection_Entry { Hit_Type.ABSORBED, Direction.NONE },
      Reflection_Entry { Hit_Type.ABSORBED, Direction.NONE },
      Reflection_Entry { Hit_Type.ABSORBED, Direction.NONE },
      Reflection_Entry { Hit_Type.ABSORBED, Direction.NONE }
    }
  },
  { // LEFT
    { // PYRAMID
      Reflection_Entry { Hit_Type.REFLECTED, Direction.UP },
      Reflection_Entry { Hit_Type.REFLECTED, Direction.DOWN },
      Reflection_Entry { Hit_Type.DEAD, Direction.NONE },
      Reflection_Entry { Hit_Type.DEAD, Direction.NONE }
    },
    { // ANUBIS
      Reflection_Entry { Hit_Type.DEAD, Direction.NONE },
      Reflection_Entry { Hit_Type.ABSORBED, Direction.NONE },
      Reflection_Entry { Hit_Type.DEAD, Direction.NONE },
      Reflection_Entry { Hit_Type.DEAD, Direction.NONE }
    },
    { // SCARAB
      Reflection_Entry { Hit_Type.REFLECTED, Direction.UP },
      Reflection_Entry { Hit_Type.REFLECTED, Direction.DOWN },
      Reflection_Entry { Hit_Type.REFLECTED, Direction.UP },
      Reflection_Entry { Hit_Type.REFLECTED, Direction.DOWN }
    },
    { // PHARAOH
      Reflection_Entry { Hit_Type.DEAD, Direction.NONE },
      Reflection_Entry { Hit_Type.DEAD, Direction.NONE },
      Reflection_Entry { Hit_Type.DEAD, Direction.NONE },
      Reflection_Entry { Hit_Type.DEAD, Direction.NONE }
    },
    { // SPHINX
      Reflection_Entry { Hit_Type.ABSORBED, Direction.NONE },
      Reflection_Entry { Hit_Type.ABSORBED, Direction.NONE },
      Reflection_Entry { Hit_Type.ABSORBED, Direction.NONE },
      Reflection_Entry { Hit_Type.ABSORBED, Direction.NONE }
    }
  },
  { // RIGHT
    { // PYRAMID
      Reflection_Entry { Hit_Type.DEAD, Direction.NONE },
      Reflection_Entry { Hit_Type.DEAD, Direction.NONE },
      Reflection_Entry { Hit_Type.REFLECTED, Direction.DOWN },
      Reflection_Entry { Hit_Type.REFLECTED, Direction.UP }
    },
    { // ANUBIS
      Reflection_Entry { Hit_Type.DEAD, Direction.NONE },
      Reflection_Entry { Hit_Type.DEAD, Direction.NONE },
      Reflection_Entry { Hit_Type.DEAD, Direction.NONE },
      Reflection_Entry { Hit_Type.ABSORBED, Direction.NONE }
    },
    { // SCARAB
      Reflection_Entry { Hit_Type.REFLECTED, Direction.DOWN },
      Reflection_Entry { Hit_Type.REFLECTED, Direction.UP },
      Reflection_Entry { Hit_Type.REFLECTED, Direction.DOWN },
      Reflection_Entry { Hit_Type.REFLECTED, Direction.UP }
    },
    { // PHARAOH
      Reflection_Entry { Hit_Type.DEAD, Direction.NONE },
      Reflection_Entry { Hit_Type.DEAD, Direction.NONE },
      Reflection_Entry { Hit_Type.DEAD, Direction.NONE },
      Reflection_Entry { Hit_Type.DEAD, Direction.NONE }
    },
    { // SPHINX
      Reflection_Entry { Hit_Type.ABSORBED, Direction.NONE },
      Reflection_Entry { Hit_Type.ABSORBED, Direction.NONE },
      Reflection_Entry { Hit_Type.ABSORBED, Direction.NONE },
      Reflection_Entry { Hit_Type.ABSORBED, Direction.NONE }
    }
  }
}

find_laser_path :: proc(
  loc: [2]int,
  direction: Direction,
  squares: [KHET_BOARD_HEIGHT][KHET_BOARD_WIDTH]Square) ->
  (path: Laser_Path, dead_loc: Maybe([2]int)) {

  next_step :: proc(loc: [2]int, direction: Direction) -> [2]int {
    next := loc
    #partial switch direction {
      case .UP: next[0] -= 1
      case .DOWN: next[0] += 1
      case .LEFT: next[1] -= 1
      case .RIGHT: next[1] += 1
    }

    return next
  }

  on_board :: proc(loc: [2]int) -> bool {
    return loc[0] >= 0 && loc[0] < KHET_BOARD_HEIGHT &&
           loc[1] >= 0 && loc[1] < KHET_BOARD_WIDTH
  }

  small_array.push_back(&path, loc)
  loc := next_step(loc, direction)

  direction := direction
  reflections := REFLECTIONS
  for on_board(loc) {
    small_array.push_back(&path, loc)

    // Deal with reflections etc.
    sq := squares[loc[0]][loc[1]]
    if sq != nil {
      piece := sq.?
      entry := reflections[direction][piece.type][piece.rotation]

      if entry.type == Hit_Type.REFLECTED {
        direction = entry.reflected_direction
      }
      else if entry.type == Hit_Type.DEAD {
        dead_loc = loc
      }

      if entry.type != Hit_Type.REFLECTED do break
    }

    loc = next_step(loc, direction)
  }

  return
}
