CheckRTCAllowed::
	ld a, [TPP1Features]
	and 4
	ret nz
	scf
	ret

LatchMapRTC:
	ld hl, rMR3w
	ld [hl], MR3_LATCH_RTC
	push hl
	pop hl
	ld [hl], MR3_MAP_RTC
	ret

WaitForRTCChange:
	; returns frame count in a and zero flag indicating change
	push hl
	push de
	push bc
	call LatchMapRTC
	ld hl, rRTCW
	ld a, [hli]
	ld b, a
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld d, a
	ld e, [hl]
	ld hl, WaitingString
	rst Print
	xor a
.loop
	push af
	call DelayFrame
	call LatchMapRTC
	ld hl, rRTCW
	ld a, [hli]
	cp b
	jr nz, .changed
	ld a, [hli]
	cp c
	jr nz, .changed
	ld a, [hli]
	cp d
	jr nz, .changed
	ld a, [hl]
	cp e
	jr nz, .changed
	pop af
	inc a
	and $3f
	jr nz, .loop
.done
	pop bc
	pop de
	pop hl
	ret

.changed
	pop af
	inc a
	jr .done

GenerateRandomRTCSetting:
	call Random
	ld b, a
.resample_day_hour
	call Random
	cp 7 << 5
	jr nc, .resample_day_hour
	ld c, a
	or $e7 ;set all bits that aren't the top two hour bits
	inc a
	jr z, .resample_day_hour
.resample_minutes
	call Random
	and $3f
	ld d, a
	cp 60
	jr nc, .resample_minutes
.resample_seconds
	call Random
	and $3f
	ld e, a
	cp 60
	jr nc, .resample_seconds
	ret

SetRTCRandomly:
	push bc
	push de
	push hl
	call GenerateRandomRTCSetting
	ld hl, rRTCW
	ld a, b
	ld [hli], a
	ld a, c
	ld [hli], a
	ld a, d
	ld [hli], a
	ld [hl], e
	pop hl
	pop de
	pop bc
	ret

CheckRTCForValue::
	call LatchMapRTC
CheckRTCLatchForValue::
	ld hl, rRTCW
	ld a, [hli]
	cp b
	jr nz, RTCMismatchError
	ld a, [hli]
	cp c
	jr nz, RTCMismatchError
	ld a, [hli]
	cp d
	jr nz, RTCMismatchError
	ld a, [hl]
	cp e
	ret z
RTCMismatchError::
	push de
	ld hl, .error_text
	ld de, wTextBuffer
	rst CopyString
	ld h, d
	ld l, e
	pop de
	call GenerateTimeString
	ld hl, wTextBuffer
	rst Print
	jp IncrementErrorCount

.error_text
	db "FAILED: RTC value<LF>"
	db "mismatch, expected<LF><@>"

SetRTCToValue::
	ld a, MR3_MAP_RTC
	ld [rMR3w], a
	ld hl, rRTCS
	ld a, e
	ld [hld], a
	ld a, d
	ld [hld], a
	ld a, c
	ld [hld], a
	ld [hl], b
	ld a, MR3_SET_RTC
	ld [rMR3w], a
	ret

ValidateRTCTime::
	ld a, 59
	cp e
	ret c
	cp d
	ret c
	ld a, c
	add a, $20
	ret c
	or $e7
	add a, 1
	ret
