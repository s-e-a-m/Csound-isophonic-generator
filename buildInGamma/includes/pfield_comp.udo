; ====================================================================
; validator.udo (Versione pulita per il generatore di gamma)
; Contiene gli opcode per la validazione dei parametri.
; ====================================================================

; UDO per validare i ritmi (devono essere positivi)
opcode validateRhythm, i, i
  i_Rhythm xin
  i_Len = ftlen(i_Rhythm)
  i_Index = 0
  i_Res = 1
  while i_Index < i_Len do
    if (tab_i(i_Index, i_Rhythm) <= 0) then
      i_Res = 0
      goto end
    endif
    i_Index += 1
  od
  end:
  xout i_Res
endop

; UDO per validare la relazione tra durata totale e durata armonica
opcode validateDuration, i, iii
  i_Dur, iHarmDur, i_Rhythm xin
  
  if i_Dur <= 0 || iHarmDur <= 0 then
    goto end
  endif
  
  iMinRhythmValue minTableNonZero i_Rhythm
  iMinEventDuration = iHarmDur / iMinRhythmValue
  i_Res = i_Dur > iMinEventDuration ? 1 : 0
  end:
  xout i_Res
endop

; UDO per calcolare l'ampiezza massima consentita
opcode calculateMaxAmplitude, i, ii
  i_Ottava, i_Registro xin
  
  if i_Ottava == 0 then
    i_MaxAmp = -6
  elseif i_Ottava <= 3 then
    i_Slope = (-12 - (-6)) / (3 - 1)
    i_MaxAmp = -6 + i_Slope * (i_Ottava - 1) - (i_Registro - 1) * 0.3
  else
    i_Progress = (i_Ottava - 3) / (10 - 3)
    i_SmoothProgress = (1 - cos(i_Progress * $M_PI)) / 2
    i_BaseAmp = -12 + (-25 - (-12)) * i_SmoothProgress
    i_RegisterInfluence = (i_Registro - 1) * 0.2
    i_MaxAmp = i_BaseAmp - i_RegisterInfluence < -12 ? i_BaseAmp - i_RegisterInfluence : -12
  endif
  
  xout i_MaxAmp
endop

; UDO per validare l'ampiezza
opcode validateAmplitude, i, iii
  i_Amp, i_Ottava, i_Registro xin
  i_MaxAmp = calculateMaxAmplitude(i_Ottava, i_Registro)
  xout (i_Amp <= i_MaxAmp ? 1 : 0)
endop

; UDO per validare ottava e registro
opcode validateFrequency, i, ii
  i_Ottava, i_Registro xin
  xout (i_Ottava >= 0 && i_Ottava <= 10 && i_Registro >= 1 && i_Registro <= 10 ? 1 : 0)
endop


; Opcode per calcolare l'ampiezza spaziale
opcode calcAmpiezza, i, iii
  iAmpDB, iRhythm, iDampening xin
  
  ; Converti da dB a linear
  iAmpLinear db2linear iAmpDB
  ;!!!
  ; ampdbfs - usare opcode già fatto per ottimizzazione in init time
  ;!!!
  
  ; Calcola il tempo basato sul ritmo (t = π/rhythm)
  iTime = $M_PI / iRhythm
  
  ; Calcola l'ampiezza usando la formula della sinusoide smorzata
  ; amp * sin(0.5 * t) * exp(gamma * t)
  iSine = sin(0.5 * iTime)
  iExp = exp(iDampening * iTime)
  iResult = iAmpLinear * iSine * iExp
  
  ; Converti il risultato in dB e arrotonda a 3 decimali
  iResultDB = linear2db(iResult)
  ;!!!
  ; dbfsamp - usare opcode già fatto per ottimizzazione in init time
  ;!!!
  
  iResultRounded round3 iResultDB
  
  xout iResultRounded
endop

opcode calcFrequenza, i, iiiiii
    i_Ottava, i_Registro, i_RitmoCorrente, i_TblNum, i_Intervalli, i_Registri xin
        
    ; Calculate octave register
    i_Indice_Ottava = int(i_Ottava * i_Intervalli)
    ; Calculate interval offset within the octave
    i_OffsetIntervallo = i_Indice_Ottava + int(((i_Registro * i_Intervalli) / i_Registri))
    
    ; Get the frequency from the table using the calculated offset
    i_Freq table i_OffsetIntervallo + i_RitmoCorrente, i_TblNum
        
    xout i_Freq
endop
