package main

import rl "vendor:raylib"

import "core:fmt"

window_width :: 800
window_height :: 450


// brick
brick_width :: 100
brick_height :: 20
brick_rows :: 4
brick_cols :: 8

//ball
ball_width :: 10
ball_height :: 10


//bat
bat_width :: 100
bat_height :: 12

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
	bricks := make([]Brick, brick_rows * brick_cols)

	for row in 0 ..< brick_rows {
		for col in 0 ..< brick_cols {
			idx := row * brick_cols + col
			bricks[idx] = Brick {
				rect = rl.Rectangle {
					x = cast(f32)(col * (brick_width + 10)) + 10,
					y = cast(f32)(row * (brick_height + 10)) + 50,
					width = brick_width,
					height = brick_height,
				},
				color = rl.BROWN,
				active = true,
			}
		}
	}

	return bricks
}


update_game :: proc(ball: ^Ball, bat: ^Bat, bricks: []Brick) {
	// move ball
	ball.rect.y -= ball.velY
	ball.rect.x += ball.velX

	// colliding against walls
	if ball.rect.x <= 0 || ball.rect.x + ball.rect.width >= window_width {
		ball.velX = -ball.velX
	}
	if ball.rect.y <= 0 {
		ball.velY = -ball.velY
	}

	// bat collision
	if rl.CheckCollisionRecs(ball.rect, bat.rect) {
		ball.velY = -ball.velY
		ball.rect.y = bat.rect.y - ball.rect.height
	}

	// move bat
	if rl.IsKeyDown(.RIGHT) {
		if bat.rect.x + bat.rect.width <= window_width {
			bat.rect.x += 4
		}
	}
	if rl.IsKeyDown(.LEFT) {
		if bat.rect.x >= 0 {
			bat.rect.x -= 4
		}
	}

	// break bricks
	for &brick in bricks {
		if brick.active && rl.CheckCollisionRecs(ball.rect, brick.rect) {
			brick.active = false
			ball.velY = -ball.velY
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
	ball.rect.x = window_width / 2 - 10 / 2
	ball.rect.y = window_height - (window_height * 30 / 100) + 10
	ball.velX = 4
	ball.velY = 4
	bat.rect.x = window_width / 2 - 100 / 2
	bat.rect.y = window_height - (window_height * 20 / 100)
	for &brick in bricks {
		if !brick.active {
			brick.active = true
		}
	}

}

main :: proc() {
	rl.InitWindow(window_width, window_height, "Window the window")
	rl.SetTargetFPS(60)

	state := GameState.Start

	bricks := init_bricks()
	defer delete(bricks)

	ball_rect := rl.Rectangle {
		x      = window_width / 2 - 10 / 2,
		y      = window_height - (window_height * 30 / 100) + 10,
		width  = ball_width,
		height = ball_height,
	}

	bat_rect := rl.Rectangle {
		x      = window_width / 2 - 100 / 2,
		y      = window_height - (window_height * 20 / 100),
		width  = bat_width,
		height = bat_height,
	}

	ball := Ball {
		rect  = ball_rect,
		color = rl.GREEN,
		velX  = 4,
		velY  = 4,
	}

	bat := Bat {
		rect  = bat_rect,
		color = rl.BLUE,
	}

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		switch state {
		case .Start:
			draw_game(ball, bat, bricks)
			msg: cstring = "Press SPACE to start"
			font_size: i32 = 20
			text_width := rl.MeasureText(msg, font_size)
			rl.DrawText(
				msg,
				window_width / 2 - text_width / 2,
				window_height / 2,
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
			if ball.rect.y > window_height {
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
				window_width / 2 - text_width / 2,
				window_height / 2,
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
			rl.DrawText(
				msg,
				window_width / 2 - text_width / 2,
				window_height / 2,
				font_size,
				rl.RED,
			)
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
				window_width / 2 - text_width / 2,
				window_height / 2,
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
