; State occupies unused bytes of the title Sonic object, cleared on title entry.
title_phase: equ v_titlesonic+objoff_30 ; 0 emerge, 1 lift, 2 words, 3 ready
title_orbit_angle: equ v_titlesonic+objoff_38 ; 16-bit phase, cleared on title entry
title_ring_angle: equ v_titlesonic+objoff_3A ; rotation of the projected ring
title_tick: equ v_titlesonic+objoff_31
title_lift: equ v_titlesonic+objoff_32
title_word_offset: equ v_titlesonic+objoff_34
title_stages_y: equ v_titlesonic+objoff_36

TitlePresentation_Update:
		cmpi.b #3,(title_phase).w
		beq.w TitleOrbit_Advance
		btst #bitStart,(v_jpadpress1).w
		bne.w .skip
		tst.b (title_phase).w
		bne.s .moving
		cmpi.b #6,(v_titlesonic+obRoutine).w
		bne.w .return
		cmpi.b #6,(v_titlesonic+obFrame).w
		blo.w .return
		move.b #1,(title_phase).w
		move.b #4,(v_ttlsonichide+obFrame).w ; shorten torso mask before adding subtitle
.moving:
		moveq #0,d0
		move.b (title_tick).w,d0
		cmpi.b #2,(title_phase).w
		beq.s .words
		lea TitleLiftCurve(pc),a1
		moveq #0,d1
		move.b (a1,d0.w),d1
		move.w d1,(title_lift).w
		bsr.w TitlePresentation_Position
		addq.b #1,(title_tick).w
		cmpi.b #TitleLiftCurve_End-TitleLiftCurve,(title_tick).w
		blo.w .return
		move.b #2,(title_phase).w
		clr.b (title_tick).w
		move.w #160,(title_word_offset).w
		move.w #224,(title_stages_y).w
		rts
.words:
		add.w d0,d0
		lea TitleWordCurve(pc),a1
		move.w (a1,d0.w),(title_word_offset).w
		lea TitleStagesCurve(pc),a1
		move.w (a1,d0.w),(title_stages_y).w
		addq.b #1,(title_tick).w
		cmpi.b #(TitleWordCurve_End-TitleWordCurve)/2,(title_tick).w
		blo.w .return
		bra.s .ready
.skip:
		bclr #bitStart,(v_jpadpress1).w ; skip consumes this press; release/repress to play
		move.b #6,(v_titlesonic+obRoutine).w
		move.b #6,(v_titlesonic+obFrame).w
		move.b #7,(v_titlesonic+obAniFrame).w
		move.b #7,(v_titlesonic+obTimeFrame).w
		move.b #4,(v_ttlsonichide+obFrame).w
		move.w #32,(title_lift).w
		bsr.w TitlePresentation_Position
.ready:
		move.l #Map_TitleSonicTrim,(v_titlesonic+obMap).w
		clr.b (v_ttlsonichide+obFrame).w ; trimmed art replaces scanline mask
		move.b #3,(title_phase).w
		clr.w (title_word_offset).w
		move.w #164,(title_stages_y).w
		move.b #1,(v_pressstart+obFrame).w
		clr.b (v_pressstart+obAniFrame).w
		move.b #31,(v_pressstart+obTimeFrame).w
.return:
		rts

TitlePresentation_Position:
		move.w (title_lift).w,d1
		move.w d1,(v_scrposy_vdp).w
		move.w #128+$1E,d0
		sub.w d1,d0
		move.w d0,(v_titlesonic+obScreenY).w
		move.w #128+$80,d0
		sub.w d1,d0
		move.w d0,(v_titletm+obScreenY).w
		move.w #128+$B8,d0
		sub.w d1,d0
		move.w d0,(v_ttlsonichide+obScreenY).w
		rts

; Append after BuildSprites; offscreen glyphs must not produce X=0 sprite masking.
TitlePresentation_Draw:
		cmpi.b #2,(title_phase).w
		blo.w .return
		moveq #0,d5
		move.b (v_spritecount).w,d5
		move.w d5,d0
		lsl.w #3,d0
		lea (v_spritetablebuffer).w,a2
		adda.w d0,a2
		move.w #ArtTile_Level_Select_Font|Tile_Pal1|Tile_Prio,d6
		lea TitleWordCursed(pc),a1
		moveq #6-1,d1
		move.w #128+152,d2
		move.w #128+104,d3
		sub.w (title_word_offset).w,d3
		bsr.s .line
		lea TitleWordSpecial(pc),a1
		moveq #7-1,d1
		move.w #128+160,d3
		add.w (title_word_offset).w,d3
		bsr.s .line
		lea TitleWordStages(pc),a1
		moveq #6-1,d1
		move.w #128+136,d3
		move.w (title_stages_y).w,d2
		addi.w #128,d2
		bsr.s .line
		move.b d5,(v_spritecount).w
		clr.l (a2)
.return:
		rts
.line:
		moveq #0,d0
		move.b (a1)+,d0
		cmpi.w #120,d3
		ble.s .next
		cmpi.w #448,d3
		bge.s .next
		cmpi.w #352,d2
		bge.s .next
		cmpi.b #sprites_max,d5
		bhs.s .next
		move.w d2,(a2)+
		clr.b (a2)+
		addq.b #1,d5
		move.b d5,(a2)+
		add.w d6,d0
		move.w d0,(a2)+
		move.w d3,(a2)+
.next:
		addq.w #8,d3
		dbf d1,.line
		rts

TitleWordCursed: dc.b $13,$25,$22,$23,$15,$14
TitleWordSpecial: dc.b $23,$20,$15,$13,$19,$11,$1C
TitleWordStages: dc.b $23,$24,$11,$17,$15,$23
	even

TitleLiftCurve:
		dc.b	0,0,1,2,4,5,8,10,12,15,17,20,22,24,27,28,30,31,32,32
TitleLiftCurve_End:
	even

TitleWordCurve:
		dc.w	160,160,158,156,153,149,144,139,134,127,121,114,107,99,92,84,76,68,61,53,46,39,33,26,21,16,11,7,4,2,0,0
TitleWordCurve_End:
	even

TitleStagesCurve:
		dc.w	224,224,223,222,221,220,218,216,214,212,209,207,204,201,198,195,193,190,187,184,181,179,176,174,172,170,168,167,166,165,164,164
TitleStagesCurve_End:
	even

; Dedicated title-only art and two palette lines, leaving Sonic/logo/text intact.
ArtTile_TitleOrbit: equ $540
TitleOrbit_Load:
		locVRAM ArtTile_TitleOrbit*tile_size
		lea TitleOrbit_Art(pc),a1
		move.w #32*tile_size/4-1,d0
.art:
		move.l (a1)+,(vdp_data_port).l
		dbf d0,.art
		lea TitleOrbit_Palette(pc),a1
		lea (v_palette_fading_line_3+2).w,a2
		moveq #15-1,d0
.pal3:
		move.w (a1)+,(a2)+
		dbf d0,.pal3
		addq.w #2,a2 ; preserve each line's transparent/backdrop entry
		moveq #15-1,d0
.pal4:
		move.w (a1)+,(a2)+
		dbf d0,.pal4
		rts
TitleOrbit_SetLogoPriority:
		lea (v_ram_start).l,a1
		move.w #34*21-1,d0
.loop:
		ori.w #Tile_Prio,(a1)+
		dbf d0,.loop
		rts

TitleOrbit_Advance:
		move.w #264,d0
		moveq #48,d1
		btst #6,(v_megadrive).w
		beq.s .ntsc
		move.w #317,d0
		moveq #57,d1
.ntsc:
		add.w d0,(title_orbit_angle).w
		add.w d1,(title_ring_angle).w
		rts

; High-priority front gems precede Sonic and the torso mask. Low-priority
; rear gems follow Sonic and sit behind the high-priority emblem plane.
; Depth comes from the unrotated ring phase, not its screen-space Y.
; Rotating around the viewing axis preserves that depth ordering.
TitleOrbit_DrawRear:
		moveq #0,d6
		bra.s TitleOrbit_DrawPass

; Prefix the title sprites so Sonic's torso mask cannot hide the front gems.
; BuildSprites supplies a2 (write cursor) and d5 (sprite count).
TitleOrbit_Draw:
		move.w #Tile_Prio,d6
TitleOrbit_DrawPass:
		cmpi.b #id_Title,(v_gamemode).w
		bne.w .return
		cmpi.b #3,(title_phase).w
		bne.w .return
		lea TitleOrbit_Phases(pc),a3
		moveq #0,d7
.loop:
		move.w (title_orbit_angle).w,d0
		add.w (a3)+,d0
		lsr.w #8,d0
		jsr (CalcSine).l
		tst.w d0
		bmi.s .rear
		tst.w d6
		beq.w .next
		bra.s .draw
.rear:
		tst.w d6
		bne.w .next
.draw:
		cmpi.b #sprites_max,d5
		bhs.w .return
		; Project the ring: minor radius is 44*cos(ring angle).
		; Horizontal retains its tilt; vertical is edge-on. Signed cosine
		; carries the tilt smoothly through edge-on without reversing depth.
		muls.w #144,d1
		asr.l #8,d1
		move.w d1,d2 ; local X
		muls.w #44,d0
		asr.l #8,d0
		move.w d0,d3 ; local Y
		move.w (title_ring_angle).w,d0
		lsr.w #8,d0
		jsr (CalcSine).l
		muls.w d1,d3 ; foreshorten local Y as the ring turns upright
		asr.l #8,d3
		move.w d2,d4
		muls.w d1,d4 ; X*cos
		move.l d4,-(sp)
		move.w d3,d4
		muls.w d0,d4 ; Y*sin
		sub.l d4,(sp)
		muls.w d0,d2 ; X*sin
		muls.w d1,d3 ; Y*cos
		add.l d3,d2
		asr.l #8,d2
		move.l (sp)+,d1
		asr.l #8,d1
		addi.w #128+160-8,d1
		move.w d2,d0
		addi.w #128+60-8,d0
		move.w d0,(a2)+
		move.b #5,(a2)+
		addq.b #1,d5
		move.b d5,(a2)+
		move.w d7,d0
		lsl.w #2,d0
		addi.w #ArtTile_TitleOrbit|Tile_Pal3,d0
		or.w d6,d0
		cmpi.w #3,d7
		blo.s .tile
		addi.w #$2000,d0
.tile:
		move.w d0,(a2)+
		move.w d1,(a2)+
.next:
		addq.w #1,d7
		cmpi.w #6,d7
		blo.w .loop
.return:
		rts
TitleOrbit_Phases: dc.w $0000,$2AAA,$5555,$8000,$AAAA,$D555
TitleOrbit_Art: binclude "artunc/Title Orbit Emeralds.bin"
	binclude "artunc/Title Sonic Trim.bin"
	even
TitleOrbit_Palette: binclude "palette/Title Orbit Emeralds.bin"
	even


; Final Sonic frames clipped at local Y=82 (screen Y=80).
Map_TitleSonicTrim: mappingsTable
	mappingsTableEntry.w .trim1
	mappingsTableEntry.w .trim1
	mappingsTableEntry.w .trim1
	mappingsTableEntry.w .trim1
	mappingsTableEntry.w .trim1
	mappingsTableEntry.w .trim1
	mappingsTableEntry.w .trim1
	mappingsTableEntry.w .trim2
.trim1: spriteHeader
	spritePiece	$38, $28, 4, 3, $1E4, 0, 0, 0, 0
	spritePiece	$48, $18, 2, 2, $1F0, 0, 0, 0, 0
	spritePiece	$38, $40, 3, 1, $1F4, 0, 0, 0, 0
	spritePiece	$38, $48, 2, 1, $1F7, 0, 0, 0, 0
	spritePiece	8, $18, 4, 4, $1D0, 0, 0, 0, 0
	spritePiece	$28, $18, 1, 4, $1E0, 0, 0, 0, 0
	spritePiece	$10, $10, 4, 4, $14A, 0, 0, 0, 0
	spritePiece	$20, 8, 2, 1, $15A, 0, 0, 0, 0
	spritePiece	$30, 0, 3, 4, $15C, 0, 0, 0, 0
	spritePiece	$48, 8, 1, 1, $168, 0, 0, 0, 0
	spritePiece	$48, $18, 1, 1, $169, 0, 0, 0, 0
	spritePiece	0, $18, 2, 2, $16A, 0, 0, 0, 0
	spritePiece	8, $28, 1, 3, $16E, 0, 0, 0, 0
	spritePiece	$10, $30, 4, 4, $171, 0, 0, 0, 0
	spritePiece	$30, $20, 4, 2, $181, 0, 0, 0, 0
	spritePiece	$50, $20, 1, 2, $189, 0, 0, 0, 0
	spritePiece	$30, $30, 3, 1, $18B, 0, 0, 0, 0
	spritePiece	$30, $38, 4, 3, $18E, 0, 0, 0, 0
	spritePiece	8, $50, 4, 1, $258, 0, 0, 0, 0
	spritePiece	$28, $50, 4, 1, $25C, 0, 0, 0, 0
.trim1_End
.trim2: spriteHeader
	spritePiece	$38, $18, 2, 1, $1F9, 0, 0, 0, 0
	spritePiece	$38, $20, 1, 1, $1FB, 0, 0, 0, 0
	spritePiece	$30, $28, 3, 1, $1FC, 0, 0, 0, 0
	spritePiece	$30, $30, 1, 2, $1FF, 0, 0, 0, 0
	spritePiece	$38, $30, 3, 4, $201, 0, 0, 0, 0
	spritePiece	8, $18, 4, 4, $1D0, 0, 0, 0, 0
	spritePiece	$28, $18, 1, 4, $1E0, 0, 0, 0, 0
	spritePiece	$10, $10, 4, 4, $14A, 0, 0, 0, 0
	spritePiece	$20, 8, 2, 1, $15A, 0, 0, 0, 0
	spritePiece	$30, 0, 3, 4, $15C, 0, 0, 0, 0
	spritePiece	$48, 8, 1, 1, $168, 0, 0, 0, 0
	spritePiece	$48, $18, 1, 1, $169, 0, 0, 0, 0
	spritePiece	0, $18, 2, 2, $16A, 0, 0, 0, 0
	spritePiece	8, $28, 1, 3, $16E, 0, 0, 0, 0
	spritePiece	$10, $30, 4, 4, $171, 0, 0, 0, 0
	spritePiece	$30, $20, 4, 2, $181, 0, 0, 0, 0
	spritePiece	$50, $20, 1, 2, $189, 0, 0, 0, 0
	spritePiece	$30, $30, 3, 1, $18B, 0, 0, 0, 0
	spritePiece	$30, $38, 4, 3, $18E, 0, 0, 0, 0
	spritePiece	8, $50, 4, 1, $258, 0, 0, 0, 0
	spritePiece	$28, $50, 4, 1, $25C, 0, 0, 0, 0
.trim2_End
	even

; Splash input helpers preserve all registers used by loading/sound routines.
Splash_ReadStart:
		movem.l d0-d7/a0-a6,-(sp)
		jsr (ReadJoypads).l
		btst #bitStart,(v_jpadpress1).w
		movem.l (sp)+,d0-d7/a0-a6
		rts

Splash_SegaPCMInput:
		bsr.s Splash_ReadStart
		beq.s .return
		move.w #-1,(v_generictimer).w ; latch skip across the blocking chant
.return:
		tst.w (v_generictimer).w
		rts

splash_stp_skip: equ v_sonicteam+objoff_3E
Splash_PresentsPoll:
		bsr.s Splash_ReadStart
		beq.s .return
		st (splash_stp_skip).w
.return:
		rts

; Same fade steps/PLC processing as the normal routines; only waits are skipped.
Splash_PresentsFadeIn:
		move.w #$003F,(v_pfade_start).w
		lea (v_palette).w,a0
		moveq #$40-1,d0
.black:
		clr.w (a0)+
		dbf d0,.black
		moveq #22-1,d4
.loop:
		tst.b (splash_stp_skip).w
		bne.s .step
		move.b #id_VBlank_PaletteFade,(v_vblank_routine).w
		jsr (WaitForVBlank).l
		btst #bitStart,(v_jpadpress1).w
		beq.s .step
		st (splash_stp_skip).w
		disable_display
.step:
		jsr (FadeIn_FromBlack).l
		jsr (RunPLC).l
		dbf d4,.loop
		rts

Splash_PresentsFadeOut:
		move.w #$003F,(v_pfade_start).w
		moveq #22-1,d4
.loop:
		tst.b (splash_stp_skip).w
		bne.s .step
		move.b #id_VBlank_PaletteFade,(v_vblank_routine).w
		jsr (WaitForVBlank).l
		btst #bitStart,(v_jpadpress1).w
		beq.s .step
		st (splash_stp_skip).w
.step:
		jsr (FadeOut_ToBlack).l
		jsr (RunPLC).l
		dbf d4,.loop
		rts
