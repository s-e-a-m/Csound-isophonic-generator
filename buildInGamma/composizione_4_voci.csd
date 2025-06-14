
<CsoundSynthesizer>

<CsOptions>
-o composizione_4_voci.wav -W -d
</CsOptions>

<CsInstruments>
sr = 44100
ksmps = 32
nchnls = 2
0dbfs = 1.0
#define SQRT2 #1.4142135623730951#
#define MAX_AMP #0.999#
#define FONDAMENTALE #32#
#define OTTAVE #10#
#define INTERVALLI #200#
#define REGISTRI #50#
#define M_PI #3.141592653589793#
gSdirSco = "./sco/"
gi_Index init 1
gi_eve_attacco ftgen 0, 0, 2^20, -2, 0
gi_Intonazione ftgen 0, 0, $OTTAVE*$INTERVALLI+1, -2, 0

#include "includes/gamma_utils.udo"
#include "includes/pfield_comp.udo"
#include "includes/NonlinearFunc.udo"
#include "includes/GenPythagFreqs.udo"
#include "initIsoAmp.orc"
#include "includes/eventoSonoro.orc"
#include "includes/voce.orc"

instr Init
    i_Res GenPythagFreqs $FONDAMENTALE, $INTERVALLI, $OTTAVE, gi_Intonazione
    if i_Res == 0 then
        prints "ERRORE: Inizializzazione del sistema pitagorico fallita!"
    endif
    ires system_i 1, sprintf("mkdir %s", gSdirSco)
    turnoff
endin

</CsInstruments>

<CsScore>
; Durata totale definita dal Python script
f1 0 4096 10 1
f2 0 1024 6 0 512 0.5 512 1 ; Envelope per il suono
; --- TABELLE GENERATE ---
; --- Tabelle di Ritmo e Posizione ---
f 1000 0 5 -2 15 4 3 13 14
f 1001 0 5 -2 0 1 2 3 4
f 1002 0 5 -2 15 13 9 11 10
f 1003 0 5 -2 0 1 2 3 4
f 1004 0 8 -2 21 20 20 18 30 25 16 13
f 1005 0 8 -2 0 1 2 3 4 5 6 7
f 1006 0 5 -2 11 14 9 14 4
f 1007 0 5 -2 0 1 2 3 0

; -----------------------

i "Init" 0 0.1

; --- VOCI GENERATE ---
; --- Istanze dello Strumento Voce ---
;	p1		p2	p3	p4	p5		p6	p7	p8	p9	p10
;	Instr	Start	Dur		RhyTab	HarmDur		DynIdx	Oct	Reg	PosTab	ID
i "Voce"	0.100	25.000	1000	2.371		2		2	10	1001	1
i "Voce"	10.100	30.000	1002	2.582		4		6	29	1003	2
i "Voce"	20.100	15.000	1004	1.650		6		4	8	1005	3
i "Voce"	5.100	40.000	1006	2.081		0		4	45	1007	4

; --------------------


</CsScore>

</CsoundSynthesizer>
