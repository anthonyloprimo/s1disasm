; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to pause the game
; ---------------------------------------------------------------------------

PauseGame:
		nop					; useless nop (probably so an rts could easily be inserted here)
		tst.b	(v_lives).w			; do you have any lives left?
		beq.s	.unpauseGame			; if not, branch (prevents pausing during a game over)
		tst.w	(f_pause).w			; is game already paused?
		bne.s	.startPause			; if yes, branch
		btst	#bitStart,(v_jpadpress1).w	; has Start button been pressed?
		beq.s	.return				; if not, branch
		cmpi.b	#id_Special,(v_gamemode).w
		beq.w	CursedPauseMenu			; use the hack's menu in Special Stages

	; Pause_StopGame:
	.startPause:
		move.w	#1,(f_pause).w			; pause the game
		move.b	#1,(v_snddriver_ram.f_pausemusic).w ; pause music
; ---------------------------------------------------------------------------

; Pause_Loop:
.pauseLoop:
		move.b	#id_VBlank_Paused,(v_vblank_routine).w ; run routine $10 in VBlank
		bsr.w	WaitForVBlank			; wait until VBlank has finished

		tst.b	(f_slomocheat).w		; is slow-motion cheat on?
		beq.s	.checkUnpausing			; if not, branch
		btst	#bitA,(v_jpadpress1).w		; is button A pressed?
		beq.s	.checkSlowMotion		; if not, branch
		move.b	#id_Title,(v_gamemode).w	; return to title screen
		nop					; useless nop
		bra.s	.unpauseMusic			; unpause music
; ---------------------------------------------------------------------------

	; Pause_ChkBC:
	.checkSlowMotion:
		btst	#bitB,(v_jpadhold1).w		; is button B held down?
		bne.s	.slowMotion			; if yes, do continuous slow-motion
		btst	#bitC,(v_jpadpress1).w		; is button C pressed?
		bne.s	.slowMotion			; if yes, advance one frame

	; Pause_ChkStart:
	.checkUnpausing:
		btst	#bitStart,(v_jpadpress1).w	; is Start button pressed?
		beq.s	.pauseLoop			; if not, keep game paused
; ---------------------------------------------------------------------------

	; Pause_EndMusic:
	.unpauseMusic:
		move.b	#$80,(v_snddriver_ram.f_pausemusic).w ; unpause the music

	; Unpause:
	.unpauseGame:
		move.w	#0,(f_pause).w			; unpause the game

	; Pause_DoNothing:
	.return:
		rts					; return to main level loop
; ===========================================================================

; Pause_SlowMo:
.slowMotion:
		move.w	#1,(f_pause).w			; keep flag set so pause is triggered on next frame again
		move.b	#$80,(v_snddriver_ram.f_pausemusic).w ; unpause the music
		rts					; return to main level loop
; End of function PauseGame

; ===========================================================================
; Special Stage pause menu
; ===========================================================================
CursedPauseMenu:
		bra.w	CursedPauseMenuSprites
		move.w	#1,(f_pause).w
		move.b	#1,(v_snddriver_ram.f_pausemusic).w
		clr.b	(v_pause_selection).w		; CONTINUE is the default
		disable_ints
		lea	(vdp_control_port).l,a6
		move.w	#$8200+(vram_fg>>10),(a6)
		move.w	#$8400+(vram_bg>>13),(a6)
		bsr.w	ClearScreen
		locVRAM	ArtTile_Error_Handler_Font*tile_size
		lea	(Art_Text).l,a5
		move.w	#(Art_Text_end-Art_Text)/2-1,d1
.loadFont:
		move.w	(a5)+,(vdp_data_port).l
		dbf	d1,.loadFont
		locVRAM	(ArtTile_Error_Handler_Font+41)*tile_size
		lea	(CursedPauseStarArt).l,a5
		moveq	#8-1,d1
.loadStar:
		move.l	(a5)+,(vdp_data_port).l
		dbf	d1,.loadStar
		enable_ints
		clr.w	(v_palette_line_1).w
		move.w	#$EEE,(v_palette_line_1+$A).w
		move.w	#$EEE,(v_palette_line_1+$C).w
		move.w	#$EEE,(v_palette_line_1+$E).w
		bsr.w	CursedPauseDrawText
		bsr.w	CursedPauseDrawSelection
.loop:
		move.b	#id_VBlank_Paused,(v_vblank_routine).w
		bsr.w	WaitForVBlank
		move.b	(v_jpadpress1).w,d0		; newly pressed buttons, never held repeats
		btst	#bitUp,d0
		beq.s	.down
		subq.b	#1,(v_pause_selection).w
		bpl.s	.redraw
		move.b	#2,(v_pause_selection).w
		bra.s	.redraw
.down:
		btst	#bitDn,d0
		beq.s	.action
		addq.b	#1,(v_pause_selection).w
		cmpi.b	#3,(v_pause_selection).w
		blo.s	.redraw
		clr.b	(v_pause_selection).w
.redraw:
		bsr.w	CursedPauseDrawSelection
		bra.s	.loop
.action:
		andi.b	#btnStart|btnA,d0
		beq.s	.loop
		moveq	#0,d0
		move.b	(v_pause_selection).w,d0
		add.w	d0,d0
		move.w	.index(pc,d0.w),d0
		jmp	.index(pc,d0.w)
.index:
		dc.w	.continue-.index,.restartStage-.index,.restartGame-.index
.continue:
		disable_ints
		bsr.w	SS_BGLoad			; restore the background tilemaps covered by the menu
		enable_ints
		moveq	#palid_Special,d0
		bsr.w	PalLoad
		clr.w	(f_pause).w
		clr.w	(v_palss_time).w		; force PalCycle_SS to restore the plane registers now
		bsr.w	PalCycle_SS			; restore Special Stage plane registers
		move.b	#$80,(v_snddriver_ram.f_pausemusic).w
		rts
.restartStage:
		move.b	#1,(v_ss_retrying).w		; preserve music on manual retry
		subq.b	#1,(v_lastspecial).w
		bpl.s	.request
		move.b	#ss_emeralds_num-1,(v_lastspecial).w
.request:
		move.w	#1,(f_restart).w
		move.b	#$80,(v_snddriver_ram.f_pausemusic).w
		clr.w	(f_pause).w
		rts
.restartGame:
		moveq	#0,d0
		move.b	d0,(v_lastspecial).w
		move.b	d0,(v_emeralds).w
		move.l	d0,(v_emldlist).w
		move.l	d0,(v_emldlist+4).w
		move.l	d0,(v_time).w			; new run resets total gameplay time
		move.b	d0,(v_ss_misses).w
		move.b	d0,(v_ss_retrying).w
		move.w	#1,(f_restart).w
		move.b	#$80,(v_snddriver_ram.f_pausemusic).w
		clr.w	(f_pause).w
		rts

CursedPauseDrawText:
		lea	(vdp_data_port).l,a6
		move.w	#ArtTile_Error_Handler_Font|Tile_Pal1|Tile_Prio,d3
		lea	(CursedPauseText).l,a1
		moveq	#6-1,d1
		locVRAM	vram_fg+(7<<7)+(17<<1),d4
		move.l	d4,4(a6)
		bsr.s	.line
		lea	(CursedPauseContinue).l,a1
		moveq	#8-1,d1
		locVRAM	vram_fg+(11<<7)+(16<<1),d4
		move.l	d4,4(a6)
		bsr.s	.line
		lea	(CursedPauseRestartStage).l,a1
		moveq	#13-1,d1
		locVRAM	vram_fg+(13<<7)+(13<<1),d4
		move.l	d4,4(a6)
		bsr.s	.line
		lea	(CursedPauseRestartGame).l,a1
		moveq	#12-1,d1
		locVRAM	vram_fg+(15<<7)+(14<<1),d4
		move.l	d4,4(a6)
.line:
		moveq	#0,d0
		move.b	(a1)+,d0
		add.w	d3,d0
		move.w	d0,(a6)
		dbf	d1,.line
		rts

CursedPauseDrawSelection:
		lea	(vdp_data_port).l,a6
		moveq	#0,d0
		locVRAM	vram_fg+(11<<7)+(10<<1),d4
		moveq	#3-1,d1
.clearRows:
		move.l	d4,4(a6)
		move.w	d0,(a6)
		addi.l	#(19<<1)<<16,d4
		move.l	d4,4(a6)
		move.w	d0,(a6)
		subi.l	#(19<<1)<<16,d4
		addi.l	#$01000000,d4			; two tilemap rows
		dbf	d1,.clearRows
		moveq	#0,d0
		move.b	(v_pause_selection).w,d0
		mulu.w	#$100,d0
		locVRAM	vram_fg+(11<<7)+(10<<1),d4
		swap	d0
		add.l	d0,d4
		move.l	d4,4(a6)
		move.w	#ArtTile_Error_Handler_Font+41|Tile_Pal1|Tile_Prio,(a6)
		addi.l	#(19<<1)<<16,d4
		move.l	d4,4(a6)
		move.w	#ArtTile_Error_Handler_Font+41|Tile_Pal1|Tile_Prio,(a6)
		rts

	charset ' ', $FF
	charset '0','9',$00
	charset '$', $0A
	charset '-', $0B
	charset '=', $0C
	charset '>', $0D
	charset '.', $0E
	charset 'Y','Z',$0F
	charset 'A','X',$11
CursedPauseText:		dc.b "PAUSED"
CursedPauseContinue:		dc.b "CONTINUE"
CursedPauseRestartStage:	dc.b "RESTART STAGE"
CursedPauseRestartGame:	dc.b "RESTART GAME"
CursedPauseDivider:		dc.b "----------"
CursedPauseMissNote:		dc.b "COUNTS AS A MISS"
CursedPauseEmeraldCount:	dc.b "EMERALDS "
CursedPauseMissCount:		dc.b "MISSES "
CursedPauseVersion:		dc.b "V 0.7"
	charset
	even
CursedPauseStarArt:
		dc.l	$00070000,$00070000,$07070700,$00777000
		dc.l	$77777770,$00777000,$07070700,$00070000
CursedPauseDividerArt:
	rept 4
		dc.l	$00000000,$00000000,$00000000,$06666660
		dc.l	$00000000,$00000000,$00000000,$00000000
	endr

; ---------------------------------------------------------------------------
; Sprite-based pause screen. Background maps stay intact. Wall patterns are
; borrowed while stage sprites are hidden, then restored before Continue.
; ---------------------------------------------------------------------------
CursedPauseMenuSprites:
		move.w	#1,(f_pause).w
		move.b	#1,(v_snddriver_ram.f_pausemusic).w
		clr.b	(v_pause_selection).w
		clr.b	(v_pause_confirm).w
		bsr.w	SS_HideSpritesForArtSwap
		disable_ints
		locVRAM	ArtTile_SS_PauseFont*tile_size
		lea	(Art_Text).l,a5
		move.w	#(Art_Text_end-Art_Text)/2-1,d1
.loadPauseFont:
		move.w	(a5)+,(vdp_data_port).l
		dbf	d1,.loadPauseFont
		locVRAM	(ArtTile_SS_PauseFont+41)*tile_size
		lea	(CursedPauseDividerArt).l,a5
		move.w	#(4*tile_size)/2-1,d1
.loadDivider:
		move.w	(a5)+,(vdp_data_port).l
		dbf	d1,.loadDivider
		enable_ints
		bsr.w	SS_LoadConfirmationArt
		bsr.w	CursedPauseLoadNote
		bsr.w	CursedPauseDarkenPalette
		bsr.w	SS_LoadPauseTimerArt
		bsr.w	CursedPauseBuildSprites
.spriteLoop:
		bsr.w	CursedPauseBuildSprites
		move.b	#id_VBlank_Paused,(v_vblank_routine).w
		bsr.w	WaitForVBlank
		move.b	(v_jpadpress1).w,d0
		tst.b	(v_pause_confirm).w
		bne.w	.confirmInput
		btst	#bitUp,d0
		beq.s	.spriteDown
		subq.b	#1,(v_pause_selection).w
		bpl.s	.spriteRedraw
		move.b	#2,(v_pause_selection).w
		bra.s	.spriteRedraw
.spriteDown:
		btst	#bitDn,d0
		beq.s	.spriteAction
		addq.b	#1,(v_pause_selection).w
		cmpi.b	#3,(v_pause_selection).w
		blo.s	.spriteRedraw
		clr.b	(v_pause_selection).w
.spriteRedraw:
		bsr.w	CursedPauseBuildSprites
		bra.s	.spriteLoop
.spriteAction:
		andi.b	#btnStart|btnA,d0
		beq.s	.spriteLoop
		tst.b	(v_pause_selection).w
		beq.s	.spriteContinue
		cmpi.b	#1,(v_pause_selection).w
		beq.s	.spriteRestartStage
		bra.s	.spriteRestartGame
.spriteContinue:
		bsr.w	SS_RestorePauseWallArt
		bsr.w	SS_LoadTimerArt
		bsr.w	CursedPauseRestorePalette
		move.b	#$80,(v_snddriver_ram.f_pausemusic).w
		clr.w	(f_pause).w
		rts
.spriteRestartStage:
		cmpi.b	#99,(v_ss_misses).w		; a manual restart counts as a miss
		bhs.s	.noManualMiss
		addq.b	#1,(v_ss_misses).w
.noManualMiss:
		move.b	#1,(v_ss_retrying).w
		subq.b	#1,(v_lastspecial).w
		bpl.s	.spriteRequest
		move.b	#ss_emeralds_num-1,(v_lastspecial).w
.spriteRequest:
		bsr.w	CursedPauseRestorePalette
		move.w	#1,(f_restart).w
		move.b	#$80,(v_snddriver_ram.f_pausemusic).w
		clr.w	(f_pause).w
		rts
.spriteRestartGame:
		move.b	#1,(v_pause_confirm).w ; open confirmation with No selected
		bra.w	.spriteLoop
.confirmInput:
		btst	#bitB,d0
		bne.s	.cancelRestart
		move.b	d0,d1
		andi.b	#btnUp|btnDn|btnL|btnR,d1
		beq.s	.confirmAction
		eori.b	#3,(v_pause_confirm).w ; toggle No/Yes
		bra.w	.spriteLoop
.confirmAction:
		andi.b	#btnStart|btnA,d0
		beq.w	.spriteLoop
		cmpi.b	#2,(v_pause_confirm).w
		bne.s	.cancelRestart
		bsr.w	CursedPauseRestorePalette
		move.b	#$80,(v_snddriver_ram.f_pausemusic).w
		clr.w	(f_pause).w
		clr.b	(v_pause_confirm).w
		move.w	#1,(f_restart).w ; exit the SS loop immediately after PauseGame
		move.b	#id_Title,(v_gamemode).w
		rts
.cancelRestart:
		clr.b	(v_pause_confirm).w
		bra.w	.spriteLoop

CursedPauseBuildSprites:
		clearRAM v_spritetablebuffer,v_spritetablebuffer_end
		lea	(v_spritetablebuffer).w,a2
		moveq	#0,d5
		bsr.w	SS_DrawStoppedTimer
		move.w	#ArtTile_SS_PauseFont|Tile_Pal1|Tile_Prio,d6

		bsr.w	SS_DrawCollectedEmeralds
		move.w	#ArtTile_SS_PauseFont|Tile_Pal1|Tile_Prio,d6
		lea	(CursedPauseMissCount).l,a1
		moveq	#7-1,d1
		move.w	#128+16,d2
		move.w	#128+240,d3
		bsr.w	CursedPauseAddLine
		moveq	#0,d0
		move.b	(v_ss_misses).w,d0
		divu.w	#10,d0
		move.l	d0,d4
		move.w	d4,d0
		bsr.w	CursedPauseAddGlyph
		move.l	d4,d0
		swap	d0
		bsr.w	CursedPauseAddGlyph

		tst.b	(v_pause_confirm).w
		bne.w	SS_DrawConfirmation

		lea	(CursedPauseText).l,a1
		moveq	#6-1,d1
		move.w	#128+40,d2
		move.w	#128+136,d3
		bsr.w	CursedPauseAddLine
		; Ten hyphens as three wide sprites, saving seven sprite-table slots.
		move.w	#128+56,d2
		move.w	#128+120,d3
		moveq	#0,d4
.addDivider:
		move.w	d2,(a2)+
		move.b	#$C,(a2)+			; 4 tiles wide, 1 tile high
		cmpi.b	#2,d4
		bne.s	.dividerSizeReady
		move.b	#$4,-1(a2)			; final sprite is 2 tiles wide
.dividerSizeReady:
		addq.b	#1,d5
		move.b	d5,(a2)+
		move.w	#ArtTile_SS_PauseFont+41|Tile_Pal1|Tile_Prio,(a2)+
		move.w	d3,(a2)+
		addi.w	#32,d3
		addq.b	#1,d4
		cmpi.b	#3,d4
		blo.s	.addDivider
		lea	(CursedPauseContinue).l,a1
		moveq	#8-1,d1
		move.w	#128+88,d2
		move.w	#128+128,d3
		bsr.w	CursedPauseAddLine
		lea	(CursedPauseRestartStage).l,a1
		moveq	#13-1,d1
		move.w	#128+112,d2
		move.w	#128+108,d3
		bsr.w	CursedPauseAddLine
		move.w	#ArtTile_SS_PauseFont|Tile_Pal2|Tile_Prio,d6
		move.w	#128+120,d2			; immediately below RESTART STAGE
		move.w	#128+96,d3
		bsr.w	CursedPauseDrawNote
		move.w	#ArtTile_SS_PauseFont|Tile_Pal1|Tile_Prio,d6
		lea	(CursedPauseRestartGame).l,a1
		moveq	#12-1,d1
		move.w	#128+136,d2			; one blank 8px row after the gray note
		move.w	#128+112,d3
		bsr.w	CursedPauseAddLine

		lea	(CursedPauseVersion).l,a1
		moveq	#5-1,d1
		move.w	#128+216,d2			; bottom-right corner
		move.w	#128+280,d3
		bsr.w	CursedPauseAddLine

		moveq	#0,d0
		move.b	(v_pause_selection).w,d0
		add.w	d0,d0
		lea	(CursedPauseArrowY).l,a0
		move.w	(a0,d0.w),d2
		move.w	#128+88,d3			; one character inward from the previous position
		bsr.s	.addArrow
		move.w	#128+224,d3
.addArrow:
		move.w	d2,(a2)+
		move.b	#0,(a2)+
		addq.b	#1,d5
		move.b	d5,(a2)+
		move.w	#ArtTile_SS_PauseFont+$D|Tile_Pal1|Tile_Prio,d0 ; first arrow glyph
		cmpi.w	#128+224,d3
		bne.s	.arrowReady
		ori.w	#$800,d0			; horizontally flip the arrow on the right
.arrowReady:
		move.w	d0,(a2)+
		move.w	d3,(a2)+
		cmpi.w	#128+88,d3
		beq.s	.addArrowReturn
		clr.b	-5(a2)				; terminate sprite link after the right star
		rts
.addArrowReturn:
		rts

CursedPauseArrowY:
		dc.w	128+88,128+112,128+136

CursedPauseAddLine:
.character:
		moveq	#0,d0
		move.b	(a1)+,d0
		cmpi.b	#$FF,d0
		beq.s	.space
		move.w	d2,(a2)+
		move.b	#0,(a2)+
		addq.b	#1,d5
		move.b	d5,(a2)+
		add.w	d6,d0
		move.w	d0,(a2)+
		move.w	d3,(a2)+
.space:
		addq.w	#8,d3
		dbf	d1,.character
		rts

CursedPauseAddGlyph:
		move.w	d2,(a2)+
		move.b	#0,(a2)+
		addq.b	#1,d5
		move.b	d5,(a2)+
		add.w	d6,d0
		move.w	d0,(a2)+
		move.w	d3,(a2)+
		addq.w	#8,d3
		rts

CursedPauseDarkenPalette:
		lea	(v_palette).w,a0
		lea	(v_palette_fading).w,a1
		moveq	#64-1,d7
.darkenColor:
		move.w	(a0),d0
		move.w	d0,(a1)+			; preserve the exact live palette
		andi.w	#$CCC,d0
		lsr.w	#1,d0				; reduce every RGB channel to roughly half
		move.w	d0,(a0)+
		dbf	d7,.darkenColor
		move.w	#$EEE,(v_palette_line_1+$A).w ; keep all three font shades bright
		move.w	#$EEE,(v_palette_line_1+$C).w
		move.w	#$EEE,(v_palette_line_1+$E).w
		move.w	#$888,(v_palette_line_2+$A).w ; gray note below RESTART STAGE
		move.w	#$888,(v_palette_line_2+$C).w
		move.w	#$888,(v_palette_line_2+$E).w
		rts

CursedPauseRestorePalette:
		lea	(v_palette_fading).w,a0
		lea	(v_palette).w,a1
		moveq	#64-1,d7
.restoreColor:
		move.w	(a0)+,(a1)+
		dbf	d7,.restoreColor
		rts

; Same note and position, packed into four wide sprites instead of 12 letters.
CursedPauseLoadNote:
		disable_ints
		locVRAM	ArtTile_SS_PauseNote*tile_size
		lea	(CursedPauseMissNote).l,a1
		moveq	#16-1,d2 ; four groups of four characters
.character:
		moveq	#0,d0
		move.b	(a1)+,d0
		cmpi.b	#$FF,d0
		beq.s	.blank
		lsl.w	#5,d0
		lea	(Art_Text).l,a3
		adda.w	d0,a3
		moveq	#8-1,d1
.copy:
		move.l	(a3)+,(vdp_data_port).l
		dbf	d1,.copy
		bra.s	.next
.blank:
		moveq	#8-1,d1
.clear:
		move.l	#0,(vdp_data_port).l
		dbf	d1,.clear
.next:
		dbf	d2,.character
		enable_ints
		rts
CursedPauseDrawNote:
		move.w	#ArtTile_SS_PauseNote|Tile_Pal2|Tile_Prio,d0
		moveq	#4-1,d1
.piece:
		move.w	d2,(a2)+
		move.b	#$C,(a2)+
		addq.b	#1,d5
		move.b	d5,(a2)+
		move.w	d0,(a2)+
		move.w	d3,(a2)+
		addq.w	#4,d0
		addi.w	#32,d3
		dbf	d1,.piece
		rts
