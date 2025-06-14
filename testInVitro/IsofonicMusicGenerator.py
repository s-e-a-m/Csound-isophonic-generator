import numpy as np
import os
import matplotlib.pyplot as plt

class IsofonicMusicGenerator:
    def __init__(self, 
                 phon_fff=100, 
                 phon_step=3,
                 dbfs_fff=-6, 
                 dbfs_step=3):
        """
        Inizializza il generatore con calibrazione completamente dinamica.
        
        Args:
            phon_fff (int): Livello di loudness in phon per la dinamica 'fff'.
            phon_step (int): Step di phon tra ogni livello di dinamica.
            dbfs_fff (float): Livello dBFS per 'fff'.
            dbfs_step (float): Step di dB tra ogni livello di dinamica.
        """
        
        # Parametri di calibrazione dinamica
        self.phon_fff = phon_fff
        self.phon_step = phon_step
        self.dbfs_fff = dbfs_fff
        self.dbfs_step = dbfs_step
        
        # Ordine delle dinamiche (può essere modificato se necessario)
        self.dynamic_order = ['ppp', 'pp', 'p', 'mf', 'f', 'ff', 'fff']
        
        # Calcola dinamicamente la mappatura Dinamica -> Phon
        self._calculate_dynamic_phon_mapping()
        
        # Calcola dinamicamente la mappatura Dinamica -> dBFS
        self._calculate_direct_dbfs_mapping()
        
        # Il resto del setup
        self.init_isophonic_curves()
        self.csound_amplitude_scale = 0.7 

    def _calculate_dynamic_phon_mapping(self):
        """
        NUOVO METODO: Calcola una mappatura dinamica da 'dinamica' a 'phon'.
        Parte da fff e sottrae uno step fisso per ogni dinamica inferiore.
        """
        self.dynamics_to_phon = {}
        # Partiamo dalla dinamica più forte (fff) e andiamo a ritroso
        for i, dynamic in enumerate(reversed(self.dynamic_order)):
            offset = i * self.phon_step
            self.dynamics_to_phon[dynamic] = self.phon_fff - offset
        
        print("=== CALIBRAZIONE PHON DINAMICA ===")
        print(f"Loudness massima (fff): {self.phon_fff} phon")
        print(f"Step di loudness: {self.phon_step} phon")
        print("Mappatura Dinamica -> Phon calcolata:")
        for dynamic in self.dynamic_order:
            print(f"  {dynamic:>3}: {self.dynamics_to_phon[dynamic]} phon")
        print("")

    def _calculate_direct_dbfs_mapping(self):
        """
        Calcola una mappatura diretta da 'dinamica' a 'dBFS'.
        Questo metodo ora si basa sui parametri di input dbfs_fff e dbfs_step.
        """
        self.dynamics_to_dbfs = {}
        for i, dynamic in enumerate(reversed(self.dynamic_order)):
            offset = i * self.dbfs_step
            self.dynamics_to_dbfs[dynamic] = self.dbfs_fff - offset
            
        print("=== CALIBRAZIONE DBFS DIRETTA ===")
        print(f"Livello massimo (fff): {self.dbfs_fff} dBFS")
        print(f"Step di livello: {self.dbfs_step} dB")
        print("Mappatura Dinamica -> dBFS calcolata (per 1000 Hz):")
        for dynamic in self.dynamic_order:
            print(f"  {dynamic:>3}: {self.dynamics_to_dbfs[dynamic]:.1f} dBFS")
        print("")
        
    # ... (TUTTI GLI ALTRI METODI RESTANO IDENTICI) ...
    # init_isophonic_curves, phon_to_db_spl, generate_note, 
    # generate_csound_score, save_score, generate_isophonic_curve, 
    # plot_calibration_curves
    # (Copiali dalla versione precedente)
    # ...
    def init_isophonic_curves(self):
        self.iso_frequencies = np.array([20, 25, 31.5, 40, 50, 63, 80, 100, 125, 160, 200, 250, 315, 400, 500, 630, 800, 1000, 1250, 1600, 2000, 2500, 3150, 4000, 5000, 6300, 8000, 10000, 12500])
        self.af_params = np.array([0.532, 0.506, 0.480, 0.455, 0.432, 0.409, 0.387, 0.367, 0.349, 0.330, 0.315, 0.301, 0.288, 0.276, 0.267, 0.259, 0.253, 0.250, 0.246, 0.244, 0.243, 0.243, 0.243, 0.242, 0.242, 0.245, 0.254, 0.271, 0.301])
        self.lu_params = np.array([-31.6, -27.2, -23.0, -19.1, -15.9, -13.0, -10.3, -8.1, -6.2, -4.5, -3.1, -2.0, -1.1, -0.4, 0.0, 0.3, 0.5, 0.0, -2.7, -4.1, -1.0, 1.7, 2.5, 1.2, -2.1, -7.1, -11.2, -10.7, -3.1])
        self.tf_params = np.array([78.5, 68.7, 59.5, 51.1, 44.0, 37.5, 31.5, 26.5, 22.1, 17.9, 14.4, 11.4, 8.6, 6.2, 4.4, 3.0, 2.2, 2.4, 3.5, 1.7, -1.3, -4.2, -6.0, -5.4, -1.5, 6.0, 12.6, 13.9, 12.3])
        self.reference_frequencies = self.iso_frequencies

    def phon_to_db_spl(self, frequency, phon_level):
        af = np.interp(frequency, self.iso_frequencies, self.af_params)
        lu = np.interp(frequency, self.iso_frequencies, self.lu_params)
        tf = np.interp(frequency, self.iso_frequencies, self.tf_params)
        term1 = 4.47e-3 * (10**(0.025 * phon_level) - 1.15)
        term2_exponent = (tf + lu) / 10.0 - 9
        term2 = (0.4 * 10**term2_exponent)**af
        af_value = term1 + term2
        if af_value <= 0: spl = tf + (phon_level / 40.0) * 20
        else: spl = (10.0 / af) * np.log10(af_value) - lu + 94.0
        if abs(frequency - 1000.0) < 0.1: spl = phon_level
        return spl

    def generate_note(self, frequency, dynamic, duration=2.0, start_time=0.0):
        if dynamic not in self.dynamics_to_dbfs: raise ValueError(f"Dinamica '{dynamic}' non riconosciuta.")
        phon_level = self.dynamics_to_phon[dynamic]
        dbfs_reference = self.dynamics_to_dbfs[dynamic]
        db_spl_target = self.phon_to_db_spl(frequency, phon_level)
        db_spl_reference_1kHz = phon_level
        frequency_offset = db_spl_target - db_spl_reference_1kHz
        final_dbfs = dbfs_reference + frequency_offset
        amplitude = 10**(final_dbfs / 20.0)
        amplitude *= self.csound_amplitude_scale
        amplitude = min(max(amplitude, 0.0), 1.0)
        return {'instrument': 1, 'start_time': start_time, 'duration': duration, 'amplitude': amplitude, 'frequency': frequency, 'dynamic': dynamic, 'phon_level': phon_level, 'db_spl_target': db_spl_target, 'dbfs_reference_1kHz': dbfs_reference, 'frequency_offset': frequency_offset, 'final_dbfs': final_dbfs}


    def generate_envelope_note(self, frequency, dynamic_start, dynamic_end, duration, start_time=0.0):
        """
        Genera i parametri per una singola nota Csound con un inviluppo dinamico.
        """
        # Funzione helper interna per calcolare l'ampiezza per una dinamica specifica
        def get_amplitude_for_dynamic(dyn):
            phon_level = self.dynamics_to_phon[dyn]
            dbfs_reference = self.dynamics_to_dbfs[dyn]
            
            db_spl_target = self.phon_to_db_spl(frequency, phon_level)
            db_spl_reference_1kHz = phon_level
            frequency_offset = db_spl_target - db_spl_reference_1kHz
            final_dbfs = dbfs_reference + frequency_offset
            
            amplitude = 10**(final_dbfs / 20.0)
            amplitude *= self.csound_amplitude_scale
            return min(max(amplitude, 0.0), 1.0)

        # Calcola ampiezza di inizio e fine
        amp_start = get_amplitude_for_dynamic(dynamic_start)
        amp_end = get_amplitude_for_dynamic(dynamic_end)
        
        # Restituisce un dizionario con i parametri per Csound
        return {
            'instrument': 2,  # Usiamo un nuovo strumento per gli inviluppi
            'start_time': start_time,
            'duration': duration,
            'amp_start': amp_start,
            'amp_end': amp_end,
            'frequency': frequency,
            'dynamic_start': dynamic_start,
            'dynamic_end': dynamic_end
        }

    def generate_csound_score(self, notes):
        score_lines = []
        for note in notes:
            line = f"i {note['instrument']} {note['start_time']:.3f} {note['duration']:.3f} {note['amplitude']:.6f} {note['frequency']:.2f}"
            score_lines.append(line)
        return '\n'.join(score_lines)

    def save_score(self, notes, filename="score.sco"):
        score = self.generate_csound_score(notes)
        with open(filename, 'w') as f: f.write(score)
        print(f"\nScore salvato in {filename}")
        return score

    def generate_isophonic_curve(self, phon_level, num_points=200):
        frequencies = np.logspace(np.log10(20), np.log10(20000), num_points)
        db_spl_values = np.zeros(num_points)
        for i, freq in enumerate(frequencies): db_spl_values[i] = self.phon_to_db_spl(freq, phon_level)
        return frequencies, db_spl_values

    def plot_calibration_curves(self):
        print("\nGenerazione del grafico delle curve di calibrazione...")
        plt.figure(figsize=(14, 9))
        labels_map = {v: k for k, v in self.dynamics_to_phon.items()}
        for dynamic in self.dynamic_order:
            phon_level = self.dynamics_to_phon[dynamic]
            freqs, spls = self.generate_isophonic_curve(phon_level)
            label = f"{labels_map[phon_level]} ({phon_level} Phon)"
            plt.plot(freqs, spls, label=label)
        plt.xscale('log')
        plt.xlabel('Frequenza (Hz)', fontsize=12)
        plt.ylabel('Pressione Sonora (dB SPL)', fontsize=12)
        plt.title('Curve Isofoniche per la Calibrazione Attuale (ISO 226:2003)', fontsize=14)
        plt.grid(True, which="both", ls="--", alpha=0.6)
        plt.legend()
        plt.xticks([20, 50, 100, 200, 500, 1000, 2000, 5000, 10000, 20000], ['20', '50', '100', '200', '500', '1k', '2k', '5k', '10k', '20k'])
        plt.minorticks_off()
        plt.xlim(20, 20000)
        plt.ylim(bottom=max(0, self.phon_fff - (len(self.dynamic_order) + 2) * self.phon_step))
        plt.tight_layout()
        plt.show()

import random # Assicurati che 'import random' sia all'inizio del file

class ScoreBuilder:
    """
    Una classe helper per costruire sequenze di note in modo programmatico.
    Gestisce il tempo e semplifica la creazione di frasi musicali ripetitive.
    """
    def __init__(self, generator: IsofonicMusicGenerator):
        """
        Inizializza il builder con un'istanza di IsofonicMusicGenerator.
        
        Args:
            generator (IsofonicMusicGenerator): L'istanza del generatore da usare
                                                per creare le note.
        """
        if not isinstance(generator, IsofonicMusicGenerator):
            raise TypeError("Il builder richiede un'istanza di IsofonicMusicGenerator.")
        
        self.generator = generator
        self.notes = []
        self.current_time = 0.0

    def add_notes_with_envelope(self, 
                                num_notes: int,
                                duration_per_note: float,
                                base_frequency: float,
                                dynamic_start: str,
                                dynamic_end: str,
                                freq_error_range: float = 20.0,
                                gap_between_notes: float = 0.05):
        """
        Aggiunge una sequenza di note, una dopo l'altra.
        
        Ogni nota ha la stessa durata e lo stesso inviluppo dinamico,
        ma con una leggera variazione casuale sulla frequenza.

        Args:
            num_notes (int): Il numero di note da generare.
            duration_per_note (float): La durata di ogni singola nota.
            base_frequency (float): La frequenza di base prima dell'errore.
            dynamic_start (str): La dinamica di partenza per l'inviluppo (es. 'p').
            dynamic_end (str): La dinamica di fine per l'inviluppo (es. 'f').
            freq_error_range (float): L'intervallo massimo dell'errore da aggiungere
                                      alla frequenza (da 0 a N). Default 20.0 Hz.
            gap_between_notes (float): La pausa in secondi tra una nota e la successiva.
        """
        print(f"-> Aggiungo {num_notes} note (da '{dynamic_start}' a '{dynamic_end}') "
              f"basate su {base_frequency:.2f} Hz...")
              
        for i in range(num_notes):
            # Calcola l'errore casuale da aggiungere alla frequenza
            random_offset = random.uniform(0, freq_error_range)
            note_frequency = base_frequency + random_offset
            
            # Genera la nota usando il metodo del generator
            note_data = self.generator.generate_envelope_note(
                frequency=note_frequency,
                dynamic_start=dynamic_start,
                dynamic_end=dynamic_end,
                duration=duration_per_note,
                start_time=self.current_time
            )
            
            # Aggiungi la nota alla lista
            self.notes.append(note_data)
            
            # Avanza il tempo per la nota successiva
            #self.current_time += duration_per_note + gap_between_notes
            
        return self # Rende il builder "chainable" (es. builder.add(...).add_silence(...))

    def add_silence(self, duration: float):
        """Aggiunge una pausa, avanzando il tempo corrente."""
        print(f"-> Aggiungo {duration:.2f}s di silenzio...")
        self.current_time += duration
        return self

    def get_notes(self):
        """Restituisce la lista finale di note generate."""
        return self.notes

    def clear(self):
        """Resetta il builder per iniziare un nuovo score."""
        self.notes = []
        self.current_time = 0.0
        return self
# --- ESEMPIO D'USO COMPLETAMENTE DINAMICO ---
if __name__ == "__main__":
    
    # === IL TUO PANNELLO DI CONTROLLO ===
    # Qui puoi sperimentare con tutti i parametri
    
    # Calibrazione Phon
    PHON_MAX = 100   # Livello di fff in phon
    PHON_STEP = 6    # Step di phon tra le dinamiche
    
    # Calibrazione dBFS
    DBFS_MAX = -30    # Livello di fff in dBFS
    DBFS_STEP = 6    # Step di dBFS tra le dinamiche
    
    # Selettore di Azione
    DO_PLOTTING = False#True
    DO_NOTE_GENERATION = False
    # ====================================
    
    # Inizializza il generatore con i tuoi parametri
    generator = IsofonicMusicGenerator(
        phon_fff=PHON_MAX, 
        phon_step=PHON_STEP,
        dbfs_fff=DBFS_MAX, 
        dbfs_step=DBFS_STEP
    )

    # 2. Crea un'istanza del nostro nuovo ScoreBuilder
    builder = ScoreBuilder(generator)
    print("\n--- COSTRUZIONE DELLO SCORE TRAMITE BUILDER ---")

    # 3. Usa il builder per comporre lo score in modo dichiarativo
    
    # Frase 1: 5 note in crescendo su un Do centrale, con leggera stonatura
    builder.add_notes_with_envelope(
        num_notes=5,
        duration_per_note=10,
        base_frequency=261.63, # Do centrale
        dynamic_start='pp',
        dynamic_end='f',
        gap_between_notes=0.1
    )
    
    # Aggiungi una pausa di 2 secondi
    builder.add_silence(2.0)
    
    # Frase 2: 8 note veloci in decrescendo su un La, con più stonatura
    builder.add_notes_with_envelope(
        num_notes=8,
        duration_per_note=4,
        base_frequency=440.0, # La
        dynamic_start='fff',
        dynamic_end='p',
        freq_error_range=35.0, # Aumentiamo l'errore per un effetto diverso
        gap_between_notes=0.05
    )
    
    # Aggiungi un'altra pausa
    builder.add_silence(3.0)
    
    # Frase 3: 3 note lunghe e gravi, con un crescendo molto ampio
    builder.add_notes_with_envelope(
        num_notes=3,
        duration_per_note=5.0,
        base_frequency=82.41, # Mi basso
        dynamic_start='ppp',
        dynamic_end='fff'
    )
    
    # 4. Ottieni la lista di note finale dal builder
    final_notes = builder.get_notes()
    

    if DO_PLOTTING:
        generator.plot_calibration_curves()

    # 5. Genera lo score Csound (questo codice rimane quasi identico)
    score_lines = []
    for note in final_notes:
        line = (f"i {note['instrument']} {note['start_time']:.3f} {note['duration']:.3f} "
                f"{note['amp_start']:.6f} {note['amp_end']:.6f} {note['frequency']:.2f}")
        score_lines.append(line)
    
    score_content = '\n'.join(score_lines)
    with open("envelope_score.sco", 'w') as f:
        f.write(score_content)
        
    print("\n--- SCORE CON INVILUPPI GENERATO ---")
    print(score_content)
    print("\nScore salvato in envelope_score.sco")
    print("Esegui con: csound IsofonicMusicGenerator.orc envelope_score.sco")



    if DO_NOTE_GENERATION:
        print("\n--- GENERAZIONE NOTE ---")
        notes_to_generate = [
            generator.generate_note(frequency=256.0, dynamic='fff', start_time=0.0, duration=2.0),
            generator.generate_note(frequency=256.0, dynamic='ff', start_time=2.0, duration=2.0),
            generator.generate_note(frequency=256.0, dynamic='f', start_time=4.0, duration=2.0),
            generator.generate_note(frequency=256.0, dynamic='mf', start_time=6.0, duration=2.0),
            generator.generate_note(frequency=256.0, dynamic='p', start_time=8.0, duration=2.0),
            generator.generate_note(frequency=256.0, dynamic='fff', start_time=10.0, duration=10.0),
            generator.generate_note(frequency=276.0, dynamic='fff', start_time=10.0, duration=10.0),
            generator.generate_note(frequency=293.0, dynamic='fff', start_time=10.0, duration=10.0),
            generator.generate_note(frequency=316.0, dynamic='fff', start_time=10.0, duration=10.0),
            generator.generate_note(frequency=327.0, dynamic='fff', start_time=10.0, duration=10.0),
            generator.generate_note(frequency=349.0, dynamic='fff', start_time=10.0, duration=10.0),
            generator.generate_note(frequency=361.0, dynamic='fff', start_time=10.0, duration=10.0),
            generator.generate_note(frequency=390.0, dynamic='fff', start_time=10.0, duration=10.0),
            generator.generate_note(frequency=256.0, dynamic='ppp', start_time=20.0, duration=10.0),
            generator.generate_note(frequency=276.0, dynamic='ppp', start_time=20.0, duration=10.0),
            generator.generate_note(frequency=293.0, dynamic='ppp', start_time=20.0, duration=10.0),
            generator.generate_note(frequency=316.0, dynamic='ppp', start_time=20.0, duration=10.0),
            generator.generate_note(frequency=327.0, dynamic='ppp', start_time=20.0, duration=10.0),
            generator.generate_note(frequency=349.0, dynamic='ppp', start_time=20.0, duration=10.0),
            generator.generate_note(frequency=361.0, dynamic='ppp', start_time=20.0, duration=10.0),
            generator.generate_note(frequency=390.0, dynamic='ppp', start_time=20.0, duration=10.0)
        ]
        score_content = generator.save_score(notes_to_generate, "my_dynamic_score.sco")
        print("\n--- SCORE GENERATO ---")
        print(score_content)
        print(f"esegui:\n csound IsofonicMusicGenerator.orc my_dynamic_score.sco")
