<CsoundSynthesizer>
<CsOptions>
-o "test.aif"
</CsOptions>

<CsInstruments>
sr = 44100
ksmps = 64
nchnls = 2
0dbfs = 1.0

; ===================================================================
;  CALIBRAZIONE DINAMICA CENTRALIZZATA IN CSOUND
; ===================================================================
; Qui definiamo la mappatura Dinamica -> Indice che useremo in Python
; 0='ppp', 1='pp', 2='p', 3='mf', 4='f', 5='ff', 6='fff'

; Parametri di calibrazione (il tuo pannello di controllo Csound)
giPhonFFF    init 100   ; Livello di 'fff' in Phon
giPhonStep   init 6    ; Step di Phon tra le dinamiche

giDbfsFFF    init -30    ; Livello di 'fff' in dBFS (a 1000 Hz)
giDbfsStep   init 6     ; Step di dBFS tra le dinamiche

; Tabelle di mappatura (i nostri "dizionari")
giNumDynamics = 7
giDynamicsToPhon ftgen 0, 0, giNumDynamics, -2, \
    giPhonFFF - (6 * giPhonStep),\  ; 0: ppp
    giPhonFFF - (5 * giPhonStep),\  ; 1: pp
    giPhonFFF - (4 * giPhonStep),\  ; 2: p
    giPhonFFF - (3 * giPhonStep),\  ; 3: mf
    giPhonFFF - (2 * giPhonStep),\  ; 4: f
    giPhonFFF - (1 * giPhonStep),\  ; 5: ff
    giPhonFFF                      ; 6: fff

giDynamicsToDbfsRef ftgen 0, 0, giNumDynamics, -2, \
    giDbfsFFF - (6 * giDbfsStep),\  ; 0: ppp
    giDbfsFFF - (5 * giDbfsStep), \ ; 1: pp
    giDbfsFFF - (4 * giDbfsStep),\  ; 2: p
    giDbfsFFF - (3 * giDbfsStep),\  ; 3: mf
    giDbfsFFF - (2 * giDbfsStep),\  ; 4: f
    giDbfsFFF - (1 * giDbfsStep),\  ; 5: ff
    giDbfsFFF                      ; 6: fff

; ===================================================================
;  UDO HELPER: GetDynamicParams
; ===================================================================
opcode GetDynamicParams, ii, i
    iDynamicIndex   xin
    iPhonValue      table iDynamicIndex, giDynamicsToPhon
    iDbfsRefValue   table iDynamicIndex, giDynamicsToDbfsRef
    xout            iPhonValue, iDbfsRefValue
endop

opcode GetDynamicParams, kk, k
    kDynamicIndex   xin
    kPhonValue      table kDynamicIndex, giDynamicsToPhon
    kDbfsRefValue   table kDynamicIndex, giDynamicsToDbfsRef
    xout            kPhonValue, kDbfsRefValue
endop

; ===================================================================
;  TABELLE ISO 226:2003
; ===================================================================
giIsoFreqs ftgen 1, 0, 32, -2, 20, 25, 31.5, 40, 50, 63, 80, 100, 125, 160, 200, 250, 315, 400, 500, 630, 800, 1000, 1250, 1600, 2000, 2500, 3150, 4000, 5000, 6300, 8000, 10000, 12500
giAf       ftgen 2, 0, 32, -2, 0.532, 0.506, 0.480, 0.455, 0.432, 0.409, 0.387, 0.367, 0.349, 0.330, 0.315, 0.301, 0.288, 0.276, 0.267, 0.259, 0.253, 0.250, 0.246, 0.244, 0.243, 0.243, 0.243, 0.242, 0.242, 0.245, 0.254, 0.271, 0.301
giLu       ftgen 3, 0, 32, -2, -31.6, -27.2, -23.0, -19.1, -15.9, -13.0, -10.3, -8.1, -6.2, -4.5, -3.1, -2.0, -1.1, -0.4, 0.0, 0.3, 0.5, 0.0, -2.7, -4.1, -1.0, 1.7, 2.5, 1.2, -2.1, -7.1, -11.2, -10.7, -3.1
giTf       ftgen 4, 0, 32, -2, 78.5, 68.7, 59.5, 51.1, 44.0, 37.5, 31.5, 26.5, 22.1, 17.9, 14.4, 11.4, 8.6, 6.2, 4.4, 3.0, 2.2, 2.4, 3.5, 1.7, -1.3, -4.2, -6.0, -5.4, -1.5, 6.0, 12.6, 13.9, 12.3

; ===================================================================
;  UDO PhonToSpl_i
; ===================================================================
opcode PhonToSpl_i, i, ii
    iphon, ifreq    xin
    ilog_freq       log             ifreq
    ilog_min_freq   log             20
    ilog_max_freq   log             12500
    iindex          linlin          ilog_freq, ilog_min_freq, ilog_max_freq, 0, 28
    iaf             tablei          iindex, giAf, 1
    ilu             tablei          iindex, giLu, 1
    itf             tablei          iindex, giTf, 1
    iterm1          =               4.47e-3 * (pow(10, 0.025 * iphon) - 1.15)
    iterm2_exp      =               (itf + ilu) / 10.0 - 9
    iterm2          =               pow(0.4 * pow(10, iterm2_exp), iaf)
    iaf_value       =               iterm1 + iterm2
    if iaf_value <= 0 then
        ispl        =               itf + (iphon / 40.0) * 20
    else
        ispl        =               (10.0 / iaf) * log10(iaf_value) - ilu + 94.0
    endif
    if abs(ifreq - 1000) < 0.1 then
        ispl = iphon
    endif
    xout            ispl
endop

; ===================================================================
;  UDO MOTORE: GetIsoAmp
; ===================================================================
opcode GetIsoAmp, i, ii
    iFrequency, iDynamicIndex xin
    iPhonLevel, iDbfsRef1kHz GetDynamicParams iDynamicIndex
    iDbSplTarget    PhonToSpl_i     iPhonLevel, iFrequency
    iDbSplRef1kHz   =               iPhonLevel
    iFrequencyOffset = iDbSplTarget - iDbSplRef1kHz
    iFinalDbfs      = iDbfsRef1kHz + iFrequencyOffset
    iFinalAmp       = ampdbfs(iFinalDbfs)
    xout iFinalAmp
endop

; ===================================================================
;  STRUMENTI DI TEST
; ===================================================================

; Strumento 1: Sinusoide semplice con sistema isofonicoù
instr 1
    iFreq       = p4
    iDynIndex   = p5  ; 0=ppp, 1=pp, 2=p, 3=mf, 4=f, 5=ff, 6=fff
    
    ; Calcola l'ampiezza usando il tuo sistema
    iAmp        GetIsoAmp iFreq, iDynIndex
    
    ; Genera il suono
    aOsc        oscili iAmp, iFreq, 1
    aEnv        linseg 0, 0.1, 1, p3-0.2, 1, 0.1, 0
    aOut        = aOsc * aEnv
    
    ; Output stereo
    outs aOut, aOut
    
    ; Debug: stampa i valori calcolati
    printf_i "Freq: %7.2f Hz | Dyn: %d | Amp: %8.6f | dB: %6.2f\n", 1, iFreq, iDynIndex, iAmp, 20*log10(iAmp)
endin

; Strumento 2: Test di debug dettagliato
instr 2
    iFreq       = p4
    iDynIndex   = p5
    
    ; Recupera i parametri della dinamica
    iPhon, iDbfsRef GetDynamicParams iDynIndex
    
    ; Calcola il dB SPL target
    iDbSplTarget PhonToSpl_i iPhon, iFreq
    
    ; Calcola l'offset e l'ampiezza finale
    iOffset     = iDbSplTarget - iPhon
    iFinalDbfs  = iDbfsRef + iOffset
    iFinalAmp   = ampdbfs(iFinalDbfs)
    
    ; Stampa analisi completa
    printf_i "\n=== ANALISI DETTAGLIATA ===\n", 1
    printf_i "Frequenza: %.2f Hz | Dinamica: %d\n", 1, iFreq, iDynIndex
    printf_i "Phon target: %.1f | dBFS ref (1kHz): %.1f\n", 1, iPhon, iDbfsRef
    printf_i "dB SPL target: %.2f | Offset freq: %+.2f\n", 1, iDbSplTarget, iOffset
    printf_i "dBFS finale: %.2f | Ampiezza: %.6f\n", 1, iFinalDbfs, iFinalAmp
    printf_i "=============================\n", 1
    
    ; Genera il suono (opzionale, commentato per non sovrapporre)
    ; aOsc        oscili iFinalAmp, iFreq, 1
    ; aEnv        linseg 0, 0.1, 1, p3-0.2, 1, 0.1, 0
    ; outs aOsc*aEnv, aOsc*aEnv
endin

; Strumento 3: Test comparativo tra dinamiche
instr 3
    iFreq       = p4
    
    printf_i "\n=== TEST COMPARATIVO FREQ %.2f Hz ===\n", 1, iFreq
    printf_i "Dyn | Phon | dBFS_ref | dB_SPL | Offset | dBFS_final | Amplitude\n", 1
    printf_i "----|------|----------|--------|--------|------------|----------\n", 1
    
    ; Testa tutte le dinamiche per la stessa frequenza
    iIndex = 0
    while iIndex < 7 do
        iPhon, iDbfsRef GetDynamicParams iIndex
        iDbSplTarget PhonToSpl_i iPhon, iFreq
        iOffset = iDbSplTarget - iPhon
        iFinalDbfs = iDbfsRef + iOffset
        iFinalAmp = ampdbfs(iFinalDbfs)
        
        printf_i " %d  | %4.0f | %8.1f | %6.2f | %+6.2f | %10.2f | %8.6f\n", 1, \
                 iIndex, iPhon, iDbfsRef, iDbSplTarget, iOffset, iFinalDbfs, iFinalAmp
        
        iIndex += 1
    od
    printf_i "=========================================================\n", 1
endin

</CsInstruments>

<CsScore>
; ===================================================================
;  SCORE DI TEST
; ===================================================================
; Tabella per oscillatori
f1 0 4096 10 1


; Test 1: Sequenza di dinamiche su 1000 Hz (frequenza di riferimento)
; Su 1000 Hz, dB SPL = Phon, quindi dovremmo vedere una progressione lineare
;   p1  p2  p3  p4     p5
;   ins time dur freq  dyn
i1   0   1.5  1000    0   ; ppp
i1   1.6 1.5  1000    1   ; pp  
i1   3.2 1.5  1000    2   ; p
i1   4.8 1.5  1000    3   ; mf
i1   6.4 1.5  1000    4   ; f
i1   8.0 1.5  1000    5   ; ff
i1   9.6 1.5  1000    6   ; fff

; Test 2: Stessa dinamica (fff) su frequenze diverse
; Qui dovremmo sentire volumi percettivamente uguali ma ampiezze diverse
i1   12  1.5  100     6   ; fff @ 100 Hz (grave)
i1   14  1.5  440     6   ; fff @ 440 Hz (La)
i1   16  1.5  1000    6   ; fff @ 1000 Hz (riferimento)
i1   18  1.5  2000    6   ; fff @ 2000 Hz 
i1   20  1.5  4000    6   ; fff @ 4000 Hz (acuto)

; Test 3: Frequenze gravi con dinamiche diverse
; Le frequenze basse richiedono più energia per essere percepite allo stesso volume
i1   23  1.5  60      2   ; p @ 60 Hz
i1   25  1.5  60      4   ; f @ 60 Hz  
i1   27  1.5  60      6   ; fff @ 60 Hz

; Test 4: Frequenze acute con dinamiche diverse
i1   30  1.5  8000    2   ; p @ 8000 Hz
i1   32  1.5  8000    4   ; f @ 8000 Hz
i1   34  1.5  8000    6   ; fff @ 8000 Hz

; Test di debug: analisi dettagliata (solo output testuale)
i2   37  0.1  440     3   ; Analisi mf @ 440 Hz
i2   37.2 0.1 100     6   ; Analisi fff @ 100 Hz
i2   37.4 0.1 4000    1   ; Analisi pp @ 4000 Hz

; Test comparativo: tutte le dinamiche su frequenze caratteristiche
i3   38   0.1  100    0   ; Confronto dinamiche @ 100 Hz
i3   38.2 0.1  1000   0   ; Confronto dinamiche @ 1000 Hz  
i3   38.4 0.1  4000   0   ; Confronto dinamiche @ 4000 Hz

; Test finale: accordo isofonica
; Tutte le note dovrebbero sembrare allo stesso volume (dinamica mf=3)
i1   40  4    261.63  3   ; Do
i1   40  4    329.63  3   ; Mi
i1   40  4    392.00  3   ; Sol
i1   40  4    523.25  3   ; Do ottava

e
</CsScore>
</CsoundSynthesizer>