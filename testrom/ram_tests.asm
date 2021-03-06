InitializeRAMBanks::
	call CheckRAMPresent
	ret c
	call MakeFullscreenTextbox
	call DoRAMBankInitialization
	jp EndFullscreenTextbox

DoRAMBankInitialization:
	ld hl, .initial_text
	rst Print
	call PrintEmptyString
.resample
	call Random
	and a
	jr z, .resample
	ld [hRAMInitialized], a
	ld hl, .selected_seed
	rst Print
	call PrintEmptyString
	call GetMaxValidRAMBank
	ld a, c
	ld [hRAMBanks], a
	ld a, MR3_MAP_SRAM_RW
	ld [rMR3w], a
	ld c, -1
.loop
	inc c
	ld a, c
	ld [rMR2w], a
	call InitializeRAMBank
	ld a, [hRAMBanks]
	cp c
	jr nz, .loop
	ld hl, .done_text
	rst Print
	jp PrintEmptyStringAndReinitializeMRRegisters

.initial_text
	db "Initializing RAM,<LF>"
	db "please wait...<@>"

.selected_seed
	db "Selected seed $"
	bigdw hRAMInitialized
	db "<LF>"
	db "for RAM content<LF>"
	db "initialization.<@>"

.done_text
	db "Initialized RAM<LF>"
	db "banks $00-$"
	bigdw hRAMBanks
	db ".<@>"

InitializeRAMBank:
	; initializes RAM bank c; destroys b and hl
	ld hl, $a000
	xor a
	ld [hli], a
	ld [hli], a
	ld a, [hRAMInitialized]
	ld [hli], a
	ld [hl], c
	ld hl, 0
	ld b, h
	ld a, [hRAMInitialized]
	rst AddNTimes
	ld b, h
	ld a, l
	ld hl, $bffc
	ld [hli], a
	ld a, b
	ld [hli], a
	ld a, $ff
	ld [hli], a
	ld [hl], a
	ret

CheckRAMPresent::
	; prints an error box if there is no SRAM
	call GetMaxValidRAMBank
	ret nc
	ld hl, NoRAMString
	call MessageBox
	ld a, ACTION_UPDATE
	ld [hNextMenuAction], a
	scf
	ret

GetMaxValidRAMBank::
	; returns the max valid RAM bank in c
	; returns carry if invalid/zero (i.e., no SRAM)
	ld a, [TPP1RAMSize]
	and a
	scf
	ret z
	cp 10
	ccf
	ret c
	ld c, a
	ld a, 1
	jr .handle_loop
.loop
	add a, a
.handle_loop
	dec c
	jr nz, .loop
	ld c, a
	dec c
	and a
	ret

CheckRAMInitialized:
	call CheckRAMPresent
	ret c
	ld a, [hRAMInitialized]
	and a
	ret nz
	ld hl, UninitializedRAMString
	call MessageBox
	ld a, ACTION_UPDATE
	ld [hNextMenuAction], a
	scf
	ret

CheckRAMStatusForTesting:
	ld b, 0
	jr _CheckRAMStatusForTesting

CheckRAMStatusForTesting_RequireTwoBanks:
	ld b, 1
_CheckRAMStatusForTesting:
	call GetMaxValidRAMBank
	ld hl, NoRAMString
	jr c, .failed
	dec b
	jr nz, .no_two_bank_testing
	ld a, c
	and a
	ld hl, OneRAMBankString
	jr z, .failed
.no_two_bank_testing
	ld a, [hRAMInitialized]
	and a
	ret nz
	call IncrementErrorCount
	ld hl, UninitializedRAMString
.failed
	rst Print
	call PrintEmptyString
	scf
	ret

TestRAMReadsReadOnly:
	call CheckRAMStatusForTesting
	ret c
	ld hl, RAMReadOnlyTestDescriptionString
	rst Print
	ld a, MR3_MAP_SRAM_RO
TestRAMReads:
	ld [rMR3w], a
	ld hl, TestingAmountOfRAMBanksString
	rst Print
	call PrintEmptyString
	ld c, -1
.loop
	inc c
	ld a, c
	ld [hCurrent], a
	ld [rMR2w], a
	call TestReadContentsFromRAMBank
	jr nc, .not_failed
	ld hl, RAMBankFailedString
	rst Print
	call IncrementErrorCount
.not_failed
	ld a, [hRAMBanks]
	cp c
	jr nz, .loop
	jp PrintEmptyStringAndReinitializeMRRegisters

TestRAMReadsReadWrite:
	call CheckRAMStatusForTesting
	ret c
	ld hl, .test_description_string
	rst Print
	ld a, MR3_MAP_SRAM_RW
	jr TestRAMReads

.test_description_string
	db "RAM reads in read/<LF>"
	db "write mode test:<@>"

TestReadContentsFromRAMBank:
	; tests reading from RAM bank c
	; returns carry if failed
	ld hl, $a000
	ld a, [hli]
	and a
	jr nz, .failed
	ld a, [hli]
	and a
	jr nz, .failed
	ld a, [hRAMInitialized]
	cp [hl]
	jr nz, .failed
	inc hl
	ld a, [hl]
	cp c
	jr nz, .failed
	ld hl, 0
	ld b, h
	ld a, [hRAMInitialized]
	rst AddNTimes
	ld a, l
	ld b, h
	ld hl, $bffc
	cp [hl]
	jr nz, .failed
	inc hl
	ld a, [hli]
	cp b
	jr nz, .failed
	ld a, [hli]
	and [hl]
	inc a
	jr nz, .failed
	ret
.failed
	scf
	ret

TestRAMWrites:
	call CheckRAMStatusForTesting
	ret c
	ld hl, .test_description_text
	rst Print
	ld hl, TestingAmountOfRAMBanksString
	rst Print
	call PrintEmptyString
	ld a, MR3_MAP_SRAM_RW
	ld [rMR3w], a
	ld c, -1
.loop
	inc c
	ld a, c
	ld [hCurrent], a
	ld [rMR2w], a
	call WriteAndVerifyRAMBank
	jr nc, .succeeded
	call IncrementErrorCount
	ld hl, RAMBankFailedString
	rst Print
.succeeded
	ld a, [hRAMBanks]
	cp c
	jr nz, .loop
	jp PrintEmptyStringAndReinitializeMRRegisters

.test_description_text
	db "RAM write and<LF>"
	db "verify test:<@>"

WriteAndVerifyRAMBank:
	call FillRandomBuffer
	ld hl, wRandomBuffer
	call GetRandomRAMAddress
	push hl
	push de
	push bc
	ld bc, $40
	rst CopyBytes
	pop bc
	ld b, $40
	pop de
	pop hl
.compare_loop
	ld a, [de]
	cp [hl]
	jr nz, .failed
	inc de
	inc hl
	dec b
	jr nz, .compare_loop
	; carry is clear here
	ret
.failed
	scf
	ret

GetRandomRAMAddress:
	call Random
	add a, a
	jr z, GetRandomRAMAddress
	dec a
	swap a
	rlca
	ld d, a
	and $e0
	ld e, a
	ld a, d
	and $1f
	add a, $a0
	ld d, a
	ret

TestRAMWritesReadOnly:
	call CheckRAMStatusForTesting
	ret c
	ld hl, .test_description_text
	rst Print
	ld hl, TestingAmountOfRAMBanksString
	rst Print
	call PrintEmptyString
	ld a, MR3_MAP_SRAM_RO
	ld [rMR3w], a
	ld c, -1
.loop
	inc c
	ld a, c
	ld [hCurrent], a
	ld [rMR2w], a
	call OverwriteInitializedRAMData
	call TestReadContentsFromRAMBank
	jr nc, .passed
	ld a, MR3_MAP_SRAM_RW
	ld [rMR3w], a
	call InitializeRAMBank
	ld a, MR3_MAP_SRAM_RO
	ld [rMR3w], a
	call IncrementErrorCount
	ld hl, RAMBankFailedString
	rst Print
.passed
	ld a, [hRAMBanks]
	cp c
	jr nz, .loop
	jp PrintEmptyStringAndReinitializeMRRegisters

.test_description_text
	db "RAM writes while<LF>"
	db "in read-only mode<LF>"
	db "test:<@>"

OverwriteInitializedRAMData:
	ld hl, $bffc
	call Random
	ld [hli], a
	call Random
	ld [hli], a
	xor a
	ld [hli], a
	ld [hli], a
	ld h, $a0
	dec a
	ld [hli], a
	ld [hli], a
	call Random
	ld [hli], a
	call Random
	ld [hl], a
	ret

TestRAMWritesDeselected:
	call CheckRAMStatusForTesting
	ret c
	ld hl, .test_description_text
	rst Print
	ld hl, TestingThreeBanksString
	rst Print
	call PrintEmptyString
	xor a
	call .test
	ld a, [hRAMBanks]
	push af
	call .test
	call Random
	pop bc
	and b
	call .test
	jp PrintEmptyStringAndReinitializeMRRegisters

.test_description_text
	db "RAM writes with<LF>"
	db "MR3 = $00 test:<@>"

.test
	ld [rMR2w], a
	ld [hCurrent], a
	ld c, a
	xor a ;ld a, MR3_MAP_REGS
	ld [rMR3w], a
	call OverwriteInitializedRAMData
	ld a, MR3_MAP_SRAM_RO
	ld [rMR3w], a
	call TestReadContentsFromRAMBank
	ret nc
	ld a, MR3_MAP_SRAM_RW
	ld [rMR3w], a
	call InitializeRAMBank
PrintRAMFailedAndIncrement:
	ld hl, RAMBankFailedString
	rst Print
	jp IncrementErrorCount

TestSwapRAMBanksDeselected:
	call CheckRAMStatusForTesting_RequireTwoBanks
	ret c
	ld hl, .test_description_text
	rst Print
	ld hl, TestingThreeBanksString
	rst Print
	call PrintEmptyString
	ld a, [hRAMBanks]
	ld c, a
.resample
	call Random
	and c
	jr z, .resample
	ld [rMR2w], a
	xor a
	call .test
	ld a, c
	call .test
	ld a, c
	dec a
	jr z, .selected_bank
.resample_bank
	call Random
	and c
	jr z, .resample_bank
	cp c
	jr z, .resample_bank
.selected_bank
	call .test
	jp PrintEmptyStringAndReinitializeMRRegisters

.test_description_text
	db "RAM bank selection<LF>"
	db "with MR3 = 0 test:<@>"

.test
	push bc
	ld [hCurrent], a
	ld c, a
	xor a ;ld a, MR3_MAP_REGS
	ld hl, rMR3w
	ld [hld], a
	ld a, c
	ld [hli], a
	ld [hl], MR3_MAP_SRAM_RO
	call TestReadContentsFromRAMBank
	pop bc
	ret nc
	jr PrintRAMFailedAndIncrement

RAMBankReadWriteScreen:
	push hl
	push de
	call ClearScreen
	hlcoord 0, 0
	lb de, SCREEN_WIDTH, SCREEN_HEIGHT - 4
	call Textbox
	ld a, 3
	rst DelayFrames
	ld hl, MaxRAMBankString
	decoord 1, 2
	rst CopyString
	pop de
	hlcoord 1, 4
	rst PrintString
	ld a, [hRAMBanks]
	hlcoord 15, 2
	call PrintHexByte
	pop hl
	jp HexadecimalEntry

TestRAMBankRangeReadWriteOption::
	call CheckRAMInitialized
	ret c
.retry
	ld hl, .hex_input
	ld de, .screen_text
	call RAMBankReadWriteScreen
	ret c
	ld a, [wBankStep]
	and a
	ld hl, ZeroStepString
	jr z, .error
	ld a, [wInitialBank]
	ld c, a
	ld a, [wFinalBank]
	cp c
	ld hl, NoBanksSelectedString
	jr c, .error
	ld c, a
	ld a, [hRAMBanks]
	cp c
	ld hl, RAMBankOutOfRangeString
	jr c, .error
	jp TestRAMBankRangeReadWrite
.error
	call MessageBox
	jr .retry

.screen_text
	db "Initial bank:<LF><LF>"
	db "Final bank:<LF><LF>"
	db "Step:<@>"

.hex_input
	hex_input 15, 4, wInitialBank
	hex_input 15, 6, wFinalBank
	hex_input 15, 8, wBankStep
	dw 0

TestOneRAMBankReadWriteOption::
	call CheckRAMInitialized
	ret c
.retry
	ld hl, .hex_input
	ld de, .screen_text
	call RAMBankReadWriteScreen
	ret c
	ld a, [wInitialBank]
	ld c, a
	ld a, [hRAMBanks]
	cp c
	jr nc, .go
	ld hl, RAMBankOutOfRangeString
	call MessageBox
	jr .retry
.go
	ld a, c
	ld [wFinalBank], a
	ld a, 1
	ld [wBankStep], a
	jr TestRAMBankRangeReadWrite

.screen_text
	db "Bank to test:<@>"

.hex_input
	hex_input 15, 4, wInitialBank
	dw 0

TestAllRAMBanksReadWriteOption::
	call CheckRAMInitialized
	ret c
	xor a
	ld [wInitialBank], a
	inc a
	ld [wBankStep], a
	ld a, [hRAMBanks]
	ld [wFinalBank], a
TestRAMBankRangeReadWrite:
	; do not run this test via ExecuteTest!
	call MakeFullscreenTextbox
	call ClearErrorCount
	ld hl, .test_description_text
	rst Print
	call PrintEmptyString
	ld a, MR3_MAP_SRAM_RW
	ld [rMR3w], a
	ld a, [wInitialBank]
	ld c, a
.loop
	ld a, c
	ld [hCurrent], a
	ld [rMR2w], a
	call TestReadContentsFromRAMBank
	jr nc, .read_success
	call IncrementErrorCount
	ld hl, .read_failed_text
	rst Print
.read_success
	call WriteAndVerifyRAMBank
	jr nc, .write_success
	call IncrementErrorCount
	ld hl, .write_failed_text
	rst Print
.write_success
	ld a, [wBankStep]
	add a, c
	jr c, .done
	ld c, a
	ld a, [wFinalBank]
	cp c
	jr nc, .loop
.done
	call PrintEmptyStringAndReinitializeMRRegisters
	call GenerateErrorCountString
	rst Print
	jp EndFullscreenTextbox
	
.test_description_text
	db "Testing RAM banks<LF>"
	db "$"
	bigdw wInitialBank
	db "-$"
	bigdw wFinalBank
	db " (step<LF>"
	db "$"
	bigdw wBankStep
	db ") for reading<LF>"
	db "and writing...<@>"

.read_failed_text
	db "FAILED: reading<LF>"
	db "from bank $"
	bigdw hCurrent
	db "<@>"

.write_failed_text
	db "FAILED: writing<LF>"
	db "to bank $"
	bigdw hCurrent
	db " (data<LF>"
	db "did not match)<@>"

TestRAMInBankAliasing:
	call CheckRAMStatusForTesting
	ret c
	ld hl, .test_description_text
	rst Print
	ld hl, TestingThreeBanksString
	rst Print
	ld a, MR3_MAP_SRAM_RW
	ld [rMR3w], a
	xor a
	call .test
	ld a, [hRAMBanks]
	call .test
	call Random
	ld c, a
	ld a, [hRAMBanks]
	and c
	call .test
	jp PrintEmptyStringAndReinitializeMRRegisters

.test_description_text
	db "RAM in-bank<LF>"
	db "aliasing test:<@>"

.test
	ld [hCurrent], a
	ld [rMR2w], a
.resample
	call GetRandomRAMAddress
	ld a, d
	cp $af
	jr nz, .go
	ld a, e
	cp $c1
	jr nc, .resample
.go
	push de
	xor a
	ld h, d
	ld l, e
	ld bc, $40
	push bc
	rst FillByte
	call FillRandomBuffer
	pop bc
	pop de
	push de
	ld a, d
	xor $10
	ld d, a
	ld hl, wRandomBuffer
	rst CopyBytes
	pop hl
	ld c, $40
.loop
	ld a, [hli]
	and a
	jr nz, .failed
	dec c
	jr nz, .loop
	ret

.failed
	ld hl, .failed_text
	rst Print
	jp IncrementErrorCount

.failed_text
	db "FAILED: aliasing<LF>"
	db "found in bank $"
	bigdw hCurrent
	db "<@>"

TestRAMCrossBankAliasing:
	call CheckRAMStatusForTesting_RequireTwoBanks
	ret c
	ld a, MR3_MAP_SRAM_RW
	ld [rMR3w], a
	ld hl, .test_description_text
	rst Print
	ld a, [hRAMBanks]
	dec a
	jr z, .two_banks
	ld hl, .testing_five_pairs_text
	rst Print
	ld a, [hRAMBanks]
	srl a
	inc a
	ld c, a
	ld b, 0
	call .test
	ld a, [hRAMBanks]
	ld b, a
	srl a
	ld c, a
	call .test
	ld a, 3
	ld [hMax], a
.loop
	ld a, [hRAMBanks]
	ld c, a
	call Random
	and c
	ld b, a
	call Random
	and c
	cp b
	jr z, .loop
	ld c, a
	call .test
	ld hl, hMax
	dec [hl]
	jr nz, .loop
.done_testing
	jp PrintEmptyStringAndReinitializeMRRegisters

.two_banks
	ld hl, TestingAmountOfRAMBanksString
	rst Print
	lb bc, 0, 1
	call .test
	jr .done_testing

.test_description_text
	db "RAM cross-bank<LF>"
	db "aliasing test:<@>"

.testing_five_pairs_text
	db "Testing five<LF>"
	db "pairs of banks...<@>"

.test
	push bc
	ld a, b
	ld [hCurrent], a
	ld [rMR2w], a
	call FillRandomBuffer
	call GetRandomRAMAddress
	ld bc, $40
	ld h, d
	ld l, e
	xor a
	rst FillByte
	pop bc
	ld a, c
	ld [hCurrent + 1], a
	ld [rMR2w], a
	push bc
	push de
	ld hl, wRandomBuffer
	ld bc, $40
	rst CopyBytes
	pop hl
	pop af
	ld [rMR2w], a
	ld c, $40
.testing_loop
	ld a, [hli]
	and a
	jr nz, .failed
	dec c
	jr nz, .testing_loop
	ret
.failed
	ld hl, .failed_text
	rst Print
	jp IncrementErrorCount

.failed_text
	db "FAILED: aliasing<LF>"
	db "found between<LF>"
	db "banks $"
	bigdw hCurrent
	db " and $"
	bigdw hCurrent + 1
	db "<@>"

RunAllRAMTests::
	call GetMaxValidRAMBank
	jr nc, .ok
	ld hl, NoRAMString
	rst Print
	jp PrintEmptyString

.ok
	call DoRAMBankInitialization
	call TestRAMReadsReadOnly
	call TestRAMReadsReadWrite
	call TestRAMWrites
	call TestRAMWritesReadOnly
	call TestRAMWritesDeselected
	ld a, [hRAMBanks]
	and a
	push af
	call nz, TestSwapRAMBanksDeselected
	call TestRAMInBankAliasing
	pop af
	call nz, TestRAMCrossBankAliasing
	ret
