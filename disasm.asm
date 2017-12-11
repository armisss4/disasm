;Paleidus disasemblerį su argumentu "/?", jis turi išmesti aprašą: atsiskaitančiojo vardas, pavardė, kursas, grupė, trumpas programos aprašymas.
;Visi parametrai disasembleriui turi būti paduodami komandine eilute, o ne prašant juos įvesti iš klaviatūros. Pvz.: disasm prog.com prog.asm.
;Disasemblerio rezultatas turi būti išvedamas į failą.
;Jeigu disasembleris paleistas be parametrų arba parametrai nekorektiški, reikia atspausdinti pagalbos pranešimą tokį patį, kaip paleidus disasemblerį su parametru "/?".
;Disasembleris turi apdoroti įvedimo išvedimo (ir kitokias) klaidas. Pavyzdžiui, nustačius, kad nurodytas failas neegzistuoja - jis turi išvesti pagalbos pranešimą ir baigti darbą.
;Failų skaitymo ar rašymo buferio dydis turi būti nemažesnis už 10 baitų.
;Failo dydis gali viršyti skaitymo ar rašymo buferio dydį.
;Su programa turi būti pateikiamas testinis com failas ir jo kodas asm faile.
;Rezultatų faile turi būti išvedama poslinkis nuo kodo segmento pradžios, komandos mašininis kodas ir pati komanda. Turėkite omenyje, kad pirmoji komanda com faile yra su poslinkiu 100h nuo segmento pradžios.
;Turi būti suprantamos ir disasembliuojamos šios komandos:
;Segmento keitimo prefiksas;
;Visi MOV variantai (6);
;Visi PUSH variantai (3);
;Visi POP variantai (3);
;Visi ADD variantai (3);
;Visi INC variantai (2);
;Visi SUB variantai (3);
;Visi DEC variantai (2);
;Visi CMP variantai (3);
;Komanda MUL;
;Komanda DIV;
;Visi CALL variantai (4);
;Visi RET variantai (4);
;Visi JMP variantai (5);
;Visos sąlyginio valdymo perdavimo komandos (17);
;Komanda LOOP;
;Komanda INT;
;Visi kitų komandų, kurios naudojamos testinėje programoje, variantai;
;Jei nuskaičius baitą nesugebama jo atpažinti, reikia jį praleisti (apie tai pažymint rezultatų faile) ir bandyti atpažinti po jo einantį baitą;


.model small
.stack 100h
.data
    info            db 'Arminas Petraitis, 2 kursas, INF4 grupe', 0Dh, 0Ah, 'Programa disasembliuoja failus, pateiktus komandineje eiluteje paleidziant programa', 0Dh, 0Ah, 'Naudojimas: disasm input.com output.asm', 0Dh, 0Ah, '$'
    readFile        db 12 dup (0)
    writeFile       db 12 dup (0)
    inBuffer        db 20 dup (?),0
    outBuffer       db 100 dup (?)
    readHandle      dw ?
    writeHandle     dw ?
    symbol          db ?
    temp            dw ?
    position        dw 100h
    
include opcodes.asm

.code

Sje MACRO location
LOCAL @@exit
    jne @@exit
    jmp location
@@exit:
ENDM

OutFill MACRO mcode, acode
    mov ax, @data
    mov es, ax
    Pos position, outBuffer
    ToAscii mcode, outBuffer+7
    Move 68h, outBuffer+4
    Move 3Ah, outBuffer+5
    Move 20h, outBuffer+6 
    MoveStrToBuf acode, outBuffer+24
    Move 0Dh, outBuffer+98
    Move 0Ah, outBuffer+99
    inc position
    jmp save
ENDM

Sjc MACRO location
LOCAL @@exit
    jnc @@exit
    jmp location
@@exit:
ENDM

Move MACRO a,b
    push ax
    mov ah, a
    mov b, ah
    pop ax
ENDM

MoveStrToBuf MACRO a,b 
LOCAL @@start,@@exit
    push ax
    push si
    mov si, 00h
    @@start:
    mov ah, a[si]
    cmp ah, 00h
    je @@exit
    mov b[si], ah
    inc si
    jmp @@start
    @@exit:
    pop si
    pop ax
ENDM

Pos MACRO a,b
    push ax
    push bx
    mov ax, a
    ToAscii ah,b
    ToAscii al,b+2
    pop bx
    pop ax
ENDM

ToAscii MACRO a,b
    push ax
    push bx
    mov al, a
    mov ah, 0h
    mov bl, 10h
    div bl
    mov b, al
    mov b+1, ah
    ToAscii2 [b]
    ToAscii2 [b+1]
    pop bx
    pop ax
ENDM

ToAscii2 MACRO var
LOCAL @@letter, @@exit
    cmp var, 09h
    ja @@letter
    add var, 30h
    jmp @@exit
@@letter:
    add var, 37h
@@exit:
ENDM

Get_file MACRO file
LOCAL @@start,@@end,@@exit,@@loop,@@exit2
    lea di, [file]
    push ax
    call space_check
@@start:
    cmp byte ptr ds:[si], 0Dh
        je @@end
    cmp byte ptr ds:[si], ' '
        jne @@loop
@@end:
    ;mov al, '$'
    ;stosb
    pop ax
    jmp @@exit
@@loop:
    lodsb
    stosb
    jmp @@start
@@exit:
    cmp byte ptr es:[file], '$'
        jne @@exit2
    jmp print_info
@@exit2:
ENDM

Clr MACRO buffer 
LOCAL @@start, @@exit
    push Si
    mov Si, 00h
    @@start:
    cmp si,100
    je @@exit
    mov buffer[si],20h
    inc si
    jmp @@start
    @@exit:
    pop Si
ENDM

Compare MACRO b, loc
LOCAL @@exit
cmp byte ptr ds:[inBuffer+si], b
jne @@exit
jmp loc
@@exit:
ENDM

start:
    mov ax, @data
    mov es, ax

    mov si, 81h
    call space_check
    
    mov al, byte ptr ds:[si]
    cmp al, 0Dh
    Sje print_info
        
    mov ax, word ptr ds:[si]
    cmp ax, 3F2Fh
    Sje print_info

    Get_file readFile
    Get_file writeFile

    mov ax, @data
    mov ds, ax
    mov	dx, offset readFile
	mov	ah, 3Dh
	mov	al, 00h
	int	21h
    Sjc print_info
	mov	readHandle, ax   
    mov ax, @data
    mov ds, ax
    mov	dx, offset writeFile
	mov	ah, 3Ch
	mov	cx, 00h
	int	21h
    Sjc print_info
    mov ah, 3Dh
    mov al, 01h
    int 21h
    Sjc print_info
	mov	writeHandle, ax
    
    reread:
    mov	bx, readHandle
	mov	dx, offset inBuffer       ; address of buffer in dx
	mov	cx, 20         		; kiek baitu nuskaitysim
	mov	ah, 3fh         	; function 3Fh - read from file
	int	21h
    mov temp, ax
    mov si, 0
    dec si
    cmp temp, 00h
    Sje finish
    startCycle:
    inc si
    cmp si,temp
    Sje reread
    Clr outBuffer
    call check_byte
    
    
    jmp startCycle
    
print_info:
    mov ax, @data
    mov ds, ax
    mov dx, offset info
    mov ah, 09h
    int 21h
    jmp finish

space_check PROC near
    space_begin:
        cmp byte ptr ds:[si], 20h
        jne space_return
        inc si
        jmp space_begin
    space_return:
        ret
space_check ENDP

check_byte PROC near
    check_begin:
    Compare 06h, PushES
    Compare 0Eh, PushCS
    Compare 16h, PushSS
    Compare 1Eh, PushDS
    Compare 07h, PopES
    Compare 0Fh, PopCS
    Compare 17h, PopSS
    Compare 1Fh, PopDS
    Compare 07h, PopES
    Compare 0Fh, PopCS
    Compare 17h, PopSS
    Compare 1Fh, PopDS
    Compare 40h, IncAX
    Compare 44h, IncSP
    Compare 43h, IncBX
    Compare 47h, IncDI
    Compare 41h, IncCX
    Compare 45h, IncBP
    Compare 42h, IncDX
    Compare 46h, IncSI
    Compare 48h, DecAX
    Compare 4Ch, DecSP
    Compare 4Bh, DecBX
    Compare 4Fh, DecDI
    Compare 49h, DecCX
    Compare 4Dh, DecBP
    Compare 4Ah, DecDX
    Compare 4Eh, DecSI
    Compare 50h, PushAX
    Compare 54h, PushSP
    Compare 53h, PushBX
    Compare 57h, PushDI
    Compare 51h, PushCX
    Compare 55h, PushBP
    Compare 52h, PushDX
    Compare 56h, PushSI
    Compare 58h, PopAX
    Compare 5Ch, PopSP
    Compare 5Bh, PopBX
    Compare 5Fh, PopDI
    Compare 59h, PopCX
    Compare 5Dh, PopBP
    Compare 5Ah, PopDX
    Compare 5Eh, PopSI
    
    Compare 0B4h, MovAh
    
    OutFill ds:[inBuffer+si], .Unknown
    ret
check_byte ENDP

PushES:
OutFill 06h, .PushES

PushCS:
OutFill 0Eh, .PushCS

PushSS:
OutFill 16h, .PushSS

PushDS:
OutFill 1Eh, .PushDS

PopES:
OutFill 07h, .PopES

PopCS:
OutFill 0Fh, .PopCS

PopSS:
OutFill 17h, .PopSS

PopDS:
OutFill 1Fh, .PopDS

IncAX:
OutFill 40h, .IncAX

IncSP:
OutFill 44h, .IncSP

IncBX:
OutFill 43h, .IncBX

IncDI:
OutFill 47h, .IncDI

IncCX:
OutFill 41h, .IncCX

IncBP:
OutFill 45h, .IncBP

IncDX:
OutFill 42h, .IncDX

IncSI:
OutFill 46h, .IncSI

DecAX:
OutFill 48h, .DecAX

DecSP:
OutFill 4Ch, .DecSP

DecBX:
OutFill 4Bh, .DecBX

DecDI:
OutFill 4Fh, .DecDI

DecCX:
OutFill 49h, .DecCX

DecBP:
OutFill 4Dh, .DecBP

DecDX:
OutFill 4Ah, .DecDX

DecSI:
OutFill 4Eh, .DecSI

PushAX:
OutFill 50h, .PushAX

PushSP:
OutFill 54h, .PushSP

PushBX:
OutFill 53h, .PushBX

PushDI:
OutFill 57h, .PushDI

PushCX:
OutFill 51h, .PushCX

PushBP:
OutFill 55h, .PushBP

PushDX:
OutFill 52h, .PushDX

PushSI:
OutFill 56h, .PushSI

PopAX:
OutFill 58h, .PopAX

PopSP:
OutFill 5Ch, .PopSP

PopBX:
OutFill 5Bh, .PopBX

PopDI:
OutFill 5Fh, .PopDI

PopCX:
OutFill 59h, .PopCX

PopBP:
OutFill 5Dh, .PopBP

PopDX:
OutFill 5Ah, .PopDX

PopSI:
OutFill 5Eh, .PopSI



MovAh:
OutFill 0B4h, .Mov

save:
    mov ax, @data
    mov ds, ax
    mov bx, writeHandle
    mov cx, 100
    ;mov dx, inBuffer+2
    ;Move inBuffer+5,outBuffer+1
 ;   mov outBuffer, inBuffer+2
    mov dx, offset outBuffer
  ;  mov outBuffer+5, inBuffer
    mov ah, 40h
    int 21h
    jmp startCycle

finish:
    mov	bx, writeHandle
	mov	ah, 3eh			
	int	21h
    mov	bx, readHandle
	mov	ah, 3eh			
	int	21h
    mov ax, 4C00h
    int 21h
end start
