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
// HIGHLIGHT_COLOR: rl.Color : {253, 244, 227, 255}
HIGHLIGHT_COLOR: rl.Color : {254, 178, 26, 220}
BG_COLOR_DAY_MODE: rl.Color : {240, 240, 240, 255}
BG_COLOR_DARK_MODE: rl.Color : {10, 10, 10, 255}

GAME_BOARD_POS: [2]int : {150, 100}

GameState :: struct {
    playing:     bool,
    enableSound: bool,
    winner:      PlayerType,
    nightMode:   bool,
}

run: bool
boardRects: [9][9]rl.Rectangle
miniBoardRects: [3][3]rl.Rectangle
game: TictactoeGame
crossTx: rl.Texture
circleTx: rl.Texture
state: GameState
smallWinSound: rl.Sound
playerWinSound: rl.Sound
playerMoveSound: rl.Sound

initBoardRects :: proc() {
    innerPadding := 2
    padding := 8
    for i := 0; i < 9; i += 1 {
        for j := 0; j < 9; j += 1 {
            boardRects[i][j] = rl.Rectangle {
                x      = f32(
                    GAME_BOARD_POS.x +
                    CASE_WIDTH * j +
                    (j / 3) * padding +
                    j * innerPadding,
                ),
                y      = f32(
                    GAME_BOARD_POS.y +
                    CASE_WIDTH * i +
                    (i / 3) * padding +
                    i * innerPadding,
                ),
                width  = CASE_WIDTH,
                height = CASE_WIDTH,
            }
        }
    }

    miniBoardWidth := boardRects[0][0].width * 3 + 4
    miniBoardHeight := boardRects[0][0].height * 3 + 4
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
    // NOTE: we don't truly need the window to be resizable, but if we leave
    // don't leave the window be resizable, for some reason CPU usage increases
    // wildly on Firefox when using the WASM build
    rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT})
    rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "TicTac ToeToe!")

    rl.InitAudioDevice()

    // load assets
    crossTx = rl.LoadTexture("assets/cross.png")
    circleTx = rl.LoadTexture("assets/circle.png")

    playerMoveSound = rl.LoadSound("assets/play.wav")
    playerWinSound = rl.LoadSound("assets/win.wav")
    smallWinSound = rl.LoadSound("assets/smallWin.wav")
    rl.SetSoundVolume(playerMoveSound, 0.5)
    rl.SetSoundVolume(playerWinSound, 0.5)
    rl.SetSoundVolume(smallWinSound, 0.5)

    restart()
    state.enableSound = true

    rl.SetTargetFPS(60)
}

restart :: proc() {
    game = tictactoe_init()
    state.playing = true
    state.winner = .NONE
    initBoardRects()
}

drawPlayerSymbol :: proc(
    playerType: PlayerType,
    pos: rl.Vector2,
    scale: f32,
    alpha: u8 = 255,
) {
    if playerType == .CIRCLE {
        rl.DrawTextureEx(circleTx, pos, 0, scale, {255, 255, 255, alpha})
    }
    if playerType == .CROSS {
        rl.DrawTextureEx(crossTx, pos, 0, scale, {255, 255, 255, alpha})
    }
}

calcGameWinner :: proc() -> PlayerType {
    // check rows
    for row in 0 ..= 2 {
        if game.winners[row][0] != .NONE &&
           game.winners[row][0] == game.winners[row][1] &&
           game.winners[row][0] == game.winners[row][2] {
            return game.winners[row][0]
        }
    }
    // check cols
    for col in 0 ..= 2 {
        if game.winners[0][col] != .NONE &&
           game.winners[0][col] == game.winners[1][col] &&
           game.winners[0][col] == game.winners[2][col] {
            return game.winners[0][col]
        }
    }
    // descending diagonal
    if game.winners[0][0] != .NONE &&
       game.winners[0][0] == game.winners[1][1] &&
       game.winners[0][0] == game.winners[2][2] {
        return game.winners[0][0]
    }
    // ascending diagonal
    if game.winners[2][2] != .NONE &&
       game.winners[2][2] == game.winners[1][1] &&
       game.winners[2][2] == game.winners[0][2] {
        return game.winners[2][2]
    }
    return PlayerType.NONE
}

play :: proc(row, column: u8) {
    fmt.println("play row =", row, "column =", column)

    rowBefore := game.board[row][column]
    boardWinnerBefore := game.winners[row / 3][column / 3]

    tictactoe_play(&game, row, column)

    rowAfter := game.board[row][column]
    boardWinnerAfter := game.winners[row / 3][column / 3]

    fmt.println("target Board is now", game.targetBoard)
    fmt.println("winners", game.winners)

    state.winner = calcGameWinner()
    state.playing = state.winner == .NONE

    if state.enableSound {
        if state.winner != .NONE {
            rl.PlaySound(playerWinSound)
        } else if boardWinnerBefore != boardWinnerAfter {
            rl.PlaySound(smallWinSound)
        } else if rowBefore != rowAfter {
            rl.PlaySound(playerMoveSound)
        }
    }
}

handleInput :: proc() {
    if !state.playing {
        return
    }
    if rl.IsMouseButtonReleased(rl.MouseButton.LEFT) {
        pos := rl.GetMousePosition()
        for i: u8 = 0; i < 9; i += 1 {
            for j: u8 = 0; j < 9; j += 1 {
                if rl.CheckCollisionPointRec(pos, boardRects[i][j]) {
                    play(i, j)
                }
            }
        }
    }
}

drawGame :: proc() {
    {
        pos: [2]f32 = {309, f32(GAME_BOARD_POS.y - 25)}
        if state.winner == .NONE {
            textColor := CIRCLE_COLOR if game.currentPlayer == .CIRCLE else CROSS_COLOR
            rl.DrawText("Player turn:", i32(pos.x), i32(pos.y), 20, textColor)
            pos.x += 130
            drawPlayerSymbol(game.currentPlayer, pos, 0.1)
        } else {
            textColor := CIRCLE_COLOR if state.winner == .CIRCLE else CROSS_COLOR
            rl.DrawText("WINNER:", i32(pos.x), i32(pos.y), 20, textColor)
            pos.x += 90
            drawPlayerSymbol(state.winner, pos, 0.1)
        }
    }

    // draw backgrounds -- highlight target board(s) and board winners
    for i := 0; i < 3; i += 1 {
        for j := 0; j < 3; j += 1 {
            rect := miniBoardRects[i][j]
            pos := rl.Vector2{f32(rect.x), f32(rect.y)}
            if state.playing &&
               (game.targetBoard == -1 || game.targetBoard == i8(i * 3 + j)) {
                rl.DrawRectangleRec(rect, HIGHLIGHT_COLOR)
            }
            if game.winners[i][j] != .NONE {
                drawPlayerSymbol(game.winners[i][j], pos + 4, 0.8, 120)
            }
        }
    }

    // here we draw the board
    thickness := 2
    for i := 0; i < 9; i += 1 {
        for j := 0; j < 9; j += 1 {
            rect := boardRects[i][j]
            rl.DrawRectangleLinesEx(rect, f32(thickness), rl.DARKGRAY)
            pos := rl.Vector2{f32(rect.x), f32(rect.y)} + 2
            if game.board[i][j] == .CIRCLE_PIN {
                drawPlayerSymbol(.CIRCLE, pos, 0.25)
            }
            if game.board[i][j] == .CROSS_PIN {
                drawPlayerSymbol(.CROSS, pos, 0.25)
            }
        }
    }
}

updateControls :: proc() {
    text: cstring = "#74#Restart"
    if state.winner != .NONE {
        text = "#74#Play again"
    }
    if rl.GuiButton({25, f32(GAME_BOARD_POS.y), 100, 40}, text) {
        restart()
    }
    rl.GuiToggle(
        {25, f32(GAME_BOARD_POS.y) + 60, 100, 40},
        "#122#Toggle sound",
        &state.enableSound,
    )
    rl.GuiToggle(
        {25, f32(GAME_BOARD_POS.y) + 120, 100, 40},
        "#94#Dark mode",
        &state.nightMode,
    )
}

update :: proc() {
    // handle input and update game state
    // dt := rl.GetFrameTime()
    handleInput()

    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground(BG_COLOR_DARK_MODE if state.nightMode else BG_COLOR_DAY_MODE)

    rl.DrawText("Tic-Tac Toe-Toe!", 170, 20, 48, CIRCLE_COLOR)

    // TODO: it seems this also works before rl.beginDrawing(), why should it be here??
    updateControls()

    drawGame()

    // Anything allocated using temp allocator is invalid after this.
    free_all(context.temp_allocator)
}


shutdown :: proc() {
    rl.UnloadTexture(crossTx)
    rl.UnloadTexture(circleTx)
    rl.CloseAudioDevice()
    rl.CloseWindow()
}

parent_window_size_changed :: proc(w, h: int) {
    rl.SetWindowSize(c.int(w), c.int(h))
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
