import os
import glob
import time
import threading

import numpy as np
from PyQt5.QtCore import QThread, pyqtSignal

from AWG_Controller import AWG_Controller
from logger import awg_logger




class AWGCommunicator(QThread):
    log = pyqtSignal(str)   # define a signal

    def __init__(self):
        super().__init__()
        self.awg = None
        self._running = True
        
    def connect_awg(self, ip_address):
        ip = ip_address        

        try:
            self.awg = AWG_Controller(ip_address=ip)
            self.connected = self.awg.connect()   
            return self.awg  
        except Exception as e:
            print(f'Error!!!! \n {e}')
            return None

    def disconnect_awg(self):
        if self.awg:
            try:
                self.awg.disconnect()
                self.awg = None
            except Exception as e:
                print(f'Error!!!!! \n {e}')
                
    def set_params(self, channel, amplitude_dict, local_path, remote_path):
        self.channel = channel
        self.amps = amplitude_dict
        self.local_path = local_path
        self.remote_path = remote_path
    def stop(self):
        self._running = False

    def run(self):
        if self.awg is None:
            self.log.emit("AWG not connected. Please connect to the AWG first.")
            return
        try:
            # clear any previous segment
            del_seg_log = self.awg.delete_segment(channel=self.channel, id=1)
            self.log.emit(f'{del_seg_log}')

            # iterate over waveform files
            for file in glob.glob(f"{self.local_path}/*.csv"):

                fname = os.path.basename(file)
                self.log.emit(f'file {fname} processing in channel {self.channel}')

                full_path = os.path.join(self.remote_path, fname).replace("\\", "/")

                # load file into AWG
                def_seg = self.awg.define_segment(channel=self.channel, segment_id=1, n_sample=720)
                impt_log = self.awg.import_file(channel=self.channel, filename=full_path)
                self.awg.set_output_state(channel=self.channel, state=1)
                self.log.emit(f'{def_seg} \n {impt_log}')
                # amplitude sweep
                for amplitude in np.arange(
                    self.amps["start_amp"],
                    self.amps["stop_amp"] + 0.001,
                    self.amps["step_amp"]
                ):

                    self.awg.abort_wave_generation(channel=self.channel)
                    out_log = self.awg.set_output_voltage_custom(channel=self.channel, value=amplitude)
                    init_log = self.awg.initiate_signal(channel=self.channel)

                    self.log.emit(f'Current amplitude is {amplitude} V')

                    for _ in range(180):
                        if not self._running:
                            return
                        time.sleep(1)

                # cleanup for this file
                abrt_log = self.awg.abort_wave_generation(channel=self.channel)
                del_log = self.awg.delete_segment(channel=self.channel, id=1)
                output_log = self.awg.set_output_state(channel=self.channel, state=0)
                self.log.emit(f'{out_log} \n {init_log} \n {abrt_log} \n {del_log} \n {output_log}')

        except Exception as e:
            self.log.emit(f"[CH{self.channel}] ❌ Error: {e}")
            
    def abort_awg_run(self, channel):
        try:
            self.awg.abort_wave_generation(channel=channel)
            return f"Success! 🛑 Waveform generation aborted for channel {channel}"
        except Exception as e:
            return e