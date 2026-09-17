; Cumulative active-play clock. v_time is MM MM SS FF here (word minutes),
; retained across attempts, reset only on a new run. No normal HUD time-over.
	if ArtTile_SS_TimerHigh*tile_size<vram_hscroll+(v_hscrolltablebuffer_end-v_hscrolltablebuffer)
		fatal "Special Stage timer overlaps actual scroll DMA length"
	endif

SS_TickRunTime:
		tst.w	(f_demo).w
		bne.s	.return
		tst.w	(f_pause).w
		bne.s	.return
		cmpi.b	#2,(v_player+obRoutine).w
		bhi.s	.return
		move.b	(v_emeralds).w,d0
		cmp.b	(v_ss_emeralds_before).w,d0
		bne.s	.return ; stop immediately on pickup, before the sparkle/spin delay
		moveq	#60,d0
		btst	#6,(v_megadrive).w
		beq.s	.ntsc
		moveq	#50,d0
.ntsc:
		addq.b	#1,(v_timecent).w
		cmp.b	(v_timecent).w,d0
		bhi.s	.return
		clr.b	(v_timecent).w
		move.b	#1,(f_timecount).w ; refresh visible glyphs at next VBlank
		addq.b	#1,(v_timesec).w
		cmpi.b	#60,(v_timesec).w
		blo.s	.return
		clr.b	(v_timesec).w
		addq.w	#1,(v_time).w
.return:
		rts

SS_LoadTimerArt:
		disable_ints
		lea	SS_TimerIdentity(pc),a3
		bsr.w	SS_LoadTimerMapped
		clr.b	(f_timecount).w
		enable_ints
		rts

; VBlank-only refresh; paused and result screens use their own color remaps.
SS_UpdateTimerArt:
		tst.b	(f_timecount).w
		beq.s	.done
		tst.w	(f_pause).w
		bne.s	.done
		clr.b	(f_timecount).w
		lea	SS_TimerIdentity(pc),a3
		bra.w	SS_LoadTimerMapped
.done:
		rts
SS_TimerIdentity:
		dc.b 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15

; a3 = pixel remapping table. Interrupts must be disabled (or called in VBlank).
; Upload at most eight visible 8x16 glyphs: up to five minutes digits, colon,
; and two seconds digits. Slots 0-5 follow SAT; slots 6-7 follow scroll DMA.
SS_LoadTimerMapped:
		locVRAM	ArtTile_SS_TimerLow*tile_size
		bsr.w	SS_TimerMinutes
		moveq	#0,d5
.minutes:
		move.w	d4,d0
		andi.w	#$F,d0
		bsr.s	.Digit
		lsr.l	#4,d4
		subq.w	#1,d6
		bne.s	.minutes
		moveq	#10,d0
		bsr.s	.Digit
		moveq	#0,d4
		move.b	(v_timesec).w,d4
		divu.w	#10,d4
		move.w	d4,d0
		bsr.s	.Digit
		swap	d4
		move.w	d4,d0
.Digit:
		lsl.w	#6,d0
		lea	(Art_Hud).l,a1
		adda.w	d0,a1
		cmpi.w	#6,d5
		bne.s	.addressReady
		locVRAM	ArtTile_SS_TimerHigh*tile_size
.addressReady:
		addq.w	#1,d5
		moveq	#32-1,d2
.word:
		move.w	(a1)+,d0
		moveq	#0,d3
		moveq	#4-1,d7
.pixel:
		rol.w	#4,d0
		move.w	d0,d1
		andi.w	#$F,d1
		lsl.w	#4,d3
		or.b	(a3,d1.w),d3
		dbf	d7,.pixel
		move.w	d3,(vdp_data_port).l
		dbf	d2,.word
		rts

; Returns decimal minutes as a packed sequence of nibbles in d4, count in d6.
; At least two digits; expands beyond 99 minutes instead of wrapping the clock.
SS_TimerMinutes:
		moveq	#0,d0
		move.w	(v_time).w,d0
		moveq	#0,d4
		moveq	#0,d6
.divide:
		divu.w	#10,d0
		move.l	d0,d1
		swap	d1
		lsl.l	#4,d4
		or.b	d1,d4
		addq.w	#1,d6
		andi.l	#$FFFF,d0
		bne.s	.divide
		cmpi.w	#2,d6
		bhs.s	.done
		lsl.l	#4,d4
		addq.w	#1,d6
.done:
		rts

; Called at the start of BuildSprites: HUD gets priority over the stage blocks.
; Leaves a2 and d5 positioned for the regular sprite builder.
SS_DrawTimerSprites:
		bsr.w	SS_TimerMinutes
		move.w	#128+16,d3
.minutes:
		move.w	d4,d0
		andi.w	#$F,d0
		bsr.s	.Glyph
		lsr.l	#4,d4
		subq.w	#1,d6
		bne.s	.minutes
		moveq	#10,d0
		bsr.s	.Glyph
		moveq	#0,d4
		move.b	(v_timesec).w,d4
		divu.w	#10,d4
		move.w	d4,d0
		bsr.s	.Glyph
		swap	d4
		move.w	d4,d0
.Glyph:
		move.w	#128+16,(a2)+
		move.b	#1,(a2)+ ; 8x16 sprite
		addq.b	#1,d5
		move.b	d5,(a2)+
		move.w	d5,d0 ; fixed slot, already incremented above
		subq.w	#1,d0
		add.w	d0,d0
		cmpi.w	#12,d0
		blo.s	.lowTiles
		addi.w	#ArtTile_SS_TimerHigh-12|Tile_Prio,d0
		bra.s	.tileReady
.lowTiles:
		addi.w	#ArtTile_SS_TimerLow|Tile_Prio,d0
.tileReady:
		tst.b	(v_player).w ; results clear object RAM; use black-on-white palette
		bne.s	.gamePalette
		ori.w	#Tile_Pal4,d0
		bra.s	.normalPalette
.gamePalette:
		tst.w	(f_pause).w
		beq.s	.normalPalette
		ori.w	#Tile_Pal2,d0
.normalPalette:
		move.w	d0,(a2)+
		move.w	d3,(a2)+
		addq.w	#8,d3
		rts

SS_DrawTotalTime:
		disable_ints
		locVRAM	vram_bg+(15<<7)+(10<<1)
		lea	.Label(pc),a1
		moveq	#12-1,d1
		bsr.s	.Text
		bsr.w	SS_TimerMinutes
.minutes:
		move.w	d4,d0
		andi.w	#$F,d0
		add.w	d3,d0
		move.w	d0,(a6)
		lsr.l	#4,d4
		subq.w	#1,d6
		bne.s	.minutes
		lea	.Min(pc),a1
		moveq	#2-1,d1
		bsr.s	.Text
		moveq	#0,d4
		move.b	(v_timesec).w,d4
		divu.w	#10,d4
		move.w	d4,d0
		add.w	d3,d0
		move.w	d0,(a6)
		swap	d4
		add.w	d3,d4
		move.w	d4,(a6)
		lea	.Sec(pc),a1
		moveq	#1-1,d1
		bsr.s	.Text
		enable_ints
		rts
.Text:
		moveq	#0,d0
		move.b	(a1)+,d0
		cmpi.b	#$FF,d0
		beq.s	.blank
		add.w	d3,d0
		bra.s	.write
.blank:
		moveq	#0,d0
.write:
		move.w	d0,(a6)
		dbf	d1,.Text
		rts
.Label:
		dc.b $24,$1F,$24,$11,$1C,$FF,$24,$19,$1D,$15,$0C,$FF ; TOTAL TIME:
.Min:
		dc.b $0A,$FF ; user's apostrophe, then space
.Sec:
		dc.b $0B ; user's double quote
		even

; Results have no gameplay objects; rebuild just the persistent timer sprites.
SS_ResultTimer:
		lea	(v_spritetablebuffer).w,a2
		moveq	#0,d5
		bsr.w	SS_DrawStoppedTimer
		bsr.w	SS_DrawCollectedEmeralds
		cmpi.b	#ss_emeralds_num,(v_emeralds).w
		bne.s	.finish
		btst	#5,(v_vblank_byte).w
		bne.s	.finish
		lea	(SS_CursedRestart).l,a1
		moveq	#SS_CursedRestart_End-SS_CursedRestart-1,d1
		move.w	#128+18*8,d2 ; two blank rows after TOTAL TIME (row 15)
		move.w	#128+(320-(SS_CursedRestart_End-SS_CursedRestart)*8)/2,d3
		move.w	#ArtTile_Level_Select_Font|Tile_Pal2|Tile_Prio,d6
		jsr	(CursedPauseAddLine).l ; append 8x8 font sprites; spaces stay transparent
.finish:
		clr.l	(a2)
		rts

; Stopped clocks toggle every 32 VBlanks: four times the ring warning's 8.
SS_DrawStoppedTimer:
		btst	#5,(v_vblank_byte).w
		bne.s	.hidden
		bra.w	SS_DrawTimerSprites
.hidden:
		rts

; Preserve the timer's live colors while the pause menu darkens the background.
; The note uses palette 2 entries 5-7; these separate entries do not affect it.
SS_LoadPauseTimerArt:
		move.w	(v_palette_fading+2).w,(v_palette_line_2+2).w
		move.w	(v_palette_fading+12).w,(v_palette_line_2+20).w
		move.w	(v_palette_fading+14).w,(v_palette_line_2+22).w
		move.w	(v_palette_fading+18).w,(v_palette_line_2+24).w
		disable_ints
		lea	.Remap(pc),a3
		bsr.w	SS_LoadTimerMapped
		enable_ints
		rts
.Remap:
		dc.b 0,1,2,3,4,5,10,11,8,12,10,11,12,13,14,15
		even
