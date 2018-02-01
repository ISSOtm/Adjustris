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
INCLUDE "joypad.inc"
INCLUDE "engine.inc"

SECTION "Room Title Code/Data",ROM0

NB_MENU_ITEMS = 4

RoomTitle::

    ldh     a,[rLCDC]       ; Turn off screen (for quick loading)
    and     a
    jr      z,.screenOff
.waitForLY
    ldh     a,[rLY]
    cp      $90
    jr      c,.waitForLY
    xor     a
    ldh     [rLCDC],a
.screenOff

    ld      a,$A8
    ldh     [rWX],a
    xor     a
    ldh     [rSCY],a
    ldh     [rSCX],a
    ldh     [rWY],a
    ldh     [MenuPosition],a
    dec     a ; ld      a,$FF
    ldh     [GameMode],a

    ld      a,$80
    ld      hl,LinesCleared       ; Clear HiScores (to prevent menu artifacts)
    ld      bc,$0012
    call    mem_Set

    xor     a                 ; Clear VRAM
    ld      hl,$8000
    ld      bc,$2000
    call    mem_Set
    ld      hl,$C000
    ld      bc,$00A0
    call    mem_Set          ; Clear OAM Table
    
    ld      hl,.OAMTable
    ld      de,Sprite_Table
    ld      bc,4 * 4
	call    mem_Copy

    ld      hl,Tiles_Numbers   ; Load Numerical Tiles 
    ld      de,$9300
    ld      bc,$00A0
    call    mem_Copy
    ld      hl,Tiles_Letters
    ld      de,$9410           ; Load Alphabet Tiles
    ld      bc,$01A0
    call    mem_Copy
    ld      hl,Global_TextSymbols
    ld      bc,16*8
    call    mem_Copy         ; Additional Symbols
    ld      hl,tiles_adjustris_logo
    ld      de,$8800
    ld      bc,16*151
    call    mem_Copy

    ld      hl,PE_CursorTiles
    ld      de,$8010
    ld      bc,$00B0
    call    mem_Copy
    ld      hl,PE_Icons
    ld      de,$9210
    ld      bc,$00B0
    call    mem_Copy

    ; Logo Map
    ; pre-wipe
    ld      a,$80
    ld      hl,$9800
    ld      bc,$0234
    call    mem_Set
    ld      hl,mapbank0_adjustris_logo
    ld      de,$9802
    ld      b,18
.Logo_Loop
    push    bc
    ld      bc,16
    call    mem_Copy
    push    hl
    ld      hl,16
    add     hl,de
    ld      d,h
    ld      e,l
    pop     hl
    pop     bc
    dec     b
    jr      nz,.Logo_Loop
  
.lpCopy
    ld      hl,$9C00
    ld      a,$18
    ld      [hli],a
    ld      a,$16
    ld      b,$12
.lpHSb0
    ld      [hli],a
    dec     b
    jr      nz,.lpHSb0
    ld      a,$19
    ld      [hl],a
    ld      a,$14

    ld      hl,$9C20
    ld      b,$10
.lpHSb1
    ld      de,$0013
    ld      [hl],a
    add     hl,de
    inc     a
    ld      [hl],a
    dec     a
    ld      de,$000D
    add     hl,de
    dec     b
    jr      nz,.lpHSb1

    ld      hl,$9E20
    ld      a,$1A
    ld      [hli],a
    ld      a,$17
    ld      b,$12
.lpHSb2
    ld      [hli],a
    dec     b
    jr      nz,.lpHSb2
    ld      a,$1B
    ld      [hl],a
    ld      a,$14

    ld      a,GUIDelay
    ldh     [MenuDelay],a  ; GUI input delay

    xor     a
    ldh     [SelectedSet],a   ; start on set 0 (1)
    
    ldh     a,[SystemType]
    and     a
    jr      z,.SkipCGBSetup
    ld      hl,.OBJPalette
    ld      b,8
    xor     a
    call    SetPalOBJ
.SkipCGBSetup

    ld      a,%11100011
    ldh     [rLCDC],a
    xor     a
    ldh     [rIF],a
    inc     a ; ld      a,%00000001
    ldh     [rIE],a   ; Enable VBlank

.MenuLoop
    call    UpdateMenuCursor
    call    MenuInput
    halt
    ldh     a,[GameMode]
    inc     a
    jr      z,.MenuLoop
    ret
    
.OAMTable
    db $90, $47, 9, 0
    db $90, $A1, 9, OAMF_XFLIP
    db $88, $98, 8, 0
    db $99, $98, 8, OAMF_YFLIP
    
.OBJPalette
    dw      $4A52, $318C, $18C6, $0000


UpdateMenuCursor:
    ldh     a,[MenuPosition]
    and     a
    ld      a,$88
    jr      z,.displayVerticalCursors
    ld      a,$A0
.displayVerticalCursors
    ld      [Sprite_Table + 4 * 2],a
    add     a,$11
    ld      [Sprite_Table + 4 * 3],a
    ret 



MenuInput:
    ldh     a,[MenuDelay]
    and     a
    jr      z,.ok
    dec     a
    ldh     [MenuDelay],a
    
    cp      3
    ret     nz
    ld      hl,Sprite_Table + 2
    ld      de,4
    ld      c,40
.resetCursorTiles
    ld      a,[hl]
    and     $FD
    ld      [hl],a
    add     hl,de
    dec     c
    jr      nz,.resetCursorTiles
    ret
.ok
    call    ReadJoyPad
    call    RandomNumber
    ld      a,GUIDelay
    ldh     [MenuDelay],a
    
    ld      b,3 ; Index of the sprite to be blinked
    ldh     a,[hPadHeld]
    bit     PADB_DOWN,a
    jr      nz,.DownPressed
    dec b
    bit     PADB_UP,a
    jr      nz,.UpPressed
    dec b
    bit     PADB_RIGHT,a
    jr      nz,.RightPressed
    dec b
    bit     PADB_LEFT,a
    jr      nz,.LeftPressed

    ldh     a,[hPadPressed]
    and     PADF_A|PADF_START
    jr      nz,.ConfirmPressed

    xor     a
    ldh     [MenuDelay],a
    ret
    
.RightPressed
    ld      hl,FX_menuMove
    call    MS_sfxM2
    ldh     a,[MenuPosition]
    inc     a
    cp      NB_MENU_ITEMS
    jr      nz,.DoneMove
    xor     a
    jr      .DoneMove
.LeftPressed
    ld      hl,FX_menuMove
    call    MS_sfxM2
    ldh     a,[MenuPosition]
    and     a
    jr      nz,.DontWrapLeft
    ld      a,NB_MENU_ITEMS
.DontWrapLeft
    dec     a
.DoneMove
    ldh     [MenuPosition],a
    jr      .BlinkCursor
    
.UpPressed
    ldh     a,[MenuPosition]
    and     a
    ret     nz
    ld      hl,FX_menuMove     ; different FX?
    call    MS_sfxM2
    ldh     a,[SelectedSet]
    inc     a
    cp      8
    jr      nz,.DoneSet
    xor     a
    jr      .DoneSet
.DownPressed
    ldh     a,[MenuPosition]
    and     a
    ret     nz
    ld      hl,FX_menuMove     ; different FX?
    call    MS_sfxM2
    ldh     a,[SelectedSet]
    and     a
    jr      nz,.DontWrapSet
    ld      a,8
.DontWrapSet
    dec     a
.DoneSet
    ldh     [SelectedSet],a
    
.BlinkCursor
    ld      a,b
    add     a,a
    add     a,a
    add     2
    ld      l,a
    ld      h,HIGH(Sprite_Table)
    ld      a,[hl]
    or      $02
    ld      [hl],a
    ret
    
.ConfirmPressed
    ld      hl,FX_menuSelect
    call    MS_sfxM2
    ldh     a,[MenuPosition]
    cp      4
    jr      c,.EnterNewMode
    ;HiScore
    ld      a,$07
    ldh     [rWX],a
    ld      a,%11100001
    ldh     [rLCDC],a
.HiScoreLoop
    ldh     a,[MenuDelay]
    and     a
    jr      z,.Hiok
    dec     a
    ldh     [MenuDelay],a
    jr      .skip
.Hiok
    call    ReadJoyPad
    ldh     a,[hPadPressed]
    and     PADF_B|PADF_START
    jr      nz,.HiScoreReturn
.skip
    halt
    jr      .HiScoreLoop
.HiScoreReturn
    ld      a,$A8
    ldh     [rWX],a  
    ld      a,%11100011
    ldh     [rLCDC],a
.ConfirmDone
    ret  
.EnterNewMode
    ldh     [GameMode],a
    jr      .ConfirmDone



MenuText:
  db "PLAY SET  "
  db "EDIT SETS "
  db "HIGHSCORES"
  db " CREDITS  "

  INCLUDE "adjustris_logo_inverted.z80"
