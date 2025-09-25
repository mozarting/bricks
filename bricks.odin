package main

import rl "vendor:raylib"

import "core:fmt"

// window
WINDOW_WIDTH :: 900
WINDOW_HEIGHT :: 600
WINDOW_TITLE :: "Bricks"
WINDOW_FPS :: 60

// brick
BRICK_WIDTH :: 100
BRICK_HEIGHT :: 20
BRICK_ROWS :: 4
BRICK_COLS :: 8

//ball
BALL_WIDTH :: 10
BALL_HEIGHT :: 10


//bat
BAT_WIDTH :: 100
BAT_HEIGHT :: 12

GameState :: enum {
	Start,
	Playing,
	Paused,
	GameOver,
	Win,
}

Ball :: struct {
	color: rl.Color,
	rect:  rl.Rectangle,
	velX:  f32,
	velY:  f32,
}

Bat :: struct {
	color: rl.Color,
	rect:  rl.Rectangle,
}

Brick :: struct {
	rect:   rl.Rectangle,
	color:  rl.Color,
	active: bool,
}

init_bricks :: proc() -> []Brick {
	bricks := make([]Brick, BRICK_ROWS * BRICK_COLS)

	spacing: f32 = 10.0

	total_width := f32(BRICK_COLS) * BRICK_WIDTH + f32(BRICK_COLS - 1) * spacing

	start_x := f32(WINDOW_WIDTH) / 2 - total_width / 2
	start_y := f32(50)

	for row in 0 ..< BRICK_ROWS {
		for col in 0 ..< BRICK_COLS {
			idx := row * BRICK_COLS + col
			bricks[idx] = Brick {
				rect = rl.Rectangle {
					x = start_x + f32(col) * (BRICK_WIDTH + spacing),
					y = start_y + f32(row) * (BRICK_HEIGHT + spacing),
					width = BRICK_WIDTH,
					height = BRICK_HEIGHT,
				},
				color = rl.BROWN,
				active = true,
			}
		}
	}

	return bricks
}

update_game :: proc(ball: ^Ball, bat: ^Bat, bricks: []Brick) {
	delta_time := rl.GetFrameTime()
	ball_speed: f32 = 200.0
	bat_speed: f32 = 300.0
	// move ball
	ball.rect.y += ball.velY * delta_time
	ball.rect.x += ball.velX * delta_time

	// colliding against walls
	if ball.rect.x <= 0 || ball.rect.x + ball.rect.width >= WINDOW_WIDTH {
		ball.velX = -ball.velX
	}
	if ball.rect.y <= 0 {
		ball.velY = -ball.velY
	}

	// bat collision
	if rl.CheckCollisionRecs(ball.rect, bat.rect) {
		ball.velY = -ball.velY
		ball.rect.y = bat.rect.y - ball.rect.height
		hit_pos := (ball.rect.x + ball.rect.width / 2 - bat.rect.x) / bat.rect.width
		ball.velX = 6.0 * (hit_pos - 0.5) * 2.0
	}

	// move bat
	if rl.IsKeyDown(.RIGHT) {
		if bat.rect.x + bat.rect.width <= WINDOW_WIDTH {
			bat.rect.x += bat_speed * delta_time
		}
	}
	if rl.IsKeyDown(.LEFT) {
		if bat.rect.x >= 0 {
			bat.rect.x -= bat_speed * delta_time
		}
	}

	// break bricks
	for &brick in bricks {
		if brick.active && rl.CheckCollisionRecs(ball.rect, brick.rect) {
			brick.active = false
			overlap_left := ball.rect.x + ball.rect.width - brick.rect.x
			overlap_right := brick.rect.x + brick.rect.width - ball.rect.x
			overlap_top := ball.rect.y + ball.rect.height - brick.rect.y
			overlap_bottom := brick.rect.y + brick.rect.height - ball.rect.y
			min_overlap := min(overlap_left, overlap_right, overlap_top, overlap_bottom)
			if min_overlap == overlap_left || min_overlap == overlap_right {
				ball.velX = -ball.velX
			} else {
				ball.velY = -ball.velY
			}
		}
	}
}

draw_game :: proc(ball: Ball, bat: Bat, bricks: []Brick) {
	rl.DrawRectangleRec(ball.rect, ball.color)
	rl.DrawRectangleRec(bat.rect, bat.color)
	for brick in bricks {
		if brick.active {
			rl.DrawRectangleRec(brick.rect, brick.color)
		}
	}
}

reset_game :: proc(ball: ^Ball, bat: ^Bat, bricks: []Brick) {
	ball.rect.x = WINDOW_WIDTH / 2 - 10 / 2
	ball.rect.y = WINDOW_HEIGHT - (WINDOW_HEIGHT * 30 / 100) + 10
	ball.velX = 200.0
	ball.velY = -200.0
	bat.rect.x = WINDOW_WIDTH / 2 - 100 / 2
	bat.rect.y = WINDOW_HEIGHT - (WINDOW_HEIGHT * 20 / 100)
	for &brick in bricks {
		if !brick.active {
			brick.active = true
		}
	}

}

main :: proc() {
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE)
	rl.SetWindowState({rl.ConfigFlag.WINDOW_RESIZABLE})
	rl.SetTargetFPS(WINDOW_FPS)

	state := GameState.Start

	bricks := init_bricks()
	defer delete(bricks)

	ball_rect := rl.Rectangle {
		x      = f32(rl.GetScreenWidth()) / 2 - 10 / 2,
		y      = f32(rl.GetScreenHeight()) - (f32(rl.GetScreenHeight()) * 30 / 100) + 10,
		width  = BALL_WIDTH,
		height = BALL_HEIGHT,
	}

	bat_rect := rl.Rectangle {
		x      = f32(rl.GetScreenWidth()) / 2 - 100 / 2,
		y      = f32(rl.GetScreenHeight()) - (f32(rl.GetScreenHeight()) * 20 / 100),
		width  = BAT_WIDTH,
		height = BAT_HEIGHT,
	}

	ball := Ball {
		rect  = ball_rect,
		color = rl.GREEN,
		velX  = 200.0,
		velY  = -200.0,
	}

	bat := Bat {
		rect  = bat_rect,
		color = rl.BLUE,
	}

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		screenWidth := rl.GetScreenWidth()
		screenHeight := rl.GetScreenHeight()

		switch state {
		case .Start:
			draw_game(ball, bat, bricks)
			msg: cstring = "Press SPACE to start"
			font_size: i32 = 20
			text_width := rl.MeasureText(msg, font_size)
			rl.DrawText(
				msg,
				screenWidth / 2 - text_width / 2,
				screenHeight / 2,
				font_size,
				rl.WHITE,
			)
			if rl.IsKeyPressed(.SPACE) {
				state = .Playing
			}

		case .Playing:
			if rl.IsKeyPressed(.P) {
				state = .Paused
			}

			update_game(&ball, &bat, bricks)
			draw_game(ball, bat, bricks)
			if ball.rect.y > f32(screenHeight) {
				state = .GameOver
			}


			all_bricks_destroyed := true
			for brick in bricks {
				if brick.active {
					all_bricks_destroyed = false
					break
				}
			}
			if all_bricks_destroyed {
				state = .Win
			}

		case .Paused:
			msg: cstring = "Paused - Press P to resume"
			font_size: i32 = 20
			text_width := rl.MeasureText(msg, font_size)
			draw_game(ball, bat, bricks)
			rl.DrawText(
				msg,
				screenWidth / 2 - text_width / 2,
				screenHeight / 2,
				font_size,
				rl.WHITE,
			)
			if rl.IsKeyPressed(.P) {
				state = .Playing
			}

		case .GameOver:
			msg: cstring = "Game Over - Press R to restart"
			font_size: i32 = 20
			text_width := rl.MeasureText(msg, font_size)
			draw_game(ball, bat, bricks)
			rl.DrawText(msg, screenWidth / 2 - text_width / 2, screenHeight / 2, font_size, rl.RED)
			if rl.IsKeyPressed(.R) {
				reset_game(&ball, &bat, bricks)
				state = .Start
			}

		case .Win:
			msg: cstring = "You won - Press R to play again"
			font_size: i32 = 20
			text_width := rl.MeasureText(msg, font_size)
			rl.DrawText(
				msg,
				screenWidth / 2 - text_width / 2,
				screenHeight / 2,
				font_size,
				rl.GREEN,
			)
			draw_game(ball, bat, bricks)
			if rl.IsKeyPressed(.R) {
				reset_game(&ball, &bat, bricks)
				state = .Start
			}
		}
		rl.EndDrawing()
	}
	rl.CloseWindow()
}
