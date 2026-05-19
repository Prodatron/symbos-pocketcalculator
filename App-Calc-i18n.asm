;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@                                                                            @
;@             S y m b O S   -   P o c k e t  C a l c u l a t o r             @
;@                   (default application texts [english])                    @
;@                                                                            @
;@             (c) 2004-2025 by Prodatron / SymbiosiS (Jörn Mika)             @
;@                                                                            @
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


;### POINTER ##################################################################

prgwintit   db 1:dw prgwintit_eng

;menus
prgwinmentx1   db 1:dw prgwinmentx1_eng
prgwinmen1tx1   db 1:dw prgwinmen1tx1_eng
prgwinmen1tx2   db 1:dw prgwinmen1tx2_eng

prgwinmentx2   db 1:dw prgwinmentx2_eng
prgwinmen2tx1   db 1:dw prgwinmen2tx1_eng
prgwinmen2tx2   db 1:dw prgwinmen2tx2_eng
prgwinmen2tx3   db 1:dw prgwinmen2tx3_eng
prgwinmen2tx4   db 1:dw prgwinmen2tx4_eng
prgwinmen2tx5   db 1:dw prgwinmen2tx5_eng
prgwinmen2tx6   db 1:dw prgwinmen2tx6_eng

prgwinmentx3   db 1:dw prgwinmentx3_eng
prgwinmen3tx1   db 1:dw prgwinmen3tx1_eng
prgwinmen3tx2   db 1:dw prgwinmen3tx2_eng

;error messages
errtxtzer   db 1:dw errtxtzer_eng
errtxtovf   db 1:dw errtxtovf_eng
errtxtimp   db 1:dw errtxtimp_eng
errtxtstk   db 1:dw errtxtstk_eng


;### TEXTS ####################################################################

prgwintit_eng   db "Calculator",0

;menus
prgwinmentx1_eng    db "Edit",0
prgwinmen1tx1_eng   db "Copy",0
prgwinmen1tx2_eng   db "Paste",0

prgwinmentx2_eng    db "View",0
prgwinmen2tx1_eng   db "Standard",0
prgwinmen2tx2_eng   db "Scientific",0
prgwinmen2tx3_eng   db "Deg",0
prgwinmen2tx4_eng   db "Rad",0
prgwinmen2tx5_eng   db "Group digits",0
prgwinmen2tx6_eng   db "US point format",0

prgwinmentx3_eng    db "?",0
prgwinmen3tx1_eng   db "Help topics",0
prgwinmen3tx2_eng   db "About Pocket Calculator",0

;error messages
errtxtzer_eng   db "Division by zero",0
errtxtovf_eng   db "Overflow",0
errtxtimp_eng   db "Improper number",0
errtxtstk_eng   db "Stack full",0


;### RESERVE
ds 30
