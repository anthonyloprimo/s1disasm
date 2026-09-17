; Collected emeralds use the original Special Stage art and collection order.
SS_DrawCollectedEmeralds:
		moveq	#0,d7
		move.b	(v_emeralds).w,d7
		beq.s	.done
		move.w	#128+8,d3
		move.w	#128+200,d2
		cmpi.w	#ss_emeralds_num,d7
		bne.s	.positioned
		tst.b	(v_player).w
		bne.s	.positioned
		move.w	#128+92,d3 ; center six 16px emeralds with 8px gaps
		move.w	#128+64,d2 ; above YOU'RE WINNER, which starts at y=96
.positioned:
		lea	(v_emldlist).w,a1
		lea	.Tiles(pc),a3
		subq.w	#1,d7
.emerald:
		moveq	#0,d0
		move.b	(a1)+,d0
		add.w	d0,d0
		move.w	d2,(a2)+
		move.b	#5,(a2)+ ; 16x16
		addq.b	#1,d5
		move.b	d5,(a2)+
		move.w	(a3,d0.w),(a2)+
		move.w	d3,(a2)+
		addi.w	#24,d3
		dbf	d7,.emerald
.done:
		rts
.Tiles:
		dc.w ArtTile_SS_Emerald+8|Tile_Pal1|Tile_Prio
		dc.w ArtTile_SS_Emerald+8|Tile_Pal2|Tile_Prio
		dc.w ArtTile_SS_Emerald+8|Tile_Pal3|Tile_Prio
		dc.w ArtTile_SS_Emerald+8|Tile_Pal4|Tile_Prio
		dc.w ArtTile_SS_Emerald|Tile_Pal1|Tile_Prio
		dc.w ArtTile_SS_Emerald+4|Tile_Pal1|Tile_Prio

; Keep the original emerald colors. Remap results text and timer pixels into
; unused palette entries instead of blackening colors used by the gems.
SS_LoadResultInterface:
		lea	(Pal_Special).l,a0
		lea	(v_palette).w,a1
		moveq	#32-1,d0
.palette:
		move.l	(a0)+,(a1)+
		dbf	d0,.palette
		move.w	#$EEE,(v_palette).w
		move.w	#$EEE,(v_palette_line_2).w
		move.w	#$EEE,(v_palette_line_3).w ; VDP $8720 selects CRAM $20 as backdrop
		clr.w	(v_palette_line_2+2).w ; results text is all black
		move.w	(Pal_Special+12).l,(v_palette_line_4+2).w ; timer shadow
		clr.w	(v_palette_line_4+20).w ; timer face (emeralds still use entry 6)
		move.w	(Pal_Special+18).l,(v_palette_line_4+14).w ; HUD light gray -> normal dark gray
		move.w	(Pal_Special+14).l,(v_palette_line_4+18).w ; HUD dark gray -> normal light gray
		disable_ints
		locVRAM	ArtTile_SS_Emerald*tile_size
		lea	(Nem_SSEmerald).l,a0
		bsr.w	NemDec
		locVRAM	ArtTile_Level_Select_Font*tile_size
		lea	(Art_Text).l,a1
		lea	.FontMap(pc),a3
		move.w	#(Art_Text_end-Art_Text)/2-1,d2
		bsr.s	.Remap
		lea	.TimerMap(pc),a3
		bsr.w	SS_LoadTimerMapped
		enable_ints
		rts
.Remap:
		move.w	(a1)+,d0
		moveq	#0,d3
		moveq	#4-1,d4
.pixel:
		rol.w	#4,d0
		move.w	d0,d1
		andi.w	#$F,d1
		lsl.w	#4,d3
		or.b	(a3,d1.w),d3
		dbf	d4,.pixel
		move.w	d3,(vdp_data_port).l
		dbf	d2,.Remap
		rts
.FontMap:
		dc.b 0,1,2,3,4,1,1,1,8,9,10,11,12,13,14,15
.TimerMap:
		dc.b 0,1,2,3,4,5,10,7,8,9,10,11,12,13,14,15

; Pause-only graphics share the temporarily hidden wall-art allocation.
SS_LoadConfirmationArt:
		disable_ints
		locVRAM	(ArtTile_SS_PauseFont+45)*tile_size
		lea	.QuestionArt(pc),a1
		moveq	#8-1,d0
.question:
		move.l	(a1)+,(vdp_data_port).l
		dbf	d0,.question
		locVRAM	ArtTile_SS_PausePanel*tile_size
		move.w	#16*tile_size/4-1,d0
.panel:
		move.l	#$11111111,(vdp_data_port).l
		dbf	d0,.panel
		enable_ints
		rts
.QuestionArt:
		dc.l $06666600,$66000660,$00006600,$00066000
		dc.l $00066000,$00000000,$00066000,$00000000

; Called after timer, emeralds and misses. Replaces the central pause choices
; with a modal; lower-priority solid sprites provide its background.
SS_DrawConfirmation:
		move.w	#ArtTile_SS_PauseFont|Tile_Pal1|Tile_Prio,d6
		lea	.Question(pc),a1
		moveq	#13-1,d1
		move.w	#128+80,d2
		move.w	#128+108,d3
		bsr.w	CursedPauseAddLine
		lea	.Yes(pc),a1
		moveq	#3-1,d1
		move.w	#128+120,d2
		move.w	#128+112,d3
		bsr.w	CursedPauseAddLine
		lea	.No(pc),a1
		moveq	#2-1,d1
		move.w	#128+184,d3
		bsr.w	CursedPauseAddLine
		move.w	#128+168,d3
		cmpi.b	#2,(v_pause_confirm).w
		bne.s	.arrow
		move.w	#128+96,d3
.arrow:
		moveq	#$D,d0
		bsr.w	CursedPauseAddGlyph
		lea	(CursedPauseVersion).l,a1
		moveq	#5-1,d1
		move.w	#128+216,d2
		move.w	#128+280,d3
		bsr.w	CursedPauseAddLine
		moveq	#3-1,d7
		move.w	#128+64,d2
.row:
		moveq	#6-1,d4
		move.w	#128+64,d3
.piece:
		move.w	d2,(a2)+
		move.b	#$F,(a2)+ ; 32x32 solid panel piece
		addq.b	#1,d5
		move.b	d5,(a2)+
		move.w	#ArtTile_SS_PausePanel|Tile_Prio,(a2)+
		move.w	d3,(a2)+
		addi.w	#32,d3
		dbf	d4,.piece
		addi.w	#32,d2
		dbf	d7,.row
		clr.l	(a2)
		rts
.Question:
		dc.b $11,$22,$15,$FF,$0F,$1F,$25,$FF,$23,$25,$22,$15,$2D
.Yes:
		dc.b $0F,$15,$23
.No:
		dc.b $1E,$1F
		even

; The pause screen has no wall sprites. Restore their original patterns before
; returning to the stage; restarts instead reload the destination game mode.
SS_RestorePauseWallArt:
		bsr.w	SS_HideSpritesForArtSwap
		disable_ints
		locVRAM	ArtTile_SS_Wall*tile_size
		lea	(Nem_SSWalls).l,a0
		bsr.w	NemDec
		enable_ints
		rts

; Remove sprites before replacing their patterns so neither entering nor leaving
; pause briefly displays old sprites with the newly uploaded graphics.
SS_HideSpritesForArtSwap:
		clearRAM v_spritetablebuffer,v_spritetablebuffer_end
		move.b	#id_VBlank_Paused,(v_vblank_routine).w
		bsr.w	WaitForVBlank
		rts
