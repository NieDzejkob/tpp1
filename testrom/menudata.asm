MainTestingMenu::
	menu "Main menu", MainTestingMenu
	option "Run all tests", OPTION_CHECK, NotImplemented
	option "ROM bank tests", OPTION_MENU, ROMTestingMenu
	option "RAM bank tests", OPTION_CHECK, LoadRAMTestingMenu
	option "RTC tests", OPTION_CHECK, NotImplemented
	option "Rumble tests", OPTION_CHECK, NotImplemented
	option "MR register tests", OPTION_MENU, MRTestingMenu
	option "Memory viewer", OPTION_CHECK, NotImplemented
	option "About", OPTION_EXEC, AboutBox
	option "Reset", OPTION_EXEC, DoReset
	end_menu

ROMTestingMenu::
	menu "ROM bank tests", MainTestingMenu
	option "Run both tests", OPTION_TEST, RunAllROMTests
	option "Test bank sample", OPTION_EXEC, TestROMBankSampleOption
	option "Test bank range", OPTION_EXEC, TestROMBankRangeOption
	option "Test all banks", OPTION_TEST, TestAllROMBanks
	option "Bankswitch speed", OPTION_TEST, TestROMBankswitchSpeed
	option "Back", OPTION_MENU, MainTestingMenu
	end_menu

RAMTestingMenu::
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

RumbleTestingMenu::
	menu "Rumble tests", MainTestingMenu
	option "Test MR4", OPTION_CHECK, NotImplemented
	option "Manual testing", OPTION_CHECK, NotImplemented
	option "Back", OPTION_MENU, MainTestingMenu
	end_menu

ManualRumbleSelection::
	menu "Rumble controls", RumbleTestingMenu
	option "Off", OPTION_CHECK, NotImplemented
	option "Low", OPTION_CHECK, NotImplemented
	option "Medium", OPTION_CHECK, NotImplemented
	option "High", OPTION_CHECK, NotImplemented
	option "Go to main menu", OPTION_MENU, MainTestingMenu
	option "Back", OPTION_MENU, RumbleTestingMenu
	end_menu

MRTestingMenu::
	menu "MR register tests", MainTestingMenu
	option "Run all tests", OPTION_TEST, RunAllMRTests
	option "Mapping test", OPTION_TEST, MRMappingTest
	option "Mirroring test", OPTION_TEST, MRMirroringTest
	option "Reading test", OPTION_TEST, MRReadingTest
	option "Writing test", OPTION_TEST, MRWritesTest
	option "Restore values", OPTION_EXEC, RestoreMRValues
	option "Back", OPTION_MENU, MainTestingMenu
	end_menu
