; One song ID per special stage. Add/import songs into the sound driver first,
; then assign their bgm_* ID here. Failed-stage retries bypass song selection.
SS_SelectStageMusic:
		moveq	#0,d0
		move.b	(v_lastspecial).w,d0 ; SS_Load leaves the NEXT stage index here
		subq.w	#1,d0
		bpl.s	.selected
		moveq	#ss_emeralds_num-1,d0
.selected:
		lea	SS_StageMusic(pc),a1
		move.b	(a1,d0.w),d0
		rts
SS_StageMusic:
		dc.b bgm_GHZ ; stage 1
		dc.b bgm_LZ ; stage 2
		dc.b bgm_MZ ; stage 3
		dc.b bgm_SLZ ; stage 4
		dc.b bgm_SYZ ; stage 5
		dc.b bgm_SBZ ; stage 6
		even
