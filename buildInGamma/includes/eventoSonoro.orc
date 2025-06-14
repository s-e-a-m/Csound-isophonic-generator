; ====================================================================
; eventoSonoro.orc (Versione pulita per il generatore di gamma)
; Strumento di sintesi spazializzata.
; ====================================================================

#define DEBUG_Evento_print_Pfields #
   if (int(i_debug) >=2) then
      Snamefile sprintf "%sComp%d.sco", gSdirSco, id_comportamento
      prints "\n\t\t\tevento sonoro %d del comportamento %d",id_evento, id_comportamento
      prints "\n\t\t\t\tattacco: %.3f\n\t\t\t\tdurata: %.3f\n\t\t\t\tamp: %.3f\n\t\t\t\tfreq1: %.3f\n\t\t\t\twz: %.3f\n\t\t\t\tdir: %.3f\n\t\t\t\tHR: %.3f\n\t\t\t\tfreq2: %.3f\n\t\t\t\tifn: %.3f\n\t\t\t\tid_evento: %.3f\n\n", p2, p3, p4, p5, p6, signum(p6),p7, p8, p9, p10    
      if (id_evento%100==0) then
      ;fprints Snamefile,"\n\t;\t\t\t\t\t\tattacco:\tdurata:\t\tamp:\t\tfreq1:\t\t\twz:\t\t\tdir:\t\tHR:\t\t\t\tfreq2:\t\tifn:\t\tid_evento:"
      endif
      fprints Snamefile,"\n\n\t;\t\t\t\t\t\tattacco:\tdurata:\t\tamp:\t\tfreq1:\t\t\t\twz:\t\tHR:\t\tfreq2:\t\t\tifn:\tid_evento:"
      fprints Snamefile,"\n\ti \"eventoSonoro\"\t\t%.3f\t\t%.3f\t\t%.3f\t\t%f\t\t\t%d\t\t%d\t\t%f\t\t%d\t\t%d", p2, p3, p4, p5, p6, p7, p8, p9, p10  
      SentireSco sprintf "%sAll.sco", gSdirSco
      fprints SentireSco,"\n\n\t; [comp %d]\t\t\t\tattacco:\tdurata:\t\tamp:\t\tfreq1:\t\t\twz:\t\tHR:\t\tfreq2:\t\t\tifn:\tid_evento:", p11
      fprints SentireSco,"\n\ti \"eventoSonoro\"\t\t%.3f\t\t%.3f\t\t%f\t\t%f\t\t%d\t\t%d\t\t%f\t\t%d\t\t%d", p2, p3, p4, p5, p6, p7, p8, p9, p10  
   endif#

instr eventoSonoro
    ;--------------------------------------------------------------
    ; Parameter Initialization
    ;--------------------------------------------------------------
    iamp = p4
    id_evento=p10
    id_comportamento=p11
    i_debug=2

    $DEBUG_Evento_print_Pfields

    ifreq1 = limit(p5, 20, sr/2)
    ifreq2 = limit(p8, 20, sr/2)
    
    iwhichZero = abs(p6)
    idirection = (p6 >= 0 ? 1 : -1)
    
    iHR = max(1, abs(p7))
    iPeriod = $M_PI * 2 / iHR
    
    iradi = (iwhichZero > 0 ? (iwhichZero - 1) * iPeriod : 0)

    ;--------------------------------------------------------------
    ; Position and Envelope Generation
    ;--------------------------------------------------------------
    kndx line 0, p3, 1
    ktab tab kndx, p9, 1
    
    krad = iradi + (ktab * iPeriod * idirection)
    kEnv = abs(sin(krad * iHR / 2))

    ;--------------------------------------------------------------
    ; Sound Generation and Spatialization
    ;--------------------------------------------------------------
    kfreq = ifreq1 ; Semplificato a frequenza costante per ora
    
    asig poscil3 iamp, kfreq
    asigEnv = asig * kEnv
    
    kMid = cos(krad)
    kSide = sin(krad)
    
    aMid = kMid * asigEnv 
    aSide = kSide * asigEnv
    
    ;--------------------------------------------------------------
    ; Output Stage
    ;--------------------------------------------------------------
    aL = (aMid + aSide) / $SQRT2
    aR = (aMid - aSide) / $SQRT2
    
    outs aL, aR
endin
