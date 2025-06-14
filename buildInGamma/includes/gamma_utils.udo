; ====================================================================
; gamma_utils.udo
; Versione filtrata di utils.udo per il generatore di gamma.
; Contiene solo gli opcode strettamente necessari.
; ====================================================================

; Opcode per convertire da linear a dB
opcode linear2db, i, i
  iLinear xin
  iDB = 20 * log10(iLinear)
  xout iDB
endop

; Opcode per convertire da dB a linear
opcode db2linear, i, i
  iDB xin
  iLinear = 10 ^ (iDB / 20)
  xout iLinear
endop

; Opcode per arrotondare a 3 decimali
opcode round3, i, i
  iValue xin
  iMultiplier = 1000
  iRounded = int(iValue * iMultiplier + 0.5) / iMultiplier
  xout iRounded
endop

; Opcode che trova il valore minimo non-zero in una tabella
; Utilizzato da validator.udo per controllare la durata.
opcode minTableNonZero, i, i
    iTableNum xin
    
    ; Ottieni la dimensione della tabella
    iSize = ftlen(iTableNum)
    
    ; Inizializza con un valore molto grande
    iMin = 1e10
    iFoundNonZero = 0
    
    indx = 0
    while indx < iSize do
        iVal = tab_i(indx, iTableNum)
        if iVal != 0 && iVal < iMin then
            iMin = iVal
            iFoundNonZero = 1
        endif
        indx += 1
    od
    
    if iFoundNonZero == 0 then
        prints "ERRORE CRITICO: Tutti i valori nella tabella dei ritmi sono 0. Impossibile procedere.\n"
        exitnow
    endif
    
    xout iMin
endop
