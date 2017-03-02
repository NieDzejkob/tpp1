MainMenu::
	ld hl, wSelectedMenu
	ld a, MainTestingMenu & $ff
	ld [hli], a
	ld [hl], MainTestingMenu >> 8
	xor a
	ld [hFirstOption], a
	ld [hSelectedOption], a
	inc a
	ld [hNextMenuAction], a
	call RenderMenu
.loop
	call DelayFrame
	call GetMenuJoypad
	call nz, UpdateMenuContents
	call RenderMenu
	jr .loop

RenderMenu:
	ld a, [hNextMenuAction]
	and a
	ret z
	dec a
	jr nz, .not_full_redraw
	call ClearScreen
	ld a, 6
	rst DelayFrames
.not_full_redraw
	; ...
	ret

GetMenuJoypad:
	; ...
	ret

UpdateMenuContents:
	; ...
	ret
