package game

import "core:c"
import "core:fmt"
// import "core:math"
// import "core:strings"
import rl "vendor:raylib"

/* BEGIN foreign library declarations */
LIB_TICTACTOE :: #config(
    LIB_TICTACTOE,
    "./tictactoe-lib-rs/tictactoe-lib-rs/target/wasm32-unknown-unknown/release/libtictactoe_lib_rs.a",
)
when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {
    foreign import lib {LIB_TICTACTOE}
} else {
    foreign import lib "../tictactoe-lib-rs/tictactoe-lib-rs/target/release/libtictactoe_lib_rs.a"
}

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
    fullBoards:    [9]bool,
}

@(default_calling_convention = "c")
foreign lib {
    tictactoe_init :: proc() -> TictactoeGame ---
    tictactoe_play :: proc(game: ^TictactoeGame, row: u8, column: u8) ---
    // tictactoe_check_victory :: proc(game: ^TictactoeGame) -> PlayerType ---
}
/* END foreign library declarations */


WINDOW_WIDTH, WINDOW_HEIGHT :: 800, 600
CASE_WIDTH :: 50

// color palette: https://colorhunt.co/palette/134686ed3f27feb21afdf4e3
CIRCLE_COLOR: rl.Color : {19, 70, 134, 255}
CIRCLE_COLOR_BACK: rl.Color : {141, 161, 186, 255}
CROSS_COLOR: rl.Color : {237, 63, 39, 255}
CROSS_COLOR_BACK: rl.Color : {227, 158, 149, 255}
HIGHLIGHT_COLOR: rl.Color : {253, 244, 227, 255}

run: bool
boardRects: [9][9]rl.Rectangle
miniBoardRects: [3][3]rl.Rectangle
game: TictactoeGame
crossTx: rl.Texture
circleTx: rl.Texture

initBoardRects :: proc() {
    innerPadding := 1
    padding := 4
    startX, startY := 150, 80
    for i := 0; i < 9; i += 1 {
        for j := 0; j < 9; j += 1 {
            boardRects[i][j] = rl.Rectangle {
                x      = f32(
                    startX + CASE_WIDTH * j + (j / 3) * padding + j * innerPadding,
                ),
                y      = f32(
                    startY + CASE_WIDTH * i + (i / 3) * padding + i * innerPadding,
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

init :: proc() {
    run = true
    rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT})
    rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "TicTac ToeToe!")

    // load assets
    crossTx = rl.LoadTexture("assets/cross.png")
    circleTx = rl.LoadTexture("assets/circle.png")

    game = tictactoe_init()
    initBoardRects()

    rl.SetTargetFPS(60)
}

update :: proc() {
    // handle input and update game state
    // dt := rl.GetFrameTime()
    if rl.IsMouseButtonReleased(rl.MouseButton.LEFT) {
        pos := rl.GetMousePosition()
        for i: u8 = 0; i < 9; i += 1 {
            for j: u8 = 0; j < 9; j += 1 {
                if rl.CheckCollisionPointRec(pos, boardRects[i][j]) {
                    fmt.println("row =", i, "column =", j)
                    tictactoe_play(&game, i, j)
                    fmt.println("target Board is now", game.targetBoard)
                    fmt.println("winners", game.winners)
                }
            }
        }
    }


    // draw
    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground({240, 240, 240, 255})
    rl.DrawText("Tic-Tac Toe-Toe!", 170, 20, 48, CIRCLE_COLOR)

    for i := 0; i < 3; i += 1 {
        for j := 0; j < 3; j += 1 {
            rect := miniBoardRects[i][j]
            pos := rl.Vector2{f32(rect.x), f32(rect.y)}
            if game.targetBoard == -1 || game.targetBoard == i8(i * 3 + j) {
                rl.DrawRectangleRec(rect, HIGHLIGHT_COLOR)
            }
            if game.winners[i][j] == .CIRCLE {
                rl.DrawTextureEx(circleTx, pos + 4, 0, 0.8, {255, 255, 255, 100})
            }
            if game.winners[i][j] == .CROSS {
                rl.DrawTextureEx(crossTx, pos + 4, 0, 0.8, {255, 255, 255, 100})
            }
        }
    }

    thickness := 2
    for i := 0; i < 9; i += 1 {
        for j := 0; j < 9; j += 1 {
            rect := boardRects[i][j]
            rl.DrawRectangleLinesEx(rect, f32(thickness), rl.DARKGRAY)
            pos := rl.Vector2{f32(rect.x), f32(rect.y)} + 2
            if game.board[i][j] == .CIRCLE_PIN {
                rl.DrawTextureEx(circleTx, pos, 0, 0.25, {255, 255, 255, 255})
            }
            if game.board[i][j] == .CROSS_PIN {
                rl.DrawTextureEx(crossTx, pos, 0, 0.25, {255, 255, 255, 255})
            }
        }
    }

    // Anything allocated using temp allocator is invalid after this.
    free_all(context.temp_allocator)
}

// In a web build, this is called when browser changes size. Remove the
// `rl.SetWindowSize` call if you don't want a resizable game.
parent_window_size_changed :: proc(w, h: int) {
    rl.SetWindowSize(c.int(w), c.int(h))
}

shutdown :: proc() {
    rl.UnloadTexture(crossTx)
    rl.UnloadTexture(circleTx)
    rl.CloseWindow()
}

should_run :: proc() -> bool {
    when ODIN_OS != .JS {
        // Never run this proc in browser. It contains a 16 ms sleep on web!
        if rl.WindowShouldClose() {
            run = false
        }
    }

    return run
}
