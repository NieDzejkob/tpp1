MainTestingMenu::
	menu "Main menu", MainTestingMenu
	option "Run all tests", OPTION_EXEC, NotImplemented
	option "ROM bank tests", OPTION_MENU, ROMTestingMenu
	option "RAM bank tests", OPTION_MENU, RAMTestingMenu
	option "RTC tests", OPTION_EXEC, NotImplemented
	option "Rumble tests", OPTION_EXEC, NotImplemented
	option "MR register tests", OPTION_EXEC, NotImplemented
	option "Memory viewer", OPTION_EXEC, NotImplemented
	option "About", OPTION_EXEC, NotImplemented
	option "Reset", OPTION_EXEC, DoReset
	end_menu

ROMTestingMenu:
	menu "ROM bank tests", MainTestingMenu
	option "Test bank sample", OPTION_EXEC, TestROMBankSampleOption
	option "Test bank range", OPTION_EXEC, TestROMBankRangeOption
	option "Test all banks", OPTION_TEST, TestAllROMBanks
	option "Back", OPTION_MENU, MainTestingMenu
	end_menu

RAMTestingMenu:
	menu "RAM bank tests", MainTestingMenu
	option "Initialize banks", OPTION_EXEC, InitializeRAMBanks
	option "Run all tests", OPTION_TEST, RunAllRAMTests
	option "Test reads R/O", OPTION_TEST, TestRAMReadsReadOnly
	option "Test reads R/W", OPTION_TEST, TestRAMReadsReadWrite
	option "Write and verify", OPTION_TEST, TestRAMWrites
	option "Test writes R/O", OPTION_TEST, TestRAMWritesReadOnly
	option "Write deselected", OPTION_TEST, TestRAMWritesDeselected
	option "Swap banks desel.", OPTION_TEST, TestSwapRAMBanksDeselected
	option "R/W test (1 bank)", OPTION_EXEC, TestOneRAMBankReadWriteOption
	option "R/W test (range)", OPTION_EXEC, TestRAMBankRangeReadWriteOption
	option "R/W test (all)", OPTION_EXEC, TestAllRAMBanksReadWriteOption
	option "In-bank aliasing", OPTION_TEST, TestRAMInBankAliasing
	option "Cross-bank alias.", OPTION_TEST, TestRAMCrossBankAliasing
	option "Back", OPTION_MENU, MainTestingMenu
	end_menu

NotImplemented:
	ld hl, .text
	call MessageBox
	ld a, ACTION_UPDATE
	ld [hNextMenuAction], a
	ret

.text
	db "Not implemented.<@>"

DoReset:
	xor a
	ld hl, rMR3w
	ld [hld], a
	ld [hld], a
	ld [hld], a
	ld [hl], 1
	rst Reset
