import numpy as np
from pyfinite import ffield

class CombinedWaveformGenerator:
    def __init__(self):
        pass

    def sinusoidal(self, frequency, num_samples, sampling_frequency=8):
        frequency = frequency * 1e9
        sampling_frequency = sampling_frequency * 1e9

        t = np.arange(0, num_samples) / sampling_frequency
        wave = np.sin(2 * np.pi * frequency * t)
        return t, wave
    def get_taps(self, order):
        F = ffield.FField(order)
        taps = [i for i, bit in enumerate(reversed(F.ShowCoefficients(F.generator))) if bit == 1]
        print("taps: ", taps)
        return taps[:-1]  # remove x^0 term which is always 1 in primitive polynomials
    
    def PRBS(self, num_samples, order, repetition_rate, sampling_frequency=7.2, max_bits=None):
        order = int(order)
        taps = self.get_taps(order)
        sampling_frequency = float(sampling_frequency) * 1e9
        repetition_rate = float(repetition_rate) * 1e6

        oversample = max(1, round(sampling_frequency / repetition_rate))  # Ensure at least 1
        max_length = (2 ** order) - 1

        if max_bits is not None:
            length = min(max_length, int(max_bits))
        else:
            length = max_length

        while True:
            seed = np.random.randint(0, 2, size=order).tolist()
            if any(seed):
                break

        state = seed.copy()
        bits = []
        for _ in range(length):
            feedback = 0
            for t in taps:
                feedback ^= state[t]
            bits.append(state[-1])
            state = [feedback] + state[:-1]

        bits = np.array(bits)
        print(f"[DEBUG] order={order}, length={length}, oversample={oversample}, total_samples={length * oversample}")
        print("Bits:", bits[:50])
        print("Unique bit values:", np.unique(bits))

        # Create waveform by repeating each bit oversample times
        waveform = np.repeat(bits, oversample)
        
        # If waveform is empty or too short, create a simple alternating pattern
        if len(waveform) == 0:
            print("[WARNING] Empty waveform generated, creating alternating pattern")
            waveform = np.tile([0, 1], num_samples // 2 + 1)[:num_samples]
        
        # Ensure we have enough samples, truncate or repeat as needed
        if len(waveform) > num_samples:
            waveform = waveform[:num_samples]
        elif len(waveform) < num_samples and len(waveform) > 0:
            # Repeat the pattern to fill num_samples
            repeats = int(np.ceil(num_samples / len(waveform)))
            waveform = np.tile(waveform, repeats)[:num_samples]
        elif len(waveform) == 0:
            # Fallback: create simple alternating pattern
            waveform = np.tile([0, 1], num_samples // 2 + 1)[:num_samples]
            
        time = np.arange(len(waveform)) / sampling_frequency

        return time, waveform
    

    def generate_lfm(self, center_freq, bandwidth, pulse_width, num_samples,
                     sampling_freq=8, pulse_repetition_rate=1e6):
   

        # Convert units
        self.sampling_freq = float(sampling_freq) * 1e9  # GHz → Hz
        self.center_freq = float(center_freq) * 1e9
        self.num_samples = num_samples
        self.pulse_width = float(pulse_width) * 1e-9     # ns → s
        self.bandwidth = float(bandwidth) * 1e9

        # Chirp rate
        self.k = self.bandwidth / self.pulse_width

        self.f0 = self.center_freq - self.bandwidth / 2
        self.f1 = self.center_freq + self.bandwidth / 2

        # Time vector
        t = np.arange(0, self.num_samples) / self.sampling_freq
        waveform = np.zeros_like(t)

        # Pulse repetition interval
        pri = 1.0 / pulse_repetition_rate
        samples_per_pulse = int(self.pulse_width * self.sampling_freq)
        samples_per_pri = int(pri * self.sampling_freq)

        # Generate repeated LFM pulses
        for start in range(0, self.num_samples, samples_per_pri):
            end = min(start + samples_per_pulse, self.num_samples)
            t_segment = t[start:end] - t[start]  # reset time for chirp
            waveform[start:end] = np.cos(2*np.pi * (self.f0 * t_segment + (self.k/2) * (t_segment**2)))

        return t, waveform
    def generate_steplfm(self, start_freq, stop_freq, step_freq, dwell_time, num_samples, sampling_freq=7.2):
        sampling_freq = float(sampling_freq) * 1e9  # GHz to Hz
        start_freq = float(start_freq) * 1e9  # GHz to Hz
        stop_freq = float(stop_freq) * 1e9  # GHz to Hz
        step_freq = float(step_freq) * 1e9 # GHz to Hz 
        dwell_time = float(dwell_time) * 1e-9

        # Calculate number of frequency steps
        num_steps = int((stop_freq - start_freq) / step_freq) + 1
        samples_per_step = num_samples // num_steps
    
        t_total = []
        waveform = []
        current_freq = start_freq
        time_offset = 0

        for step in range(num_steps):
            # Use samples_per_step instead of num_samples
            if step == num_steps - 1:  # Last step gets remaining samples
                current_samples = num_samples - len(np.concatenate(waveform)) if waveform else samples_per_step
            else:
                current_samples = samples_per_step
            
            t = np.arange(current_samples) / sampling_freq
            level = (current_freq - start_freq) / step_freq + 1
            wave = np.full_like(t, fill_value=level)
            t_total.append(t + time_offset)
            waveform.append(wave)
            time_offset += current_samples / sampling_freq
            current_freq += step_freq

        t_total = np.concatenate(t_total)
        waveform = np.concatenate(waveform)

        return t_total, waveform
    