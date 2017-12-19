	;; Programa reaguoja i perduodamus parametrus
	;; isveda pagalba, jei nera nurodyti reikiami parametrai
	;; source failas skaitomas dalimis
	;; destination failas rasomas dalimis
	;; jei destination failas jau egzistuoja, jis yra isvalomas
	;; jei source failas nenurodytas - skaito iš stdin iki tuščios naujos eilutės
	;; galima nurodyti daugiau nei vieną source failą - juos sujungia
.model small
;.stack 100H

JUMPS ; auto generate inverted condition jmp on far jumps
	

;*************************Pakeista******************************
;.code
BSeg SEGMENT
;***************************************************************

;*******************Pridėta*************************************
	ORG	100h
	ASSUME ds:BSeg, cs:BSeg, ss:BSeg
;***************************************************************


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
    xor ah, ah
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

Clr MACRO buffer, bSize
LOCAL @@start, @@exit
    push Si
    xor Si, Si
    @@start:
        cmp si, bSize
        je @@exit
        mov buffer[si],20h
        inc si
        jmp @@start
    @@exit:
        pop Si
ENDM


START:
	;mov	ax, @data
	;mov	es, ax			; es kad galetume naudot stosb funkcija: Store AL at address ES:(E)DI
 
	mov	si, 81h        		; programos paleidimo parametrai rasomi segmente es pradedant 129 (arba 81h) baitu        
 
	call	skip_spaces
	
	mov	al, byte ptr ds:[si]	; nuskaityti pirma parametro simboli
	cmp	al, 13			; jei nera parametru
	je	help			; tai isvesti pagalba
	;; ar reikia isvesti pagalba
	mov	ax, word ptr ds:[si]
	cmp	ax, 3F2Fh        	; jei nuskaityta "/?" - 3F = '?'; 2F = '/'
	je	help                 	; rastas "/?", vadinasi reikia isvesti pagalba
	;; destination failo pavadinimas
	lea	di, destF
	call	read_filename		; perkelti is parametro i eilute
	cmp	byte ptr es:[destF], '$' ; jei nieko nenuskaite
	je	help

	;; source failo pavadinimas
	lea	di, sourceF
	call	read_filename		; perkelti is parametro i eilute

	push	ds si

	;mov	ax, @data
	;mov	ds, ax
	
	;; rasymui
	mov	dx, offset destF	; ikelti i dx destF - failo pavadinima
	mov	ah, 3ch			; isvalo/sukuria faila - komandos kodas
	mov	cx, 0			; normal - no attributes
	int	21h			; INT 21h / AH= 3Ch - create or truncate file.
					;   Jei nebus isvalytas - tai perrasines senaji,
					;   t.y. jei pries tai buves failas ilgesnis - like simboliai isliks.
	jc	err_destination
	mov	ah, 3dh			; atidaro faila - komandos kodas
	mov	al, 1			; rasymui
	int	21h			; INT 21h / AH= 3Dh - open existing file.
	jc	err_destination
	mov	destFHandle, ax		; issaugom handle

	jmp	startConverting

readSourceFile:
	pop	si ds
	;; source failo pavadinimas
	lea	di, sourceF
	call	read_filename		; perkelti is parametro i eilute

	push	ds si

	;mov	ax, @data
	;mov	ds, ax
	
	cmp	byte ptr ds:[sourceF], '$' ; jei nieko nenuskaite
	jne	startConverting
	jmp	closeF
	
startConverting:
	;; atidarom
	cmp	byte ptr ds:[sourceF], '$' ; jei nieko nenuskaite
	jne	source_from_file
	
	mov	sourceFHandle, 0
	jmp	skaitom
	
source_from_file:
	mov	dx, offset sourceF	; failo pavadinimas
	mov	ah, 3dh                	; atidaro faila - komandos kodas
	mov	al, 0                  	; 0 - reading, 1-writing, 2-abu
	int	21h			; INT 21h / AH= 3Dh - open existing file
	jc	err_source		; CF set on error AX = error code.
	mov	sourceFHandle, ax	; issaugojam filehandle
  
skaitom:
	mov	bx, sourceFHandle
	mov	dx, offset buffer       ; address of buffer in dx
	mov	cx, 20         		; kiek baitu nuskaitysim
	mov	ah, 3fh         	; function 3Fh - read from file
	int	21h
	
	mov	cx, ax          	; bytes actually read
	cmp	ax, 0			; jei nenuskaite
	jne	_6			; tai ne pabaiga

	mov	bx, sourceFHandle	; pabaiga skaitomo failo
	mov	ah, 3eh			; uzdaryti
	int	21h
	jmp	readSourceFile		; atidaryti kita skaitoma faila, jei yra
_6:
	mov	si, offset buffer	; skaitoma is cia
	mov	bx, destFHandle		; rasoma i cia

	cmp	sourceFHandle, 0
	jne	_7
	cmp	byte ptr ds:[si], 13
	je	closeF
_7:
atrenka:
	lodsb  				; Load byte at address DS:(E)SI into AL
	call	replace
	loop	atrenka

	jmp	skaitom

help:
	;mov	ax, @data
	;mov	ds, ax
	
	mov	dx, offset apie         
	mov	ah, 09h
	int	21h

	jmp	_end
	
closeF:
	;; uzdaryti dest
    mov di, 1050
    save:
    sub di, 50
    clr outbuff, 40
    pos di, outbuff
    mov outbuff+39, 0Dh
    mov outbuff+40, 0Ah
    mov bx, 00h
    save_1:
    cmp bx, 25
    ja save_3
    cmp word ptr ds:[letter+bx], di ;<------------------------------------- WHYYYYY
    jae save_2
    inc bx
    jmp save_1
    save_2:
    mov outbuff+6+bx, 'x'
    inc bx
    jmp save_1
    save_3:
    mov bx, 0
    
    lea dx, outbuff
    mov cx, 40
  	mov	bx, destFHandle
    mov	ah, 40h			; INT 21h / AH= 40h - write to file
	int	21h
    cmp di, 01h
    ja save
    	
    lea dx, letterstr
    mov cx, 33
  	mov	bx, destFHandle
    mov	ah, 40h			; INT 21h / AH= 40h - write to file
	int	21h


	mov	ah, 3eh			; uzdaryti
	mov	bx, destFHandle
	int	21h

_end:
	mov	ax, 4c00h
	int	21h  

err_source:
	;mov	ax, @data
	;mov	ds, ax
	
	mov	dx, offset err_s        
	mov	ah, 09h
	int	21h

	mov	dx, offset sourceF
	int	21h
	
	mov	ax, 4c01h
	int	21h  
	
err_destination:
	;mov	ax, @data
	;mov	ds, ax
	
	mov	dx, offset err_d         
	mov	ah, 09h
	int	21h

	mov	dx, offset destF
	int	21h
	
	mov	ax, 4c02h
	int	21h  
	
	
;; procedures
	
skip_spaces PROC near

skip_spaces_loop:
	cmp byte ptr ds:[si], ' '
	jne skip_spaces_end
	inc si
	jmp skip_spaces_loop
skip_spaces_end:
	ret
	
skip_spaces ENDP

read_filename PROC near

	push	ax
	call	skip_spaces
read_filename_start:
	cmp	byte ptr ds:[si], 13	; jei nera parametru
	je	read_filename_end	; tai taip, tai baigtas failo vedimas
	cmp	byte ptr ds:[si], ' '	; jei tarpas
	jne	read_filename_next	; tai praleisti visus tarpus, ir sokti prie kito parametro
read_filename_end:
	mov	al, '$'			; irasyti '$' gale
	stosb                           ; Store AL at address ES:(E)DI, di = di + 1
	pop	ax
	ret
read_filename_next:
	lodsb				; uzkrauna kita simboli
	stosb                           ; Store AL at address ES:(E)DI, di = di + 1
	jmp read_filename_start

read_filename ENDP
	
replace PROC near
    push si
    mov ah, 0
	cmp al, 'A'
	jb exit
	cmp al, 'Z'
	ja mini
    
    mov si, ax
    sub si, 40h
    inc letter+si
    jmp exit
    
    mini:
	cmp al, 'a'
	jb exit
	cmp al, 'z'
	ja exit
    
    mov si, ax
    sub si, 60h
    inc letter+si

    exit:
    pop si
    ret
replace ENDP

apie    	db 'Programa skaiciuoja raides failuose ir isveda i lentele',13,10,9,'uzd.exe [/?] destinationFile [ - | sourceFile1 [sourceFile2] [...] ]',13,10,13,10,9,'/? - pagalba',13,10,'$'
err_s    	db 'Source failo nepavyko atidaryti skaitymui',13,10,'$'
err_d    	db 'Destination failo nepavyko atidaryti rasymui',13,10,'$'

sourceF   	db 12 dup (0)
sourceFHandle	dw ?

destF   	db 12 dup (0)
destFHandle 	dw ?
	
buffer  	db 20 dup (?)
simbolis 	db ?

letter      dw 30 dup (0) 
outbuff     db 40 dup (' ')
Letterstr   db '       ABCDEFGHIJKLMNOPQRSTUVWXYZ  '

BSeg ends
 
end START