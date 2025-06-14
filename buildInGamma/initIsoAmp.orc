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
;  TABELLE ISO 226:2003 (Necessarie per l'UDO IsoAmp)
; ===================================================================
giIsoFreqs ftgen 0, 0, 32, -2, 20, 25, 31.5, 40, 50, 63, 80, 100, 125, 160, 200, 250, 315, 400, 500, 630, 800, 1000, 1250, 1600, 2000, 2500, 3150, 4000, 5000, 6300, 8000, 10000, 12500
giAf       ftgen 0, 0, 32, -2, 0.532, 0.506, 0.480, 0.455, 0.432, 0.409, 0.387, 0.367, 0.349, 0.330, 0.315, 0.301, 0.288, 0.276, 0.267, 0.259, 0.253, 0.250, 0.246, 0.244, 0.243, 0.243, 0.243, 0.242, 0.242, 0.245, 0.254, 0.271, 0.301
giLu       ftgen 0, 0, 32, -2, -31.6, -27.2, -23.0, -19.1, -15.9, -13.0, -10.3, -8.1, -6.2, -4.5, -3.1, -2.0, -1.1, -0.4, 0.0, 0.3, 0.5, 0.0, -2.7, -4.1, -1.0, 1.7, 2.5, 1.2, -2.1, -7.1, -11.2, -10.7, -3.1
giTf       ftgen 0, 0, 32, -2, 78.5, 68.7, 59.5, 51.1, 44.0, 37.5, 31.5, 26.5, 22.1, 17.9, 14.4, 11.4, 8.6, 6.2, 4.4, 3.0, 2.2, 2.4, 3.5, 1.7, -1.3, -4.2, -6.0, -5.4, -1.5, 6.0, 12.6, 13.9, 12.3


; ===================================================================
;  UDO HELPER: GetDynamicParams
;  Prende un indice di dinamica e restituisce i suoi valori Phon e dBFS di riferimento.
;  Output: kPhon, kDbfsRef (o iPhon, iDbfsRef se usato a i-rate)
; ===================================================================
opcode GetDynamicParams, ii, i
    iDynamicIndex   xin
    
    ; Legge i valori dalle tabelle di mappatura globali
    iPhonValue      table iDynamicIndex, giDynamicsToPhon
    iDbfsRefValue   table iDynamicIndex, giDynamicsToDbfsRef
    
    xout            iPhonValue, iDbfsRefValue
endop

opcode GetDynamicParams, kk, k ; Versione a k-rate, se dovesse servire
    kDynamicIndex   xin
    kPhonValue      table kDynamicIndex, giDynamicsToPhon
    kDbfsRefValue   table kDynamicIndex, giDynamicsToDbfsRef
    xout            kPhonValue, kDbfsRefValue
endop



; ===================================================================
; UDO: Interp (Simula np.interp per l'interpolazione lineare)
; Prende in input:
; - iX: Il punto in cui interpolare (es. la frequenza)
; - iXp_tab: La tabella dei punti X noti (es. giIsoFreqs)
; - iFp_tab: La tabella dei punti Y noti (es. giAf)
; ===================================================================
opcode Interp, i, iii
    iX, iXp_tab, iFp_tab    xin
    
    iLen      ftlen    iXp_tab
    iIndex    init     0
    iFound    init     0
    
    ; Trova l'indice giusto nella tabella delle frequenze
    while iIndex < iLen && iFound == 0 do
        iCurrFreq   table iIndex, iXp_tab
        if iX <= iCurrFreq then
            iFound = 1
        else
            iIndex += 1
        endif
    od
    
    ; Gestione dei casi limite (frequenza fuori range)
    if iIndex == 0 then
        iY table 0, iFp_tab ; Frequenza <= della prima
        igoto end
    elseif iIndex >= iLen then
        iY table iLen - 1, iFp_tab ; Frequenza >= dell'ultima
        igoto end
    else
        ; Interpolazione lineare
        iX0       table    iIndex - 1, iXp_tab
        iX1       table    iIndex, iXp_tab
        iY0       table    iIndex - 1, iFp_tab
        iY1       table    iIndex, iFp_tab
        
        ; Evita divisione per zero se i punti sono duplicati
        if iX1 == iX0 then
            iY = iY0
        else
            iY = iY0 + (iX - iX0) * (iY1 - iY0) / (iX1 - iX0)
        endif
        end:
        xout iY
    endif
endop

; UDO per calcolare dB SPL da Phon (helper per IsoAmp)
opcode PhonToSpl_i, i, ii
    iphon, ifreq    xin
        
    ; ########## MODIFICA CRUCIALE ##########
    ; Usiamo il nostro nuovo UDO di interpolazione lineare, replicando Python
    iaf             Interp  ifreq, giIsoFreqs, giAf
    ilu             Interp  ifreq, giIsoFreqs, giLu
    itf             Interp  ifreq, giIsoFreqs, giTf
    
    ; Il resto della formula è identico al tuo codice Python
    iterm1          =       4.47e-3 * (pow(10, 0.025 * iphon) - 1.15)
    iterm2_exp      =       (itf + ilu) / 10.0 - 9
    iterm2          =       pow(0.4 * pow(10, iterm2_exp), iaf)
    iaf_value       =       iterm1 + iterm2
    
    if iaf_value <= 0 then
        ispl        =       itf + (iphon / 40.0) * 20
    else
        ispl        =       (10.0 / iaf) * log10(iaf_value) - ilu + 94.0
    endif
    
    if abs(ifreq - 1000) < 0.1 then
        ispl = iphon
    endif
    
    xout            ispl
endop


; ===================================================================
;  UDO MOTORE: GetIsoAmp (Get Isofonic Amplitude)
;  Calcola l'ampiezza lineare isofonica finale partendo solo da
;  frequenza e indice di dinamica.
;  Questo UDO è l'equivalente Csound del tuo vecchio metodo Python "generate_note".
; ===================================================================
opcode GetIsoAmp, i, ii
    iFrequency, iDynamicIndex xin
    
    ; 1. Recupera i parametri di base per la dinamica data
    iPhonLevel, iDbfsRef1kHz GetDynamicParams iDynamicIndex
    
    ; 2. Calcola il dB SPL target per la frequenza e il livello phon dati
    iDbSplTarget    PhonToSpl_i     iPhonLevel, iFrequency
    
    ; 3. Il dB SPL di riferimento a 1kHz è per definizione uguale al livello Phon
    iDbSplRef1kHz   =               iPhonLevel ; Questo è ridondante ma chiarisce la logica
    
    ; 4. Calcola l'offset di compensazione
    iFrequencyOffset = iDbSplTarget - iDbSplRef1kHz
    
    ; 5. Applica l'offset al livello dBFS di riferimento
    iFinalDbfs      = iDbfsRef1kHz + iFrequencyOffset
    
    ; 6. Converti il dBFS finale in ampiezza lineare
    iFinalAmp       = ampdbfs(iFinalDbfs)
    
    xout iFinalAmp
endop

