sr=96000
ksamps =32
nchnls=2
0dbfs = 1


instr 1
iamp=p4
ifreq= p5
asinusoide oscil iamp,ifreq
kenv cosseg 0, p3/60, 1, p3-p3/30, 1, p3/60, 0
aout = kenv*asinusoide
outs aout,aout
endin

; Strumento 2: Nota con inviluppo dinamico (NUOVO)
instr 2
    idur = p3
    iamp_start = p4 ; Ampiezza di inizio (calcolata da Python)
    iamp_end = p5   ; Ampiezza di fine (calcolata da Python)
    ifreq = p6      ; Frequenza (costante in questo esempio)

    ; Crea un inviluppo di ampiezza lineare da iamp_start a iamp_end
    ; 'line' è perfetto per questo
    ;kamp_env line iamp_start, idur, iamp_end
    
    ; Puoi usare anche inviluppi esponenziali per un crescendo/decrescendo più naturale
    kamp_env expseg iamp_start, idur, iamp_end
    
    ; Genera il segnale audio
    asig oscili kamp_env, ifreq
    
    ; Applica un breve inviluppo di fade-in/out per evitare click
    kfade linseg 0, 0.01, 1, idur - 0.02, 1, 0.01, 0
    
    outs asig * kfade, asig * kfade
endin