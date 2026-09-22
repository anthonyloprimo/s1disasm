; Capture block replaces the unused W slot ($26); layouts remain unchanged.
; Per-player bytes are unused by the Special Stage object and cleared on entry.
sonss_captured: equ objoff_2A
sonss_capture_cooldown: equ objoff_2B
sonss_capture_block: equ objoff_2C ; long: layout address + 1, as used by FindWall
sonss_capture_grace: equ 12 ; active gameplay frames; pauses do not consume it

; Called before normal movement. d0=1 means remain attached and update view only.
SonicSS_CaptureControl:
		tst.b sonss_capture_cooldown(a0)
		beq.s .check
		subq.b #1,sonss_capture_cooldown(a0)
.check:
		tst.b sonss_captured(a0)
		beq.w .free
		bsr.w SonicSS_CaptureStop
		move.b (v_jpadpress2).w,d0 ; require a fresh press of any jump button
		andi.b #btnABC,d0
		bne.s .release
		moveq #1,d0
		rts
.release:
		clr.b sonss_captured(a0)
		move.b #sonss_capture_grace,sonss_capture_cooldown(a0)
		; Jump away from the captured block, including side/underside contacts.
		; This is a player jump, not a bumper launch, and uses normal jump force.
		move.l sonss_capture_block(a0),d1
		subi.l #v_sslayout_base+1,d1
		move.w d1,d2
		andi.w #ss_layout_rowlength-1,d1
		mulu.w #ss_blocksize,d1
		subi.w #20,d1
		lsr.w #7,d2
		andi.w #ss_layout_rowlength-1,d2
		mulu.w #ss_blocksize,d2
		subi.w #20+(ss_blocksize*2),d2
		sub.w obX(a0),d1
		sub.w obY(a0),d2
		jsr (CalcAngle).l
		jsr (CalcSine).l
		muls.w #-sonss_jumpspeed,d1
		asr.l #8,d1
		move.w d1,obVelX(a0)
		muls.w #-sonss_jumpspeed,d0
		asr.l #8,d0
		move.w d0,obVelY(a0)
		bset #1,obStatus(a0)
		move.b #1,jumping(a0)
		move.w #sfx_Jump,d0
		jsr (QueueSound2).l
.free:
		moveq #0,d0
		rts

; Called only after solid collision resolution has selected this block.
; Freeze at the resolved contact position: no snap to the block's center.
SonicSS_CaptureTouch:
		move.l sonss_touchedblock_ram(a0),d0
		tst.b sonss_capture_cooldown(a0)
		beq.s .catch
		cmp.l sonss_capture_block(a0),d0
		beq.s .return ; another capture block can still catch Sonic immediately
.catch:
		move.l d0,sonss_capture_block(a0)
		move.b #1,sonss_captured(a0)
		clr.b sonss_capture_cooldown(a0)
		bsr.s SonicSS_CaptureStop
.return:
		rts

SonicSS_CaptureStop:
		clr.w obVelX(a0)
		clr.w obVelY(a0)
		clr.w obInertia(a0)
		clr.b jumping(a0)
		bclr #1,obStatus(a0) ; attached is a jumpable state
		rts
