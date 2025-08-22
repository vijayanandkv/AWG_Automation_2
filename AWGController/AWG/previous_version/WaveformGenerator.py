import numpy as np
from scipy import signal
import matplotlib.pyplot as plt
import seaborn as sns
from pyfinite import ffield
import csv
from logger import awg_logger

# Create a class to generate waveforms

class WaveformGenerator:
    def __init__(self, ip_address):
        self.pulse_width = None
        self.bandwidth = None
        self.chirp = None
        self.logger = awg_logger()
        if self.logger._log_file_path is None:
                self.log._initialize_log_file(f"awg_{ip_address}")

    # Sinusoidal wave
    def sinusoidal(self, frequency, amplitude = 1, sampling_frequency=7.2):
        amplitude = float(amplitude)
        frequency = float(frequency) * 1e9  # user gives frequency in GHz
        sampling_frequency = float(sampling_frequency) * 1e9  # user gives sampling frequency in GHz
        period = 1 / frequency
        oversample = int(period * sampling_frequency)
        time = np.arange(0, period, 1 / sampling_frequency)
        wave = (amplitude / 2) * np.sin(2 * np.pi * frequency * time)

        self.logger._log_command(command="generate sine wave", duration_ms=None, response = "Successfully generated")
        print(f"num samples: {len(wave)}, over sample {oversample}")

        return  time, wave

    def get_taps(self, order):
        F = ffield.FField(order)
        taps = [i for i, bit in enumerate(reversed(F.ShowCoefficients(F.generator))) if bit == 1]
        print("taps: ", taps)
        return taps[:-1]  # remove x^0 term which is always 1 in primitive polynomials

    def PRBS(self, amplitude, order, repetition_rate, sampling_frequency=7.2, max_bits=None):
        amplitude = float(amplitude)
        order = int(order)
        taps = self.get_taps(order)
        sampling_frequency = float(sampling_frequency) * 7.2e9
        repetition_rate = float(repetition_rate) * 1e6

        oversample = round(sampling_frequency / repetition_rate)
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

        waveform = np.repeat(bits * amplitude, oversample)
        time = np.arange(len(waveform)) / sampling_frequency
        self.logger._log_command(command="generate PRBS wave", duration_ms=None, response = "Successfully generated")

        return time, waveform
    

    def generate_lfm(self, center_freq, bandwidth, pulse_width, sampling_freq = 7.2):
        
        self.sampling_freq = float(sampling_freq) * 1e9  # GHz to Hz
        self.center_freq = float(center_freq) * 1e9  # GHz to Hz
        self.pulse_width = pulse_width * 1e-9
        self.bandwidth = float(bandwidth * 1e9)
        self.k = self.bandwidth/self.pulse_width
        

        self.f0 = float(self.center_freq - self.bandwidth / 2)
        self.f1 = float(self.center_freq + self.bandwidth / 2)

        t = np.arange(0, self.pulse_width, 1 / self.sampling_freq)
        waveform = np.cos(2*np.pi * ((self.f0 * t) + (self.k/2) * (t ** 2)))   #signal.chirp(t, f0=self.f0, f1=self.f1, t1=self.pulse_width, method='linear') 

        return t, waveform

    '''def plot(self, time, waveform, amplitude, title="Waveform", bits=None, num_bits=50):
        plt.figure(figsize=(10, 4))
        if bits is not None:
            oversample = len(waveform) // len(bits)
            num_bits = min(num_bits, len(bits))
            num_samples = oversample * num_bits
        else:
            num_samples = len(waveform)

        plt.plot(time[:num_samples], waveform[:num_samples], label='Waveform', linewidth=1.5)

        if bits is not None:
            oversample = len(waveform) // len(bits)
            bit_times = time[:len(bits) * oversample:oversample]
            plt.step(bit_times[:num_bits], bits[:num_bits] * amplitude,
                     where='post', linestyle='--', label='Bits', alpha=0.5)

        plt.title(title + f' sample rate 7.2GHz')
        plt.xlabel("Time (ns)")
        plt.ylabel("Amplitude (V)")
        plt.grid(True)
        plt.legend()
        plt.tight_layout()
        plt.show()

    def save_file(self, waveform_name, wave):
        filename = f"single_channel_{waveform_name}_waveform.csv"
        with open(filename, mode='w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Ch1"])
            for value in wave:
                writer.writerow([value])
        print(f"Saved: {filename}")'''
