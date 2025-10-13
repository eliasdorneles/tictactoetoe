package raylib_thingie

import "core:c"
import "core:fmt"
import "core:math"
import rl "vendor:raylib"

/* BEGIN foreign library declarations */
foreign import lib "./tictactoe-lib-rs/tictactoe-lib-rs/target/release/libtictactoe_lib_rs.a"

Case :: enum c.int {
    BLANK      = 0,
    CROSS_PIN  = 1,
    CIRCLE_PIN = 2,
}

PlayerType :: enum c.int {
    NONE   = 0,
    CROSS  = 1,
    CIRCLE = 2,
}

TictactoeGame :: struct {
    board:         [9][9]Case,
    winners:       [3][3]PlayerType,
    currentPlayer: PlayerType,
    targetBoard:   i8, // -1, when initialized, otherwise 0..8, in L-R, T-D order
}

@(default_calling_convention = "c", link_prefix = "")
foreign lib {
    tictactoe_init :: proc() -> TictactoeGame ---
    tictactoe_play :: proc(game: ^TictactoeGame, row: u8, column: u8) ---
    // tictactoe_check_victory :: proc(game: ^TictactoeGame) -> PlayerType ---
}
/* END foreign library declarations */


WINDOW_WIDTH, WINDOW_HEIGHT :: 800, 600
CASE_WIDTH :: 50

restart :: proc() {
}

update :: proc() {
    dt := rl.GetFrameTime()
    if rl.IsMouseButtonReleased(rl.MouseButton.LEFT) {
        pos := rl.GetMousePosition()
        for i: u8 = 0; i < 9; i += 1 {
            for j: u8 = 0; j < 9; j += 1 {
                if rl.CheckCollisionPointRec(pos, boardRects[i][j]) {
                    tictactoe_play(&game, i, j)
                    fmt.println("target Board is now", game.targetBoard)
                }
            }
        }
    }
}

drawCase :: proc(game: ^TictactoeGame, i, j: int) {

}

draw :: proc() {
    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground({200, 200, 200, 255})
    rl.DrawText("Tic-Tac Toe-Toe!", 200, 20, 40, rl.BLUE)

    highlightColor: rl.Color = {255, 255, 200, 255}
    for i := 0; i < 3; i += 1 {
        for j := 0; j < 3; j += 1 {
            if game.targetBoard == -1 || game.targetBoard == i8(i * 3 + j) {
                rl.DrawRectangleRec(miniBoardRects[i][j], highlightColor)
            }
        }
    }

    thickness := 2
    for i := 0; i < 9; i += 1 {
        for j := 0; j < 9; j += 1 {
            rect := boardRects[i][j]
            rl.DrawRectangleLinesEx(rect, f32(thickness), rl.DARKGRAY)
            if game.board[i][j] == .CIRCLE_PIN {
                center := rl.Vector2 {
                    f32(rect.x + rect.width / 2),
                    f32(rect.y + rect.height / 2),
                }
                rl.DrawRing(center, 15, 20, 0, 360, 0, rl.DARKGREEN)
            }
            if game.board[i][j] == .CROSS_PIN {
                padding: f32 = 8
                startPos := rl.Vector2{(rect.x + padding), (rect.y + padding)}
                endPos := rl.Vector2 {
                    (rect.x + rect.width - padding),
                    (rect.y + rect.height - padding),
                }
                rl.DrawLineEx(startPos, endPos, 5, rl.DARKBROWN)
                startPos.y, endPos.y = endPos.y, startPos.y
                rl.DrawLineEx(startPos, endPos, 5, rl.DARKBROWN)
            }
        }
    }
}

initBoardRects :: proc() {
    innerPadding := 1
    padding := 4
    startX, startY := 150, 80
    for i := 0; i < 9; i += 1 {
        for j := 0; j < 9; j += 1 {
            boardRects[i][j] = rl.Rectangle {
                x      = f32(
                    startX + CASE_WIDTH * i + (i / 3) * padding + i * innerPadding,
                ),
                y      = f32(
                    startY + CASE_WIDTH * j + (j / 3) * padding + j * innerPadding,
                ),
                width  = CASE_WIDTH,
                height = CASE_WIDTH,
            }
        }
    }
    miniBoardWidth := boardRects[0][0].width * 3
    miniBoardHeight := boardRects[0][0].height * 3
    for i := 0; i < 3; i += 1 {
        for j := 0; j < 3; j += 1 {
            miniBoardRects[i][j] = rl.Rectangle {
                x      = boardRects[i * 3][j * 3].x,
                y      = boardRects[i * 3][j * 3].y,
                width  = miniBoardWidth,
                height = miniBoardHeight,
            }

        }
    }
}

boardRects: [9][9]rl.Rectangle
miniBoardRects: [3][3]rl.Rectangle
game: TictactoeGame

main :: proc() {
    game = tictactoe_init()
    initBoardRects()
    rl.SetConfigFlags({.VSYNC_HINT})

    rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "TicTac ToeToe!")
    defer rl.CloseWindow()

    rl.InitAudioDevice()
    defer rl.CloseAudioDevice()

    rl.SetTargetFPS(60)

    restart()

    for !rl.WindowShouldClose() {
        update()
        draw()
    }
}
