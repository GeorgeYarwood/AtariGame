    processor 6502

    include "vcs.h"
    include "macro.h"

    SEG.U Variables
    ORG $80
xPos byte
yPos byte
yHeight byte

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

    lda #17     ;Elements in the array
    sta yHeight

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
    ldx 242

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
CheckP0Up:
    lda #%00010000
    bit SWCHA
    bne CheckP0Down
    inc yPos

CheckP0Down:
    lda #%00100000
    bit SWCHA
    bne CheckP0Left
    dec yPos

CheckP0Left:
    lda #%01000000
    bit SWCHA
    bne CheckP0Right
    dec xPos

CheckP0Right:
    lda #%10000000
    bit SWCHA
    bne NoInput
    inc xPos

CheckFire:
    lda #%10000000
    bit INPT4
    bne NoInput
    jmp SpawnMissile
SpawnMissile:
    lda #2
    sta ENAM0
    ldx xPos
    stx missileXPos
NoInput:
    ; fallback when no input was performed


    jmp StartFrame

pBitmap:
    byte #%00000000
    byte #%01111110
    byte #%00010100
    byte #%00010100
    byte #%00010100
    byte #%00010100
    byte #%00011100
    byte #%01011101
    byte #%01011101
    byte #%01011101
    byte #%01011101
    byte #%01111111
    byte #%00111110
    byte #%00010000
    byte #%00011100
    byte #%00011100
    byte #%00011100

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Lookup table for the player colors
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pCol:
    byte #$00
    byte #$F6
    byte #$F2
    byte #$F2
    byte #$F2
    byte #$F2
    byte #$F2
    byte #$C2
    byte #$C2
    byte #$C2
    byte #$C2
    byte #$C2
    byte #$C2
    byte #$3E
    byte #$3E
    byte #$3E
    byte #$24

eBitmap
    byte #%00000000
    byte #%01111000
    byte #%01111000
    byte #%01111000
    byte #%01111000
    byte #%01111000
    byte #%01111000
    byte #%00110000

eCol:
    byte #$4C
    byte #$4C
    byte #$4C
    byte #$4C
    byte #$4C
    byte #$4C
    byte #$4C
    byte #$00

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Complete ROM size
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    org $FFFC
    word Reset
    word Reset
