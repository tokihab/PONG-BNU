STACK SEGMENT PARA 'STACK'

	DB 64 DUP (' ')
	
STACK ENDS

DATA SEGMENT PARA 'DATA'

	TIME_AUX DB 0      ;time check
	GAME_ACTIVE DB 1
	WINNER_INDEX DB 0
	CURRENT_SCENE DB 0
	EXITING_GAME DB 0
	
	TXT_PI_PTS DB '0','$'
	TXT_PII_PTS DB '0','$'
	GAME_OVER_TXT DB 'GAME OVER','$'
	WINNER_TXT DB 'Player 0 Won','$'
	TXT_REPLAY DB 'Press R to play again','$'
	TXT_MAIN_MENU DB 'Press E to exit to main menu','$'
	TXT_TITLE DB 'MAIN MENU','$'
	TXT_SINGLE DB 'SINGLEPLAYER - S KEY','$'
	TXT_MULTI DB 'MULTIPLAYER - M KEY','$'
	TXT_CLOSE DB 'EXIT - E KEY','$'
	
	WINDOW_W DW 140h   ;width
	WINDOW_H DW 0C8h   ;height
	WINDOW_BOUNDS DW 6 ;checks collisions
	
	BALL_SX DW 0A0h
	BALL_SY	DW 64h
	BALL_X DW 0A0h     ;x pos
	BALL_Y DW 64h      ;y pos
	BALL_SIZE DW 06h   ;size wxh
	BALL_VX DW 05h     ;hv of ball
	BALL_VY DW 02h     ;vv of ball
	
	LPADDLE_X DW 0Ah
	LPADDLE_Y DW 55h
	LPAD_PTS DB 0
	RPADDLE_X DW 130h
	RPADDLE_Y DW 55h
	RPAD_PTS DB 0
	AI DB 0
	PADDLE_H DW 25h
	PADDLE_W DW 06h
	PADDLE_VELOCITY DW 0Fh

DATA ENDS

CODE SEGMENT PARA 'CODE'

	MAIN PROC FAR
	ASSUME CS:CODE,DS:DATA,SS:STACK ;assime segments as registers
	PUSH DS 						;push DS to STACK
	SUB AX,AX 						;clean AX register
	PUSH AX 						;push AX to STACK
	MOV AX,DATA 					;save DATA segment on AX register
	MOV DS,AX   					;save AX on DS segment
	POP AX							;release top to AX register
	POP AX
	
		CALL CLEAR_SCRN
		
		CHECK_TIME:
		
			CMP EXITING_GAME,01h
			JE START_EXIT
			
			CMP CURRENT_SCENE,00h
			JE SHOW_MM
		
			CMP GAME_ACTIVE,00h
			JE SHOW_KO
		
			MOV AH,2Ch      ;sys time
			INT 21h
			
			CMP DL,TIME_AUX ;current time equal to previous time
			JE CHECK_TIME   ;check again, else ->
			MOV TIME_AUX,DL ;update time
			
			CALL CLEAR_SCRN
			CALL MOVE_BALL
			CALL DRAW_BALL
			CALL MOVE_PADDLES
			CALL DRAW_PADDLES
			CALL DRAW_UI
			JMP CHECK_TIME
			
			SHOW_KO:
				CALL KO_MENU
				JMP CHECK_TIME
				RET
		
			SHOW_MM:
				CALL MAIN_MENU_UI
				JMP CHECK_TIME
			RET
			
			START_EXIT:
				CALL EXIT_GAME
			
	MAIN ENDP
	
	MOVE_BALL PROC NEAR

		; Update Ball X Position
		MOV AX, BALL_VX       ; AX = BALL_VX
		ADD BALL_X, AX        ; BALL_X += BALL_VX
		
		; Check Collision with Left and Right Bounds
		;CMP BALL_X, 00h      ; BALL_X <= 0
		;JLE PTS_PII

		MOV AX, WINDOW_BOUNDS ; AX = WINDOW_W
		;SUB AX, BALL_SIZE    ; AX = WINDOW_W - BALL_SIZE
		CMP BALL_X, AX        ; BALL_X >= WINDOW_W - BALL_SIZE
		JL PTS_PII
		
		MOV AX,WINDOW_W
		SUB AX,BALL_SIZE
		SUB AX,WINDOW_BOUNDS
		CMP BALL_X,AX
		JG PTS_PI
		JMP MOVE_BV

		PTS_PI:
			
			INC LPAD_PTS
			CALL RESET_BALL   ; Reset Ball Position
			CALL INC_PI_PTS
			CMP LPAD_PTS, 05h
			JGE GAME_OVER
			
		RET
		
		PTS_PII:
			
			INC RPAD_PTS
			CALL RESET_BALL   ; Reset Ball Position
			CALL INC_PII_PTS
			CMP RPAD_PTS, 05h
			JGE GAME_OVER
			
		RET
		
		GAME_OVER:
		
			CMP LPAD_PTS,05h
			JNL PI_WINS
			JMP PII_WINS
			
			PI_WINS:
				MOV WINNER_INDEX, 01h
				JMP CONTINUE_KO
				
			PII_WINS:
				MOV WINNER_INDEX, 02h
				JMP CONTINUE_KO
				
			CONTINUE_KO:
				MOV LPAD_PTS, 00h
				MOV RPAD_PTS, 00h
				CALL INC_PI_PTS
				CALL INC_PII_PTS
				MOV GAME_ACTIVE,00h
				RET

		MOVE_BV:
		
			; Update Ball Y Position
			MOV AX, BALL_VY       ; AX = BALL_VY
			ADD BALL_Y, AX        ; BALL_Y += BALL_VY

			; Check Collision with Top and Bottom Bounds
			;CMP BALL_Y, 00h      ; BALL_Y <= 0
			MOV AX,WINDOW_BOUNDS
			CMP BALL_Y,AX
			JL REV_VY             ; Reverse Y velocity

			MOV AX, WINDOW_H      ; AX = WINDOW_H
			SUB AX, BALL_SIZE     ; AX = WINDOW_H - BALL_SIZE
			SUB AX, WINDOW_BOUNDS
			CMP BALL_Y, AX        ; BALL_Y >= WINDOW_H - BALL_SIZE
			JG REV_VY             ; Reverse Y velocity

			; Check Collision with Right Paddle
			MOV AX, BALL_X
			ADD AX, BALL_SIZE
			CMP AX, RPADDLE_X     ; BALL_X + BALL_SIZE <= RPADDLE_X
			JNG CHECK_CLP

			MOV AX, RPADDLE_X
			ADD AX, PADDLE_W
			CMP BALL_X, AX        ; BALL_X >= RPADDLE_X + PADDLE_W
			JNL CHECK_CLP

			MOV AX, BALL_Y
			ADD AX, BALL_SIZE
			CMP AX, RPADDLE_Y     ; BALL_Y + BALL_SIZE <= RPADDLE_Y
			JNG CHECK_CLP

			MOV AX, RPADDLE_Y
			ADD AX, PADDLE_H
			CMP BALL_Y, AX        ; BALL_Y >= RPADDLE_Y + PADDLE_H
			JNL CHECK_CLP

			JMP REV_VX            ; Reverse X velocity

		CHECK_CLP:
		
			; Check Collision with Left Paddle
			MOV AX, BALL_X
			ADD AX, BALL_SIZE
			CMP AX, LPADDLE_X     ; BALL_X + BALL_SIZE <= LPADDLE_X
			JNG EXIT_CC

			MOV AX, LPADDLE_X
			ADD AX, PADDLE_W
			CMP BALL_X, AX        ; BALL_X >= LPADDLE_X + PADDLE_W
			JNL EXIT_CC

			MOV AX, BALL_Y
			ADD AX, BALL_SIZE
			CMP AX, LPADDLE_Y     ; BALL_Y + BALL_SIZE <= LPADDLE_Y
			JNG EXIT_CC

			MOV AX, LPADDLE_Y
			ADD AX, PADDLE_H
			CMP BALL_Y, AX        ; BALL_Y >= LPADDLE_Y + PADDLE_H
			JNL EXIT_CC

		JMP REV_VX                ; Reverse X velocity

		REV_VY:
			NEG BALL_VY           ; Reverse (negate) ball's Y velocity
		RET

		REV_VX:
			NEG BALL_VX           ; Reverse (negate) ball's X velocity
		RET

		EXIT_CC:
			RET

	MOVE_BALL ENDP

	MOVE_PADDLES PROC NEAR
	
		MOV AH, 01h
		INT 16h
		JZ CHECK_RP
	
		MOV AH, 00h
		INT 16h
		
		CMP AL,77h
		JE MOVE_LPU
		CMP AL,57h
		JE MOVE_LPU
		
		CMP AL,73h
		JE MOVE_LPD
		CMP AL,53h
		JE MOVE_LPD
		JMP CHECK_RP
		
		MOVE_LPU:
		
			MOV AX,PADDLE_VELOCITY
			SUB LPADDLE_Y,AX
			
			MOV AX,WINDOW_BOUNDS
			CMP LPADDLE_Y,AX
			JL TLFIX_POS
			JMP CHECK_RP
			
			TLFIX_POS:
			
				MOV LPADDLE_Y,AX
				JMP CHECK_RP
		
		MOVE_LPD:
		
			MOV AX,PADDLE_VELOCITY
			ADD LPADDLE_Y,AX
			
			MOV AX,WINDOW_H
			SUB AX,WINDOW_BOUNDS
			SUB AX,PADDLE_H
			CMP LPADDLE_Y,AX
			JG BLFIX_POS
			JMP CHECK_RP
		
			BLFIX_POS:

				MOV LPADDLE_Y,AX
				JMP CHECK_RP
				
		CHECK_RP:
		
		CMP AI,01h
		JE AII
		
		CHECK_KEYS:
		
			CMP AL,6Fh
			JE MOVE_RPU
			CMP AL,4Fh
			JE MOVE_RPU
			
			CMP AL,6Ch
			JE MOVE_RPD
			CMP AL,4Ch
			JE MOVE_RPD
			JMP EXIT_PM
			
		AII:
		
			MOV AX,BALL_Y
			ADD AX,BALL_SIZE
			CMP AX,RPADDLE_Y
			JL MOVE_RPU
			
			MOV AX,RPADDLE_Y
			ADD AX,PADDLE_H
			CMP AX,BALL_Y
			JL MOVE_RPD
			
			JMP EXIT_PM
		
		MOVE_RPU:
		
			MOV AX,PADDLE_VELOCITY
			SUB RPADDLE_Y,AX
			
			MOV AX,WINDOW_BOUNDS
			CMP RPADDLE_Y,AX
			JL TRFIX_POS
			JMP EXIT_PM
			
			TRFIX_POS:
			
				MOV RPADDLE_Y,AX
				JMP EXIT_PM
		
		MOVE_RPD:
		
			MOV AX,PADDLE_VELOCITY
			ADD RPADDLE_Y,AX
			
			MOV AX,WINDOW_H
			SUB AX,WINDOW_BOUNDS
			SUB AX,PADDLE_H
			CMP RPADDLE_Y,AX
			JG BRFIX_POS
			JMP EXIT_PM
		
			BRFIX_POS:

				MOV RPADDLE_Y,AX
				JMP EXIT_PM
		
		EXIT_PM:
			RET
	
	MOVE_PADDLES ENDP
	
	RESET_BALL PROC NEAR
	
		MOV AX,BALL_SX
		MOV BALL_X,AX
		
		MOV AX,BALL_SY
		MOV BALL_Y,AX	

		NEG BALL_VX
		NEG BALL_VY
	
		RET
	
	RESET_BALL ENDP
	
	DRAW_BALL PROC NEAR
	
		MOV CX, BALL_X    ;set intial x
		MOV DX, BALL_Y    ;set intial y
		
		DRAW_BALL_H:
			MOV AH, 0Ch   ;set config to write pixel mode
			MOV AL, 0Fh   ;pixel white
			MOV BH, 00h   ;pg no
			INT 10h
			
			INC CX        ;CX++
			MOV AX,CX     ;CX-ballx>size, next line else, next column
			SUB AX,BALL_X
			CMP AX,BALL_SIZE
			JNG DRAW_BALL_H
			
			MOV CX,BALL_X ;CX goes back to intial column
			INC DX        ;next line
			
			MOV AX,DX     ;DX-bally>size, exit else, next line
			SUB AX,BALL_Y
			CMP AX,BALL_SIZE
			JNG DRAW_BALL_H
	
		RET
	
	DRAW_BALL ENDP
	
	DRAW_PADDLES PROC NEAR
	
		MOV CX, LPADDLE_X    ;set intial x
		MOV DX, LPADDLE_Y    ;set intial y
		
		DRAW_LPADDLE_H:
			
			MOV AH, 0Ch      ;set config to write pixel mode
			MOV AL, 0Fh      ;pixel white
			MOV BH, 00h      ; pg no
			INT 10h
			
			INC CX           ;CX++
			MOV AX,CX        ;CX-LPADDLEx>size, next line else, next column
			SUB AX,LPADDLE_X
			CMP AX,PADDLE_W
			JNG DRAW_LPADDLE_H
			
			MOV CX,LPADDLE_X ;CX goes back to intial column
			INC DX           ;next line
			
			MOV AX,DX        ;DX-LPADDLEy>size, exit else, next line
			SUB AX,LPADDLE_Y
			CMP AX,PADDLE_H
			JNG DRAW_LPADDLE_H
		
		MOV CX, RPADDLE_X ;set intial x
		MOV DX, RPADDLE_Y ;set intial y
		
		DRAW_RPADDLE_H:
			
			MOV AH, 0Ch      ;set config to write pixel mode
			MOV AL, 0Fh      ;pixel white
			MOV BH, 00h      ; pg no
			INT 10h
			
			INC CX           ;CX++
			MOV AX,CX        ;CX-RPADDLEx>size, next line else, next column
			SUB AX,RPADDLE_X
			CMP AX,PADDLE_W
			JNG DRAW_RPADDLE_H
			
			MOV CX,RPADDLE_X ;CX goes back to intial column
			INC DX           ;next line
			
			MOV AX,DX        ;DX-RPADDLEy>size, exit else, next line
			SUB AX,RPADDLE_Y
			CMP AX,PADDLE_H
			JNG DRAW_RPADDLE_H
			
		RET
	
		RET
	
	DRAW_PADDLES ENDP
	
	DRAW_UI PROC NEAR
	
		MOV AH,02h
		MOV BH,00h
		MOV DH,04h
		MOV DL,06h
		INT 10h
		
		MOV AH,09h
		LEA DX,TXT_PI_PTS
		INT 21h
		
		MOV AH,02h
		MOV BH,00h
		MOV DH,04h
		MOV DL,1Fh
		INT 10h
		
		MOV AH,09h
		LEA DX,TXT_PII_PTS
		INT 21h
	
		RET
	
	DRAW_UI ENDP
	
	INC_PI_PTS PROC NEAR
	
		XOR AX,AX
		MOV AL,LPAD_PTS
		
		ADD AL,30h
		MOV [TXT_PI_PTS],AL
	
		RET
	
	INC_PI_PTS ENDP
	
	INC_PII_PTS PROC NEAR
	
		XOR AX,AX
		MOV AL,RPAD_PTS
		
		ADD AL,30h
		MOV [TXT_PII_PTS],AL
	
		RET
	
	INC_PII_PTS ENDP
	
	KO_MENU PROC NEAR
	
		CALL CLEAR_SCRN
	
		MOV AH,02h
		MOV BH,00h
		MOV DH,04h
		MOV DL,04h
		INT 10h
		
		MOV AH,09h
		LEA DX,GAME_OVER_TXT
		INT 21h
		
		MOV AH,02h
		MOV BH,00h
		MOV DH,06h
		MOV DL,04h
		INT 10h
		
		CALL UPDATE_KO
		
		MOV AH,09h
		LEA DX,WINNER_TXT
		INT 21h
		
		MOV AH,02h
		MOV BH,00h
		MOV DH,08h
		MOV DL,04h
		INT 10h
		
		MOV AH,09h
		LEA DX,TXT_REPLAY
		INT 21h
		
		MOV AH,02h
		MOV BH,00h
		MOV DH,0Ah
		MOV DL,04h
		INT 10h
		
		MOV AH,09h
		LEA DX,TXT_MAIN_MENU
		INT 21h
		
		MOV AH,00h
		INT 16h
		
		CMP AL,'R'
		JE REPLAY
		CMP AL,'r'
		JE REPLAY
		CMP AL,'E'
		JE EXIT_MM
		CMP AL,'e'
		JE EXIT_MM
		RET
		
		REPLAY:
			MOV GAME_ACTIVE,01h
		RET
		
		EXIT_MM:
			MOV GAME_ACTIVE,00h
			MOV	CURRENT_SCENE,00h
		RET
	
	KO_MENU ENDP
	
	MAIN_MENU_UI PROC NEAR
	
		CALL CLEAR_SCRN
	
		MOV AH,02h
		MOV BH,00h
		MOV DH,04h
		MOV DL,04h
		INT 10h
		
		MOV AH,09h
		LEA DX,TXT_TITLE
		INT 21h
		
		MOV AH,02h
		MOV BH,00h
		MOV DH,06h
		MOV DL,04h
		INT 10h
		
		MOV AH,09h
		LEA DX,TXT_SINGLE
		INT 21h
		
		MOV AH,02h
		MOV BH,00h
		MOV DH,08h
		MOV DL,04h
		INT 10h
		
		MOV AH,09h
		LEA DX,TXT_MULTI
		INT 21h
		
		MOV AH,02h
		MOV BH,00h
		MOV DH,0Ah
		MOV DL,04h
		INT 10h
		
		MOV AH,09h
		LEA DX,TXT_CLOSE
		INT 21h
		
		MM_WAIT:
			MOV AH,00h
			INT 16h
			
			CMP AL,'S'
			JE START_SINGLE
			CMP AL,'s'
			JE START_SINGLE
			
			CMP AL,'M'
			JE START_MULTI
			CMP AL,'m'
			JE START_MULTI
			
			CMP AL,'E'
			JE CLOSE_GAME
			CMP AL,'e'
			JE CLOSE_GAME
			JMP MM_WAIT
			
		START_SINGLE:
			MOV CURRENT_SCENE,01h
			MOV GAME_ACTIVE,01h
			MOV AI,01h
		RET
			
		START_MULTI:
			MOV CURRENT_SCENE,01h
			MOV GAME_ACTIVE,01h
			MOV AI,00h
		RET
			
		CLOSE_GAME:
			MOV EXITING_GAME,01h
		RET
		
	RET
	
	MAIN_MENU_UI ENDP
	
	UPDATE_KO PROC NEAR
	
		MOV AL,WINNER_INDEX
		ADD AL,30h
		MOV [WINNER_TXT+7],AL
	
		RET
	
	UPDATE_KO ENDP
	
	CLEAR_SCRN PROC NEAR
	
		MOV AH, 00h ;set config to video mode
		MOV AL, 0Dh ;choose mode
		INT 10h
		
		MOV AH, 0Bh ;set config to bgs mode
		MOV BH, 00h ;to bg color
		MOV BL, 00h ;bg black
		INT 10h
	
		RET
		
	CLEAR_SCRN ENDP
	
	EXIT_GAME PROC NEAR
	
		MOV AH, 00h ;set config to video mode
		MOV AL, 02h ;choose mode
		INT 10h
		
		MOV AH,4CH
		INT 21h
	
		RET
	
	EXIT_GAME ENDP

CODE ENDS

END