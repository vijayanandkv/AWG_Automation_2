import glob
import os
import time
import paramiko
from scp import SCPClient
from datetime import datetime
import threading

import math
import csv
from scipy import signal
import numpy as np
from numpy.fft import fft

import plotly.graph_objects as go
from plotly.subplots import make_subplots
import plotly.io as pio


from AWG_Controller import AWG_Controller
from WaveformGenerator import WaveformGenerator
from CombinedWaveformGenerator import CombinedWaveformGenerator


import PyQt5.QtWidgets as QtWidgets
from PyQt5.QtWidgets import QMessageBox, QFileDialog, QDialog, QVBoxLayout, QLabel, QLineEdit, QPushButton, QHBoxLayout, QFormLayout


class AWG_GUI_handler:
    def __init__(self, gui_instance):
        self.gui = gui_instance
        self.awg = None


    def handle_generate_waveform(self, channel):
         
        waveform_type = getattr(self.gui, f"ch{channel}_waveform_selector").currentText()

        # Validate inputs
        is_valid, error_msg = self.validate_inputs(channel, waveform_type)
        if not is_valid:
            QMessageBox.warning(self.gui, "Input Required", error_msg)
            self.gui.log_box.append(f"⚠️ {error_msg}")
            return
            
        ch_folder = QFileDialog.getExistingDirectory(self.gui, "Select Folder to Save CSV") 
        datetime_1 = datetime.now().strftime("%Y%m%d_%H%M")
        self.folder_name = f"channel_{channel}_{datetime_1}"
        full_path = os.path.join(ch_folder, self.folder_name)
        os.makedirs(full_path, exist_ok=True)

        if waveform_type == "Sine":
            fig = make_subplots(rows = 2, cols = 1, subplot_titles=(f"channel{channel} waveform", f"channel{channel} FFT"))
            self.generator = WaveformGenerator(ip_address='1.00.0')
            start = float(getattr(self.gui, f"ch{channel}_start_freq").text().strip())
            stop= float(getattr(self.gui, f"ch{channel}_stop_freq").text().strip())
            step = float(getattr(self.gui, f"ch{channel}_step_freq").text().strip())
            
            for f in np.arange(start, stop + 0.0001, step):
                t, w = self.generator.sinusoidal(frequency=f)
                freq, x = self.fft_signal(w, iota=2)
                # Plot waveform
                fig.add_trace(go.Scatter(x=t * 1e9, y=w.astype(float), mode='lines', name=f"{waveform_type}_{f:.2f} GHz"), row=1, col=1)
                fig.add_trace(go.Scatter(x=freq, y=x, mode='lines', name=f"{waveform_type}_{f:.2f} GHz"), row=2, col=1)                
                self.save_waveform_to_csv(waveform_data= w, waveform_type=waveform_type, channel=channel, folder= full_path)
                
            fig.update_xaxes(title_text="Time (ns)", row=1, col=1)
            fig.update_yaxes(title_text="Amplitude (V)", row=1, col=1)
            fig.update_xaxes(title_text="F (GHz)", row = 2, col= 1)
            fig.update_yaxes(title_text="Power dBm", row = 2, col= 1)
                
            html = pio.to_html(fig, full_html=False, include_plotlyjs='cdn')
            getattr(self.gui, f"ch{channel}_plot_view").setHtml(html)

        elif waveform_type == "PRBS":
            fig = make_subplots(rows = 2, cols= 1, subplot_titles=(f"channel{channel} waveform", f"channel{channel} FFT"))
            self.generator = WaveformGenerator(ip_address='1.00.0')
            start = float(getattr(self.gui, f"ch{channel}_start_order").text().strip())
            stop= float(getattr(self.gui, f"ch{channel}_stop_order").text().strip())
            step = float(getattr(self.gui, f"ch{channel}_step_order").text().strip())
            repetition_rate = int(getattr(self.gui, f"ch{channel}_prbs_repetition_rate").text().strip())
            
            for f in np.arange(start, stop + 0.0001, step):
                t, w = self.generator.PRBS(amplitude=1, order=f, repetition_rate=repetition_rate)
                freq, x = self.fft_signal(w, iota=2)
                # Plot waveform
                fig.add_trace(go.Scatter(x=t * 1e9, y=w, mode='lines', name=f"{waveform_type}_{f:.2f} GHz", line=dict(shape="hv")), row=1, col=1)
                fig.add_trace(go.Scatter(x=freq, y=x, mode='lines', name=f"{waveform_type}_{f:.2f} GHz"), row = 2, col= 1)
                  
                self.save_waveform_to_csv(waveform_data= w, waveform_type=waveform_type, channel=channel, folder= full_path)
                
            fig.update_xaxes(title_text="Time (ns)", row=1, col=1)
            fig.update_yaxes(title_text="Amplitude (V)", row=1, col=1)
            fig.update_xaxes(title_text="F (GHz)", row = 2, col= 1)
            fig.update_yaxes(title_text="Power dBm", row = 2, col= 1)
                
            html = pio.to_html(fig, full_html=False, include_plotlyjs='cdn')
            getattr(self.gui, f"ch{channel}_plot_view").setHtml(html)

        elif waveform_type == "LFM":
            fig = make_subplots(rows = 2, cols= 1, subplot_titles=(f"channel{channel} waveform", f"channel{channel} FFT"))
            self.generator = WaveformGenerator(ip_address='1.00.0')
            start = float(getattr(self.gui, f"ch{channel}_start_center_freq").text().strip())
            stop= float(getattr(self.gui, f"ch{channel}_stop_center_freq").text().strip())
            step = float(getattr(self.gui, f"ch{channel}_step_center_freq").text().strip())
            pulse_width = int(getattr(self.gui, f"ch{channel}_lfm_pulse_width").text().strip())
            bandwidth = float(getattr(self.gui, f"ch{channel}_lfm_bandwidth").text().strip())
            
            for f in np.arange(start, stop + 0.0001, step):
                t, w = self.generator.generate_lfm(center_freq=f, bandwidth=bandwidth, pulse_width=pulse_width)
                freq, wave = self.fft_signal(w, iota=2)
                # Plot waveform
                fig.add_trace(go.Scatter(x=t * 1e9, y=w, mode='lines', name=f"{waveform_type}_{f:.2f} GHz"), row=1, col=1)
                fig.add_trace(go.Scatter(x=freq, y=wave, mode='lines', name=f"{waveform_type}_{f:.2f} GHz"), row = 2, col= 1)
                    
                self.save_waveform_to_csv(waveform_data= w, waveform_type=waveform_type, channel=channel, folder= full_path)
                
            fig.update_xaxes(title_text="Time (ns)", row=1, col=1)
            fig.update_yaxes(title_text="Amplitude (V)", row=1, col=1)
            fig.update_xaxes(title_text="F (GHz)", row = 2, col= 1)
            fig.update_yaxes(title_text="Power dBm", row = 2, col= 1)
                
            html = pio.to_html(fig, full_html=False, include_plotlyjs='cdn')
            getattr(self.gui, f"ch{channel}_plot_view").setHtml(html)

        elif waveform_type == "Noise":
            fig = make_subplots(rows = 2, cols= 1, subplot_titles=(f"channel{channel} waveform", f"channel{channel} FFT"))
            self.generator = WaveformGenerator(ip_address='1.00.0')
            start = float(getattr(self.gui, f"ch{channel}_start_variance").text().strip())
            stop= float(getattr(self.gui, f"ch{channel}_stop_variance").text().strip())
            step = float(getattr(self.gui, f"ch{channel}_step_variance").text().strip())
            
            for f in np.arange(start, stop + 0.0001, step):
                t, w = self.generator.sinusoidal(frequency=f)
                freq, x = self.fft_signal(w, iota=2)
                # Plot waveform
                fig.add_trace(go.Scatter(x=t * 1e9, y=w, mode='lines', name=f"{waveform_type}_{f:.2f} GHz"), row=1, col=1)
                fig.add_trace(go.Scatter(x=freq, y=x, mode='lines', name=f"{waveform_type}_{f:.2f} GHz"), row = 2, col= 1)
                    
                self.save_waveform_to_csv(waveform_data= w, waveform_type=waveform_type, channel=channel, folder= full_path)
                
            fig.update_xaxes(title_text="Time (ns)", row=1, col=1)
            fig.update_yaxes(title_text="Amplitude (V)", row=1, col=1)
            fig.update_xaxes(title_text="F (GHz)", row = 2, col= 1)
            fig.update_yaxes(title_text="Power dBm", row = 2, col= 1)
                
            html = pio.to_html(fig, full_html=False, include_plotlyjs='cdn')
            getattr(self.gui, f"ch{channel}_plot_view").setHtml(html)   

        elif waveform_type == "stepLFM":
            fig = make_subplots(rows = 2, cols = 1, subplot_titles=(f"channel{channel} waveform", f"channel{channel} FFT"))
            self.generator = WaveformGenerator(ip_address='1.00.0')
            start = float(getattr(self.gui, f"ch{channel}_lfm_start_freq").text().strip())
            stop= float(getattr(self.gui, f"ch{channel}_lfm_stop_freq").text().strip())
            step = float(getattr(self.gui, f"ch{channel}_lfm_step_freq").text().strip())
            dwell_time = float(getattr(self.gui, f"ch{channel}_lfm_dwell_time").text().strip())

            t, w = self.generator.generate_steplfm(start_freq=start, stop_freq=stop, 
                                                    step_freq=step, dwell_time=dwell_time)

            freq, x = self.fft_signal(w, iota=2)

            fig.add_trace(go.Scatter(x=t * 1e9, y=w, mode='lines', 
                                    name=f"{waveform_type}_{start:.2f}-{stop:.2f} GHz"), 
                                    row=1, col=1)
                
            fig.add_trace(go.Scatter(x=freq, y=x, mode='lines', 
                                        name=f"{waveform_type}_{start:.2f}-{stop:.2f} GHz"), 
                                        row = 2, col= 1)
            self.save_waveform_to_csv(waveform_data= w, waveform_type=waveform_type, channel=channel, folder= full_path)
            
            fig.update_xaxes(title_text="Time (ns)", row=1, col=1)
            fig.update_yaxes(title_text="Frequency", row=1, col=1)
            fig.update_xaxes(title_text="F (GHz)", row = 2, col= 1)
            fig.update_yaxes(title_text="Power dBm", row = 2, col= 1)

            html = pio.to_html(fig, full_html=False, include_plotlyjs='cdn')
            getattr(self.gui, f"ch{channel}_plot_view").setHtml(html)
        self.handle_upload_waveform(file_path=full_path, channel=channel)
        

    def run(self, channel):
        self.gui.log_box.append(f"no error!")
        if self.awg == None:
            QMessageBox.warning(self.gui, "Warning", "Connect to AWG first!!")
            
        start_amp = float(getattr(self.gui, f'ch{channel}_start_amp').text().strip())
        stop_amp = float(getattr(self.gui, f'ch{channel}_stop_amp').text().strip())
        step_amp = float(getattr(self.gui, f'ch{channel}_step_amp').text().strip())

        self.gui.log_box.append(f"Remote path: {self.remote_path}")
        state_1 = self.gui.ch1_upload_check_bx.isChecked()
        state_2 = self.gui.ch2_upload_check_bx.isChecked()
            
        output_log = self.awg.set_output_state(channel=channel, state=1)
        del_seg_log = self.awg.delete_segment(channel=channel,id=1)

        if channel == 1 or state_1:
            file_path = self.ch1_file_path
            print(f"File path: {file_path}")
        elif channel == 2 or state_2:
            file_path = self.ch2_file_path
            print(f"File path: {file_path}")
        for file in glob.glob(f"{file_path}/*.csv"):
            try:                    
                filname = os.path.basename(file)
                print(f"File name: {filname}")
                remote_path = os.path.join(self.remote_path, self.folder_name).replace("\\", "/")

                full_path = os.path.join(remote_path, filname).replace("\\", "/")
                
                self.gui.log_box.append(f"FUll path: {full_path}")
                self.gui.log_box.append(f"Processing: {file}")
                seg_log = self.awg.define_segment(channel=channel, segment_id=1, n_sample=720)
                imp_log = self.awg.import_file(full_path)
                self.gui.log_box.append(f"{seg_log}")
                self.gui.log_box.append(f"no error")

                for amplitude in np.arange(start_amp, stop_amp + 0.001, step_amp):
                    abort_log = None
                    out_volt_log = None
                    init_log = None
                    def initiate_signal():
                        nonlocal abort_log, out_volt_log, init_log
                        abort_log = self.awg.abort_wave_generation(channel=channel)
                            
                        out_volt_log = self.awg.set_output_voltage_custom(channel=channel, value=amplitude)
                                                
                        init_log = self.awg.initiate_signal(channel=channel)
                        time.sleep(60)
                    init_thread = threading.Thread(target=initiate_signal)
                    init_thread.start()
                    init_thread.join()
                    self.awg.abort_wave_generation(channel=channel)

                del_seg_log = self.awg.delete_segment(channel=channel,id=1)
                self.gui.log_box.append(f"{seg_log}\n{imp_log}\n{abort_log}\n{output_log}\n{out_volt_log}\n{init_log}\n{del_seg_log}")
                output_log = self.awg.set_output_state(channel=channel, state=0)
            except Exception as e:
                self.gui.log_box.append(f"{e}")
                        
    def update_waveform_inputs(self, waveform_type, channel):
        """Update input field availability based on waveform type and channel"""
        if channel == 1:
            # Channel 1 inputs
            self.gui.ch1_sine_group.setVisible(waveform_type == 'Sine')            
            self.gui.ch1_prbs_group.setVisible(waveform_type == "PRBS")
            self.gui.ch1_lfm_group.setVisible(waveform_type == "LFM")
            self.gui.ch1_noise_group.setVisible(waveform_type == "Noise")
            self.gui.ch1_step_lfm_group.setVisible(waveform_type == "stepLFM")
        elif channel == 2:
            # Channel 1 inputs
            self.gui.ch2_sine_group.setVisible(waveform_type == 'Sine')            
            self.gui.ch2_prbs_group.setVisible(waveform_type == "PRBS")
            self.gui.ch2_lfm_group.setVisible(waveform_type == "LFM")
            self.gui.ch2_noise_group.setVisible(waveform_type == "Noise")
            self.gui.ch2_step_lfm_group.setVisible(waveform_type == "stepLFM")

    def get_channel_inputs(self, channel):
        """Get input widgets for specified channel"""
        if channel == 1:
            return {
                'waveform_selector': self.gui.ch1_waveform_selector,
                'ch1_start_freq': self.gui.ch1_start_freq,
                'ch1_stop_freq': self.gui.ch1_stop_freq,
                'ch1_step_freq': self.gui.ch1_step_freq,
                'ch1_start_amp': self.gui.ch1_start_amp,
                'ch1_stop_amp': self.gui.ch1_stop_amp,
                'ch1_step_amp': self.gui.ch1_step_amp,
                'ch1_start_order': self.gui.ch1_start_order,
                'ch1_stop_order': self.gui.ch1_stop_order,
                'ch1_step_order': self.gui.ch1_step_order,
                'prbs_repetition_rate': self.gui.ch1_prbs_repetition_rate,
                'ch1_start_noise': self.gui.ch1_start_variance,
                'ch1_stop_noise': self.gui.ch1_stop_variance,
                'ch1_step_noise': self.gui.ch1_step_variance,
                'ch1_start_center_freq': self.gui.ch1_start_center_freq,
                'ch1_stop_center_freq': self.gui.ch1_stop_center_freq,
                'ch1_step_center_freq': self.gui.ch1_step_center_freq,
                'lfm_pulse_width': self.gui.ch1_lfm_pulse_width,
                'lfm_bandwidth': self.gui.ch1_lfm_bandwidth,
                'ch1_start_lfm_freq': self.gui.ch1_lfm_start_freq,
                'ch1_stop_lfm_freq': self.gui.ch1_lfm_stop_freq,
                'ch1_step_lfm_freq': self.gui.ch1_lfm_step_freq,
                'ch1_dwell_time': self.gui.ch1_lfm_dwell_time,
                'canvas': self.gui.ch1_plot_view,
                
            }
        elif channel == 2:
            return {
                'waveform_selector': self.gui.ch2_waveform_selector,
                'ch2_start_freq': self.gui.ch2_start_freq,
                'ch2_stop_freq': self.gui.ch2_stop_freq,
                'ch2_step_freq': self.gui.ch2_step_freq,
                'ch2_start_amp': self.gui.ch2_start_amp,
                'ch2_stop_amp': self.gui.ch2_stop_amp,
                'ch2_step_amp': self.gui.ch2_step_amp,
                'ch2_start_order': self.gui.ch2_start_order,
                'ch2_stop_order': self.gui.ch2_stop_order,
                'ch2_step_order': self.gui.ch2_step_order,
                'prbs_repetition_rate': self.gui.ch2_prbs_repetition_rate,
                'ch2_start_noise': self.gui.ch2_start_variance,
                'ch2_stop_noise': self.gui.ch2_stop_variance,
                'ch2_step_noise': self.gui.ch2_step_variance,
                'ch2_start_center_freq': self.gui.ch2_start_center_freq,
                'ch2_stop_center_freq': self.gui.ch2_stop_center_freq,
                'ch2_step_center_freq': self.gui.ch2_step_center_freq,
                'lfm_pulse_width': self.gui.ch2_lfm_pulse_width,
                'lfm_bandwidth': self.gui.ch2_lfm_bandwidth,
                'canvas': self.gui.ch2_plot_view,
            }

    def validate_inputs(self, channel, waveform_type):
        """Validate inputs based on waveform type"""
        if channel == 1 or channel == 2:

            if waveform_type == "Sine":
                if (not getattr(self.gui, f'ch{channel}_start_freq').text().strip() or
                    not getattr(self.gui, f'ch{channel}_stop_freq').text().strip() or
                    not getattr(self.gui, f'ch{channel}_step_freq').text().strip() or
                    not getattr(self.gui, f'ch{channel}_start_amp').text().strip() or 
                    not getattr(self.gui, f'ch{channel}_stop_amp').text().strip() or
                    not getattr(self.gui, f'ch{channel}_step_amp').text().strip()):
                    
                    return False, "All inputs are required!!!"
                     
            
            elif waveform_type == "PRBS":
                if (not getattr(self.gui, f'ch{channel}_start_order').text().strip() or
                    not getattr(self.gui, f'ch{channel}_stop_order').text().strip() or
                    not getattr(self.gui, f'ch{channel}_step_order').text().strip() or
                    not getattr(self.gui, f'ch{channel}_start_amp').text().strip() or 
                    not getattr(self.gui, f'ch{channel}_stop_amp').text().strip() or
                    not getattr(self.gui, f'ch{channel}_step_amp').text().strip() or
                    not getattr(self.gui, f'ch{channel}_prbs_repetition_rate').text().strip()):
                    return False, "All inputs are required!!!"
                
            elif waveform_type == "LFM":
                if (not getattr(self.gui, f'ch{channel}_start_center_freq').text().strip() or
                    not getattr(self.gui, f'ch{channel}_stop_center_freq').text().strip() or  
                    not getattr(self.gui, f'ch{channel}_step_center_freq').text().strip() or 
                    not getattr(self.gui, f'ch{channel}_lfm_pulse_width').text().strip() or 
                    not getattr(self.gui, f'ch{channel}_lfm_bandwidth').text().strip() or
                    not getattr(self.gui, f'ch{channel}_start_amp').text().strip() or
                    not getattr(self.gui, f'ch{channel}_stop_amp').text().strip() or
                    not getattr(self.gui, f'ch{channel}_step_amp').text().strip()):
                    return False, "All inputs are required!!!"
                
            elif waveform_type == "Noise":
                if (not getattr(self.gui, f'ch{channel}_start_variance').text().strip() or
                    not getattr(self.gui, f'ch{channel}_stop_variance').text().strip() or
                    not getattr(self.gui, f'ch{channel}_step_variance').text().strip() or
                    not getattr(self.gui, f'ch{channel}_start_amp').text().strip() or 
                    not getattr(self.gui, f'ch{channel}_stop_amp').text().strip() or
                    not getattr(self.gui, f'ch{channel}_step_amp').text().strip()):
                    return False, "All inputs are required!!!"
                
            elif waveform_type == "stepLFM":
                if (not getattr(self.gui, f'ch{channel}_lfm_start_freq').text().strip() or
                    not getattr(self.gui, f'ch{channel}_lfm_stop_freq').text().strip() or  
                    not getattr(self.gui, f'ch{channel}_lfm_step_freq').text().strip() or 
                    not getattr(self.gui, f'ch{channel}_lfm_dwell_time').text().strip() or
                    not getattr(self.gui, f'ch{channel}_start_amp').text().strip() or
                    not getattr(self.gui, f'ch{channel}_stop_amp').text().strip() or
                    not getattr(self.gui, f'ch{channel}_step_amp').text().strip()):
                    return False, "All inputs are required!!!"
            
                
            return True, ""
    

    def save_waveform_to_csv(self, waveform_data, waveform_type, channel, folder):
        """Save waveform data to a CSV file."""
        self.folder = folder
        if not self.folder:
            self.gui.log_box.append("⚠️ Save operation cancelled by user.")
            return None

        filename = f"{waveform_type.lower()}.csv"

        try:
            full_path = os.path.join(self.folder, filename)

            with open(full_path, mode='w', newline='') as file:
                writer = csv.writer(file)
                writer.writerow(["Y1"])
                for value in waveform_data:
                    writer.writerow([value])
            self.gui.log_box.append(f"✅ Channel {channel} waveform data saved to: {full_path}")
            return full_path
        except Exception as e:
            self.gui.log_box.append(f"❌ Error saving waveform: {e}")
            return None

    def check_awg_connection(self):
        """Check if AWG is connected"""
        if not self.awg:
            self.gui.log_box.append("❌ AWG not connected. Please connect first.")
            return False
        return True

    def handle_connect(self):
        """Handle AWG connection"""
        ip = self.gui.ip_input.text().strip()
        # Enable tabs if AWG is connected

        if not ip:
            self.gui.log_box.append("❌ Please enter AWG IP address")
            QMessageBox.warning(self.gui, "Input Required", "Please enter AWG IP address")
            self.gui.ip_input.setFocus()
            self.gui.status_light.set_connected(False)
            return
            
        try:
            self.awg = AWG_Controller(ip_address=ip)
            self.connected = self.awg.connect()
            response, status = self.awg.is_connected()
            if not response:
                self.gui.log_box.append("Device not found")
            else:
                self.gui.status_light.set_connected(True)
                self.gui.log_box.append(f"{status}")
                self.update_channel_buttons()
                self.gui.logs_tab.setEnabled(True)
        except Exception as e:
            self.gui.status_light.set_connected(False)
            self.gui.log_box.append(f"❌ Connection failed: {e}")

    def handle_disconnect(self):
        """Handle AWG disconnection"""
        if self.awg:
            try:
                self.awg.disconnect()
                self.gui.status_light.set_connected(False)
                self.awg = None
                self.gui.log_box.append("🔌 Disconnected from AWG")

                self.update_channel_buttons()
            except Exception as e:
                self.gui.log_box.append(f"❌ Disconnect error: {e}")

    def update_channel_buttons(self):
        """Update channel button states based on connection"""
        state, log = self.awg.is_connected()
        if state:
            self.gui.log_box.append(log)
            self.gui.ch1_on_btn.setEnabled(state)
            self.gui.ch1_off_btn.setEnabled(state)
            self.gui.ch2_on_btn.setEnabled(state)
            self.gui.ch2_off_btn.setEnabled(state)
       

    def handle_channel_enable(self, channel):
        """Enable specified channel"""
        if not self.check_awg_connection():
            return
        try:
            # Add your channel enable logic here
            self.gui.log_box.append(f"✅ Channel {channel} enabled")
            if channel == 1:
                self.gui.tabs.setTabEnabled(1, True)
                self.gui.tabs.setTabEnabled(3, True)
            elif channel == 2:
                self.gui.tabs.setTabEnabled(2, True)
                self.gui.tabs.setTabEnabled(4, True)
        except Exception as e:
            self.gui.log_box.append(f"❌ Failed to enable channel {channel}: {e}")

    def handle_channel_disable(self, channel):
        """Disable specified channel"""
        if not self.check_awg_connection():
            return
        try:
            # Add your channel disable logic here
            self.gui.log_box.append(f"🔴 Channel {channel} disabled")
            if channel == 1:
                self.gui.tabs.setTabEnabled(1, False)
            elif channel == 2:
                self.gui.tabs.setTabEnabled(2, False)
        except Exception as e:
            self.gui.log_box.append(f"❌ Failed to disable channel {channel}: {e}")

    def handle_abort(self, channel):
        """Abort waveform generation for specified channel"""
        if not self.check_awg_connection():
            return
        
        try:
            self.awg.abort_wave_generation(channel=channel)
            self.gui.log_box.append(f"🛑 Waveform generation aborted for channel {channel}")
        except Exception as e:
            self.gui.log_box.append(f"❌ Failed to abort waveform generation: {e}")

    def closeEvent(self, event):

        """Handle application close event"""
        if self.awg:
            try:
                self.awg.disconnect()
            except:
                pass
        event.accept()

    def fft_signal(self, w, iota):
        x = fft(w)
        x = np.absolute(x)
        N = len(w)
        n = np.arange(N)
        T = N/ (1e9)  # Convert to time in seconds
        freq = n/T
        return freq/1e9, x
    
    
    def toggle_upload_check(self, channel):
        if channel ==1:
            is_upload = self.gui.ch1_upload_check_bx.isChecked()
            if is_upload:
                self.gui.ch1_waveform_selector.setEnabled(False)
                self.gui.ch1_sine_group.setEnabled(False)
                self.gui.ch1_prbs_group.setEnabled(False)
                self.gui.ch1_lfm_group.setEnabled(False)
                self.gui.ch1_noise_group.setEnabled(False)
                self.gui.ch1_upload_group.setEnabled(True)
            else:
                self.gui.ch1_waveform_selector.setEnabled(True)
                self.gui.ch1_sine_group.setEnabled(True)
                self.gui.ch1_prbs_group.setEnabled(True)
                self.gui.ch1_lfm_group.setEnabled(True) 
                self.gui.ch1_noise_group.setEnabled(True)
                self.gui.ch1_upload_group.setEnabled(False)
        elif channel == 2:
            is_upload = self.gui.ch2_upload_check_bx.isChecked()
            if is_upload:
                self.gui.ch2_waveform_selector.setEnabled(False)
                self.gui.ch2_sine_group.setEnabled(False)
                self.gui.ch2_prbs_group.setEnabled(False)
                self.gui.ch2_lfm_group.setEnabled(False)
                self.gui.ch2_noise_group.setEnabled(False)
                self.gui.ch2_upload_group.setEnabled(True)
            else:
                self.gui.ch2_waveform_selector.setEnabled(True)
                self.gui.ch2_sine_group.setEnabled(True)
                self.gui.ch2_prbs_group.setEnabled(True)
                self.gui.ch2_lfm_group.setEnabled(True) 
                self.gui.ch2_noise_group.setEnabled(True)
                self.gui.ch2_upload_group.setEnabled(False)

    def handle_browse_file(self, channel):
        file_path = QFileDialog.getExistingDirectory(self.gui, "Select Folder to Save CSV")

        if file_path:
            if channel == 1:
                self.gui.ch1_file_path_input.setText(file_path)
            elif channel == 2:
                self.gui.ch2_file_path_input.setText(file_path)
 
    def handle_upload_waveform(self, file_path, channel):
        username, password = self.handle_login_ssh()
        """Upload waveform file to the AWG"""
        '''if not self.check_awg_connection():
            return'''
        
        if not file_path:
            self.gui.log_box.append("❌ Please select a waveform file to upload.")
            return
        
        try:
            if channel == 1:
                self.ch1_file_path = file_path
            elif channel == 2:
                self.ch2_file_path = file_path 
            elif self.gui.ch1_upload_check_bx.isChecked():
                self.ch1_file_path = self.gui.ch1_file_path_input.text().strip()
            elif self.gui.ch2_upload_check_bx.isChecked():
                self.ch2_file_path = self.gui.ch2_file_path_input.text().strip() 
            ssh = paramiko.SSHClient()
            ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            remote_ip = self.gui.ip_input.text().strip()
            
            self.remote_path = "C:/Users/Administrator/Desktop/CH/"
            ssh.connect(remote_ip, username=username, password=password)

                    # ✅ Delete all folders inside the remote directory
            delete_cmd = f'''powershell -Command "Get-ChildItem -Path '{self.remote_path}' -Directory | Remove-Item -Recurse -Force"'''
            stdin, stdout, stderr = ssh.exec_command(delete_cmd)
            err_output = stderr.read().decode().strip()
            if err_output:
                self.gui.log_box.append(f"⚠️ Remote delete warning: {err_output}")


            with SCPClient(ssh.get_transport()) as scp:
                scp.put(file_path, self.remote_path, recursive=True)

            self.gui.log_box.append("✅ Folder transferred successfully.")

                   

        except Exception as e:
            self.gui.log_box.append(f"❌ Exception: {str(e)}")
            return False
        
    def handle_login_ssh(self):
        dialogue = QDialog(self.gui)
        dialogue.setWindowTitle("SSH Login")
        dialogue.setFixedSize(400, 400) 

        layout = QVBoxLayout(dialogue)
        username_input = QLineEdit("Administrator", dialogue)
        username_input.setPlaceholderText("Username")
        password_input = QLineEdit("Administrator", dialogue)
        password_input.setPlaceholderText("Password")
        password_input.setEchoMode(QLineEdit.Password)

        layout.addWidget(QLabel("Username:"))
        layout.addWidget(username_input)
        layout.addWidget(QLabel("Password:"))
        layout.addWidget(password_input)
        button_layout = QHBoxLayout()
        ok_button = QPushButton("OK", dialogue)
        cancel_button = QPushButton("Cancel", dialogue)
        button_layout.addWidget(ok_button)
        button_layout.addWidget(cancel_button)
        layout.addLayout(button_layout)

        ok_button.clicked.connect(dialogue.accept)
        cancel_button.clicked.connect(dialogue.reject)

        if dialogue.exec_() == QDialog.Accepted:
            username = username_input.text().strip()
            password = password_input.text().strip()
            return username, password
            if not username or not password:
                QMessageBox.warning(self.gui, "Input Required", "Please enter both username and password")
                return

    def toggle_wave_selector_check(self):
        self.gui.sine_param_grp.setEnabled(self.gui.sine_check_bx.isChecked())
        self.gui.prbs_param_grp.setEnabled(self.gui.prbs_check_bx.isChecked())
        self.gui.lfm_param_grp.setEnabled(self.gui.lfm_check_bx.isChecked())
        self.gui.noise_param_grp.setEnabled(self.gui.noise_check_bx.isChecked())
        self.gui.step_lfm_param_grp.setEnabled(self.gui.step_lfm_check_bx.isChecked())
    
    def toggle_ch_bx(self):
        state_1 = self.gui.ch1_cb.isChecked()
        state_2 = self.gui.ch2_cb.isChecked()
        if state_1 and state_2:
            QMessageBox.warning(self.gui, "Warning!!!!", "Select only one channel at a time!")
            self.gui.ch1_cb.setChecked(False)
            self.gui.ch2_cb.setChecked(False)

        elif state_1 and not state_2:
            # CH1 checked → disable CH2
            self.gui.ch2_cb.setEnabled(False)
            self.gui.ch1_cb.setEnabled(True)

        elif state_2 and not state_1:
            # CH2 checked → disable CH1
            self.gui.ch1_cb.setEnabled(False)
            self.gui.ch2_cb.setEnabled(True)

        else:
            # None checked OR both checked → enable both
            self.gui.ch1_cb.setEnabled(True)
            self.gui.ch2_cb.setEnabled(True)


    def handle_combined_waveform(self, channel):
        fig = make_subplots(rows=2, cols=1, subplot_titles=("Combined Waveform", "FFT of Combined Waveform"))

        # --- number of samples ---
        try:
            num_samples = int(self.gui.num_samples_input.text().strip())
            start_amp = float(getattr(self.gui, f'ch{channel}_start_amp').text().strip())
            stop_amp = float(getattr(self.gui, f'ch{channel}_stop_amp').text().strip())
            step_amp = float(getattr(self.gui, f'ch{channel}_step_amp').text().strip())

        except ValueError:
            QMessageBox.warning(self.gui, "Input Required", "Please enter all values!")
            self.gui.log_box.append("❌ Please enter a valid number of samples")
            return

        combined_waveform = CombinedWaveformGenerator()
        wave = np.zeros(num_samples)

        # --- folder to save ---
        combined_folder = QFileDialog.getExistingDirectory(self.gui, "Select Folder to Save CSV") 
        if not combined_folder:
            return
        datetime_1 = datetime.now().strftime("%Y%m%d_%H%M")
        self.folder_name = f"combined_{datetime_1}"
        full_path = os.path.join(combined_folder, self.folder_name)
        os.makedirs(full_path, exist_ok=True)

        # --- loop through waveform slots ---
        for i, cb in enumerate(self.gui.wave_boxes):
            if not cb.isChecked():
                continue

            wf_type = self.gui.dropdown_boxes[i].currentText()
            if wf_type == "Select":
                continue

            params = {}
            # get parameter widgets from param_groups[i]
            param_layout = self.gui.param_groups[i].layout()
            for j in range(param_layout.rowCount()):
                label_item = param_layout.itemAt(j, QFormLayout.LabelRole)
                field_item = param_layout.itemAt(j, QFormLayout.FieldRole)
                if label_item and field_item:
                    key = label_item.widget().text().rstrip(":")
                    val = field_item.widget().text().strip()
                    params[key] = val

            # --- generate waveform based on type ---
            if wf_type == "Sine":
                frequency = float(params.get("Frequency", 1e6))
                t, w = combined_waveform.sinusoidal(num_samples=num_samples, frequency=frequency)
            elif wf_type == "PRBS":
                order = int(params.get("Order", 7))
                repetition_rate = int(params.get("Repetition Rate", 1e6))
                t, w = combined_waveform.PRBS(num_samples=num_samples, order=order, repetition_rate=repetition_rate)
            elif wf_type == "LFM":
                center_freq = float(params.get("Center Freq", 1e6))
                bandwidth = float(params.get("Bandwidth", 1e6))
                pulse_width = int(params.get("Pulse Width", 100))
                t, w = combined_waveform.generate_lfm(num_samples=num_samples, center_freq=center_freq,
                                                      bandwidth=bandwidth, pulse_width=pulse_width)
            elif wf_type == "Step LFM":
                start_freq = float(params.get("Start Freq", 1e6))
                stop_freq = float(params.get("Stop Freq", 2e6))
                step_freq = float(params.get("Step Freq", 1e5))
                dwell_time = float(params.get("Dwell Time", 10))
                t, w = combined_waveform.generate_steplfm(num_samples=num_samples, start_freq=start_freq,
                                                          stop_freq=stop_freq, step_freq=step_freq,
                                                          dwell_time=dwell_time)
            elif wf_type == "Noise":
                variance = float(params.get("Variance", 1))
                t, w = combined_waveform.generate_noise(num_samples=num_samples, variance=variance)
            else:
                continue

            wave += w

        # --- FFT ---
        f, x = self.fft_signal(wave, iota=2)
        t = np.arange(num_samples) / 7.2e9

        # --- save ---
        self.save_waveform_to_csv(waveform_data=wave, waveform_type="combined", channel='channel', folder=full_path)
        if self.gui.ch1_cb.isChecked():
            channel = 1
            self.handle_upload_waveform(channel=channel, file_path=full_path)
        elif self.gui.ch2_cb.isChecked():
            channel = 2
            self.handle_upload_waveform(channel=channel, file_path=full_path)
        else:
            QMessageBox.warning(self.gui, "Channel required", "Select a channel")        

        # --- plot ---
        fig.add_trace(go.Scatter(x=t * 1e9, y=wave, mode='lines', name='Combined Waveform'), row=1, col=1)
        fig.add_trace(go.Scatter(x=f, y=x, mode='lines', name='FFT of Combined Waveform'), row=2, col=1)

        fig.update_xaxes(title_text="Time (ns)", row=1, col=1)
        fig.update_yaxes(title_text="Amplitude", row=2, col=1)
        fig.update_xaxes(title_text="F (GHz)", row=2, col=1)
        fig.update_yaxes(title_text="Power dBm", row=2, col=1)

        html = pio.to_html(fig, full_html=False, include_plotlyjs='cdn')
        self.gui.plot_view.setHtml(html)

    