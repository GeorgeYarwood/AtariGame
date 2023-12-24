    processor 6502

    include "vcs.h"
    include "macro.h"

    SEG.U Variables
    ORG $80
xPos byte
yPos byte
yHeight byte
maxHeight byte
canJump byte

missileXPos byte

    SEG Code
    ORG $F000

Reset:
    CLEAN_START

    ldx #$7E
    stx COLUBK  ;Bg col

    ldx #$D0    ;Playfield col
    stx COLUPF

    lda #10
    sta xPos  ;Init player start pos

    lda #32     ;Elements in the array
    sta yHeight

    lda #80
    sta maxHeight

    lda #2
    sta canJump

StartFrame:
    lda #2
    sta VBLANK
    sta VSYNC

    ldx #4
VSync:      ;Three lines of VSYNC
    dex
    sta WSYNC
    bne VSync

    lda #0
    sta VSYNC   ;Disable VSYNC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Use VBLANK to set player horizontal pos
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda xPos
    and #$7F    ;Restricts pos within -8-7 cutting off anything higher
    sta WSYNC
    sta HMCLR
    
    sec ;Carry flag
DivideLoop:
    sbc #15        ; subtract 15 from the accumulator
    bcs DivideLoop  ;While carry flag is set, loop
    eor #7
    REPEAT 4    ;Shift left 4 times for the TIA
        ASL
    REPEND
    sta HMP0
    sta RESP0
    sta WSYNC
    sta HMOVE

    ldx #36
VBlank:     ;Output remaining VBLANK
    DEX
    sta WSYNC
    bne VBlank

    lda #0
    sta VBLANK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 242 (PAL) Visible scanlines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ldx #242

Scanline:
    txa
    SEC
    sbc yPos
    cmp yHeight
    bcc LoadPlayerBitmap

    lda #0

LoadPlayerBitmap:
    tay
    lda pBitmap,Y  ;A is our scanline, so iterate arr based on that
    sta WSYNC
    sta GRP0 ;Set p graphic address
    lda pCol,Y ;Get col same as bitmap
    sta COLUP0
    dex
    bne Scanline

    lda #2
    sta VBLANK
    ldx 31

Overscan:
    dex 
    sta WSYNC
    bne Overscan

    lda #0
    sta VBLANK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Joystick input test for P0 up/down/left/right
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; CheckP0Up:
;     lda #%00010000
;     bit SWCHA
;     bne CheckP0Down
;     inc yPos

; CheckP0Down:
;     lda #%00100000
;     bit SWCHA
;     bne CheckP0Left
;     dec yPos

CheckP0Left:
    lda #%01000000
    bit SWCHA
    bne CheckP0Right
    dec xPos

CheckP0Right:
    lda #%10000000
    bit SWCHA
    bne CheckFire
    inc xPos

CheckFire:
    lda #2
    cmp canJump
    bne NoInput
    lda #%10000000
    bit INPT4
    bne NoInput
    jmp JumpPlayer

JumpPlayer:
    clc
    lda maxHeight
    cmp yPos
    bcc NoInput
    REPEAT 15
        inc yPos
    REPEND
    lda #0
    sta canJump
    jmp NextFrame
NoInput:
    ; fallback when no input was performed

    lda #0
Gravity:
    cmp yPos
    beq ZeroPos
    dec yPos
    jmp NextFrame

ZeroPos:
    lda #2
    sta canJump
    jmp NextFrame
NextFrame:
    jmp StartFrame

pBitmap:
    byte #%00000000
    byte #%00111110
    byte #%00110110
    byte #%00110110
    byte #%00101010
    byte #%00010010
    byte #%00111111

    byte #%00001100
    byte #%00001100

    byte #%0001110
    byte #%00111110

    byte #%10111101
    byte #%10111101
    byte #%10111101
    byte #%10111101
    byte #%10111101
    byte #%10111101
    byte #%10111101
    byte #%10111101
    byte #%10111101
    byte #%10111101
    byte #%10111101
    
    byte #%00111100
    byte #%00100100
    byte #%00100100
    byte #%00100100
    byte #%00100100
    byte #%00100100
    byte #%00100100
    byte #%00100100
    byte #%00100100

    byte #%01101100
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Lookup table for the player colors
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pCol:
    byte #$00
    byte #$00
    byte #$40
    byte #$40
    byte #$40
    byte #$40
    byte #$42
    byte #$42
    byte #$44
    byte #$D2
    byte #$D2
     byte #$00
    byte #$40
    byte #$40
    byte #$40
    byte #$40
    byte #$42
    byte #$42
    byte #$44
    byte #$D2
    byte #$D2
     byte #$00
    byte #$40
    byte #$40
    byte #$40
    byte #$40
    byte #$42
    byte #$42
    byte #$44
    byte #$D2
    byte #$D2
    byte #$D2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Complete ROM size
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    org $FFFC
    word Reset
    word Reset
