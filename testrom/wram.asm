; note: bank 1 is used as a randomness source

SECTION "Main WRAM", WRAM0[$c000]

wScreenBuffer:: ds SCREEN_HEIGHT * SCREEN_WIDTH

wRandomSeed:: ds 8

wSelectedMenu:: ds 2

SECTION "Program stack", WRAM0[$cf00]

Stack:: ds $100
StackTop::
