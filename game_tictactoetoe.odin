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

TictactoeGame :: struct {
    board: [9][9]Case,
}

@(default_calling_convention = "c", link_prefix = "")
foreign lib {
    tictactoe_init :: proc() -> TictactoeGame ---
}
/* END foreign library declarations */


WINDOW_WIDTH, WINDOW_HEIGHT :: 800, 600
CASE_WIDTH :: 50

restart :: proc() {
}

update :: proc() {
    dt := rl.GetFrameTime()
    // TODO: read and handle input here
}

draw :: proc(game: ^TictactoeGame) {
    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground({200, 200, 200, 255})
    rl.DrawText("Tic-Tac Toe-Toe!", 200, 20, 40, rl.BLUE)

    thickness := 2
    innerPadding := 1
    padding := 4
    startX, startY := 150, 80
    for i := 0; i < 9; i += 1 {
        for j := 0; j < 9; j += 1 {
            rect := rl.Rectangle {
                x      = f32(
                    startX + CASE_WIDTH * i + (i / 3) * padding + i * innerPadding,
                ),
                y      = f32(
                    startY + CASE_WIDTH * j + (j / 3) * padding + j * innerPadding,
                ),
                width  = CASE_WIDTH,
                height = CASE_WIDTH,
            }
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

main :: proc() {
    game := tictactoe_init()
    rl.SetConfigFlags({.VSYNC_HINT})

    rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "TicTac ToeToe!")
    defer rl.CloseWindow()

    rl.InitAudioDevice()
    defer rl.CloseAudioDevice()

    rl.SetTargetFPS(60)

    restart()

    for !rl.WindowShouldClose() {
        update()
        draw(&game)
    }
}
