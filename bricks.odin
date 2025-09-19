package main

import rl "vendor:raylib"

import "core:fmt"

window_width :: 800
window_height :: 450

GameState :: enum {
	Start,
	Playing,
	Paused,
	GameOver,
}

Ball :: struct {
	color:  rl.Color,
	posX:   i32,
	posY:   i32,
	width:  i32,
	height: i32,
	velX:   i32,
	velY:   i32,
}

Bat :: struct {
	color:  rl.Color,
	posX:   i32,
	posY:   i32,
	width:  i32,
	height: i32,
}

main :: proc() {
	rl.InitWindow(window_width, window_height, "Window the window")
	rl.SetTargetFPS(60)


	ball := Ball {
		color  = rl.GREEN,
		posX   = window_width / 2 - 10 / 2,
		posY   = window_height - (window_height * 30 / 100) + 10,
		width  = 10,
		height = 10,
		velX   = 4,
		velY   = 4,
	}

	bat := Bat {
		color  = rl.BLUE,
		posX   = window_width / 2 - 100 / 2,
		posY   = window_height - (window_height * 20 / 100),
		width  = 100,
		height = 12,
	}

	state := GameState.Start


	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)
		switch state {
		case .Start:
			rl.DrawRectangle(ball.posX, ball.posY, ball.width, ball.height, ball.color)
			rl.DrawRectangle(bat.posX, bat.posY, bat.width, bat.height, bat.color)
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
			rl.DrawRectangle(ball.posX, ball.posY, ball.width, ball.height, ball.color)
			rl.DrawRectangle(bat.posX, bat.posY, bat.width, bat.height, bat.color)
			ball.posY -= ball.velY
			ball.posX += ball.velX
			if ball.posX <= 0 || ball.posX + ball.width >= window_width {
				ball.velX = -ball.velX
			}
			if ball.posY <= 0 {
				ball.velY = -ball.velY
			}
			if ball.posX < bat.posX + bat.width &&
			   ball.posX + ball.width > bat.posX &&
			   ball.posY < bat.posY + bat.height &&
			   ball.posY + ball.height > bat.posY {
				ball.velY = -ball.velY
				ball.posY = bat.posY - ball.height
			}
			if rl.IsKeyDown(.RIGHT) {
				if bat.posX + bat.width <= window_width {
					bat.posX += 4
				}
			}
			if rl.IsKeyDown(.LEFT) {
				if bat.posX >= 0 {
					bat.posX -= 4
				}
			}
			if ball.posY > window_height {
				state = .GameOver
			}
		case .Paused:
			msg: cstring = "Paused - Press P to resume"
			font_size: i32 = 20
			text_width := rl.MeasureText(msg, font_size)
			rl.DrawRectangle(ball.posX, ball.posY, ball.width, ball.height, ball.color)
			rl.DrawRectangle(bat.posX, bat.posY, bat.width, bat.height, bat.color)
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
			rl.DrawText(
				msg,
				window_width / 2 - text_width / 2,
				window_height / 2,
				font_size,
				rl.RED,
			)

			ball.posX = window_width / 2 - 10 / 2
			ball.posY = window_height - (window_height * 30 / 100) + 10
			ball.velX = 4
			ball.velY = 4
			bat.posX = window_width / 2 - 100 / 2
			bat.posY = window_height - (window_height * 20 / 100)

			rl.DrawRectangle(ball.posX, ball.posY, ball.width, ball.height, ball.color)
			rl.DrawRectangle(bat.posX, bat.posY, bat.width, bat.height, bat.color)

			if rl.IsKeyPressed(.R) {
				state = .Playing
			}
		}
		rl.EndDrawing()
	}
	rl.CloseWindow()
}
