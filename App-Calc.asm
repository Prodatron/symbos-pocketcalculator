;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@                                                                            @
;@             S y m b O S   -   P o c k e t  C a l c u l a t o r             @
;@                                                                            @
;@          (c) 2004, 2007-2026 by Prodatron / SymbiosiS (Jörn Mika)          @
;@                                                                            @
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

relocate_start

;Todo


;==============================================================================
;### CODE AREA ################################################################
;==============================================================================

;### APPLICATION HEADER #######################################################

;header structure
prgdatcod       equ 0           ;Length of the code area (OS will place this area everywhere)
prgdatdat       equ 2           ;Length of the data area (screen manager data; OS will place this area inside a 16k block of one 64K bank)
prgdattra       equ 4           ;Length of the transfer area (stack, message buffer, desktop manager data; placed between #c000 and #ffff of a 64K bank)
prgdatorg       equ 6           ;Original origin of the assembler code
prgdatrel       equ 8           ;Number of entries in the relocator table
prgdatstk       equ 10          ;Length of the stack in bytes
prgdatrs1       equ 12          ;*reserved* (3 bytes)
prgdatnam       equ 15          ;program name (24+1[0] chars)
prgdatflg       equ 40          ;flags (+1=16colour icon available)
prgdat16i       equ 41          ;file offset of 16colour icon
prgdatrs2       equ 43          ;*reserved* (5 bytes)
prgdatidn       equ 48          ;"SymExe10" SymbOS executable file identification
prgdatcex       equ 56          ;additional memory for code area (will be reserved directly behind the loaded code area)
prgdatdex       equ 58          ;additional memory for data area (see above)
prgdattex       equ 60          ;additional memory for transfer area (see above)
prgdatres       equ 62          ;*reserved* (28 bytes)
prgdatism       equ 90          ;Application icon (small version), 8x8 pixel, SymbOS graphic format
prgdatibg       equ 109         ;Application icon (big version), 24x24 pixel, SymbOS graphic format
prgdatlen       equ 256         ;length of header

prgpstdat       equ 6           ;start address of the data area
prgpsttra       equ 8           ;start address of the transfer area
prgpstspz       equ 10          ;additional sub process or timer IDs (4*1)
prgpstbnk       equ 14          ;64K ram bank (1-8), where the application is located
prgpstmem       equ 48          ;additional memory areas; 8 memory areas can be registered here, each entry consists of 5 bytes
                                ;00  1B  Ram bank number (1-8; if 0, the entry will be ignored)
                                ;01  1W  Address
                                ;03  1W  Length
prgpstnum       equ 88          ;Application ID
prgpstprz       equ 89          ;Main process ID

App_BegCode dw App_BegData-App_BegCode  ;length of code area
            dw App_BegTrns-App_BegData  ;length of data area
            dw App_EndTrns-App_BegTrns  ;length of transfer area
prgdatadr   dw #1000                ;original origin                    POST address data area
prgtrnadr   dw relocate_count       ;number of relocator table entries  POST address transfer area
prgprztab   dw prgstk-App_BegTrns     ;stack length                     POST table processes
            dw 0                    ;*reserved*
App_BnkNum  db 0                    ;*reserved*                         POST bank number
            db "Pocket Calculator":ds 15-8:db 0 ;name
            db 1                    ;flags (+1=16c icon)
            dw prgicn16c-App_BegCode  ;16 colour icon offset
            ds 5                    ;*reserved*
prgmemtab   db "SymExe10"           ;SymbOS-EXE-identifier              POST table reserved memory areas
            dw 0                    ;additional code memory
            dw 0                    ;additional data memory
            dw 0                    ;additional transfer memory
            ds 28                   ;*reserved*

prgicnsml   db 2,8,8
            db #0f,#0f,#78,#41,#0f,#0f,#2a,#ab,#7d,#e5,#2a,#ab,#7d,#e5,#0f,#0f
prgicnbig   db 6,24,24
            db #f8,#f0,#f0,#f0,#f0,#f1,#80,#00,#00,#00,#00,#12,#93,#ff,#ff,#ff,#ff,#be,#93,#f0,#f0,#f0,#f0,#36,#93,#b0,#f0,#d0,#50,#36,#93,#f0,#f0,#d0,#50,#36,#93,#f0,#f0,#f0,#f0,#36,#93,#00,#00,#00,#00,#36
            db #83,#5f,#0f,#0f,#af,#be,#83,#0f,#0f,#0f,#0f,#3e,#82,#9d,#2b,#47,#46,#be,#93,#b6,#6d,#cb,#db,#b6,#83,#0f,#0f,#0f,#0f,#3e,#82,#9d,#2b,#47,#46,#be,#93,#b6,#6d,#cb,#db,#b6,#83,#0f,#0f,#0f,#0f,#3e
            db #82,#9d,#2b,#47,#46,#be,#93,#b6,#6d,#cb,#ca,#be,#83,#0f,#0f,#0f,#0e,#be,#82,#11,#2b,#47,#46,#be,#93,#fe,#6d,#cb,#db,#b6,#83,#0f,#0f,#0f,#0f,#3e,#b7,#ff,#ff,#ff,#ff,#fe,#f8,#f0,#f0,#f0,#f0,#f1

;### PRGPRZ -> Program-Process
dskprzn     db 2
sysprzn     db 3
windatprz   equ 3
prgwin      db 0

prgprz  ld a,(App_BegCode+47)
        cp 3
        jr nz,$+5
        ld (prgwindat+0),a

        call prglng
        call SySystem_HLPINI
        ld a,(App_PrcID)
        ld (prgwindat+windatprz),a

        ld c,MSC_DSK_WINOPN
        ld a,(App_BnkNum)
        ld b,a
        ld de,prgwindat
        call msgsnd             ;open window
prgprz1 call msgdsk             ;get message -> IXL=status, IXH=sender process
        cp MSR_DSK_WOPNER
        jp z,prgend             ;no memory for new window -> bye bye
        cp MSR_DSK_WOPNOK
        jr nz,prgprz1           ;other message -> ignore
        ld a,(App_MsgBuf+4)
        ld (prgwin),a           ;window has been opened -> save number

        ld a,1                  ;set deg
        call FLO_DEGRAD
        jp inpres               ;reset calculator

prgprz0 ld a,(edtlen)
        or a
        jp nz,edtchr
        call msgget
        jr nc,prgprz0
        cp MSR_DSK_WCLICK       ;*** form control has been clicked
        jr nz,prgprz0
        ld e,(iy+1)
        ld a,(prgwin)           ;main window?
        cp e
        jr z,prgprz4
        ;...there is only one window, so ignore
        jr prgprz0
prgprz4 ld a,(iy+2)
        cp DSK_ACT_CLOSE        ;*** close has been clicked
        jp z,prgend
        cp DSK_ACT_KEY          ;*** a key has been clicked
        jp z,prgkey
        cp DSK_ACT_MENU         ;*** a menu entry has been clicked
        jr z,prgprz2
        cp DSK_ACT_CONTENT      ;*** a control has been clicked
        jr nz,prgprz0
prgprz2 ld l,(iy+8)
        ld h,(iy+9)
        ld a,l
        or h
        jr z,prgprz0
        ld a,(iy+3)             ;A=click type (0/1/2=mouse left/right/double, 7=control has been "clicked" via keyboard)
        jp (hl)

;### PRGKEY -> Check key
prgkeya equ 45
prgkeyt db "0":dw inpnu0
        db "1":dw inpnu1
        db "2":dw inpnu2
        db "3":dw inpnu3
        db "4":dw inpnu4
        db "5":dw inpnu5
        db "6":dw inpnu6
        db "7":dw inpnu7
        db "8":dw inpnu8
        db "9":dw inpnu9
        db "+":dw opradd
        db "-":dw oprsub
        db "*":dw oprmul
        db "/":dw oprdiv
        db "y":dw oprpot
        db "=":dw oprequ
        db  13:dw oprequ
        db   8:dw inpbck
        db 127:dw inpclr
        db  27:dw inpres
        db "(":dw inpbro
        db ")":dw inpbrc
        db "r":dw fncrev
        db ",":dw inpcom
        db ".":dw inpcom
        db "s":dw fncsin
        db "o":dw fnccos
        db "t":dw fnctan
        db "g":dw fncarc
        db "%":dw fncper
        db 141:dw inpsgn
        db 142:dw setdeg
        db 143:dw setrad
        db 144:dw setnrm
        db 145:dw setsci
        db "x":dw inpexp
        db "n":dw fncln
        db "l":dw fnclog
        db "!":dw fncfac
        db "p":dw fncpi
        db "|":dw fncsqt
        db "@":dw fncxp2
        db "#":dw fncxp3
        db "C"-64:dw edtcop
        db "V"-64:dw edtpst

prgkey  ld d,(iy+4)
        call SyDesktop_KEYINT   ;convert primary to international
        jp c,prgprz0
        push af
prgkey3 jr z,prgkey4
        ld d,0
        call SyDesktop_KEYINT   ;ignore additional chars
        jr prgkey3
prgkey4 pop af

prgkey0 ld hl,prgkeyt
        ld b,prgkeya
        ld de,3
        call clclcs
prgkey1 cp (hl)
        jr z,prgkey2
        add hl,de
        djnz prgkey1
        jp prgprz0
prgkey2 inc hl
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        ld a,7
        jp (hl)

;### PRGEND -> Quit program
prgend  ld a,(App_PrcID)
        db #dd:ld l,a
        ld a,(sysprzn)
        db #dd:ld h,a
        ld iy,App_MsgBuf
        ld (iy+0),MSC_SYS_PRGEND
        ld a,(App_BegCode+prgpstnum)
        ld (iy+1),a
        rst #10
prgend0 rst #30
        jr prgend0

;### PRGINF -> open info window
prginf  ld hl,prgmsginf         ;*** Info-Window
        ld b,1+128
        call prginf0
        jp prgprz0
prginf0 ld (App_MsgBuf+1),hl
        ld a,(App_BnkNum)
        ld c,a
        ld (App_MsgBuf+3),bc
        ld a,MSC_SYS_SYSWRN
        ld (App_MsgBuf),a
        ld a,(App_PrcID)
        db #dd:ld l,a
        ld a,(sysprzn)
        db #dd:ld h,a
        ld iy,App_MsgBuf
        rst #10
        ret

;### PRGLNG -> load language pack
prglng  ld hl,(App_BegCode)
        ld de,App_BegCode
        dec h
        add hl,de               ;HL=code area end=path
        ex de,hl
        ld a,(App_BnkNum)
        ld c,a
        ld hl,texts_int
        ld ix,256*0+9           ;default language=9 (english), pack=0
        ld iyl,0                ;language-file version 0
        jp SySystem_LNGLOD

SySystem_LNGLOD
        ld (App_MsgBuf+6),a
        ld (App_MsgBuf+7),bc
        ld (App_MsgBuf+8),hl
        ld (App_MsgBuf+10),ix
        ld (App_MsgBuf+12),iy
        ld a,(App_BnkNum)
        ld iyh,a
        ld c,MSC_SYS_EXTFNC
        ld l,FNC_DXT_LNGLOD
        call SySystem_SendMessage
SySLLo1 call SySystem_WaitMessage
        cp MSR_SYS_EXTFNC
        jr nz,SySLLo1
        ld a,(App_MsgBuf+1)
        ret
SySystem_SendMessage
        ld iy,App_MsgBuf
        ld (iy+0),c
        ld (App_MsgBuf+1),hl
        ld (iy+3),a
        ld (App_MsgBuf+4),de
        db #dd:ld h,3       ;3 is the number of the system manager process
        ld a,(App_PrcID)
        db #dd:ld l,a
        rst #10
        ret
SySystem_WaitMessage
        ld iy,App_MsgBuf
SySWMs1 db #dd:ld h,3       ;3 is the number of the system manager process
        ld a,(App_PrcID)
        db #dd:ld l,a
        rst #08             ;wait for a system manager message
        db #dd:dec l
        jr nz,SySWMs1
        ld a,(iy+0)
        ret


;==============================================================================
;### MEMORY-ROUTINES ##########################################################
;==============================================================================

memval  ds 5    ;FP value
memflg  db 0    ;0=memory empty, 1=memory contains value
memnul  ds 5

memclr  xor a               ;clear memory
        call memsta
        jp prgprz0

memsto  ld hl,dspvalact     ;stores displayed value into memory
        call FLO_SGN
        jr z,memclr
        ex de,hl
        ld hl,memval
        call FLO_MOVE
        ld a,1
        call memsta
        jp prgprz0

memadd  ld a,(memflg)       ;adds displayed value to memory
        or a
        jr z,memsto
        ld hl,memval
        ld de,dspvalact
        call FLO_ADD
        jp prgprz0

memred  ld a,(memflg)       ;reads memory
        or a
        ld de,memnul
        jr z,memred1
        ld de,memval
memred1 call dspget
        call dsptxt
        jp prgprz0

memsta  ld (memflg),a       ;set and show memory status
        add a:add a
        add 2+8
        ld (prgwinobj2+2),a
        ld e,4
        jp msgsnd0


;==============================================================================
;### SET-ROUTINES #############################################################
;==============================================================================

modtyp  db 0

setnrm  xor a               ;** set normal calculator mode
        jr setmod
setsci  ld a,1              ;** set scientific calculator mode
setmod  ld hl,modtyp
        cp (hl)
        jp z,prgprz0
        ld (hl),a
        ld ix,prgwinmen2a
        xor 1
        call setrad3
        ld a,(hl)
        ld de,150
        ld hl,86
        ld bc,prgwingrpa
        or a
        jr z,setmod1
        ld de,150+52
        ld hl,86+14
        ld bc,prgwingrpb
setmod1 ld (prgwindat0),bc
        ld c,MSC_DSK_WINSIZ
        call msgsnd2
        jp inpres

setdeg  ld a,1              ;** set deg via menu
        jr setrad1
setrad  xor a               ;** set rad via menu
setrad1 ld (radianflg),a
        call setrad0
        ld de,256*6+256-2
        call msgsnd0
        jp prgprz0
setrad0 call FLO_DEGRAD
        ld ix,prgwinmen2b
setrad3 add a
        inc a
        ld (ix+0),a
        cpl
        add 4+1
        ld (ix+8),a
        ret
setrad2 ld a,(radianflg)    ;** set deg/rad via radio buttons
        call setrad0
        jp prgprz0

setdig  ld a,(dspchrflg)    ;** set 1000 digit separation on/off
        xor 1
        ld (dspchrflg),a
        add a
        inc a
        ld (prgwinmen2c),a
setdig1 call dsptxt
        jp prgprz0
setpoi  ld hl,(dspchrcom)   ;** set US point format on/off
        ld a,l
        ld l,h
        ld h,a
        ld (dspchrcom),hl
        ld hl,prgwinmen2c+8
        ld a,(hl)
        xor 2
        ld (hl),a
        jr setdig1

setfe   ld a,(dspfeflg)     ;** switch between normal and exponent view
        xor 1
        ld (dspfeflg),a
        ld a,-1
        ld (inpedista),a
        jr setdig1


;==============================================================================
;### CALCULATION-ROUTINES #####################################################
;==============================================================================

brkanz  db 0

stkmax  equ 16
stkmem  ds stkmax*6  ;operator (0=+,1=-,2=*,3=/,4=^,6=[), FP value (if operator<>6)
stklen  db 0

;### STKGET -> Get pointer to last stack entry
;### Output     HL=pointer, ZF=1 Stack is empty
;### Destroyed  AF,BC
stkget  ld a,(stklen)
        add a
        ret z
        ld c,a
        add a
        add c
        ld c,a
        ld b,0
        ld hl,stkmem-6
        add hl,bc
        ret

;### STKINC -> Adds a new entry to the stack
;### Output     CF=1 ok, CF=0 stack full, HL=error message
stkinc  ld hl,stklen
        ld a,stkmax-1
        cp (hl)
        jr z,stkinc1
        inc (hl)
        call stkget
        scf
        ret
stkinc1 ld hl,errtxtstk
        ret

;### OPREXE -> User clicked operand
;How it works
;1.) stack empty -> goto 5
;2.) compare with last operator on stack
;3.) that is a bracket -> goto 5
;4.) if calculator is in "standard mode" or if the last op is bigger or equal
;    -> remove last entry from stack, use op with last and current number -> current number = result -> goto 1
;5.) put current number + current operator onto the stack and display current number

opradd  xor a :jr oprexe
oprsub  ld a,1:jr oprexe
oprmul  ld a,2:jr oprexe
oprdiv  ld a,3:jr oprexe
oprpot  ld a,4

oprexe  ld e,a
        srl e
        ld d,a
oprexe1 call stkget
        jr z,oprexe2
        ld a,(hl)
        cp 6
        jr z,oprexe2
        ld c,a
        ld a,(modtyp)
        or a
        jr z,oprexe4    ;don't care about +/*/... order in "standard" mode
        ld a,c
        srl a
        cp e
        jr c,oprexe2
oprexe4 push de
        call oprclc
        pop de
        jp nc,fncres0
        jr oprexe1
oprexe2 call stkinc
        jp nc,fncres1
        ld (hl),d
        inc hl
        ld de,dspvalact
        call FLO_MOVE
oprexe3 call dspget
        call dsptxt
        jp prgprz0

;### OPREQU -> User clicked "=" button
oprequb db -1:ds 5

oprequ  xor a
        ld (brkanz),a
        call dspbrk
        ld a,#18    ;=jr
oprequ0 ld (oprequx),a
        call stkget
        jr z,oprequ4
        ld a,(hl)
        cp 6
        jr z,oprequ3
        ld (oprequb),a
        push hl
        ld de,dspvalact
        ld hl,oprequb+1
        call FLO_MOVE
        pop hl
        jr oprequ2
oprequ1 call stkget
        ld de,dspvalact
        jr z,oprexe3
        ld a,(hl)
        cp 6
        jr z,oprequ3
oprequ2 ld (oprequb),a
        call oprclc
        jr nc,fncres0
        jr oprequ1
oprequ3 ld hl,stklen
        dec (hl)
oprequx jr oprequ1
        ld hl,brkanz
        inc (hl)
        dec (hl)
        ld de,dspvalact
        jr z,oprexe3
        dec (hl)
        push de
        call dspbrk
        pop de
        jr oprexe3
oprequ4 ld hl,oprequb
        ld a,(hl)
        inc a
        ld de,dspvalact
        jr z,oprexe3
        ld de,dspvaltmp
        push de
        ld bc,6
        ldir
        pop hl
        call oprclc
        jr nc,fncres0
        xor a
        ld (stklen),a
        jp oprexe3

;### OPRCLC -> Calculates the result of (HL) [A] (dspvalact), stores the result in (dspvalact) and removes the last stack entry
;### Input      (HL)=stack entry (operand [0=add, 1=sub, 2=mul, 3=div, 4=pot], FP value)
;### Output     CF=0 error
oprclc  ld a,(hl)
        inc hl
        ld de,dspvalact
        cp 1
        jr c,oprclca
        jr z,oprclcs
        cp 3
        jr c,oprclcm
        jr z,oprclcd
oprclcp call FLO_POT
oprclc1 push af
        ex de,hl
        ld hl,stklen
        dec (hl)
        ld hl,dspvalact
        call FLO_MOVE
        pop af
        ret
oprclca call FLO_ADD
        jr oprclc1
oprclcs call FLO_SUB
        jr oprclc1
oprclcm call FLO_MULT
        jr oprclc1
oprclcd call FLO_DIV
        jr oprclc1


;==============================================================================
;### FUNCTION-ROUTINES ########################################################
;==============================================================================

;### FNCRES -> Checks, if an operation or function caused an error
fncres  ex de,hl
        jp c,oprexe3
fncres0 ld hl,errtxtzer
        jr z,fncres1
        ld hl,errtxtovf
        jp m,fncres1
fncres2 ld hl,errtxtimp
fncres1 ld de,dsptxtval
        ld bc,1+dspvaldig+3+1+4+1
        ldir
        call inpres0
        call dsptxtx
        jp prgprz0

;### STANDARD FUNCTIONS
fncsin  ld hl,dspvalact:call FLO_SIN:       jr fncres
fnccos  ld hl,dspvalact:call FLO_COS:       jr fncres
fnctan  ld hl,dspvalact:call FLO_TAN:       jr fncres
fncarc  ld hl,dspvalact:call FLO_ARC_TAN:   jr fncres
fncsqt  ld hl,dspvalact:call FLO_SQR:       jr fncres
fncln   ld hl,dspvalact:call FLO_LOG_NAT:   jr fncres
fnclog  ld hl,dspvalact:call FLO_LOG_DEC:   jr fncres
fncepx  ld hl,dspvalact:call FLO_POT_E:     jr fncres

;### SPECIAL FUNCTIONS
fncpi   ld de,FLO_CONST_PI      ;*** gets PI
        jp oprexe3

fncxp2  ld de,FLO_CONST_2       ;*** X^2
fncxp21 ld hl,dspvalact
        call FLO_POT
        jr fncres

fncxp3  ld de,FLO_CONST_3       ;*** X^3
        jr fncxp21

fncrev  ld de,FLO_CONST_1NEG    ;*** reverts the displayed number (1/x)
        jr fncxp21

fncfac  ld a,(dspvallen)        ;*** n!
        or a
        jr z,fncfac2        ;0!=1
        ld a,(dspintflg)
        or a
        jr z,fncres2        ;number must be integer
        ld a,(dspvalsgn)
        or a
        jp nz,fncres2       ;and positive
        ld de,FLO_CONST_1
        ld hl,fncfact
        call FLO_MOVE       ;copy 1 into current value
        ld de,dspvalact
        ld hl,dspvaltmp
        call FLO_MOVE       ;copy current value into multiply value
fncfac1 call FLO_SGN
        ld de,fncfact
        jp z,oprexe3        ;multiply value = 0 -> finished
        ex de,hl
        call FLO_MULT
        jp nc,fncres0
        ld hl,dspvaltmp
        ld de,FLO_CONST_1NEG
        call FLO_ADD
        jr fncfac1
fncfac2 ld de,FLO_CONST_1
        jp oprexe3
fncfact ds 5                ;current value

fncper  call stkget             ;*** % (new = last/100*current)
        jp z,inpclr
        inc hl
        ex de,hl
        ld hl,dspvalact
        call FLO_MULT
        jp nc,fncres0
        ld de,FLO_CONST_100
        call FLO_DIV
        jp nc,fncres0
        ex de,hl
        jp oprexe3


;==============================================================================
;### INPUT-ROUTINES ###########################################################
;==============================================================================

inpedista   db 0        ;Edit status (-1=RO, 0=normal, 1=with comma, 2=exponent)

;### INPBRO -> Open bracket
inpbro  call stkinc
        jp nc,prgprz0
        ld (hl),6
        ld hl,brkanz
        inc (hl)
        call dspbrk
        jp prgprz0

;### INPBRC -> Close bracket
inpbrc  ld a,#3e    ;ld a,x
        jp oprequ0

;### INPEXP -> Add exponent
inpexp  call inppha1
        ld a,(inpedista)
        cp 2
        jp nc,prgprz0       ;do nothing, if already in exp or in RO mode
        ld a,(dspvallen)
        sub 1
        jp c,prgprz0        ;do nothing, if len=0
        jr nz,inpexp1
        ld a,(dspvalnum)
        cp "0"
        jp z,prgprz0        ;do nothing, if len=1 and mantissa=0
inpexp1 ld a,2
        ld (inpedista),a
        jp inpphb

;### INPCLR -> Clear input
inpclr  call inpclr0
        jp inpphb
inpclr0 xor a
        jp inppha0

;### INPRES -> Reset calculator session
inpres  call inpres0
        jp inpphb
inpres0 xor a               ;clear stack
        ld (stklen),a
        ld (dspfeflg),a     ;reset F-E
        ld (brkanz),a       ;clear brackets
        dec a
        ld (oprequb),a      ;clear last operand
        call dspbrk
        jr inpclr0          ;clear input

;### INPBCK -> Backspace
inpbck  call inppha
        ld a,(inpedista)
        cp 1
        jr z,inpbck2
        jr nc,inpbck4
inpbck1 ld a,(dspvallen)    ;** before comma
        or a
        jp z,inpphb
        dec a
        ld (dspvallen),a
        ld e,a
        ld d,0
        ld hl,dspvalnum
        add hl,de
        ld (hl),d
        jp inpphb
inpbck2 ld hl,dspvalexp     ;** after comma
        ld a,(hl)
        or a
        jr nz,inpbck3
inpbck5 ld (inpedista),a    ;exp was 0 -> only deactivate comma edit mode
        jp prgprz0
inpbck3 inc (hl)
        jr inpbck1
inpbck4 ld a,(dspvalexp)    ;** exponent
        call sgnget
        or a
        ld bc,10*256+256-1
        jr nz,inpbck6
        ld a,(dspvallen)
        dec a
        neg
        ld (dspvalexp),a
        ld a,1
        ld (inpedista),a
        jp inpphb
inpbck6 inc c
        sub b
        jr nc,inpbck6
        ld a,c
        call sgnput
        ld (dspvalexp),a
        jp inpphb

;### INPSGN -> Change sign
inpsgn  call inppha1
        ld a,(inpedista)
        cp 2
        jr z,inpsgn1
        ld a,(dspvalsgn)    ;** change mantissa sign
        cpl
        ld (dspvalsgn),a
        jp inpphb
inpsgn1 ld a,(dspvalexp)    ;** change exponent sign
        ld hl,dspvallen
        add (hl)
        dec a
        neg
        ld hl,dspvallen
        sub (hl)
        inc a
        ld (dspvalexp),a
        jp inpphb

;### INPCOM -> Set comma
inpcom  call inppha
        ld hl,inpedista
        ld a,(hl)
        or a
        jp nz,prgprz0       ;set comma only, if no comma and no exponent existing
        ld (hl),1
        ld a,(dspvallen)
        or a
        jp nz,inpphb
        ld (dspvalnum+1),a  ;len=0 -> add 0 at the beginning and set len=1
        inc a
        ld (dspvallen),a
        ld a,"0"
        ld (dspvalnum),a
        jp inpphb

;### INPNUM -> User typed number
inpnu0  xor a :jr inpnum
inpnu1  ld a,1:jr inpnum
inpnu2  ld a,2:jr inpnum
inpnu3  ld a,3:jr inpnum
inpnu4  ld a,4:jr inpnum
inpnu5  ld a,5:jr inpnum
inpnu6  ld a,6:jr inpnum
inpnu7  ld a,7:jr inpnum
inpnu8  ld a,8:jr inpnum
inpnu9  ld a,9

inpnum  push af
        call inppha
        pop bc
        ld a,(inpedista)
        cp 1
        jr z,inpnum2
        jr nc,inpnum3
        ld a,b                  ;** input before comma
        or a
        jr nz,inpnum4
        ld a,(dspvallen)
        or a
        jr nz,inpnum4           ;no zero before comma allowed, if len=0
        call dspput
        ld de,dsptxtval
        call dsptxty
        call dsptxtx
        jp prgprz0
inpnum4 call inpnum1
        jp nc,prgprz0
        jp inpphb
inpnum1 ld a,(dspvallen)
        cp dspvalmax
        ret nc
        inc a
        ld (dspvallen),a
        ld l,a
        ld h,0
        ld de,dspvalnum-1
        add hl,de
        ld a,b
        add "0"
        ld (hl),a
        scf
        ret
inpnum2 call inpnum1            ;** input after comma
        jp nc,prgprz0
        ld hl,dspvalexp
        dec (hl)
        jr inpphb
inpnum3 ld a,(dspvalexp)        ;** input exponent
        call sgnget
        cp 10
        jp nc,prgprz0
        add a
        ld c,a
        add a
        add a
        add c
        add b
        call sgnput
        ld (dspvalexp),a
        jr inpphb

sgnget  ld hl,dspvallen
        add (hl)
        dec a
        or a
        ld e,0
        ret p
        inc e
        neg
        ret
sgnput  dec e
        jr nz,sgnput1
        neg
sgnput1 inc a
        sub (hl)
        ret

;### INPPHA -> Phase A [before input] Resets input, if R/O, and makes a backup
;### Output     CF=0 no reset, CF=1 reset because R/O
;### Destroyed  AF,BC,DE,HL
inppha  ld a,(inpedista)
        inc a
        jr nz,inppha1
inppha0 ld (inpedista),a        ;was RO -> reset
        ld hl,dspvalnum
        ld de,dspvalnum+1
        ld (hl),0
        ld bc,14-1
        ldir
        call inppha1
        scf
        ret
inppha1 ld hl,dspvalnum         ;make backup
        ld de,dspvalbak
        ld bc,14
        ldir
        or a
        ret

;### INPPHB -> Phase B [after input] Tests, if value ok (if not restores backup), displays it and jumps back to main loop
inpphb  call dspput
        jr nc,inpphb1
        ld hl,dspvalbak         ;restore backup
        ld de,dspvalnum
        ld bc,14
        ldir
inpphb1 call dsptxt
        jp prgprz0


;==============================================================================
;### DISPLAY-ROUTINES #########################################################
;==============================================================================

dspvaltmp   ds 5+1
dspvalact   ds 5        ;always contains the displayed number

dspvalmax   equ 10

dspvalnum   ds 10+1
dspvallen   db 0
dspvalsgn   db 0        ;0=positive; display no sign, -1=minus
dspvalexp   db 0        ;exponent (signed)

dspvalbak   ds 14       ;backup for old display value, if new one is too big
dspvaldig   equ 10      ;maximum amount of displayed mantissa digits

dspintflg   db 0        ;flag, if displayed number is integer
dspchrflg   db 1        ;flag, if 1000 points should be displayed
dspfeflg    db 0        ;flag, if exponent display
dspchrcom   db ","      ;symbol for 1000 points
dspchrpoi   db "."      ;symbol for comma

;### DSPGET -> converts 5byte floating point value to display format
;### Input  DE=pointer to 5byte floating point value
dspget  ld hl,0
        ld (dspvalsgn),hl   ;sgn,exp=0
        ld a,-1
        ld (inpedista),a
        ld hl,dspvalact
        call FLO_MOVE
        ex de,hl
        ld hl,dspvaltmp
        call FLO_MOVE
        call FLO_PREPARE
        ld a,b
        or a
        jr z,dspget3
        and 128
        add a
        sbc 0
        ld (dspvalsgn),a
        ld a,e
        ld (dspvalexp),a
        ld ix,(dspvaltmp+0)
        ld de,(dspvaltmp+2)
        db #dd:ld a,l
        db #dd:or h
        or e
        or d
        jr z,dspget3
        ld iy,dspvalnum
        call clcn32
        push iy:pop hl
        ld bc,dspvalnum-1
        or a
        sbc hl,bc
        ld c,l
        ld a,"0"
        ld hl,dspvalexp
dspget1 cp (iy+0)
        jr nz,dspget2
        ld (iy+0),0
        dec iy
        inc (hl)
        dec c
        jr nz,dspget1
dspget2 ld a,c
dspget3 ld (dspvallen),a
        ret

;### DSPTXT -> converts display format value to text and displays it
dsptxt  call dsptxt0
dsptxtx ld de,256*1+256-2       ;*** Display
        jp msgsnd0
dsptxt0 xor a
        ld (dspintflg),a
        ld hl,dsptxtval
        ld a,(dspvalsgn)        ;*** Sign
        inc a
        jr nz,dsptxt1
        ld (hl),"-"
        inc hl
dsptxt1 ex de,hl
        ld a,(dspvallen)        ;*** Test, if value=0
        or a
        jr nz,dsptxti
dsptxty ld a,"0"                ;display only 0.
        ld (de),a
        inc de
        jr dsptxth
dsptxti ld hl,dspvalnum
        ld a,(inpedista)
        cp 2
        jr z,dsptxt6            ;display exponent, if in exp edit mode
        jr c,dsptxtj
        ld a,(dspfeflg)
        or a
        jr nz,dsptxt6           ;display exponent, if in RO mode and F-E on
dsptxtj ld a,(dspvalexp)        ;*** Exponent
        ld b,a
        or a
        ld a,(dspvallen)
        ld c,a
        jp m,dsptxta
        add b                   ;*** Exponent positive -> exp display, if dspvallen + dspvalexp <= dspvaldig
        cp dspvaldig+1          ;a=length of complete number
        jr nc,dsptxt6
        ld b,a                  ;*** Display mantissa without comma (a,b=length of mantissa before comma)
        ld a,1
        ld (dspintflg),a
        ld a,b
dsptxt2 sub 3
        jr z,dsptxtf
        jr nc,dsptxt2
dsptxtf add 3
        ld c,a                  ;c=1000 counter
dsptxt3 ld a,(hl)
        inc hl
        or a
        jr nz,dsptxt4
        ld a,"0"
        dec hl
dsptxt4 call dsptxt5
        jr nz,dsptxt3
dsptxth ld a,(dspchrcom)
        ld (de),a
        inc de
        xor a
        ld (de),a
        ret
dsptxt6 ldi                     ;**** Display mantissa with exponent
        ld a,(dspchrcom)
        ld (de),a
        inc de
        ld a,(dspvallen)
dsptxt7 dec a
        jr z,dsptxt8
        ldi
        jr dsptxt7
dsptxt8 ex de,hl
        ld (hl),"e"
        inc hl
        ld a,(dspvallen)        ;exp display = -(exp + mantissa length - 1)
        ld c,a
        ld a,(dspvalexp)
        add c
        dec a
        ld (hl),"+"
        jp p,dsptxt9
        ld (hl),"-"
        neg
dsptxt9 inc hl
        ex de,hl
        call clcdez
        ex de,hl
        ld (hl),e
        inc hl
        ld (hl),d
        inc hl
        ld (hl),0
        ret
dsptxta add b                   ;*** Comma negative (a,c=len, b=comma -> a=len-neg comma)
        jr c,dsptxtb
        neg                     ;a=-(len+exp) [=distance between comma and first digit]
        ld b,a
        add c                   ;a=new number of digits-1
        cp dspvaldig+1
        jr nc,dsptxt6           ;too large -> display with exponent
        call dsptxte
        ld a,"0"
dsptxtg ld (de),a
        inc de
        djnz dsptxtg
        jr dsptxtd
dsptxtb jr z,dsptxtc            ;*** Display negative comma without exponent
        ld b,a
        call dsptxt2
        jr dsptxtd
dsptxtc call dsptxte
dsptxtd ld a,(hl)
        ldi
        or a
        jr nz,dsptxtd
        ret
dsptxte ld a,"0"
        ld (de),a
        inc de
        ld a,(dspchrcom)
        ld (de),a
        inc de
        ret
dsptxt5 ld (de),a               ;adds a digit (in A) and inserts a point, if needed
        inc de
        dec b
        ret z
        dec c
        ret nz
        ld a,(dspchrflg)
        dec a
        ret nz
        ld a,(dspchrpoi)
        ld (de),a
        inc de
        ld c,3+1
        dec c
        ret

;### DSPPUT -> Converts displayed value into 5byte FP value
;### Output     (dspvalact)=FP, CF=1 number exceeds limit
dspput  ld a,(dspvallen)
        or a
        ld ix,0
        ld hl,0
        jr z,dspput1
        ld iy,dspvalnum
        call clcr32
        ret c
dspput1 ld (dspvaltmp+0),ix
        ld (dspvaltmp+2),hl
        ld a,(dspvalsgn)
        ld hl,dspvaltmp
        call FLO_KONV_LW_TO_FLO
        ld a,(dspvalexp)
        call FLO_10A
        ccf
        ret c
        ld de,dspvaltmp
        ld hl,dspvalact
        call FLO_MOVE
        or a
        ret

;### DSPBRK -> Displays current number of brackets
dspbrk  ld hl,prgwinobj3+2
        ld (hl),2+8
        ld a,(brkanz)
        or a
        jr z,dspbrk3
        ld (hl),2+12
        cp 10
        jr nc,dspbrk1
        add "0"
        ld l,a
        ld h,0
        jr dspbrk2
dspbrk1 call clcdez
dspbrk2 ld (dsptxtbrk+2),hl
dspbrk3 ld de,8*256+256-2
        jp msgsnd0


;==============================================================================
;### EDIT-ROUTINES ############################################################
;==============================================================================

edtmax  equ 32
edtbuf  ds edtmax
edtpos  dw 0
edtlen  db 0

;### EDTCOP -> copies current display into clipboard
edtcop  ld hl,dsptxtval
        push hl
        call strlen                 ;HL=Stringende (0), BC=Länge (maximal 255, ohne Terminator)
        dec hl
        ld a,(dspchrcom)
        cp (hl)
        jr nz,edtcop1
        dec c
edtcop1 pop ix
        push bc:pop iy
        ld a,(App_BnkNum)
        ld e,a
        ld d,1
        rst #20:dw jmp_bufput
        jp prgprz0

;### EDTPST -> copies clipboard into input
edtpst  ld ix,edtbuf
        ld (edtpos),ix
        ld a,(App_BnkNum)
        ld e,a
        ld d,1
        ld iy,edtmax
        rst #20:dw jmp_bufget
        jp c,prgprz0
        call inpclr0
        ld a,iyl
;### EDTCHR -> copies one char from buffer to input
edtchr  dec a
        ld (edtlen),a
        ld hl,(edtpos)
        ld a,(dspchrpoi)
        cp (hl)
        ld a,(hl)
        inc hl
        ld (edtpos),hl
        jp z,prgprz0
        jp prgkey0


;==============================================================================
;### SUB-ROUTINES #############################################################
;==============================================================================

SySystem_HLPFLG db 0    ;flag, if HLP-path is valid
SySystem_HLPPTH db "%help.exe "
SySystem_HLPPTH1 ds 128
SySHInX db ".HLP",0

SySystem_HLPINI
        ld hl,(App_BegCode)
        ld de,App_BegCode
        dec h
        add hl,de                   ;HL = CodeEnd = Command line
        ld de,SySystem_HLPPTH1
        ld bc,0
        db #dd:ld l,128
SySHIn1 ld a,(hl)
        or a
        jr z,SySHIn3
        cp " "
        jr z,SySHIn3
        cp "."
        jr nz,SySHIn2
        ld c,e
        ld b,d
SySHIn2 ld (de),a
        inc hl
        inc de
        db #dd:dec l
        ret z
        jr SySHIn1
SySHIn3 ld a,c
        or b
        ret z
        ld e,c
        ld d,b
        ld hl,SySHInX
        ld bc,5
        ldir
        ld a,1
        ld (SySystem_HLPFLG),a
        ret

hlpopn  ld a,(SySystem_HLPFLG)
        or a
        jp z,prgprz0
        ld a,(App_BnkNum)
        ld d,a
        ld a,PRC_ID_SYSTEM
        ld c,MSC_SYS_PRGRUN
        ld hl,SySystem_HLPPTH
        ld b,l
        ld e,h
        call msgsnd1
        jp prgprz0

;******************************************************************************
;*** Name           DesktopService_KeyboardInternational
;*** Input          D  = Bit[0-6] primary charcode (28-127)
;***                     Bit[7]   flag, if only codes 32-127 allowed
;*** Output         E  = Bit[0]   =1 -> no char available
;***                     Bit[6]   =1 -> last char, =0 -> more chars available 
;***                - if E[bit0]=0
;***                D  = international char
;*** Destroyed      AF,BC,E,H,IX,IY
;*** Description    [...]
;******************************************************************************
SyDesktop_KEYINT
        ld a,DSK_SRV_KEYINT
        ld c,MSC_DSK_DSKSRV
        call SyDesktop_SendMessage
SyDSrv1 call SyDesktop_WaitMessage
        cp MSR_DSK_DSKSRV
        jr nz,SyDSrv1
        ld a,(iy+1)
        cp DSK_SRV_KEYINT
        jr nz,SyDSrv1
        ld hl,(App_MsgBuf+2)
        push hl:pop af
        ret

SyDesktop_SendMessage
;******************************************************************************
;*** Input          C  = Command
;***                A  = Window ID
;***                DE,HL = additional parameters
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Sends a message to the desktop manager, which includes the
;***                window ID and additional parameters
;******************************************************************************
        ld iy,App_MsgBuf
        ld b,a
        ld (App_MsgBuf+0),bc
        ld (App_MsgBuf+2),de
        ld (App_MsgBuf+4),hl
        db #dd:ld h,PRC_ID_DESKTOP
        ld a,(App_PrcID)
        db #dd:ld l,a
        rst #10
        ret

SyDesktop_WaitMessage
;******************************************************************************
;*** Input          -
;*** Output         IY = message buffer
;***                A  = first byte in the Message buffer (IY+0)
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Waits for a message coming from the Desktop Manager. Will
;***                go to sleep state state until a message is received.
;******************************************************************************
        ld iy,App_MsgBuf
SyDWMs1 db #dd:ld h,PRC_ID_DESKTOP
        ld a,(App_PrcID)
        db #dd:ld l,a
        rst #08             ;wait for a desktop manager message
        db #dd:dec l
        jr nz,SyDWMs1
        ld a,(App_MsgBuf+0)
        ret

;### MSGGET -> Message für Programm abholen
;### Ausgabe    CF=0 -> keine Message vorhanden, CF=1 -> IXH=Absender, (recmsgb)=Message, A=(recmsgb+0), IY=recmsgb
;### Veraendert 
msgget  ld a,(App_PrcID)
        db #dd:ld l,a           ;IXL=Rechner-Prozeß-Nummer
        db #dd:ld h,-1
        ld iy,App_MsgBuf           ;IY=Messagebuffer
        rst #08                 ;Message holen -> IXL=Status, IXH=Absender-Prozeß
        or a
        db #dd:dec l
        ret nz
        ld iy,App_MsgBuf
        ld a,(iy+0)
        or a
        jp z,prgend
        scf
        ret

;### MSGDSK -> Message für Programm von Desktop-Prozess abholen
;### Ausgabe    CF=0 -> keine Message vorhanden, CF=1 -> IXH=Absender, (recmsgb)=Message, A=(recmsgb+0), IY=recmsgb
;### Veraendert 
msgdsk  call msgget
        jr nc,msgdsk            ;keine Message
        ld a,(dskprzn)
        db #dd:cp h
        jr nz,msgdsk            ;Message von anderem als Desktop-Prozeß -> ignorieren
        ld a,(App_MsgBuf)
        ret

;### MSGSND -> Message an Desktop-Prozess senden
;### Eingabe    C=Kommando, B/E/D/L/H=Parameter1/2/3/4/5
msgsnd0 ld c,MSC_DSK_WINDIN
msgsnd2 ld a,(prgwin)
        ld b,a
msgsnd  ld a,(dskprzn)
msgsnd1 db #dd:ld h,a
        ld a,(App_PrcID)
        db #dd:ld l,a
        ld iy,App_MsgBuf
        ld (iy+0),c
        ld (iy+1),b
        ld (iy+2),e
        ld (iy+3),d
        ld (iy+4),l
        ld (iy+5),h
        rst #10
        ret

;### STRLEN -> Ermittelt Länge eines Strings
;### Eingabe    HL=String (0-terminiert)
;### Ausgabe    HL=Stringende (0), BC=Länge (maximal 255, ohne Terminator)
;### Verändert  -
strlen  push af
        xor a
        ld bc,255
        cpir
        ld a,254
        sub c
        ld c,a
        dec hl
        pop af
        ret

;### CLCLCS -> Lowercase
;### Input      A=char
;### Output     A=lcase(Zeichen)
;### Destroyed  F
clclcs  cp "A"
        ret c
        cp "Z"+1
        ret nc
        add "a"-"A"
        ret

;### CLCDEZ -> Converts 8bit value into two decimal digits
;### Input      A=value
;### Output     L=10.ascii digit, H=1. ascci digit
;### Destroyed  AF
clcdez  ld l,0
clcdez1 sub 10
        jr c,clcdez2
        inc l
        jr clcdez1
clcdez2 add "0"+10
        ld h,a
        ld a,"0"
        add l
        ld l,a
        ret

;### CLCR32 -> Converts ASCII-String (teminated by 0) into 32Bit-number (unsigned)
;### Input      IY=string
;### Output     HL,IX=number, CF=1 overflow
clcr32  ld ix,0
        ld hl,0
clcr321 ld a,(iy+0)
        or a
        ret z
        add ix,ix:adc hl,hl:ret c
        db #dd:ld c,l
        db #dd:ld b,h
        ld e,l
        ld d,h
        add ix,ix:adc hl,hl:ret c
        add ix,ix:adc hl,hl:ret c
        add ix,bc:adc hl,de:ret c   ;HL,IX*=10
        sub "0"
        ld c,a
        ld b,0
        add ix,bc
        ld c,b
        adc hl,bc:ret c             ;HL,IX+=digit
        inc iy
        jr clcr321

;### CLCN32 -> Converts 32Bit-number (unsigned) in ASCII-String (teminated by 0)
;### Input      DE,IX=value, IY=destination address
;### Output     IY=Address of last char
;### Destroyed  AF,BC,DE,HL,IX,IY
clcn32t dw 1,0,     10,0,     100,0,     1000,0,     10000,0
        dw #86a0,1, #4240,#f, #9680,#98, #e100,#5f5, #ca00,#3b9a
clcn32z ds 4

clcn32  ld (clcn32z),ix
        ld (clcn32z+2),de
        ld ix,clcn32t+36
        ld b,9
        ld c,0
clcn321 ld a,"0"
        or a
clcn322 ld e,(ix+0):ld d,(ix+1):ld hl,(clcn32z):  sbc hl,de:ld (clcn32z),hl
        ld e,(ix+2):ld d,(ix+3):ld hl,(clcn32z+2):sbc hl,de:ld (clcn32z+2),hl
        jr c,clcn325
        inc c
        inc a
        jr clcn322
clcn325 ld e,(ix+0):ld d,(ix+1):ld hl,(clcn32z):  add hl,de:ld (clcn32z),hl
        ld e,(ix+2):ld d,(ix+3):ld hl,(clcn32z+2):adc hl,de:ld (clcn32z+2),hl
        ld de,-4
        add ix,de
        inc c
        dec c
        jr z,clcn323
        ld (iy+0),a
        inc iy
clcn323 djnz clcn321
        ld a,(clcn32z)
        add "0"
        ld (iy+0),a
        ld (iy+1),0
        ret

read "App-Calc-Float.asm"


;==============================================================================
;### DATA-AREA ################################################################
;==============================================================================

App_BegData

prgicn16c db 12,24,24:dw $+7:dw $+4,12*24:db 5
db #91,#11,#11,#11,#11,#11,#11,#11,#11,#11,#11,#19,#18,#88,#88,#88,#88,#88,#88,#88,#88,#88,#88,#a1,#18,#a9,#99,#99,#99,#99,#99,#99,#99,#99,#9a,#91,#18,#a9,#11,#11,#11,#11,#11,#11,#11,#11,#8a,#91
db #18,#a9,#1c,#11,#11,#11,#11,#c1,#c1,#c1,#8a,#91,#18,#a9,#11,#11,#11,#11,#11,#c1,#c1,#c1,#8a,#91,#18,#a9,#11,#11,#11,#11,#11,#11,#11,#11,#8a,#91,#18,#a9,#88,#88,#88,#88,#88,#88,#88,#88,#8a,#91
db #18,#aa,#a9,#a9,#aa,#aa,#aa,#aa,#9a,#9a,#9a,#91,#18,#aa,#aa,#aa,#aa,#aa,#aa,#aa,#aa,#aa,#aa,#91,#18,#a8,#9a,#89,#a8,#9a,#89,#aa,#89,#a8,#9a,#91,#18,#a9,#1a,#91,#a9,#1a,#91,#aa,#91,#a9,#1a,#91
db #18,#aa,#aa,#aa,#aa,#aa,#aa,#aa,#aa,#aa,#aa,#91,#18,#a8,#9a,#89,#a8,#9a,#89,#aa,#89,#a8,#9a,#91,#18,#a9,#1a,#91,#a9,#1a,#91,#aa,#91,#a9,#1a,#91,#18,#aa,#aa,#aa,#aa,#aa,#aa,#aa,#aa,#aa,#aa,#91
db #18,#a8,#9a,#89,#a8,#9a,#89,#aa,#89,#a8,#9a,#91,#18,#a9,#1a,#91,#a9,#1a,#91,#aa,#91,#a8,#9a,#91,#18,#aa,#aa,#aa,#aa,#aa,#aa,#aa,#aa,#a8,#9a,#91,#18,#a8,#88,#89,#a8,#9a,#89,#aa,#89,#a8,#9a,#91
db #18,#a9,#99,#91,#a9,#1a,#91,#aa,#91,#a9,#1a,#91,#18,#aa,#aa,#aa,#aa,#aa,#aa,#aa,#aa,#aa,#aa,#91,#1a,#99,#99,#99,#99,#99,#99,#99,#99,#99,#99,#91,#91,#11,#11,#11,#11,#11,#11,#11,#11,#11,#11,#19

;==============================================================================
;%%% MULTI LANGUAGE TEXTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;==============================================================================

texts_int
read"App-Calc-i18n.asm"
texts_int_end

list
texts_int_len   equ texts_int_end-texts_int
nolist

;### Misc
prgmsginf1 db "Pocket Calculator for SymbOS",0
prgmsginf2  db " Version 1.1 (Build "
read "..\..\..\SRC-Main\build.asm"
            db "pdt)",0
prgmsginf3 db " Copyright <c> 2026 SymbiosiS",0

;### Display
dsptxtmem   db "M",0
dsptxtval   ds 1+dspvaldig+3+1+4+1     ;display text (sign + mantissa + 1000seperators + comma + exponent + 0terminator)
dsptxtbrk   db "(=##",0
dsptxtdeg   db "Deg",0
dsptxtrad   db "Rad",0

;### Buttons
buttxtbck   db "<-",0
buttxtce    db "CE",0
buttxtc     db "C",0
buttxtmc    db "MC",0
buttxtmr    db "MR",0
buttxtms    db "MS",0
buttxtmpl   db "M+",0
buttxtn0    db "0",0
buttxtn1    db "1",0
buttxtn2    db "2",0
buttxtn3    db "3",0
buttxtn4    db "4",0
buttxtn5    db "5",0
buttxtn6    db "6",0
buttxtn7    db "7",0
buttxtn8    db "8",0
buttxtn9    db "9",0
buttxtadd   db "+",0
buttxtsub   db "-",0
buttxtmul   db "*",0
buttxtdiv   db "/",0
buttxtpm    db "+/-",0
buttxtcom   db ",",0
buttxtequ   db "=",0
buttxtsqt   db "sqrt",0
buttxtper   db "%",0
buttxtrev   db "1/x",0
buttxtsin   db "sin",0
buttxtcos   db "cos",0
buttxttan   db "tan",0
buttxtarc   db "arc",0
buttxtpi    db "PI",0
buttxtxp2   db "x^2",0
buttxtxp3   db "x^3",0
buttxtxpy   db "x^y",0
buttxtfe    db "F-E",0
buttxtln    db "ln",0
buttxtlog   db "log",0
buttxtepx   db "e^x",0
buttxtnfc   db "n!",0
buttxtbro   db "(",0
buttxtbrc   db ")",0
buttxtexp   db "Exp",0


;==============================================================================
;### TRANSFER AREA ############################################################
;==============================================================================

App_BegTrns
;### PRGPRZS -> Stack for Program-Process
        ds 128
prgstk  ds 6*2
        dw prgprz
App_PrcID db 0
App_MsgBuf ds 14

;### INFO-WINDOW ##############################################################

prgmsginf   dw prgmsginf1,4*1+2, prgmsginf2,4*1+2, prgmsginf3,4*1+2, 0,prgicnbig,prgicn16c

;### MAIN-WINDOW ##############################################################

prgwindat dw #3501,0,50,30,150,86,0,0,150,86,150,86,150+52,86+14,prgicnsml,prgwintit,0,prgwinmen
prgwindat0 dw prgwingrpa,0,0:ds 136+14

prgwinmen  dw 3, 1+4,prgwinmentx1,prgwinmen1,0, 1+4,prgwinmentx2,prgwinmen2,0, 1+4,prgwinmentx3,prgwinmen3,0
prgwinmen1 dw 2, 1,prgwinmen1tx1,edtcop,0, 1,prgwinmen1tx2,edtpst,0
prgwinmen2 dw 8
prgwinmen2a dw 1+2,prgwinmen2tx1,setnrm,0, 1,prgwinmen2tx2,setsci,0, 1+8,0,0,0
prgwinmen2b dw 1+2,prgwinmen2tx3,setdeg,0, 1,prgwinmen2tx4,setrad,0, 1+8,0,0,0
prgwinmen2c dw 1+2,prgwinmen2tx5,setdig,0, 1,prgwinmen2tx6,setpoi,0
prgwinmen3 dw 3, 1,prgwinmen3tx1,hlpopn,0, 1+8,0,0,0, 1,prgwinmen3tx2,prginf,0

;standard view
prgwingrpa db 36,0:dw prgwinobja,0,0,0,0,0,0
prgwinobja
dw     00,255*256+00,2         ,  0,  0,1000,1000,0    ;00=Background
dw     00,255*256+02,3+4+64,      2,  2, 146,  12,0    ;01=Display Border
dw     00,255*256+01,prgwinobj1,  4,  4, 142,   8,0    ;02=Display Text
dw     00,255*256+02,3+4+32+64,   4, 16,  18,  12,0    ;03=Memory Border
dw     00,255*256+01,prgwinobj2,  6, 18,  14,   8,0    ;04=Memory Text

dw inpbck,255*256+16,buttxtbck , 30, 16,  38,  12,0    ;05=Button "Back"

dw     00,255*256+64,0         ,  0,  0,   1,   1,0    ;06=*invisible in standard mode*
dw     00,255*256+64,0         ,  0,  0,   1,   1,0    ;07=*invisible in standard mode*
dw     00,255*256+64,0         ,  0,  0,   1,   1,0    ;08=*invisible in standard mode*
dw     00,255*256+64,0         ,  0,  0,   1,   1,0    ;09=*invisible in standard mode*

dw inpclr,255*256+16,buttxtce  , 70, 16,  38,  12,0    ;10=Button "CE"
dw inpres,255*256+16,buttxtc   ,110, 16,  38,  12,0    ;11=Button "C"

dw memclr,255*256+16,buttxtmc  ,  2, 30,  22,  12,0    ;12=Button "MC"
dw inpnu7,255*256+16,buttxtn7  , 30, 30,  22,  12,0    ;13=Button "7"
dw inpnu8,255*256+16,buttxtn8  , 54, 30,  22,  12,0    ;14=Button "8"
dw inpnu9,255*256+16,buttxtn9  , 78, 30,  22,  12,0    ;15=Button "9"
dw oprdiv,255*256+16,buttxtdiv ,102, 30,  22,  12,0    ;16=Button "/"
dw fncsqt,255*256+16,buttxtsqt ,126, 30,  22,  12,0    ;17=Button "sqrt"

dw memred,255*256+16,buttxtmr  ,  2, 44,  22,  12,0    ;18=Button "MR"
dw inpnu4,255*256+16,buttxtn4  , 30, 44,  22,  12,0    ;19=Button "4"
dw inpnu5,255*256+16,buttxtn5  , 54, 44,  22,  12,0    ;20=Button "5"
dw inpnu6,255*256+16,buttxtn6  , 78, 44,  22,  12,0    ;21=Button "6"
dw oprmul,255*256+16,buttxtmul ,102, 44,  22,  12,0    ;22=Button "*"
dw fncper,255*256+16,buttxtper ,126, 44,  22,  12,0    ;23=Button "%"

dw memsto,255*256+16,buttxtms  ,  2, 58,  22,  12,0    ;24=Button "MS"
dw inpnu1,255*256+16,buttxtn1  , 30, 58,  22,  12,0    ;25=Button "1"
dw inpnu2,255*256+16,buttxtn2  , 54, 58,  22,  12,0    ;26=Button "2"
dw inpnu3,255*256+16,buttxtn3  , 78, 58,  22,  12,0    ;27=Button "3"
dw oprsub,255*256+16,buttxtsub ,102, 58,  22,  12,0    ;28=Button "-"
dw fncrev,255*256+16,buttxtrev ,126, 58,  22,  12,0    ;29=Button "1/x"

dw memadd,255*256+16,buttxtmpl ,  2, 72,  22,  12,0    ;30=Button "M+"
dw inpnu0,255*256+16,buttxtn0  , 30, 72,  22,  12,0    ;31=Button "0"
dw inpsgn,255*256+16,buttxtpm  , 54, 72,  22,  12,0    ;32=Button "+/-"
dw inpcom,255*256+16,buttxtcom , 78, 72,  22,  12,0    ;33=Button ","
dw opradd,255*256+16,buttxtadd ,102, 72,  22,  12,0    ;34=Button "+"
dw oprequ,255*256+16,buttxtequ ,126, 72,  22,  12,0    ;35=Button "="

;scientific view
prgwingrpb db 52,0:dw prgwinobjb,0,0,0,0,0,0
prgwinobjb
dw     00,255*256+00,2         ,  0,  0,1000,1000,0    ;00=Background
dw     00,255*256+02,3+4+64,      2,  2, 198,  12,0    ;01=Display Border
dw     00,255*256+01,prgwinobj1,  4,  4, 194,   8,0    ;02=Display Text
dw     00,255*256+02,3+4+32+64,  80, 30,  18,  12,0    ;03=Memory Border
dw     00,255*256+01,prgwinobj2, 82, 32,  14,   8,0    ;04=Memory Text

dw     00,255*256+02,3+4+32+64,   4, 16,  66,  12,0    ;05=Border Deg/Rad
dw setdeg,255*256+18,prgwinobj4,  8, 18,  28,   8,0    ;06=Radio Deg
dw setrad,255*256+18,prgwinobj5, 38, 18,  28,   8,0    ;07=Radio Rad
dw     00,255*256+02,3+4+32+64,  78, 16,  22,  12,0    ;08=Brackets Border
dw     00,255*256+01,prgwinobj3, 80, 18,  18,   8,0    ;09=Brackets Text

dw inpbck,255*256+16,buttxtbck ,106, 16,  30,  12,0    ;10=Button "Back"
dw inpclr,255*256+16,buttxtce  ,138, 16,  30,  12,0    ;11=Button "CE"
dw inpres,255*256+16,buttxtc   ,170, 16,  30,  12,0    ;12=Button "C"

dw fncsin,255*256+16,buttxtsin ,  2, 30,  22,  12,0    ;13=Button "sin"
dw fncrev,255*256+16,buttxtrev , 26, 30,  22,  12,0    ;14=Button "1/x"
dw setfe ,255*256+16,buttxtfe  , 50, 30,  22,  12,0    ;15=Button "F-E"
dw inpnu7,255*256+16,buttxtn7  ,106, 30,  22,  12,0    ;16=Button "7"
dw inpnu8,255*256+16,buttxtn8  ,130, 30,  22,  12,0    ;17=Button "8"
dw inpnu9,255*256+16,buttxtn9  ,154, 30,  22,  12,0    ;18=Button "9"
dw oprdiv,255*256+16,buttxtdiv ,178, 30,  22,  12,0    ;19=Button "/"

dw fnccos,255*256+16,buttxtcos ,  2, 44,  22,  12,0    ;20=Button "cos"
dw fncxp2,255*256+16,buttxtxp2 , 26, 44,  22,  12,0    ;21=Button "x^2"
dw fncln ,255*256+16,buttxtln  , 50, 44,  22,  12,0    ;22=Button "Ln"
dw memclr,255*256+16,buttxtmc  , 78, 44,  22,  12,0    ;23=Button "MC"
dw inpnu4,255*256+16,buttxtn4  ,106, 44,  22,  12,0    ;24=Button "4"
dw inpnu5,255*256+16,buttxtn5  ,130, 44,  22,  12,0    ;25=Button "5"
dw inpnu6,255*256+16,buttxtn6  ,154, 44,  22,  12,0    ;26=Button "6"
dw oprmul,255*256+16,buttxtmul ,178, 44,  22,  12,0    ;27=Button "*"

dw fnctan,255*256+16,buttxttan ,  2, 58,  22,  12,0    ;28=Button "tan"
dw fncxp3,255*256+16,buttxtxp3 , 26, 58,  22,  12,0    ;29=Button "x^3"
dw fnclog,255*256+16,buttxtlog , 50, 58,  22,  12,0    ;30=Button "Log"
dw memred,255*256+16,buttxtmr  , 78, 58,  22,  12,0    ;31=Button "MR"
dw inpnu1,255*256+16,buttxtn1  ,106, 58,  22,  12,0    ;32=Button "1"
dw inpnu2,255*256+16,buttxtn2  ,130, 58,  22,  12,0    ;33=Button "2"
dw inpnu3,255*256+16,buttxtn3  ,154, 58,  22,  12,0    ;34=Button "3"
dw oprsub,255*256+16,buttxtsub ,178, 58,  22,  12,0    ;35=Button "-"

dw fncarc,255*256+16,buttxtarc ,  2, 72,  22,  12,0    ;36=Button "arc"
dw oprpot,255*256+16,buttxtxpy , 26, 72,  22,  12,0    ;37=Button "x^y"
dw fncepx,255*256+16,buttxtepx , 50, 72,  22,  12,0    ;38=Button "e^x"
dw memsto,255*256+16,buttxtms  , 78, 72,  22,  12,0    ;39=Button "MS"
dw inpnu0,255*256+16,buttxtn0  ,106, 72,  22,  12,0    ;40=Button "0"
dw inpsgn,255*256+16,buttxtpm  ,130, 72,  22,  12,0    ;41=Button "+/-"
dw inpcom,255*256+16,buttxtcom ,154, 72,  22,  12,0    ;42=Button ","
dw opradd,255*256+16,buttxtadd ,178, 72,  22,  12,0    ;43=Button "+"

dw fncpi ,255*256+16,buttxtpi  ,  2, 86,  22,  12,0    ;44=Button "PI"
dw fncsqt,255*256+16,buttxtsqt , 26, 86,  22,  12,0    ;45=Button "sqrt"
dw fncfac,255*256+16,buttxtnfc , 50, 86,  22,  12,0    ;46=Button "n!"
dw memadd,255*256+16,buttxtmpl , 78, 86,  22,  12,0    ;47=Button "M+"
dw inpbro,255*256+16,buttxtbro ,106, 86,  22,  12,0    ;48=Button "("
dw inpbrc,255*256+16,buttxtbrc ,130, 86,  22,  12,0    ;49=Button ")"
dw inpexp,255*256+16,buttxtexp ,154, 86,  22,  12,0    ;50=Button "Exp"
dw oprequ,255*256+16,buttxtequ ,178, 86,  22,  12,0    ;51=Button "="


prgwinobj1  dw dsptxtval,0+4+256
prgwinobj2  dw dsptxtmem,2+8+512
prgwinobj3  dw dsptxtbrk,2+12+512

prgwinobj4  dw radianflg,dsptxtdeg,2+4+256,radiancoo
prgwinobj5  dw radianflg,dsptxtrad,2+4+000,radiancoo
radiancoo   ds 4
radianflg   db 1


App_EndTrns

relocate_table
relocate_end
