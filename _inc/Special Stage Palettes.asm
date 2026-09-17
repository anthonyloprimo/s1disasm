; Generated from the existing zone colors by build_tools/generate_ss_zone_palettes.py.
; Base/cycle files are independent editable palettes; originals stay untouched.
; Index follows the actual selected stage, including retries and stage skipping.
SS_GetStagePaletteEntry:
		moveq	#0,d0
		move.b	(v_lastspecial).w,d0
		subq.w	#1,d0
		bpl.s	.valid
		moveq	#ss_emeralds_num-1,d0
.valid:
		mulu.w	#12,d0
		lea	SS_StagePalettes(pc),a1
		adda.w	d0,a1
		rts
SS_LoadStagePalette:
		bsr.s	SS_GetStagePaletteEntry
		movea.l	(a1),a0
		lea	(v_palette_fading).w,a1
		moveq	#32-1,d0
.copy:
		move.l	(a0)+,(a1)+
		dbf	d0,.copy
		rts
; Preserve the cycle offset in d0 while finding the current theme.
SS_GetStageCycle1:
		move.l	d0,-(sp)
		bsr.s	SS_GetStagePaletteEntry
		movea.l	4(a1),a1
		move.l	(sp)+,d0
		rts
SS_GetStageCycle2:
		move.l	d0,-(sp)
		bsr.s	SS_GetStagePaletteEntry
		movea.l	8(a1),a1
		move.l	(sp)+,d0
		rts
SS_StagePalettes:
		dc.l SS_ZonePalette1,SS_ZoneCycle1_1,SS_ZoneCycle2_1
		dc.l SS_ZonePalette2,SS_ZoneCycle1_2,SS_ZoneCycle2_2
		dc.l SS_ZonePalette3,SS_ZoneCycle1_3,SS_ZoneCycle2_3
		dc.l SS_ZonePalette4,SS_ZoneCycle1_4,SS_ZoneCycle2_4
		dc.l SS_ZonePalette5,SS_ZoneCycle1_5,SS_ZoneCycle2_5
		dc.l SS_ZonePalette6,SS_ZoneCycle1_6,SS_ZoneCycle2_6
SS_ZonePalette1:	binclude "palette/Special Stage Zones/1 - Base.bin"
		even
SS_ZoneCycle1_1:	binclude "palette/Special Stage Zones/1 - Cycle 1.bin"
		even
SS_ZoneCycle2_1:	binclude "palette/Special Stage Zones/1 - Cycle 2.bin"
		even
SS_ZonePalette2:	binclude "palette/Special Stage Zones/2 - Base.bin"
		even
SS_ZoneCycle1_2:	binclude "palette/Special Stage Zones/2 - Cycle 1.bin"
		even
SS_ZoneCycle2_2:	binclude "palette/Special Stage Zones/2 - Cycle 2.bin"
		even
SS_ZonePalette3:	binclude "palette/Special Stage Zones/3 - Base.bin"
		even
SS_ZoneCycle1_3:	binclude "palette/Special Stage Zones/3 - Cycle 1.bin"
		even
SS_ZoneCycle2_3:	binclude "palette/Special Stage Zones/3 - Cycle 2.bin"
		even
SS_ZonePalette4:	binclude "palette/Special Stage Zones/4 - Base.bin"
		even
SS_ZoneCycle1_4:	binclude "palette/Special Stage Zones/4 - Cycle 1.bin"
		even
SS_ZoneCycle2_4:	binclude "palette/Special Stage Zones/4 - Cycle 2.bin"
		even
SS_ZonePalette5:	binclude "palette/Special Stage Zones/5 - Base.bin"
		even
SS_ZoneCycle1_5:	binclude "palette/Special Stage Zones/5 - Cycle 1.bin"
		even
SS_ZoneCycle2_5:	binclude "palette/Special Stage Zones/5 - Cycle 2.bin"
		even
SS_ZonePalette6:	binclude "palette/Special Stage Zones/6 - Base.bin"
		even
SS_ZoneCycle1_6:	binclude "palette/Special Stage Zones/6 - Cycle 1.bin"
		even
SS_ZoneCycle2_6:	binclude "palette/Special Stage Zones/6 - Cycle 2.bin"
		even
