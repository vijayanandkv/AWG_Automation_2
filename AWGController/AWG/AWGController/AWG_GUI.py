import sys
import os
import csv
import scipy
import time
from scipy import signal
from PyQt5.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, QTabWidget, QGroupBox,
    QLabel, QPushButton, QLineEdit, QTextEdit, QComboBox, QFileDialog, QFormLayout,
    QMessageBox, QCheckBox
)
from PyQt5.QtWebEngineWidgets import QWebEngineView
from PyQt5.QtGui import QPixmap, QColor, QPainter
from PyQt5.QtCore import QSize, Qt

from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg as FigureCanvas
from matplotlib.figure import Figure

import plotly.graph_objects as go
import plotly.io as pio

import numpy as np

from config_loader import load_config


from AWG_GUI_handler import AWG_GUI_handler

CONFIG = load_config()

class StatusLight(QLabel):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setFixedSize(20, 20)
        self.set_connected(False)

    def set_connected(self, connected):
        pixmap = QPixmap(self.size())
        pixmap.fill(QColor("transparent"))
        painter = QPainter(pixmap)
        color = QColor(0, 255, 0) if connected else QColor(0, 100, 0)
        painter.setBrush(color)
        painter.setPen(QColor("black"))
        painter.drawEllipse(0, 0, 20, 20)
        painter.end()
        self.setPixmap(pixmap)

class AWGGui(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle(CONFIG.get("window", {}).get("title", "AWG Automation GUI"))
        self.setGeometry(100, 100, CONFIG["window"]["width"], CONFIG["window"]["height"])

        self.handler = AWG_GUI_handler(self)

        self.channel1_on = False
        self.channel2_on = False
        self.output1_on = False
        self.output2_on = False
        

        self.tabs = QTabWidget()
        self.setCentralWidget(self.tabs)
        self.tab_widgets = {}

        for tab_name in CONFIG.get("tabs", {}):
            widget = QWidget()
            self.tabs.addTab(widget, tab_name)
            self.tab_widgets[tab_name] = widget
        for tab_name, enabled in CONFIG.get("tabs", {}).items():
            index = self.tabs.indexOf(self.tab_widgets[tab_name])
            self.tabs.setTabEnabled(index, enabled)


        for tab_name in self.tab_widgets:
            method_name = f"init_{tab_name.lower().replace(' ', '_')}_tab"
            if hasattr(self, method_name):
                setattr(self, f"{tab_name.lower().replace(' ', '_')}_tab", self.tab_widgets[tab_name])
                getattr(self, method_name)()

    def init_settings_tab(self):
        layout = QHBoxLayout()
        side_panel = QVBoxLayout()
        main_panel = QVBoxLayout()
        connection_box = QGroupBox()
        connection_layout = QHBoxLayout()

        self.status_light = StatusLight()
        side_panel.addWidget(self.status_light)

        form_layout = QFormLayout()
        self.ip_input = QLineEdit("WINDOWS-EJL97HL")
        form_layout.addRow("AWG IP Address:", self.ip_input)

        connection_layout.addLayout(form_layout)
        connection_box.setLayout(connection_layout)
        side_panel.addWidget(connection_box)

        connect_btn_box = QGroupBox()
        connect_btn_layout = QHBoxLayout()
        self.connect_btn = QPushButton(CONFIG['buttons']['connect']['label'])
        self.disconnect_btn = QPushButton(CONFIG['buttons']['disconnect']['label'])
        connect_btn_layout.addWidget(self.connect_btn)
        connect_btn_layout.addWidget(self.disconnect_btn)
        connect_btn_box.setLayout(connect_btn_layout)
        side_panel.addWidget(connect_btn_box)

        ch1_btn_group = QGroupBox()
        ch1_btn_layout = QHBoxLayout()
        self.ch1_on_btn = QPushButton(CONFIG['buttons']['CH1_Enable']['label'])
        self.ch1_off_btn = QPushButton(CONFIG['buttons']['CH1_Disable']['label'])
        self.ch1_on_btn.setEnabled(False)
        self.ch1_off_btn.setEnabled(False)
        ch1_btn_layout.addWidget(self.ch1_on_btn)
        ch1_btn_layout.addWidget(self.ch1_off_btn)
        ch1_btn_group.setLayout(ch1_btn_layout)
        side_panel.addWidget(ch1_btn_group)

        ch2_btn_group = QGroupBox()
        ch2_btn_layout = QHBoxLayout()
        self.ch2_on_btn = QPushButton(CONFIG['buttons']['CH2_Enable']['label'])
        self.ch2_off_btn = QPushButton(CONFIG['buttons']['CH2_Disable']['label'])
        self.ch2_on_btn.setEnabled(False)
        self.ch2_off_btn.setEnabled(False)
        ch2_btn_layout.addWidget(self.ch2_on_btn)
        ch2_btn_layout.addWidget(self.ch2_off_btn)
        ch2_btn_group.setLayout(ch2_btn_layout)
        side_panel.addWidget(ch2_btn_group)
        side_panel.addStretch()

        self.log_box = QTextEdit()
        self.log_box.setReadOnly(True)
        main_panel.addWidget(QLabel("SCPI Command Log"))
        main_panel.addWidget(self.log_box)

        layout.addLayout(side_panel, 1)
        layout.addLayout(main_panel, 3)
        self.settings_tab.setLayout(layout)

        # Connect button signals
        self.connect_btn.clicked.connect(self.handler.handle_connect)
        self.disconnect_btn.clicked.connect(self.handler.handle_disconnect)
        self.ch1_on_btn.clicked.connect(lambda: self.handler.handle_channel_enable(1))
        self.ch1_off_btn.clicked.connect(lambda: self.handler.handle_channel_disable(1))
        self.ch2_on_btn.clicked.connect(lambda: self.handler.handle_channel_enable(2))
        self.ch2_off_btn.clicked.connect(lambda: self.handler.handle_channel_disable(2))

    def init_channel_1_tab(self):
        layout = QHBoxLayout()
        side_panel = QVBoxLayout()
        main_panel = QVBoxLayout()

         # Waveform selection
        waveform_group = QGroupBox()
        waveform_layout = QHBoxLayout()
        waveform_label = QLabel("Select Waveform:")
        self.ch1_waveform_selector = QComboBox()
        self.ch1_waveform_selector.addItems(CONFIG["waveforms"]["options"])
        self.ch1_waveform_selector.currentTextChanged.connect(lambda text: self.handler.update_waveform_inputs(text, 1))
        waveform_layout.addWidget(waveform_label)
        waveform_layout.addWidget(self.ch1_waveform_selector)
        waveform_group.setLayout(waveform_layout)
        side_panel.addWidget(waveform_group)

        # Parameters group
        self.ch1_common_param_group = QGroupBox("Parameters")
        common_param_form = QFormLayout()

        self.ch1_start_amp = QLineEdit()
        self.ch1_stop_amp = QLineEdit()
        self.ch1_step_amp = QLineEdit()

        common_param_form.addRow("Start Amplitude (V):",self.ch1_start_amp)
        common_param_form.addRow("Stop Amplitude (V):",self.ch1_stop_amp)
        common_param_form.addRow("Step Amplitude (V):",self.ch1_step_amp)

        self.ch1_common_param_group.setLayout(common_param_form)
        self.ch1_common_param_group.setVisible(True)
        side_panel.addWidget(self.ch1_common_param_group)
        
        # Sine parameters
        self.ch1_sine_group = QGroupBox()
        ch1_sine_layout = QFormLayout()

        self.ch1_start_freq = QLineEdit()
        self.ch1_stop_freq = QLineEdit()
        self.ch1_step_freq = QLineEdit()
        self.ch1_generate_sine_wave_btn = QPushButton(CONFIG['buttons']['Generate_waveform']['label'])
        
        ch1_sine_layout.addRow("Start Frequency (GHz):", self.ch1_start_freq)
        ch1_sine_layout.addRow("Stop Frequency (GHz):", self.ch1_stop_freq)
        ch1_sine_layout.addRow("Step Frequency (GHz):", self.ch1_step_freq)
        ch1_sine_layout.addRow(self.ch1_generate_sine_wave_btn)

        self.ch1_sine_group.setLayout(ch1_sine_layout)      
        self.ch1_sine_group.setVisible(False)
        side_panel.addWidget(self.ch1_sine_group)
        
        # PRBS parameters
        self.ch1_prbs_group = QGroupBox()
        prbs_layout = QFormLayout()
        
        self.ch1_start_order = QLineEdit()
        self.ch1_stop_order = QLineEdit()
        self.ch1_step_order = QLineEdit()
        self.ch1_prbs_repetition_rate = QLineEdit()

        prbs_layout.addRow("Start Order:", self.ch1_start_order)
        prbs_layout.addRow("Stop Order:", self.ch1_stop_order)
        prbs_layout.addRow("Step Order:", self.ch1_step_order)
        prbs_layout.addRow("Repetition Rate", self.ch1_prbs_repetition_rate)
        self.ch1_generate_prbs_wave_btn = QPushButton(CONFIG['buttons']['Generate_waveform']['label'])
        prbs_layout.addRow(self.ch1_generate_prbs_wave_btn)

        self.ch1_prbs_group.setLayout(prbs_layout)
        self.ch1_prbs_group.setVisible(False)
        side_panel.addWidget(self.ch1_prbs_group)
        
        # Noise parameters
        self.ch1_noise_group = QGroupBox()
        noise_layout = QFormLayout()

        self.ch1_start_variance = QLineEdit()
        self.ch1_stop_variance = QLineEdit()
        self.ch1_step_variance = QLineEdit()
        self.ch1_generate_noise_wave_btn = QPushButton(CONFIG['buttons']['Generate_waveform']['label'])
        noise_layout.addRow("Start Variance (Hz):", self.ch1_start_variance)
        noise_layout.addRow("Stop Variance (Hz):", self.ch1_stop_variance)
        noise_layout.addRow("Step Variance (Hz):", self.ch1_step_variance)
        noise_layout.addRow(self.ch1_generate_noise_wave_btn)

        self.ch1_noise_group.setLayout(noise_layout)
        self.ch1_noise_group.setVisible(False)
        side_panel.addWidget(self.ch1_noise_group)
                
        # LFM parameters
        self.ch1_lfm_group = QGroupBox()
        lfm_layout = QFormLayout()

        self.ch1_start_center_freq = QLineEdit()
        self.ch1_stop_center_freq = QLineEdit()
        self.ch1_step_center_freq = QLineEdit()
        self.ch1_lfm_pulse_width = QLineEdit()
        self.ch1_lfm_bandwidth = QLineEdit()
        self.ch1_generate_lfm_wave_btn = QPushButton(CONFIG['buttons']['Generate_waveform']['label'])
        lfm_layout.addRow("Starting Center Freq (GHz):", self.ch1_start_center_freq)
        lfm_layout.addRow("Stoping Center Freq (GHz):", self.ch1_stop_center_freq)
        lfm_layout.addRow("Step Center Freq (GHz):", self.ch1_step_center_freq)
        lfm_layout.addRow("Pulse width (ns):", self.ch1_lfm_pulse_width)
        lfm_layout.addRow("Bandwidth (GHz):", self.ch1_lfm_bandwidth)
        lfm_layout.addRow(self.ch1_generate_lfm_wave_btn)

        self.ch1_lfm_group.setLayout(lfm_layout)
        self.ch1_lfm_group.setVisible(False)
        side_panel.addWidget(self.ch1_lfm_group)

        # step LFM parameters
        self.ch1_step_lfm_group = QGroupBox()
        step_lfm_layout = QFormLayout()

        self.ch1_lfm_start_freq = QLineEdit()
        self.ch1_lfm_stop_freq = QLineEdit()
        self.ch1_lfm_step_freq = QLineEdit()
        self.ch1_lfm_dwell_time = QLineEdit()
        self.ch1_generate_step_lfm_wave_btn = QPushButton(CONFIG['buttons']['Generate_waveform']['label'])
        step_lfm_layout.addRow("Starting Freq (GHz):", self.ch1_lfm_start_freq)
        step_lfm_layout.addRow("Stoping Freq (GHz):", self.ch1_lfm_stop_freq)
        step_lfm_layout.addRow("Step Freq (GHz):", self.ch1_lfm_step_freq)
        step_lfm_layout.addRow("Dwell time (ns):", self.ch1_lfm_dwell_time)
        step_lfm_layout.addRow(self.ch1_generate_step_lfm_wave_btn)

        self.ch1_step_lfm_group.setLayout(step_lfm_layout)
        self.ch1_step_lfm_group.setVisible(False)
        side_panel.addWidget(self.ch1_step_lfm_group)

        #Upload waveform
        self.ch1_upload_check_group = QGroupBox("Upload Waveform")
        upload_layout = QHBoxLayout()
        self.ch1_upload_check_bx = QCheckBox("Upload Waveform to AWG")
        self.ch1_upload_check_bx.stateChanged.connect(lambda: self.handler.toggle_upload_check(1))
        upload_layout.addWidget(self.ch1_upload_check_bx)
        self.ch1_upload_check_group.setLayout(upload_layout)
        side_panel.addWidget(self.ch1_upload_check_group)

        #upload file 
        self.ch1_upload_group = QGroupBox("Upload Waveform File")
        upload_file_layout = QFormLayout()
        upload_btns_layout = QHBoxLayout()
        self.ch1_file_path_input = QLineEdit()
        self.ch1_file_path_input.setReadOnly(True)
        self.ch1_browse_btn = QPushButton(CONFIG['buttons']['browse']['label'])
        self.ch1_upload_btn = QPushButton(CONFIG['buttons']['upload']['label'])

        upload_file_layout.addRow("Waveform File Path:", self.ch1_file_path_input)
        upload_btns_layout.addWidget(self.ch1_browse_btn)
        upload_btns_layout.addWidget(self.ch1_upload_btn)
        upload_file_layout.addRow(upload_btns_layout)
        self.ch1_upload_group.setLayout(upload_file_layout)
        self.ch1_upload_group.setEnabled(False)
        side_panel.addWidget(self.ch1_upload_group)


        
        # Run group
        ch1_run_group = QGroupBox()
        run_layout = QFormLayout()
        self.ch1_run_btn = QPushButton(CONFIG["buttons"]['run']['label'])
        self.ch1_abort_btn = QPushButton(CONFIG['buttons']['abort']['label'])
        run_layout.addRow(self.ch1_run_btn)
        run_layout.addRow(self.ch1_abort_btn)
        ch1_run_group.setLayout(run_layout)
        side_panel.addWidget(ch1_run_group)

     
        # Create the interactive Plotly view for channel 1
        plot_group = QGroupBox("Sample waveform")
        plot_layout = QHBoxLayout()

        self.ch1_plot_view = QWebEngineView()  # This replaces the canvas
        plot_layout.addWidget(self.ch1_plot_view)

        plot_group.setLayout(plot_layout)
        main_panel.addWidget(plot_group)

        layout.addLayout(side_panel, 1)
        layout.addLayout(main_panel, 3)
        self.channel_1_tab.setLayout(layout)
        
        # Update initial state
        self.handler.update_waveform_inputs(self.ch1_waveform_selector.currentText(), 1)

        # Connect signals
        self.ch1_generate_sine_wave_btn.clicked.connect(lambda: self.handler.handle_generate_waveform(1))
        self.ch1_generate_prbs_wave_btn.clicked.connect(lambda: self.handler.handle_generate_waveform(1))
        self.ch1_generate_noise_wave_btn.clicked.connect(lambda: self.handler.handle_generate_waveform(1))
        self.ch1_generate_lfm_wave_btn.clicked.connect(lambda: self.handler.handle_generate_waveform(1))
        self.ch1_generate_step_lfm_wave_btn.clicked.connect(lambda: self.handler.handle_generate_waveform(1))

        self.ch1_browse_btn.clicked.connect(lambda: self.handler.handle_browse_file(1))
        self.ch1_upload_btn.clicked.connect(lambda: self.handler.handle_upload_waveform(file_path= self.ch1_file_path_input.text().strip(), channel = 1))

        self.ch1_run_btn.clicked.connect(lambda: self.handler.run(channel=1))
        self.ch1_abort_btn.clicked.connect(lambda: self.handler.handle_abort(1))

    def init_channel_2_tab(self):
        layout = QHBoxLayout()
        side_panel = QVBoxLayout()
        main_panel = QVBoxLayout()

        # Waveform selection
        waveform_group = QGroupBox()
        waveform_layout = QHBoxLayout()
        waveform_label = QLabel("Select Waveform:")
        self.ch2_waveform_selector = QComboBox()
        self.ch2_waveform_selector.addItems(CONFIG["waveforms"]["options"])
        self.ch2_waveform_selector.currentTextChanged.connect(lambda text: self.handler.update_waveform_inputs(text, 2))
        waveform_layout.addWidget(waveform_label)
        waveform_layout.addWidget(self.ch2_waveform_selector)
        waveform_group.setLayout(waveform_layout)
        side_panel.addWidget(waveform_group)

         #Common Parameters group
        self.ch2_common_param_group = QGroupBox("Parameters")
        common_param_form = QFormLayout()

        self.ch2_start_amp = QLineEdit()
        self.ch2_stop_amp = QLineEdit()
        self.ch2_step_amp = QLineEdit()

        common_param_form.addRow("Start Amplitude (V):",self.ch2_start_amp)
        common_param_form.addRow("Stop Amplitude (V):",self.ch2_stop_amp)
        common_param_form.addRow("Step Amplitude (V):",self.ch2_step_amp)

        self.ch2_common_param_group.setLayout(common_param_form)
        self.ch2_common_param_group.setVisible(True)
        side_panel.addWidget(self.ch2_common_param_group)
        
        # Sine parameters
        self.ch2_sine_group = QGroupBox()
        ch2_sine_layout = QFormLayout()

        self.ch2_start_freq = QLineEdit()
        self.ch2_stop_freq = QLineEdit()
        self.ch2_step_freq = QLineEdit()
        self.ch2_generate_sine_wave_btn = QPushButton(CONFIG['buttons']['Generate_waveform']['label'])
        
        ch2_sine_layout.addRow("Start Frequency (GHz):", self.ch2_start_freq)
        ch2_sine_layout.addRow("Stop Frequency (GHz):", self.ch2_stop_freq)
        ch2_sine_layout.addRow("Step Frequency (GHz):", self.ch2_step_freq)
        ch2_sine_layout.addRow(self.ch2_generate_sine_wave_btn)

        self.ch2_sine_group.setLayout(ch2_sine_layout)
        self.ch2_sine_group.setVisible(False)
        side_panel.addWidget(self.ch2_sine_group)       
        
       # PRBS parameters
        self.ch2_prbs_group = QGroupBox()
        prbs_layout = QFormLayout()

        self.ch2_start_order = QLineEdit()
        self.ch2_stop_order = QLineEdit()
        self.ch2_step_order = QLineEdit()
        self.ch2_prbs_repetition_rate = QLineEdit()
        self.ch2_generate_prbs_wave_btn = QPushButton(CONFIG['buttons']['Generate_waveform']['label'])

        prbs_layout.addRow("Start Order:", self.ch2_start_order)
        prbs_layout.addRow("Stop Order:", self.ch2_stop_order)
        prbs_layout.addRow("Step Order:", self.ch2_step_order)
        prbs_layout.addRow("Repetition Rate", self.ch2_prbs_repetition_rate)
        prbs_layout.addRow(self.ch2_generate_prbs_wave_btn)

        self.ch2_prbs_group.setLayout(prbs_layout)
        self.ch2_prbs_group.setVisible(True)
        side_panel.addWidget(self.ch2_prbs_group)
        
        # Noise parameters
        self.ch2_noise_group = QGroupBox()
        noise_layout = QFormLayout()

        self.ch2_start_variance = QLineEdit()
        self.ch2_stop_variance = QLineEdit()
        self.ch2_step_variance = QLineEdit()
        self.ch2_generate_noise_wave_btn = QPushButton(CONFIG['buttons']['Generate_waveform']['label'])
        noise_layout.addRow("Start Variance (Hz):", self.ch2_start_variance)
        noise_layout.addRow("Stop Variance (Hz):", self.ch2_stop_variance)
        noise_layout.addRow("Step Variance (Hz):", self.ch2_step_variance)
        noise_layout.addRow(self.ch2_generate_noise_wave_btn)

        self.ch2_noise_group.setLayout(noise_layout)
        self.ch2_noise_group.setVisible(False)
        side_panel.addWidget(self.ch2_noise_group)
        
        # LFM parameters
        self.ch2_lfm_group = QGroupBox()
        lfm_layout = QFormLayout()

        self.ch2_start_center_freq = QLineEdit()
        self.ch2_stop_center_freq = QLineEdit()
        self.ch2_step_center_freq = QLineEdit()
        self.ch2_lfm_pulse_width = QLineEdit()
        self.ch2_lfm_bandwidth = QLineEdit()
        self.ch2_generate_lfm_wave_btn = QPushButton(CONFIG['buttons']['Generate_waveform']['label'])
        lfm_layout.addRow("Starting Center Freq (GHz):", self.ch2_start_center_freq)
        lfm_layout.addRow("Stoping Center Freq (GHz):", self.ch2_stop_center_freq)
        lfm_layout.addRow("Step Center Freq (GHz):", self.ch2_step_center_freq)
        lfm_layout.addRow("Pulse width (ns):", self.ch2_lfm_pulse_width)
        lfm_layout.addRow("Bandwidth (GHz):", self.ch2_lfm_bandwidth)
        lfm_layout.addRow(self.ch2_generate_lfm_wave_btn)

        self.ch2_lfm_group.setLayout(lfm_layout)
        self.ch2_lfm_group.setVisible(False)
        side_panel.addWidget(self.ch2_lfm_group)

        # step LFM parameters
        self.ch2_step_lfm_group = QGroupBox()
        step_lfm_layout = QFormLayout()

        self.ch2_lfm_start_freq = QLineEdit()
        self.ch2_lfm_stop_freq = QLineEdit()
        self.ch2_lfm_step_freq = QLineEdit()
        self.ch2_lfm_dwell_time = QLineEdit()
        self.ch2_generate_step_lfm_wave_btn = QPushButton(CONFIG['buttons']['Generate_waveform']['label'])
        step_lfm_layout.addRow("Starting Freq (GHz):", self.ch2_lfm_start_freq)
        step_lfm_layout.addRow("Stoping Freq (GHz):", self.ch2_lfm_stop_freq)
        step_lfm_layout.addRow("Step Freq (GHz):", self.ch2_lfm_step_freq)
        step_lfm_layout.addRow("Dwell time (ns):", self.ch2_lfm_dwell_time)
        step_lfm_layout.addRow(self.ch2_generate_step_lfm_wave_btn)

        self.ch2_step_lfm_group.setLayout(step_lfm_layout)
        self.ch2_step_lfm_group.setVisible(False)
        side_panel.addWidget(self.ch2_step_lfm_group)

        #Upload waveform
        self.ch2_upload_check_group = QGroupBox("Upload Waveform")
        upload_layout = QHBoxLayout()
        self.ch2_upload_check_bx = QCheckBox("Upload Waveform to AWG")
        self.ch2_upload_check_bx.stateChanged.connect(lambda: self.handler.toggle_upload_check(2))
        upload_layout.addWidget(self.ch2_upload_check_bx)
        self.ch2_upload_check_group.setLayout(upload_layout)
        side_panel.addWidget(self.ch2_upload_check_group)

        #upload file 
        self.ch2_upload_group = QGroupBox("Upload Waveform File")
        upload_file_layout = QFormLayout()
        upload_btns_layout = QHBoxLayout()
        self.ch2_file_path_input = QLineEdit()
        self.ch2_file_path_input.setReadOnly(True)
        self.ch2_browse_btn = QPushButton(CONFIG['buttons']['browse']['label'])
        self.ch2_upload_btn = QPushButton(CONFIG['buttons']['upload']['label'])

        upload_file_layout.addRow("Waveform File Path:", self.ch2_file_path_input)
        upload_btns_layout.addWidget(self.ch2_browse_btn)
        upload_btns_layout.addWidget(self.ch2_upload_btn)
        upload_file_layout.addRow(upload_btns_layout)
        self.ch2_upload_group.setLayout(upload_file_layout)
        self.ch2_upload_group.setEnabled(False)
        side_panel.addWidget(self.ch2_upload_group)

        # Run group

        ch2_run_group = QGroupBox()
        run_layout = QFormLayout()
        self.ch2_run_btn = QPushButton(CONFIG["buttons"]['run']['label'])
        self.ch2_abort_btn = QPushButton(CONFIG['buttons']['abort']['label'])
        run_layout.addRow(self.ch2_run_btn)
        run_layout.addRow(self.ch2_abort_btn)
        ch2_run_group.setLayout(run_layout)
        side_panel.addWidget(ch2_run_group)

        # Create the plot canvas and axes for channel 2
        plot_group = QGroupBox("Sample waveform")
        plot_layout = QHBoxLayout()
        self.ch2_plot_view = QWebEngineView()  # This replaces the canvas
        plot_layout.addWidget(self.ch2_plot_view)


        #plot_layout.addWidget(self.ch2_canvas)     
        plot_group.setLayout(plot_layout)

        # Add the plot to the main panel
        main_panel.addWidget(plot_group)

        layout.addLayout(side_panel, 1)
        layout.addLayout(main_panel, 3)
        self.channel_2_tab.setLayout(layout)
        
        # Update initial state
        self.handler.update_waveform_inputs(self.ch2_waveform_selector.currentText(), 2)

        # Connect signals
        self.ch2_generate_sine_wave_btn.clicked.connect(lambda: self.handler.handle_generate_waveform(2))
        self.ch2_generate_prbs_wave_btn.clicked.connect(lambda: self.handler.handle_generate_waveform(2))
        self.ch2_generate_noise_wave_btn.clicked.connect(lambda: self.handler.handle_generate_waveform(2))
        self.ch2_generate_lfm_wave_btn.clicked.connect(lambda: self.handler.handle_generate_waveform(2))
        self.ch2_generate_step_lfm_wave_btn.clicked.connect(lambda: self.handler.handle_generate_waveform(2))

        self.ch2_browse_btn.clicked.connect(lambda: self.handler.handle_browse_file(2))
        self.ch2_upload_btn.clicked.connect(lambda:self.handler.handle_upload_waveform(file_path= self.ch2_file_path_input.text().strip(), channel=2))
        self.ch2_run_btn.clicked.connect(lambda: self.handler.run(2))
        self.ch2_abort_btn.clicked.connect(lambda: self.handler.handle_abort(2))

    def init_channel_1_output_tab(self):
        layout = QHBoxLayout()
        side_panel = QVBoxLayout()
        main_panel = QVBoxLayout()



        # Add layouts
        layout.addLayout(side_panel, 1)
        layout.addLayout(main_panel, 3)
        self.channel_1_output_tab.setLayout(layout)


    def init_channel_2_output_tab(self):
        layout = QHBoxLayout()
        side_panel = QVBoxLayout()
        main_panel = QVBoxLayout()

 


        # Add layouts
        layout.addLayout(side_panel, 1)
        layout.addLayout(main_panel, 3)
        self.channel_2_output_tab.setLayout(layout)

    def init_combined_waveform_tab(self):

        layout = QHBoxLayout()
        side_panel = QVBoxLayout()
        main_panel = QVBoxLayout()

        #Select Sine Wave check box
        self.sine_check_grp = QGroupBox("Select Sine Wave")
        sine_check_layout = QHBoxLayout()
        self.sine_check_bx = QCheckBox("Sine Wave")
        self.sine_check_bx.stateChanged.connect(lambda: self.handler.toggle_wave_selector_check())
        self.prbs_check_bx = QCheckBox("PRBS")
        self.prbs_check_bx.stateChanged.connect(lambda: self.handler.toggle_wave_selector_check())
        self.lfm_check_bx = QCheckBox("LFM")
        self.lfm_check_bx.stateChanged.connect(lambda: self.handler.toggle_wave_selector_check())
        self.noise_check_bx = QCheckBox("Noise")
        self.noise_check_bx.stateChanged.connect(lambda: self.handler.toggle_wave_selector_check())
        self.step_lfm_check_bx = QCheckBox("Step LFM")
        self.step_lfm_check_bx.stateChanged.connect(lambda: self.handler.toggle_wave_selector_check())

        sine_check_layout.addWidget(self.sine_check_bx)
        sine_check_layout.addWidget(self.prbs_check_bx)
        sine_check_layout.addWidget(self.lfm_check_bx)
        sine_check_layout.addWidget(self.noise_check_bx)
        sine_check_layout.addWidget(self.step_lfm_check_bx)
        self.sine_check_grp.setLayout(sine_check_layout)
        side_panel.addWidget(self.sine_check_grp)

        #parameters for sine wave
        self.sine_param_grp = QGroupBox("Sine Wave Parameters")
        sine_param_layout = QFormLayout()
        self.sine_frequency = QLineEdit()
        sine_param_layout.addRow("Frequency", self.sine_frequency)
        self.sine_param_grp.setLayout(sine_param_layout)
        self.sine_param_grp.setEnabled(False)
        side_panel.addWidget(self.sine_param_grp)


        #parameters for PRBS
        self.prbs_param_grp = QGroupBox("PRBS Parameters")
        prbs_param_layout = QFormLayout()
        self.prbs_order = QLineEdit()
        prbs_param_layout.addRow("Order:", self.prbs_order)
        self.prbs_repetition_rate = QLineEdit() 
        prbs_param_layout.addRow("Repetition Rate (MHz):", self.prbs_repetition_rate)
        self.prbs_param_grp.setLayout(prbs_param_layout)
        self.prbs_param_grp.setEnabled(False)
        side_panel.addWidget(self.prbs_param_grp)

        #parameters for LFM
        self.lfm_param_grp = QGroupBox("LFM Parameters")
        lfm_param_layout = QFormLayout()
        self.lfm_center_freq = QLineEdit()  
        lfm_param_layout.addRow("Center Frequency (GHz):", self.lfm_center_freq)
        self.lfm_bandwidth = QLineEdit()
        lfm_param_layout.addRow("Bandwidth (GHz):", self.lfm_bandwidth)
        self.lfm_pulse_width = QLineEdit()
        lfm_param_layout.addRow("Pulse Width (ns):", self.lfm_pulse_width)
        self.lfm_param_grp.setLayout(lfm_param_layout)
        self.lfm_param_grp.setEnabled(False)
        side_panel.addWidget(self.lfm_param_grp)

        #parameters for Noise
        self.noise_param_grp = QGroupBox("Noise Parameters")
        noise_param_layout = QFormLayout()
        self.noise_variance = QLineEdit()
        noise_param_layout.addRow("Variance (Hz):", self.noise_variance)
        self.noise_param_grp.setLayout(noise_param_layout)
        self.noise_param_grp.setEnabled(False)
        side_panel.addWidget(self.noise_param_grp)

        #parameters for Step LFM
        self.step_lfm_param_grp = QGroupBox("Step LFM Parameters")
        step_lfm_param_layout = QFormLayout()
        self.step_lfm_start_freq = QLineEdit()
        step_lfm_param_layout.addRow("Starting Frequency (GHz):", self.step_lfm_start_freq)
        self.step_lfm_stop_freq = QLineEdit()
        step_lfm_param_layout.addRow("Stopping Frequency (GHz):", self.step_lfm_stop_freq)
        self.step_lfm_step_freq = QLineEdit()
        step_lfm_param_layout.addRow("Step Frequency (GHz):", self.step_lfm_step_freq)
        self.step_lfm_dwell_time = QLineEdit()
        step_lfm_param_layout.addRow("Dwell Time (ns):", self.step_lfm_dwell_time)
        self.step_lfm_param_grp.setLayout(step_lfm_param_layout)
        self.step_lfm_param_grp.setEnabled(False)
        side_panel.addWidget(self.step_lfm_param_grp)

        #common num samples 
        num_samples_group = QGroupBox("Common Parameters")
        num_samples_layout = QFormLayout()
        self.num_samples_input = QLineEdit()
        num_samples_layout.addRow("Number of Samples:", self.num_samples_input)
        num_samples_group.setLayout(num_samples_layout)
        side_panel.addWidget(num_samples_group)
        

        #Generate waveform button
        self.generate_wave_group = QGroupBox()
        generate_wave_layout = QFormLayout()
        self.generate_wave_btn = QPushButton(CONFIG['buttons']['Generate_waveform']['label'])
        generate_wave_layout.addRow(self.generate_wave_btn)
        self.generate_wave_group.setLayout(generate_wave_layout)
        side_panel.addWidget(self.generate_wave_group)

        #plot group
        plot_group = QGroupBox("Sample waveform")
        plot_layout = QHBoxLayout()
        self.plot_view = QWebEngineView()
        plot_layout.addWidget(self.plot_view)
        plot_group.setLayout(plot_layout)
        main_panel.addWidget(plot_group)

        #connect buttons
        self.generate_wave_btn.clicked.connect(self.handler.handle_combined_waveform)

        layout.addLayout(side_panel, 1)
        layout.addLayout(main_panel, 3)
        self.combined_waveform_tab.setLayout(layout)

        


        
if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = AWGGui()
    window.show()
    sys.exit(app.exec_())