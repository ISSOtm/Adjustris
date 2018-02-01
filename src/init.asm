;******************************************************************************
;* 
;* Adjustris - Block dropping puzzle game for Gameboy
;*
;* Written in 2017 by Dave VanEe (tbsp) dave.vanee@gmail.com
;* 
;* To the extent possible under law, the author(s) have dedicated all copyright 
;* and related and neighboring rights to this software to the public domain 
;* worldwide. This software is distributed without any warranty.
;*   
;* You should have received a copy of the CC0 Public Domain Dedication along with 
;* this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
;*
;******************************************************************************

INCLUDE "gbhw.inc"
INCLUDE "memory.inc"

INCLUDE "engine.inc"

;******************************************************************************
;**                                   IRQs                                   **
;******************************************************************************

SECTION "VBLANK IRQ",ROM0[$0040]
    push    af
    push    hl
    call    SpriteDMA_HRAM
    jp      vblank

SECTION "LCDC IRQ",ROM0[$0048]
    reti

SECTION "TIMER IRQ",ROM0[$0050]
    reti

SECTION "SERIAL IRQ",ROM0[$0058]
    reti

SECTION "HILO IRQ",ROM0[$0060]
    reti


;******************************************************************************
;**                              Program Start                               **
;******************************************************************************


SECTION "Init",ROM0[$0150]

; This label is located in header.asm, in order to jr to it.
; Start::
_Start:
    ld      sp,$E000
    
    sub     $11
    jr      z,.CGB
    ld      a,$FF
.CGB
    inc     a
    push    af          ; Save this for after clearing
	
    call    waitvbl
    xor     a
    ldh     [rLCDC],a   ; Turn off screen (for quick loading)

    xor     a           ; Clear RAM
    ld      hl,$8000
    ld      bc,$2000
    call    mem_Set
    ld      hl,$C000
    ld      bc,$1000
    call    mem_Set
    
    ; Init HRAM
    ld      bc,10 << 8 | LOW(SpriteDMA_HRAM)
    ld      hl,SpriteDMA
.copyDMARoutine
    ld      a,[hli]
    ld      [c],a
    inc     c
    dec     b
    jr      nz,.copyDMARoutine
    
    ld      b,$7F - 10
    xor     a
.initHRAM
    ld      [c],a
    inc     c
    dec     b
    jr      nz,.initHRAM
    
    pop     af
    ldh     [SystemType],a
    and     a
    jr      z,.skipCGBInit
    ; ld      a,1
    ld      [rVBK],a
    xor     a
    ld      hl,$8000
    ld      bc,$2000
    call    mem_Set
    ; xor     a
    ld      [rVBK],a
    
    ld      hl,.defaultCGBPalette
    xor     a
    ld      b,8
    call    SetPalBG
    jr      .skipDMGInit
    
.defaultCGBPalette
    dw      $4A52, $318C, $18C6, $0000
    
.skipCGBInit
  
    ld      a,%11100100 ; Set Palettes
    ldh     [rBGP],a
    ldh     [rOBP0],a
    ldh     [rOBP1],a
.skipDMGInit

    call    InitSRAM

    ld      a,%01000000
    ldh     [rSTAT],a
    ld      a,9        ; Set STAT Match LY
    ldh     [rLYC],a
  
    call    MS_setup_sound

  
    xor     a
    ldh     [TileUpdate],a		; thanks bgb (beware)
    ldh     [FrameCounter],a	; thanks bgb (beware)
    ldh     [GameMode],a
  
    ld      a,40        ; Initialize random number generator
    ld      [Seed],a
    ld      [Seed+1],a
    ld      [Seed+2],a
  
    ld      a,%10000000 ; turn on the LCD
    ldh     [rLCDC],a
    xor     a
    ldh     [rIF],a
    inc     a
    ldh     [rIE],a
    
    ei
    
    jp      Main



InitSRAM:
    ld      hl,SaveID
    ld      de,SaveRef

    xor     a
    ld      [rRAMB],a   ; set to ram bank 0
    ld      a,$0A
    ld      [rRAMG],a     ; enable SRAM access
    ld      b,4
.checkPattern
    ld      a,[de]
    cp      [hl]
    jr      nz,.NoSaveExists
    inc     de
    inc     hl
    dec     b
    jr      nz,.checkPattern
    jr      .SaveExists
    
    ; Copy remainder of pattern
.NoSaveExists
    ld      a,[de]
    ld      [hli],a
    inc     de
    dec     b
    jr      nz,.NoSaveExists
    ld      hl,SavedScores
    ld      a,$80                  ; initialize hiscores
    ld      bc,152                 ; ((6*3)+1)*8
    call    mem_Set
    ld      hl,Null_Piece_Set
    ld      de,SavedSets
    ld      bc,9
    call    mem_Copy
    ld      hl,Null_Piece_Set
    ld      bc,9
    call    mem_Copy
    ld      hl,Null_Piece_Set
    ld      bc,9
    call    mem_Copy
    ld      hl,Null_Piece_Set
    ld      bc,9
    call    mem_Copy
    ld      a,$FD
    ld      [de],a                 ; termination byte
  
.SaveExists
    xor     a
    ld      [rRAMG],a     ; disable SRAM access
  
    ret
