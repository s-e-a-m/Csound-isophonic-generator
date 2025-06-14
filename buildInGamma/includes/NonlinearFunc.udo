; ===========================================================================
; NonlinearFunc.udo - Generatore di ritmi caotici
; ===========================================================================
; Genera valori ritmici con comportamento controllabile dal deterministico al caotico.
;
; Input:
;   iX          - Valore precedente (seme iniziale)
;   iMode       - Modalità di comportamento (0=convergente, 1=periodico, 2=caotico, 3=caos_vero)
;   iMinVal     - (Opzionale) Valore minimo di output (default = 1)
;   iMaxVal     - (Opzionale) Valore massimo di output (default = 35)
; Output:
;   iResult     - Nuovo valore ritmico generato (intero tra iMinVal e iMaxVal)
; ===========================================================================
opcode NonlinearFunc, i, ippo
  iX, iMode, iMinVal, iMaxVal xin
  
  ; Valori di default per min/max se non specificati
  iMinVal = (iMinVal == 0) ? 1 : iMinVal
  iMaxVal = (iMaxVal == 0) ? 35 : iMaxVal
  
  ; Assicurati che iX sia entro limiti sensati
  iX = limit(iX, 1, 100)
  
  iPI = 4 * taninv(1.0)  
  iTemp = 0
  
  if iMode == 0 then
    ; --- MODALITÀ 0: CONVERGENTE ---
    iR = 2.8
    iTemp = iR * iX * (1 - iX/40)
    
  elseif iMode == 1 then
    ; --- MODALITÀ 1: PERIODICA ---
    iP1 = sin(iX * iPI/18)
    iP2 = cos(iX * iPI/10)
    iTemp = abs(iP1 * iP2) * 20 + 10
    
  elseif iMode == 2 then
    ; --- MODALITÀ 2: CAOTICA DETERMINISTICA ---
    iR = 3.99
    iNormX = (iX % 100) / 100
    iNormX = limit(iNormX, 0.01, 0.99)
    iLogistic = iR * iNormX * (1 - iNormX)
    iNoise = random:i(-0.05, 0.05)
    iLogistic = limit(iLogistic + iNoise, 0, 1)
    iRange = iMaxVal - iMinVal + 1
    iTemp = iMinVal + (iLogistic * iRange)
    
  else
    ; --- MODALITÀ 3: CAOS VERO (DEFAULT) ---
    ; 1. Componente deterministica (60%)
    iSeed1 = (iX * 1.3) % 10
    iSeed2 = (iX * 0.7) % 10
    iSeed3 = (iX * 2.5) % 10
    iNonlinear1 = abs(sin(iSeed1 * iPI/5 + iSeed2))
    iNonlinear2 = abs(cos(iSeed2 * iPI/3 + iSeed3))
    iNonlinear3 = abs(tan(iSeed3 * iPI/7 + iSeed1) % 1)
    iDeterministic = (iNonlinear1 + iNonlinear2 + iNonlinear3) / 3
    
    ; 2. Componente casuale (40%)
    iRandom = random:i(0, 1)
    
    ; 3. Combina le componenti
    iMixRatio = 0.6
    iCombined = (iDeterministic * iMixRatio) + (iRandom * (1 - iMixRatio))
    
    ; 4. Perturbazione periodica
    iPerturbation = 0
    if (iX % 7 == 0) then 
      iPerturbation = random:i(-0.3, 0.3)
    endif
    
    ; 5. Mappa al range finale
    iRange = iMaxVal - iMinVal + 1
    iTemp = iMinVal + (iCombined * iRange) + (iPerturbation * iRange)
  endif
  
  ; Garantisci che il risultato sia un intero valido nell'intervallo richiesto
  iResult = max(iMinVal, min(iMaxVal, round(iTemp)))
  
  xout iResult
endop
