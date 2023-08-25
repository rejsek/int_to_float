.386
.model  flat,stdcall
.stack  1024
ExitProcess proto,dwExitCode:dword

STD_INPUT_HANDLE  EQU -10
STD_OUTPUT_HANDLE EQU -11
STD_ERROR_HANDLE  EQU -12

GetStdHandle PROTO, nStdHandle: DWORD
WriteConsoleA PROTO, handle: DWORD, lpBuffer:PTR BYTE, nNumberOfBytesToWrite:DWORD, lpNumberOfBytesWritten:PTR DWORD, lpReserved:DWORD
ReadConsoleA PROTO,  handle: DWORD, lpBuffer:PTR BYTE, nNumberOfBytesToRead:DWORD, lpNumberOfCharsRead:PTR DWORD, pInputControl:DWORD
ExitProcess PROTO, dwExitCode: DWORD

.data
    input               dd  ?       ; Inicializace celeho cisla pro prevod
    msb_pos             dd  0       ; Inicializace pomocne promenne pro ulozeni hlavniho bitu
    sign                dd  0       ; Inicializace promenne, ktera uchovava informaci o znamenku

    consoleOutHandler   dd  ?
    consoleInHandler    dd  ?
    result_digits       db  10 DUP(?)
    
    new_line            db  " ", 10, 0
    msg                 db  "Vysledek prevodu je: ", 13, 10, 0

    buffer              db	 128 DUP(?)
    bytes	            dd   ?

.code

; Podprogram pro zjisteni vstupu od uzivatele
ReadInput proc
    INVOKE GetStdHandle, STD_INPUT_HANDLE             ; Vezmi input handler
    mov consoleInHandler, eax
  
    ; Nacteni cisla z konzole
    INVOKE ReadConsoleA, consoleInHandler, offset buffer, lengthof buffer, offset bytes, 0
    
    mov eax, 0
    mov esi, offset buffer

    movzx edx, byte ptr [esi]
    cmp edx, 2Dh              ; Jestli je to "-"
    jne convert_loop          ; Pokud neni vstup zaporny, pokracuj standartnim cyklem

    inc esi                   ; Preskoc prvni znak
    mov [sign], 1

    ; Pretypovani na HEX cislo
    convert_loop:
	    movzx edx, byte ptr [esi]   ; Načíst ASCII znak do EDX

	    cmp edx, 0DH
	    je done

	    ; Provést konverzi na číslici a aktualizovat registr EAX
        sub dl, '0'                ; Konverze ASCII na numerickou hodnotu
        imul eax, eax, 10          ; Násobení aktuálního výsledku deseti
        add eax, edx               ; Přidání aktuální číslice k výsledku
	
	    inc esi                    ; Posunout ukazatel na další znak v řetězci
	    jmp convert_loop           ; Opakovat cyklus pro další znak

    done:
        mov [input], eax
    ret

ReadInput endp

; Podprogram pro vypsani vysledku a zpravy do konzole
ShowOutput proc
    ; Převod výsledku na řetězec
    lea edi, result_digits + 8
    mov ecx, 8
    mov ebx, 16

    convert_to_hex_loop:
        mov edx, 0
        div ebx
        add dl, '0'           ; Pro zjisteni ASCII reprezentace cisla
        cmp dl, '9'           ; Porovnani, jestli je hodnota '9' - pokud je vetsi, zvoli se pismeno
        jbe not_letter
        add dl, 7

    not_letter:
        mov [edi], dl
        dec edi
        loop convert_to_hex_loop

    mov byte ptr [edi], 0     ; Ukonceni retezce

    INVOKE GetStdHandle, STD_OUTPUT_HANDLE
    mov consoleOutHandler, eax

    INVOKE WriteConsoleA, consoleOutHandler, offset new_line, lengthof new_line, offset bytes, 0
    INVOKE WriteConsoleA, consoleOutHandler, offset msg, lengthof msg, offset bytes, 0
    INVOKE WriteConsoleA, consoleOutHandler, offset result_digits, 9, offset bytes, 0

    ret

ShowOutput endp

; Hlavni bod programu
main proc
    call ReadInput

    cmp eax, 0
    je done         ;pokud je vstup 0
    
    ; Inicializace
    xor eax, eax ; eax - vynulování registru
    xor ebx, ebx ; ebx - vynulování registru
    xor ecx, ecx ; ecx - vynulování registru
    xor edx, edx ; edx - vynulování registru
    xor esi, esi ; esi - vynulování registru

    ; Nacteni vstupu
    mov eax, input
      
    mov ebx, input
    shr ebx, 31

    xor ebx, ebx      ; Vynulovani registru ebx

    ; Hledani pozice nejvyznamnejsiho bitu (MSB)
    mov ecx, 31           ; Inicializace čítače
    mov edx, 80000000h    ; inicializave porovnavaci hodnoty

    search_msb:
        cmp edx, eax    ; porovnani edx s eax
        jbe bit_found   ; pokud eax je mensi nebo rovno edx, skoc na nalezeny bit
        shr edx, 1      ; pousn edx doprava
        dec ecx         ; dekrementace citace
        jmp search_msb  ; opakovani cyklu

    bit_found:
        mov [msb_pos], ecx  ; Ulozeni pozice MSB do pameti

    ; Odstraneni nejvyznamnejsiho bitu
    mov ebx, eax
    btr ebx, ecx       ; Odstranění bitu na pozici MSB
    mov eax, ebx

    ; Vypocet exponentu
    mov esi, [msb_pos]    ; Načtení pozice MSB do registru ESI
    add esi, 127          ; Přičtení 127 k pozici MSB pro výpočet exponentu

    ; Vypocet mantisy
    mov edx, 23       ; Nacteni 23 do registru edx - slouzi pro dopocteni nasledneho posunuti mantisy
    sub edx, ecx      ; Odecteni pozice hlavniho bitu od 23
    mov ecx, edx      ; Presunuti obsahu registru edx do registru ecx

    shl eax, cl       ; Vezme low byte z registru ecx - shl pracuje pouze s konstantou nebo hodnotou ulozenou v cl

    ; Posun exponentu
    shl esi, 23       ; Posun exponentu do spravne pozice

    ; Kombinace exponentu a mantisy
    xor ebx, ebx      ; Vynulovani registru ebx
    mov ebx, [sign]   ; Nacteni hodnoty v promenne sign
    shl ebx, 31
    or eax, ebx       ; Kombinace se znaminkem
    or eax, esi       ; Kombinace s exponentem

    done:
        call ShowOutput

    invoke  ExitProcess,0
main endp

end main
