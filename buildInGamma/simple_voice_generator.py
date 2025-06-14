#!/usr/bin/env python3
"""
Simple Voice Generator for Csound (v1.0)
=========================================
Questo script genera una composizione semplice chiamando N istanze
dello strumento Csound 'Voce'.
Permette di controllare parametri chiave come il numero di voci,
il loro timing, e i loro registri musicali.

Lo scopo è testare l'interazione tra più comportamenti 'Voce'
in un ambiente controllato.
"""

import random
from pathlib import Path

# =============================================================================
# CLASSE SCORE BUILDER (Il nostro compositore)
# =============================================================================
class ScoreBuilder:
    """
    Costruisce lo score Csound gestendo la generazione delle note
    e la creazione delle tabelle di dati necessarie.
    """
    def __init__(self):
        self.events = []
        self.rhythm_tables = {}
        self.next_table_id = 1000  # Iniziamo da un ID alto per evitare conflitti
        self.current_time = 0.0

        # Mappa per tradurre la dinamica in un indice per Csound
        self.dynamic_to_index = {
            'ppp': 0, 'pp': 1, 'p': 2, 'mf': 3, 'f': 4, 'ff': 5, 'fff': 6
        }

    def add_voice(self,
                  start_time,
                  duration,
                  dynamic,
                  octave_range,
                  register_range,
                  num_rhythms=5,
                  rhythm_value_range=(2, 16)):
        """
        Aggiunge una singola istanza (un "comportamento") dello strumento Voce.

        Args:
            start_time (float): Tempo di inizio dell'evento.
            duration (float): Durata totale del comportamento.
            dynamic (str): La dinamica desiderata (es. 'ppp', 'f', 'fff').
            octave_range (tuple): Range (min, max) da cui scegliere l'ottava.
            register_range (tuple): Range (min, max) da cui scegliere il registro.
            num_rhythms (int): Quanti valori ritmici generare per la tabella.
            rhythm_value_range (tuple): Range (min, max) per i valori dei ritmi.
        """
        print(f"-> Aggiungo Voce: start={start_time:.2f}s, dur={duration}s, dyn='{dynamic}', "
              f"ott={octave_range}, reg={register_range}")

        # 1. Seleziona i parametri base per questa voce
        ottava = random.randint(*octave_range)
        registro = random.randint(*register_range)

        # 2. Ottieni l'indice della dinamica
        try:
            dynamic_idx = self.dynamic_to_index[dynamic.lower()]
        except KeyError:
            print(f"ATTENZIONE: Dinamica '{dynamic}' non valida. Uso 'mf' (3) come default.")
            dynamic_idx = 3

        # 3. Genera un pattern ritmico unico per questa voce
        ritmi = tuple(random.randint(*rhythm_value_range) for _ in range(num_rhythms))
        posizioni = tuple(i % r for i, r in enumerate(ritmi) if r > 0)

        # 4. Mappa il pattern ritmico a numeri di tabella Csound
        if ritmi not in self.rhythm_tables:
            self.rhythm_tables[ritmi] = {
                'ritmi_tab_num': self.next_table_id,
                'pos_tab_num': self.next_table_id + 1,
                'posizioni': posizioni  # Memorizziamo anche le posizioni
            }
            self.next_table_id += 2

        table_info = self.rhythm_tables[ritmi]

        # 5. Crea e memorizza l'evento
        event_data = {
            'time': start_time,
            'pfields': {
                'p2_attack': 0.0,
                'p3_duration': duration,
                'p4_rhythm_tab': table_info['ritmi_tab_num'],
                'p5_harmonic_dur': random.uniform(1.5, 3.0),
                'p6_dynamic_idx': dynamic_idx,
                'p7_octave': ottava,
                'p8_register': registro,
                'p9_pos_tab': table_info['pos_tab_num'],
                'p10_id_comp': len(self.events) + 1,
            }
        }
        self.events.append(event_data)
        
    def generate_csd(self, output_filename="generated_composition.csd"):
        """
        Genera il file .csd finale completo di score e strumenti.
        """
        if not self.events:
            print("Nessun evento da generare. CSD non creato.")
            return

        # --- Costruzione dello SCORE ---
        # 1. Definizioni delle tabelle
        score_tables = "; --- Tabelle di Ritmo e Posizione ---\n"
        for ritmi, info in self.rhythm_tables.items():
            ritmi_str = ' '.join(map(str, ritmi))
            pos_str = ' '.join(map(str, info['posizioni']))
            score_tables += f"f {info['ritmi_tab_num']} 0 {len(ritmi)} -2 {ritmi_str}\n"
            score_tables += f"f {info['pos_tab_num']} 0 {len(info['posizioni'])} -2 {pos_str}\n"

        # 2. Istanze degli strumenti (le nostre "voci")
        score_lines = "; --- Istanze dello Strumento Voce ---\n"
        score_lines += ";\tp1\t\tp2\tp3\tp4\tp5\t\tp6\tp7\tp8\tp9\tp10\n"
        score_lines += ";\tInstr\tStart\tDur\t\tRhyTab\tHarmDur\t\tDynIdx\tOct\tReg\tPosTab\tID\n"
        total_duration = 0
        for event in self.events:
            p = event['pfields']
            line = (f"i \"Voce\"\t{event['time']+.1:.3f}\t{p['p3_duration']:.3f}\t{p['p4_rhythm_tab']}\t"
                    f"{p['p5_harmonic_dur']:.3f}\t\t{p['p6_dynamic_idx']}\t\t{p['p7_octave']}\t{p['p8_register']}\t"
                    f"{p['p9_pos_tab']}\t{p['p10_id_comp']}\n")
            score_lines += line
            total_duration = max(total_duration, event['time'] + p['p3_duration'])

        # --- Assemblaggio del CSD completo ---
        csd_template = self.get_csd_template()
        csd_content = csd_template.format(
            total_duration=total_duration + 5.0,  # Aggiungi 5s di coda
            score_tables=score_tables,
            score_lines=score_lines,
            output_filename=output_filename.replace('.csd', '.wav')
        )

        output_path = Path(__file__).parent / output_filename
        with open(output_path, 'w') as f:
            f.write(csd_content)
        
        print(f"\n✓ File CSD generato con successo: '{output_path}'")
        print(f"  Per eseguirlo: csound \"{output_path}\"")


    def get_csd_template(self):
        """
        Restituisce il template CSD che contiene tutto il necessario
        (strumenti, UDO, setup globale) per eseguire lo score.
        """
        # Questo template ora è autonomo e contiene tutto il codice Csound.
        return """
<CsoundSynthesizer>

<CsOptions>
-o {output_filename} -W -d
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
{score_tables}
; -----------------------

i "Init" 0 0.1

; --- VOCI GENERATE ---
{score_lines}
; --------------------


</CsScore>

</CsoundSynthesizer>
"""

# =============================================================================
# ESECUZIONE DELLO SCRIPT
# =============================================================================
if __name__ == "__main__":
    
    print("--- Generatore Semplice di Voci Csound ---")
    
    # 1. Inizializza il nostro builder
    builder = ScoreBuilder()
    
    # 2. Definisci la composizione (IL TUO PANNELLO DI CONTROLLO)
    
    # Voce 1: Grave e 'piano', inizia subito
    builder.add_voice(
        start_time=0.0,
        duration=25.0,
        dynamic='p',
        octave_range=(1, 3),
        register_range=(1, 10)
    )

    # Voce 2: Acuta e 'forte', inizia dopo un po'
    builder.add_voice(
        start_time=10.0,
        duration=30.0,
        dynamic='f',
        octave_range=(5, 7),
        register_range=(20, 40)
    )
    
    # Voce 3: In registro medio, dinamica 'fff', entra a metà
    builder.add_voice(
        start_time=20.0,
        duration=15.0,
        dynamic='fff',
        octave_range=(3, 5),
        register_range=(5, 25),
        num_rhythms=8,
        rhythm_value_range=(8, 32)
    )

    # Voce 4: Molto debole e sporadica
    builder.add_voice(
        start_time=5.0,
        duration=40.0,
        dynamic='ppp',
        octave_range=(2, 6),
        register_range=(1, 50)
    )

    # 3. Genera il file CSD finale
    builder.generate_csd("composizione_4_voci.csd")