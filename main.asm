.386
.model  flat,stdcall
.stack  1024
ExitProcess proto,dwExitCode:dword


.data
    input           dd  20000     ; Inicializace celeho cisla pro prevod
    msb_pos         dd  0       ; Inicializace pomocne promenne pro ulozeni hlavniho bitu
    result          dd  0       ; Inicializace promenne, do ktere se ulozi vysledny prevod

.code
main proc c
      ; Inicializace
      xor eax, eax ; eax - vynulování registru
      xor ebx, ebx ; ebx - vynulování registru
      xor ecx, ecx ; ecx - vynulování registru
      xor edx, edx ; edx - vynulování registru
      xor esi, esi ; esi - vynulování registru

      ; Nacteni vstupu
      mov eax, input

      ; Hledani pozice nejvyznamnejsiho bity (MSB)
      mov ecx, 31           ; Inicializace èítaèe
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
      btr ebx, ecx       ; Odstranìní bitu na pozici MSB
      mov eax, ebx

      ; Vypocet exponentu
      mov esi, [msb_pos]    ; Naètení pozice MSB do registru ESI
      add esi, 127          ; Pøiètení 127 k pozici MSB pro výpoèet exponentu

      ; Vypocet mantisy
      mov edx, 23       ; Nacteni 23 do registru edx - slouzi pro dopocteni nasledneho posunuti mantisy
      sub edx, ecx      ; Odecteni pozice hlavniho bitu od 23
      mov ecx, edx      ; Presunuti obsahu registru edx do registru ecx

      shl eax, cl       ; Vezme low byte z registru ecx - shl pracuje pouze s konstantou nebo hodnotou ulozenou v cl

      ; Posun exponentu
      shl esi, 23       ; Posun exponentu do spravne pozice

      ; Kombinace exponentu a mantisy
      or eax, esi       ; Kombinace s ER4 (exponentem)

      ; Ulozeni vysledky do pameti
      mov [result], eax     ; Ulozeni vysledku do promenne result

    invoke  ExitProcess,0
main endp

end main