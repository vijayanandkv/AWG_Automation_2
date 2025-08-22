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
from PyQt5.QtGui import QPixmap, QColor, QPainter
from PyQt5.QtCore import QSize, Qt

from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg as FigureCanvas
from matplotlib.figure import Figure
import numpy as np

from AWG_Controller import AWG_Controller
from WaveformGenerator import WaveformGenerator
from config_loader import load_config

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

        self.awg = None
        self.generator = None
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
        self.connect_btn.clicked.connect(self.handle_connect)
        self.disconnect_btn.clicked.connect(self.handle_disconnect)
        self.ch1_on_btn.clicked.connect(lambda: self.handle_channel_enable(1))
        self.ch1_off_btn.clicked.connect(lambda: self.handle_channel_disable(1))
        self.ch2_on_btn.clicked.connect(lambda: self.handle_channel_enable(2))
        self.ch2_off_btn.clicked.connect(lambda: self.handle_channel_disable(2))

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
        self.ch1_waveform_selector.currentTextChanged.connect(lambda text: self.update_waveform_inputs(text, 1))
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
        self.ch1_generate_wave_btn = QPushButton(CONFIG['buttons']['Generate_waveform']['label'])
        
        ch1_sine_layout.addRow("Start Frequency (GHz):", self.ch1_start_freq)
        ch1_sine_layout.addRow("Stop Frequency (GHz):", self.ch1_stop_freq)
        ch1_sine_layout.addRow("Step Frequency (GHz):", self.ch1_step_freq)
        ch1_sine_layout.addRow(self.ch1_generate_wave_btn)

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
        self.ch1_generate_wave_btn = QPushButton(CONFIG['buttons']['Generate_waveform']['label'])
        prbs_layout.addRow(self.ch1_generate_wave_btn)

        self.ch1_prbs_group.setLayout(prbs_layout)
        self.ch1_prbs_group.setVisible(False)
        side_panel.addWidget(self.ch1_prbs_group)
        
        # Noise parameters
        self.ch1_noise_group = QGroupBox()
        noise_layout = QFormLayout()

        self.ch1_start_variance = QLineEdit()
        self.ch1_stop_variance = QLineEdit()
        self.ch1_step_variance = QLineEdit()
        self.ch1_generate_wave_btn = QPushButton(CONFIG['buttons']['Generate_waveform']['label'])
        noise_layout.addRow("Start Variance (Hz):", self.ch1_start_variance)
        noise_layout.addRow("Stop Variance (Hz):", self.ch1_stop_variance)
        noise_layout.addRow("Step Variance (Hz):", self.ch1_step_variance)
        noise_layout.addRow(self.ch1_generate_wave_btn)

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
        self.ch1_generate_wave_btn = QPushButton(CONFIG['buttons']['Generate_waveform']['label'])
        lfm_layout.addRow("Starting Center Freq (GHz):", self.ch1_start_center_freq)
        lfm_layout.addRow("Stoping Center Freq (GHz):", self.ch1_stop_center_freq)
        lfm_layout.addRow("Step Center Freq (GHz):", self.ch1_step_center_freq)
        lfm_layout.addRow("Pulse width (ns):", self.ch1_lfm_pulse_width)
        lfm_layout.addRow("Bandwidth (GHz):", self.ch1_lfm_bandwidth)
        lfm_layout.addRow(self.ch1_generate_wave_btn)

        self.ch1_lfm_group.setLayout(lfm_layout)
        self.ch1_lfm_group.setVisible(False)
        side_panel.addWidget(self.ch1_lfm_group)

        #Upload waveform
        self.ch1_upload_check_group = QGroupBox("Upload Waveform")
        upload_layout = QHBoxLayout()
        self.ch1_upload_check_bx = QCheckBox("Upload Waveform to AWG")
        self.ch1_upload_check_bx.stateChanged.connect(lambda: self.toggle_upload_check(1))
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

     
        # Create the plot canvas and axes for channel 1
        plot_group = QGroupBox("Sample waveform")
        plot_layout = QHBoxLayout()

        self.ch1_canvas = FigureCanvas(Figure(figsize=(10, 3)))
        self.ch1_ax, self.ch1_ax_fft = self.ch1_canvas.figure.subplots(1, 2)
        plot_layout.addWidget(self.ch1_canvas)
        plot_group.setLayout(plot_layout)

        # Add the plot to the main panel
        main_panel.addWidget(plot_group)

        layout.addLayout(side_panel, 1)
        layout.addLayout(main_panel, 3)
        self.channel_1_tab.setLayout(layout)
        
        # Update initial state
        self.update_waveform_inputs(self.ch1_waveform_selector.currentText(), 1)

        # Connect signals
        self.ch1_generate_wave_btn.clicked.connect(lambda: self.handle_generate_waveform(1))
        self.ch1_run_btn.clicked.connect(lambda: self.run(1))
        self.ch1_abort_btn.clicked.connect(lambda: self.handle_abort(1))

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
        self.ch2_waveform_selector.currentTextChanged.connect(lambda text: self.update_waveform_inputs(text, 2))
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
        
        ch2_sine_layout.addRow("Start Frequency (GHz):", self.ch2_start_freq)
        ch2_sine_layout.addRow("Stop Frequency (GHz):", self.ch2_stop_freq)
        ch2_sine_layout.addRow("Step Frequency (GHz):", self.ch2_step_freq)

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

        prbs_layout.addRow("Start Order:", self.ch2_start_order)
        prbs_layout.addRow("Stop Order:", self.ch2_stop_order)
        prbs_layout.addRow("Step Order:", self.ch2_step_order)
        prbs_layout.addRow("Repetition Rate", self.ch2_prbs_repetition_rate)

        self.ch2_prbs_group.setLayout(prbs_layout)
        self.ch2_prbs_group.setVisible(True)
        side_panel.addWidget(self.ch2_prbs_group)
        
        # Noise parameters
        self.ch2_noise_group = QGroupBox()
        noise_layout = QFormLayout()

        self.ch2_start_variance = QLineEdit()
        self.ch2_stop_variance = QLineEdit()
        self.ch2_step_variance = QLineEdit()
        noise_layout.addRow("Start Variance (Hz):", self.ch2_start_variance)
        noise_layout.addRow("Stop Variance (Hz):", self.ch2_stop_variance)
        noise_layout.addRow("Step Variance (Hz):", self.ch2_step_variance)

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
        lfm_layout.addRow("Starting Center Freq (GHz):", self.ch2_start_center_freq)
        lfm_layout.addRow("Stoping Center Freq (GHz):", self.ch2_stop_center_freq)
        lfm_layout.addRow("Step Center Freq (GHz):", self.ch2_step_center_freq)
        lfm_layout.addRow("Pulse width (ns):", self.ch2_lfm_pulse_width)
        lfm_layout.addRow("Bandwidth (GHz):", self.ch2_lfm_bandwidth)

        self.ch2_lfm_group.setLayout(lfm_layout)
        self.ch2_lfm_group.setVisible(False)
        side_panel.addWidget(self.ch2_lfm_group)

        # Run group

        ch2_run_group = QGroupBox()
        run_layout = QFormLayout()
        self.ch2_generate_wave_btn = QPushButton(CONFIG['buttons']['Generate_waveform']['label'])
        run_layout.addRow(self.ch2_generate_wave_btn)
        self.ch2_run_btn = QPushButton(CONFIG["buttons"]['run']['label'])
        self.ch2_abort_btn = QPushButton(CONFIG['buttons']['abort']['label'])
        run_layout.addRow(self.ch2_run_btn)
        run_layout.addRow(self.ch2_abort_btn)
        ch2_run_group.setLayout(run_layout)
        side_panel.addWidget(ch2_run_group)

        # Create the plot canvas and axes for channel 2
        plot_group = QGroupBox("Sample waveform")
        plot_layout = QHBoxLayout()
        self.ch2_canvas = FigureCanvas(Figure(figsize=(10, 3)))
        self.ch2_ax, self.ch2_ax_fft = self.ch2_canvas.figure.subplots(1, 2)

        plot_layout.addWidget(self.ch2_canvas)     
        plot_group.setLayout(plot_layout)

        # Add the plot to the main panel
        main_panel.addWidget(plot_group)

        layout.addLayout(side_panel, 1)
        layout.addLayout(main_panel, 3)
        self.channel_2_tab.setLayout(layout)
        
        # Update initial state
        self.update_waveform_inputs(self.ch2_waveform_selector.currentText(), 2)

        # Connect signals
        self.ch2_generate_wave_btn.clicked.connect(lambda: self.handle_generate_waveform(2))
        self.ch2_run_btn.clicked.connect(lambda: self.run(2))
        self.ch2_abort_btn.clicked.connect(lambda: self.handle_abort(2))

    def init_channel_1_output_tab(self):
        layout = QHBoxLayout()
        side_panel = QVBoxLayout()
        main_panel = QVBoxLayout()

        # Output ON/OFF group
        self.ch1_output_group = QGroupBox("Channel 1 Output Control")
        ch1_output_hbox = QHBoxLayout()
        self.enable_ch1_out_btn = QPushButton(CONFIG["buttons"]['output1_enable']['label'])
        self.disable_ch1_out_btn = QPushButton(CONFIG['buttons']['output1_disable']['label']) 
        ch1_output_hbox.addWidget(self.enable_ch1_out_btn)
        ch1_output_hbox.addWidget(self.disable_ch1_out_btn)
        self.ch1_output_group.setLayout(ch1_output_hbox)
        side_panel.addWidget(self.ch1_output_group)

        # Output Voltage Settings group
        self.ch1_set_output_group = QGroupBox("Set Output Voltage")
        ch1_set_output_form = QFormLayout()
    
        self.ch1_output_mode_selector = QComboBox()
        self.ch1_output_mode_selector.addItems(['Minimum', 'Maximum', 'Custom'])
        ch1_set_output_form.addRow(QLabel("Output Voltage State:"), self.ch1_output_mode_selector)

        self.ch1_output_voltage_input = QLineEdit()
        self.ch1_output_voltage_input.setPlaceholderText("Enter custom voltage")
        self.ch1_output_voltage_input.setVisible(False)
        ch1_set_output_form.addRow("Custom Voltage:", self.ch1_output_voltage_input)

        self.ch1_set_output_voltage_btn = QPushButton(CONFIG['buttons']['set_voltage']['label'])
        ch1_set_output_form.addRow(self.ch1_set_output_voltage_btn)

        self.ch1_set_output_group.setLayout(ch1_set_output_form)
        self.ch1_set_output_group.setEnabled(False)
        side_panel.addWidget(self.ch1_set_output_group)

        #Output offset setting
        self.ch1_set_output_offset_group = QGroupBox("Set Output Offset Voltage")
        ch1_set_output_offset_form = QFormLayout()
    
        self.ch1_output_offset_selector = QComboBox()
        self.ch1_output_offset_selector.addItems(['Minimum', 'Maximum', 'Custom'])
        ch1_set_output_offset_form.addRow(QLabel("Output Offset Voltage State:"), self.ch1_output_offset_selector)

        self.ch1_output_offsetvoltage_input = QLineEdit()
        self.ch1_output_offsetvoltage_input.setPlaceholderText("Enter custom voltage")
        self.ch1_output_offsetvoltage_input.setVisible(False)
        ch1_set_output_offset_form.addRow("Custom Voltage:", self.ch1_output_offsetvoltage_input)

        self.ch1_set_output_offsetvoltage_btn = QPushButton(CONFIG['buttons']['set_offset']['label'])
        ch1_set_output_offset_form.addRow(self.ch1_set_output_offsetvoltage_btn)

        self.ch1_set_output_offset_group.setLayout(ch1_set_output_offset_form)
        self.ch1_set_output_offset_group.setEnabled(False)
        side_panel.addWidget(self.ch1_set_output_offset_group)

        #Output lowlevel settings
        self.ch1_set_output_low_group = QGroupBox("Set Output minimum Voltage")
        ch1_set_output_low_form = QFormLayout()
    
        self.ch1_output_low_selector = QComboBox()
        self.ch1_output_low_selector.addItems(['Minimum', 'Maximum', 'Custom'])
        ch1_set_output_low_form.addRow(QLabel("Output minimum Voltage:"), self.ch1_output_low_selector)

        self.ch1_output_lowvoltage_input = QLineEdit()
        self.ch1_output_lowvoltage_input.setPlaceholderText("Enter custom voltage")
        self.ch1_output_lowvoltage_input.setEnabled(False)
        ch1_set_output_low_form.addRow("Custom Voltage:", self.ch1_output_lowvoltage_input)

        self.ch1_set_output_lowvoltage_btn = QPushButton(CONFIG['buttons']['set_low_level']['label'])
        ch1_set_output_low_form.addRow(self.ch1_set_output_lowvoltage_btn)

        self.ch1_set_output_low_group.setLayout(ch1_set_output_low_form)
        self.ch1_set_output_low_group.setEnabled(False)
        side_panel.addWidget(self.ch1_set_output_low_group)

        #Output highlevel settings
        self.ch1_set_output_high_group = QGroupBox("Set Output minimum Voltage")
        ch1_set_output_high_form = QFormLayout()
    
        self.ch1_output_high_selector = QComboBox()
        self.ch1_output_high_selector.addItems(['Minimum', 'Maximum', 'Custom'])
        ch1_set_output_high_form.addRow(QLabel("Output maximum Voltage:"), self.ch1_output_high_selector)

        self.ch1_output_highvoltage_input = QLineEdit()
        self.ch1_output_highvoltage_input.setPlaceholderText("Enter custom voltage")
        self.ch1_output_highvoltage_input.setVisible(False)
        ch1_set_output_high_form.addRow("Custom Voltage:", self.ch1_output_highvoltage_input)

        self.ch1_set_output_highvoltage_btn = QPushButton(CONFIG['buttons']['set_high_level']['label'])
        ch1_set_output_high_form.addRow(self.ch1_set_output_highvoltage_btn)

        self.ch1_set_output_high_group.setLayout(ch1_set_output_high_form)
        self.ch1_set_output_high_group.setEnabled(False)
        side_panel.addWidget(self.ch1_set_output_high_group)

        #Output termination settings
        self.ch1_set_output_termination_group = QGroupBox("Set Output termination Voltage")
        ch1_set_output_termination_form = QFormLayout()
    
        self.ch1_output_termination_selector = QComboBox()
        self.ch1_output_termination_selector.addItems(['Minimum', 'Maximum', 'Custom'])
        ch1_set_output_termination_form.addRow(QLabel("Output maximum Voltage:"), self.ch1_output_termination_selector)

        self.ch1_output_terminationvoltage_input = QLineEdit()
        self.ch1_output_terminationvoltage_input.setPlaceholderText("Enter custom voltage")
        self.ch1_output_terminationvoltage_input.setEnabled(False)
        ch1_set_output_termination_form.addRow("Custom Voltage:", self.ch1_output_terminationvoltage_input)

        self.ch1_set_output_terminationvoltage_btn = QPushButton(CONFIG['buttons']['set_termination']['label'])
        ch1_set_output_termination_form.addRow(self.ch1_set_output_terminationvoltage_btn)

        self.ch1_set_output_termination_group.setLayout(ch1_set_output_termination_form)
        self.ch1_set_output_termination_group.setEnabled(False)
        side_panel.addWidget(self.ch1_set_output_termination_group)


        # Add layouts
        layout.addLayout(side_panel, 1)
        layout.addLayout(main_panel, 3)
        self.channel_1_output_tab.setLayout(layout)

        #connect modes
        self.ch1_output_mode_selector.currentIndexChanged.connect(lambda: self.toggle_custom_voltage_input(channel=1))
        self.ch1_output_offset_selector.currentIndexChanged.connect(lambda: self.toggle_custom_voltage_input(channel=1))
        self.ch1_output_low_selector.currentIndexChanged.connect(lambda: self.toggle_custom_voltage_input(channel=1))
        self.ch1_output_high_selector.currentIndexChanged.connect(lambda: self.toggle_custom_voltage_input(channel=1))
        self.ch1_output_termination_selector.currentIndexChanged.connect(lambda: self.toggle_custom_voltage_input(channel=1))

        # Connect buttons
        self.enable_ch1_out_btn.clicked.connect(lambda: self.handle_output_state(1, 1))
        self.disable_ch1_out_btn.clicked.connect(lambda: self.handle_output_state(1, 0))
        self.ch1_set_output_voltage_btn.clicked.connect(lambda: self.handle_output_voltage(channel=1))
        self.ch1_set_output_offsetvoltage_btn.clicked.connect(lambda: self.handle_output_offset_voltage(channel=1))
        self.ch1_set_output_lowvoltage_btn.clicked.connect(lambda: self.handle_output_offset_voltage(channel=1))
        self.ch1_set_output_highvoltage_btn.clicked.connect(lambda: self.handle_output_high_voltage(channel=1))
        self.ch1_set_output_terminationvoltage_btn.clicked.connect(lambda: self.handle_output_termination_voltage(channel=1))

    def init_channel_2_output_tab(self):
        layout = QHBoxLayout()
        side_panel = QVBoxLayout()
        main_panel = QVBoxLayout()

        # Output ON/OFF group
        self.ch2_output_group = QGroupBox("Channel 1 Output Control")
        ch2_output_hbox = QHBoxLayout()
        self.enable_ch2_out_btn = QPushButton(CONFIG["buttons"]['output2_enable']['label'])
        self.disable_ch2_out_btn = QPushButton(CONFIG['buttons']['output2_disable']['label']) 
        ch2_output_hbox.addWidget(self.enable_ch2_out_btn)
        ch2_output_hbox.addWidget(self.disable_ch2_out_btn)
        self.ch2_output_group.setLayout(ch2_output_hbox)
        side_panel.addWidget(self.ch2_output_group)

        # Output Voltage Settings group
        self.ch2_set_output_group = QGroupBox("Set Output Voltage")
        ch2_set_output_form = QFormLayout()
    
        self.ch2_output_mode_selector = QComboBox()
        self.ch2_output_mode_selector.addItems(['Minimum', 'Maximum', 'Custom'])
        ch2_set_output_form.addRow(QLabel("Output Voltage State:"), self.ch2_output_mode_selector)

        self.ch2_output_voltage_input = QLineEdit()
        self.ch2_output_voltage_input.setPlaceholderText("Enter custom voltage")
        self.ch2_output_voltage_input.setEnabled(False)
        ch2_set_output_form.addRow("Custom Voltage:", self.ch2_output_voltage_input)

        self.ch2_set_output_voltage_btn = QPushButton(CONFIG['buttons']['set_voltage']['label'])
        ch2_set_output_form.addRow(self.ch2_set_output_voltage_btn)

        self.ch2_set_output_group.setLayout(ch2_set_output_form)
        self.ch2_set_output_group.setEnabled(False)
        side_panel.addWidget(self.ch2_set_output_group)

        #Output offset setting
        self.ch2_set_output_offset_group = QGroupBox("Set Output Offset Voltage")
        ch2_set_output_offset_form = QFormLayout()
    
        self.ch2_output_offset_selector = QComboBox()
        self.ch2_output_offset_selector.addItems(['Minimum', 'Maximum', 'Custom'])
        ch2_set_output_offset_form.addRow(QLabel("Output Offset Voltage State:"), self.ch2_output_offset_selector)

        self.ch2_output_offsetvoltage_input = QLineEdit()
        self.ch2_output_offsetvoltage_input.setPlaceholderText("Enter custom voltage")
        self.ch2_output_offsetvoltage_input.setEnabled(False)
        ch2_set_output_offset_form.addRow("Custom Voltage:", self.ch2_output_offsetvoltage_input)

        self.ch2_set_output_offsetvoltage_btn = QPushButton(CONFIG['buttons']['set_offset']['label'])
        ch2_set_output_offset_form.addRow(self.ch2_set_output_offsetvoltage_btn)

        self.ch2_set_output_offset_group.setLayout(ch2_set_output_offset_form)
        self.ch2_set_output_offset_group.setEnabled(False)
        side_panel.addWidget(self.ch2_set_output_offset_group)

        #Output lowlevel settings
        self.ch2_set_output_low_group = QGroupBox("Set Output minimum Voltage")
        ch2_set_output_low_form = QFormLayout()
    
        self.ch2_output_low_selector = QComboBox()
        self.ch2_output_low_selector.addItems(['Minimum', 'Maximum', 'Custom'])
        ch2_set_output_low_form.addRow(QLabel("Output minimum Voltage:"), self.ch2_output_low_selector)

        self.ch2_output_lowvoltage_input = QLineEdit()
        self.ch2_output_lowvoltage_input.setPlaceholderText("Enter custom voltage")
        self.ch2_output_lowvoltage_input.setEnabled(False)
        ch2_set_output_low_form.addRow("Custom Voltage:", self.ch2_output_lowvoltage_input)

        self.ch2_set_output_lowvoltage_btn = QPushButton(CONFIG['buttons']['set_low_level']['label'])
        ch2_set_output_low_form.addRow(self.ch2_set_output_lowvoltage_btn)

        self.ch2_set_output_low_group.setLayout(ch2_set_output_low_form)
        self.ch2_set_output_low_group.setEnabled(False)
        side_panel.addWidget(self.ch2_set_output_low_group)

        #Output highlevel settings
        self.ch2_set_output_high_group = QGroupBox("Set Output minimum Voltage")
        ch2_set_output_high_form = QFormLayout()
    
        self.ch2_output_high_selector = QComboBox()
        self.ch2_output_high_selector.addItems(['Minimum', 'Maximum', 'Custom'])
        ch2_set_output_high_form.addRow(QLabel("Output maximum Voltage:"), self.ch2_output_high_selector)

        self.ch2_output_highvoltage_input = QLineEdit()
        self.ch2_output_highvoltage_input.setPlaceholderText("Enter custom voltage")
        self.ch2_output_highvoltage_input.setEnabled(False)
        ch2_set_output_high_form.addRow("Custom Voltage:", self.ch2_output_highvoltage_input)

        self.ch2_set_output_highvoltage_btn = QPushButton(CONFIG['buttons']['set_high_level']['label'])
        ch2_set_output_high_form.addRow(self.ch2_set_output_highvoltage_btn)

        self.ch2_set_output_high_group.setLayout(ch2_set_output_high_form)
        self.ch2_set_output_high_group.setEnabled(False)
        side_panel.addWidget(self.ch2_set_output_high_group)

        #Output termination settings
        self.ch2_set_output_termination_group = QGroupBox("Set Output minimum Voltage")
        ch2_set_output_termination_form = QFormLayout()
    
        self.ch2_output_termination_selector = QComboBox()
        self.ch2_output_termination_selector.addItems(['Minimum', 'Maximum', 'Custom'])
        ch2_set_output_termination_form.addRow(QLabel("Output maximum Voltage:"), self.ch2_output_termination_selector)

        self.ch2_output_terminationvoltage_input = QLineEdit()
        self.ch2_output_terminationvoltage_input.setPlaceholderText("Enter custom voltage")
        self.ch2_output_terminationvoltage_input.setEnabled(False)
        ch2_set_output_termination_form.addRow("Custom Voltage:", self.ch2_output_terminationvoltage_input)

        self.ch2_set_output_terminationvoltage_btn = QPushButton(CONFIG['buttons']['set_termination']['label'])
        ch2_set_output_termination_form.addRow(self.ch2_set_output_terminationvoltage_btn)

        self.ch2_set_output_termination_group.setLayout(ch2_set_output_termination_form)
        self.ch2_set_output_termination_group.setEnabled(False)
        side_panel.addWidget(self.ch2_set_output_termination_group)


        # Add layouts
        layout.addLayout(side_panel, 1)
        layout.addLayout(main_panel, 3)
        self.channel_2_output_tab.setLayout(layout)

        # Connect buttons
        self.enable_ch2_out_btn.clicked.connect(lambda: self.handle_output_state(1, 1))
        self.disable_ch2_out_btn.clicked.connect(lambda: self.handle_output_state(1, 0))
        self.ch2_set_output_voltage_btn.clicked.connect(lambda: self.handle_output_voltage(channel=2))
        self.ch2_set_output_offsetvoltage_btn.clicked.connect(lambda: self.handle_output_offset_voltage(channel=2))
        self.ch2_set_output_lowvoltage_btn.clicked.connect(lambda: self.handle_output_offset_voltage(channel=2))
        self.ch2_set_output_highvoltage_btn.clicked.connect(lambda: self.handle_output_high_voltage(channel=2))
        self.ch2_set_output_terminationvoltage_btn.clicked.connect(lambda: self.handle_output_termination_voltage(channel=2))

        self.ch2_output_mode_selector.currentIndexChanged.connect(lambda: self.toggle_custom_voltage_input(channel=2))
        self.ch2_output_offset_selector.currentIndexChanged.connect(lambda: self.toggle_custom_voltage_input(channel=2))
        self.ch2_output_low_selector.currentIndexChanged.connect(lambda: self.toggle_custom_voltage_input(channel=2))
        self.ch2_output_high_selector.currentIndexChanged.connect(lambda: self.toggle_custom_voltage_input(channel=2))
        self.ch2_output_termination_selector.currentIndexChanged.connect(lambda: self.toggle_custom_voltage_input(channel=2))

    def init_logs_tab(self):

        '''layout = QHBoxLayout()
        side_panel = QVBoxLayout()
        main_panel = QVBoxLayout()

        ch1_freq_group = QGroupBox("Channel 1 inputs")
        ch1_freq_layout = QFormLayout()

        # CH 1 Input fields
        
        self.ch1_start_freq = QLineEdit()        
        self.ch1_stop_freq = QLineEdit()        
        self.ch1_step_freq = QLineEdit()        
        self.ch1_start_amplitude = QLineEdit()        
        self.ch1_stop_amplitude = QLineEdit()
        self.ch1_step_amplitude = QLineEdit()

        #Define, Run, and Abort buttons for channel  1
        self.ch1_generate_waveform_btn = QPushButton(CONFIG["buttons"]['Generate_waveform']['label'])
        self.ch1_run_waveform_btn = QPushButton(CONFIG["buttons"]['run']['label'])
        self.ch1_abort_waveform_btn = QPushButton(CONFIG["buttons"]['abort']['label'])


        ch1_freq_layout.addRow("Enter start frequency(GHz): ", self.ch1_start_freq)
        ch1_freq_layout.addRow("Enter stop frequency(GHz): ", self.ch1_stop_freq)
        ch1_freq_layout.addRow("Enter step value for frequency(GHz): ", self.ch1_step_freq)
        ch1_freq_layout.addRow("Enter amplitude starting value (V): ", self.ch1_start_amplitude)
        ch1_freq_layout.addRow("Enter amplitude stop value (V): ", self.ch1_stop_amplitude)
        ch1_freq_layout.addRow("Enter amplitude step value (V): ", self.ch1_step_amplitude)
        ch1_freq_layout.addRow(self.ch1_generate_waveform_btn)
        ch1_freq_layout.addRow(self.ch1_run_waveform_btn)
        ch1_freq_layout.addRow(self.ch1_abort_waveform_btn)

        ch1_freq_group.setLayout(ch1_freq_layout)
        side_panel.addWidget(ch1_freq_group)

        #Channel 2 layout

        ch2_freq_group = QGroupBox("Channel 2 inputs")
        ch2_freq_layout = QFormLayout()

        # CH 2 Input fields
        self.ch2_start_freq = QLineEdit()        
        self.ch2_stop_freq = QLineEdit()        
        self.ch2_step_freq = QLineEdit()        
        self.ch2_start_amplitude = QLineEdit()        
        self.ch2_stop_amplitude = QLineEdit()
        self.ch2_step_amplitude = QLineEdit()

        #Define, Run, and Abort buttons for Channel 2 
        self.ch2_generate_waveform_btn = QPushButton(CONFIG["buttons"]['Generate_waveform']['label'])
        self.ch2_run_waveform_btn = QPushButton(CONFIG["buttons"]['run']['label'])
        self.ch2_abort_waveform_btn = QPushButton(CONFIG["buttons"]['abort']['label'])


        ch2_freq_layout.addRow("Enter start frequency(GHz): ", self.ch2_start_freq)
        ch2_freq_layout.addRow("Enter stop frequency(GHz): ", self.ch2_stop_freq)
        ch2_freq_layout.addRow("Enter step value for frequency(GHz): ", self.ch2_step_freq)
        ch2_freq_layout.addRow("Enter amplitude starting value (V): ", self.ch2_start_amplitude)
        ch2_freq_layout.addRow("Enter amplitude stop value (V): ", self.ch2_stop_amplitude)
        ch2_freq_layout.addRow("Enter amplitude step value (V): ", self.ch2_step_amplitude)
        ch2_freq_layout.addRow(self.ch2_generate_waveform_btn)
        ch2_freq_layout.addRow(self.ch2_run_waveform_btn)
        ch2_freq_layout.addRow(self.ch2_abort_waveform_btn)

        ch2_freq_group.setLayout(ch2_freq_layout)
        side_panel.addWidget(ch2_freq_group)

        layout.addLayout(side_panel, 1)
        layout.addLayout(main_panel, 3)
        self.logs_tab.setLayout(layout)

        #Connect CH 1 Buttons
        self.ch1_generate_waveform_btn.clicked.connect(lambda: self.handle_generate_waveform(1))
        self.ch1_run_waveform_btn.clicked.connect(lambda: self.run(channel=1))
        self.ch1_abort_waveform_btn.clicked.connect(lambda: self.handle_abort(channel=1))

        #Connect CH 2 Buttons
        self.ch2_generate_waveform_btn.clicked.connect(lambda: self.handle_generate_waveform(2))
        self.ch2_run_waveform_btn.clicked.connect(lambda: self.run(channel=2))
        self.ch2_abort_waveform_btn.clicked.connect(lambda: self.handle_abort(channel=2))'''

    def handle_generate_waveform(self, channel):
         
        if channel == 1:
             
            inputs = self.get_channel_inputs(channel)
            waveform_type = inputs['waveform_selector'].currentText()

            # Validate inputs
            is_valid, error_msg = self.validate_inputs(channel, inputs, waveform_type)
            if not is_valid:
                QMessageBox.warning(self, "Input Required", error_msg)
                self.log_box.append(f"⚠️ {error_msg}")
                return
            
            ch1_folder = QFileDialog.getExistingDirectory(self, "Select Folder to Save CSV") 

            if waveform_type == "Sine":
                self.generator = WaveformGenerator(ip_address='1.00.0')
                start = float(self.ch1_start_freq.text().strip())
                stop= float(self.ch1_stop_freq.text().strip())
                step = float(self.ch1_step_freq.text().strip())
            
                for f in np.arange(start, stop + 0.0001, step):
                    t, w = self.generator.sinusoidal(frequency=f)
                    w_fft, x = self.fft_signal(w, iota=2)
                     # Plot waveform
                    inputs['ax'].plot(t * 1e9, w, label = f"{waveform_type}_{f:.2f} GHz") 
                    inputs['ax_fft'].plot(w_fft, x, label = f"{waveform_type}_{f:.2f} GHz")                   
                    self.save_waveform_to_csv(waveform_data= w, waveform_type=waveform_type, frequency= f, channel=1, folder= ch1_folder)
                inputs['ax'].set_title(f"Channel {channel} - {waveform_type} Waveform")
                inputs['ax'].set_xlabel("Time (ns)")
                inputs['ax'].set_ylabel("Amplitude (V)")
                inputs['ax'].legend()
                inputs['canvas'].draw()

                inputs['ax_fft'].set_title(f"Channel {channel} - {waveform_type} Waveform")
                inputs['ax_fft'].set_xlabel("F (GHz)")
                inputs['ax_fft'].set_ylabel("Power dBm")
                inputs['ax_fft'].legend()
                inputs['canvas'].draw()

                
                inputs['ax'].clear()
                inputs['ax_fft'].clear()

            elif waveform_type == "PRBS":
                self.generator = WaveformGenerator(ip_address='1.00.0')
                start = float(self.ch1_start_order.text().strip())
                stop= float(self.ch1_stop_order.text().strip())
                step = float(self.ch1_step_order.text().strip())
                repetition_rate = int(self.ch1_prbs_repetition_rate.text().strip())
            
                for f in np.arange(start, stop + 0.0001, step):
                    t, w = self.generator.PRBS(amplitude=1, order=f, repetition_rate=repetition_rate)
                    w_fft, x = self.fft_signal(w, iota=2)
                    # Plot waveform
                    inputs['ax'].plot(t * 1e9, w, label = f"{waveform_type}_{f:.2f} GHz") 
                    inputs['ax_fft'].plot(w_fft, x, label = f"{waveform_type}_{f:.2f} GHz") 
                   
                    self.save_waveform_to_csv(waveform_data= w, waveform_type=waveform_type, frequency= f, channel=1, folder= ch1_folder)
                inputs['ax'].set_title(f"Channel {channel} - {waveform_type} Waveform")
                inputs['ax'].set_xlabel("Time (ns)")
                inputs['ax'].set_ylabel("Amplitude (V)")
                inputs['ax'].legend()
                inputs['canvas'].draw()

                inputs['ax_fft'].set_title(f"Channel {channel} - {waveform_type} Waveform")
                inputs['ax_fft'].set_xlabel("F (GHz)")
                inputs['ax_fft'].set_ylabel("Power dBm")
                inputs['ax_fft'].legend()
                inputs['canvas'].draw()

                inputs['ax'].clear()
                inputs['ax_fft'].clear()

            if waveform_type == "LFM":
                self.generator = WaveformGenerator(ip_address='1.00.0')
                start = float(self.ch1_start_center_freq.text().strip())
                stop= float(self.ch1_stop_center_freq.text().strip())
                step = float(self.ch1_step_center_freq.text().strip())
                pulse_width = int(self.ch1_lfm_pulse_width.text().strip())
                bandwidth = float(self.ch1_lfm_bandwidth.text().strip())
            
                for f in np.arange(start, stop + 0.0001, step):
                    t, w = self.generator.generate_lfm(center_freq=f, bandwidth=bandwidth, pulse_width=pulse_width)
                    w_fft, x = self.fft_signal(w, iota=2)
                    # Plot waveform
                    inputs['ax'].plot(t * 1e9, w, label = f"{waveform_type}_{f:.2f} GHz") 
                    inputs['ax_fft'].plot(w_fft, x, label = f"{waveform_type}_{f:.2f} GHz")
                    
                    self.save_waveform_to_csv(waveform_data= w, waveform_type=waveform_type, frequency= f, channel=1, folder= ch1_folder)
                inputs['ax'].set_title(f"Channel {channel} - {waveform_type} Waveform")
                inputs['ax'].set_xlabel("Time (ns)")
                inputs['ax'].set_ylabel("Amplitude (V)")
                inputs['ax'].legend()
                inputs['canvas'].draw()

                inputs['ax_fft'].set_title(f"Channel {channel} - {waveform_type} Waveform")
                inputs['ax_fft'].set_xlabel("F (GHz)")
                inputs['ax_fft'].set_ylabel("Power dBm")
                inputs['ax_fft'].legend()
                inputs['canvas'].draw()

                inputs['ax'].clear()
                inputs['ax_fft'].clear()

            if waveform_type == "Noise":
                self.generator = WaveformGenerator(ip_address='1.00.0')
                start = float(self.ch1_start_variance.text().strip())
                stop= float(self.ch1_stop_variance.text().strip())
                step = float(self.ch1_step_variance.text().strip())
            
                for f in np.arange(start, stop + 0.0001, step):
                    t, w = self.generator.sinusoidal(frequency=f)
                    w_fft, x = self.fft_signal(w, iota=2)
                    # Plot waveform
                    inputs['ax'].plot(t * 1e9, w, label = f"{waveform_type}_{f:.2f} GHz") 
                    inputs['ax_fft'].plot(w_fft, x, label = f"{waveform_type}_{f:.2f} GHz")
                    
                    self.save_waveform_to_csv(waveform_data= w, waveform_type=waveform_type, frequency= f, channel=1, folder= ch1_folder)
                inputs['ax'].set_title(f"Channel {channel} - {waveform_type} Waveform")
                inputs['ax'].set_xlabel("Time (ns)")
                inputs['ax'].set_ylabel("Amplitude (V)")
                inputs['ax'].legend()
                inputs['canvas'].draw()

                inputs['ax_fft'].set_title(f"Channel {channel} - {waveform_type} Waveform")
                inputs['ax_fft'].set_xlabel("F (GHz)")
                inputs['ax_fft'].set_ylabel("Power dBm")
                inputs['ax_fft'].legend()
                inputs['canvas'].draw()

                inputs['ax'].clear()
                inputs['ax_fft'].clear()

        elif channel == 2:
              
            inputs = self.get_channel_inputs(channel)
            waveform_type = inputs['waveform_selector'].currentText()  

            # Validate inputs
            is_valid, error_msg = self.validate_inputs(channel, inputs, waveform_type)
            if not is_valid:
                QMessageBox.warning(self, "Input Required", error_msg)
                self.log_box.append(f"⚠️ {error_msg}")
                return     

            ch2_folder = QFileDialog.getExistingDirectory(self, "Select Folder to Save CSV") 

            if waveform_type == "Sine":
                self.generator = WaveformGenerator(ip_address='1.00.0')
                start = float(self.ch2_start_freq.text().strip())
                stop= float(self.ch2_stop_freq.text().strip())
                step = float(self.ch2_step_freq.text().strip())
            
                for f in np.arange(start, stop + 0.0001, step):
                    t, w = self.generator.sinusoidal(frequency=f)
                    w_fft, x = self.fft_signal(w, iota=2)
                    inputs['ax'].plot(t * 1e9, w, label = f"{waveform_type}_{f:.2f} GHz")
                    inputs['ax_fft'].plot(w_fft, x, label = f"{waveform_type}_{f:.2f} GHz")
                    
                    self.save_waveform_to_csv(waveform_data= w, waveform_type=waveform_type, frequency= f, channel=2, folder= ch2_folder)
                inputs['ax_fft'].set_title(f"Channel {channel} - {waveform_type} Waveform")
                inputs['ax_fft'].set_xlabel("F (GHz)")
                inputs['ax_fft'].set_ylabel("Power dBm")
                inputs['ax_fft'].legend()
                inputs['canvas'].draw()

                inputs['ax'].clear()
                inputs['ax_fft'].clear()

            elif waveform_type == "PRBS":
                self.generator = WaveformGenerator(ip_address='1.00.0')
                start = float(self.ch2_start_order.text().strip())
                stop= float(self.ch2_stop_order.text().strip())
                step = float(self.ch2_step_order.text().strip())
                repetition_rate = int(self.ch2_prbs_repetition_rate.text().strip())
            
                for f in np.arange(start, stop + 0.0001, step):
                    t, w = self.generator.PRBS(amplitude=1, order=f, repetition_rate=repetition_rate)
                    w_fft, x = self.fft_signal(w, iota=2)
                    inputs['ax'].plot(t * 1e9, w, label = f"{waveform_type}_{f:.2f} GHz")
                    inputs['ax_fft'].plot(w_fft, x, label = f"{waveform_type}_{f:.2f} GHz")
                    
                    self.save_waveform_to_csv(waveform_data= w, waveform_type=waveform_type, frequency= f, channel=2, folder= ch2_folder)
                inputs['ax_fft'].set_title(f"Channel {channel} - {waveform_type} Waveform")
                inputs['ax_fft'].set_xlabel("F (GHz)")
                inputs['ax_fft'].set_ylabel("Power dBm")
                inputs['ax_fft'].legend()
                inputs['canvas'].draw()

                inputs['ax'].clear()
                inputs['ax_fft'].clear()

            if waveform_type == "LFM":
                self.generator = WaveformGenerator(ip_address='1.00.0')
                start = float(self.ch2_start_center_freq.text().strip())
                stop= float(self.ch2_stop_center_freq.text().strip())
                step = float(self.ch2_step_center_freq.text().strip())
                pulse_width = int(self.ch2_lfm_pulse_width.text().strip())
                bandwidth = float(self.ch2_lfm_bandwidth.text().strip())
            
                for f in np.arange(start, stop + 0.0001, step):
                    t, w = self.generator.generate_lfm(center_freq=f, bandwidth=bandwidth,pulse_width=pulse_width)
                    w_fft, x = self.fft_signal(w, iota=2)
                    inputs['ax'].plot(t * 1e9, w, label = f"{waveform_type}_{f:.2f} GHz")
                    inputs['ax_fft'].plot(w_fft, x, label = f"{waveform_type}_{f:.2f} GHz")
                    
                    self.save_waveform_to_csv(waveform_data= w, waveform_type=waveform_type, frequency= f, channel=2, folder= ch2_folder)
                inputs['ax_fft'].set_title(f"Channel {channel} - {waveform_type} Waveform")
                inputs['ax_fft'].set_xlabel("F (GHz)")
                inputs['ax_fft'].set_ylabel("Power dBm")
                inputs['ax_fft'].legend()
                inputs['canvas'].draw()

                inputs['ax'].clear()
                inputs['ax_fft'].clear()

            if waveform_type == "Noise":
                self.generator = WaveformGenerator(ip_address='1.00.0')
                start = float(self.ch2_start_variance.text().strip())
                stop= float(self.ch2_stop_variance.text().strip())
                step = float(self.ch2_step_variance.text().strip())
            
                for f in np.arange(start, stop + 0.0001, step):
                    t, w = self.generator.sinusoidal(frequency=f)
                    w_fft, x = self.fft_signal(w, iota=2)
                    inputs['ax'].plot(t * 1e9, w, label = f"{waveform_type}_{f:.2f} GHz")
                    inputs['ax_fft'].plot(w_fft, x, label = f"{waveform_type}_{f:.2f} GHz")
                    
                    self.save_waveform_to_csv(waveform_data= w, waveform_type=waveform_type, frequency= f, channel=2, folder= ch2_folder)
                inputs['ax_fft'].set_title(f"Channel {channel} - {waveform_type} Waveform")
                inputs['ax_fft'].set_xlabel("F (GHz)")
                inputs['ax_fft'].set_ylabel("Power dBm")
                inputs['ax_fft'].legend()
                inputs['canvas'].draw()

                inputs['ax'].clear()
                inputs['ax_fft'].clear()

    def run(self, channel):
        self.log_box.append(f"no error!")
        if channel == 1:
            inputs = self.get_channel_inputs(channel=channel)
            wave_type = inputs['waveform_selector'].currentText()
            start_amp = float(inputs['ch1_start_amp'].text().strip())
            stop_amp = float(inputs['ch1_stop_amp'].text().strip())
            step_amp = float(inputs['ch1_step_amp'].text().strip())

            if wave_type == 'Sine':
                
                start = float(inputs['ch1_start_freq'].text().strip())
                stop = float(inputs['ch1_stop_freq'].text().strip())
                step = float(inputs['ch1_step_freq'].text().strip())
                output_log = self.awg.set_output_state(channel=channel, state=1)
                for f in np.arange(start, stop + 0.0001, step):
                    try:                    
                        file_path = self.folder + f"\\{wave_type.lower()}_{f}_ch{channel}.csv" 
                    
                        self.log_box.append(f"Processing: {file_path}")
                        seg_log = self.awg.define_segment(channel=channel, segment_id=1, n_sample=720)
                        imp_log = self.awg.import_file(file_path)
                        self.log_box.append(f"{seg_log}")
                        self.log_box.append(f"no error")

                        for amplitude in np.arange(start_amp, stop_amp + 0.001, step_amp):
                            abort_log = self.awg.abort_wave_generation(channel=channel)
                            
                            out_volt_log = self.awg.set_output_voltage_custom(channel=channel, value=amplitude)
                            self.log_box.append(f"no error!")
                        
                            
                            init_log = self.awg.initiate_signal(channel=channel)
                            time.sleep(60)
                            self.awg.abort_wave_generation(channel=channel)

                        del_seg_log = self.awg.delete_segment(channel=channel,id=1)
                        self.log_box.append(f"Successfully processed {file_path}\n{abort_log}\n{output_log}\n{out_volt_log}\n{init_log}\n{del_seg_log}")
                        output_log = self.awg.set_output_state(channel=channel, state=0)
                    except Exception as e:
                        self.log_box.append(f"{e}")

            elif wave_type == 'PRBS':
                start = float(inputs['ch1_start_order'].text.strip())
                stop = float(inputs['ch1_stop_order'].text.strip())
                step = float(inputs['ch1_step_order'].text().strip())

                for f in np.arange(start, stop + 0.0001, step):
                    try:                    
                        file_path = self.folder + f"{wave_type}_{f}_ch{channel}.csv" 
                    
                        self.log_box.append(f"Processing: {file_path}")
                        seg_log = self.awg.define_segment(channel=channel, segment_id=1, n_sample=720)
                        imp_log = self.awg.import_file(file_path)
                        self.log_box.append(f"{seg_log}")
                        self.log_box.append(f"no error")

                        for amplitude in np.arange(start_amp, stop_amp + 0.001, step_amp):
                            abort_log = self.awg.abort_wave_generation(channel=channel)
                            output_log = self.awg.set_output_state(channel=channel, state=0)
                            out_volt_log = self.awg.set_output_voltage_custom(channel=channel, value=amplitude)
                            self.log_box.append(f"no error!")
                        
                            output_log = self.awg.set_output_state(channel=channel, state=1)
                            init_log = self.awg.initiate_signal(channel=channel)

                        del_seg_log = self.awg.delete_segment(channel=channel)
                        self.log_box.append(f"Successfully processed {file_path}\n{abort_log}\n{output_log}\n{out_volt_log}\n{init_log}\n{del_seg_log}")
                    
                    except Exception as e:
                        self.log_box.append(f"{e}")
                
            elif wave_type == 'LFM':
                start = float(inputs['ch1_start_center_freq'].text().strip())
                stop = float(inputs['ch1_stop_center_freq'].text().strip())
                step = float(inputs['ch1_step_center_freq'].text().strip())

                for f in np.arange(start, stop + 0.0001, step):
                    try:                    
                        file_path = self.folder + f"{wave_type}_{f}_ch{channel}.csv" 
                    
                        self.log_box.append(f"Processing: {file_path}")
                        seg_log = self.awg.define_segment(channel=channel, segment_id=1, n_sample=720)
                        imp_log = self.awg.import_file(file_path)
                        self.log_box.append(f"{seg_log}")
                        self.log_box.append(f"no error")

                        for amplitude in np.arange(start_amp, stop_amp + 0.001, step_amp):
                            abort_log = self.awg.abort_wave_generation(channel=channel)
                            output_log = self.awg.set_output_state(channel=channel, state=0)
                            out_volt_log = self.awg.set_output_voltage_custom(channel=channel, value=amplitude)
                            self.log_box.append(f"no error!")
                        
                            output_log = self.awg.set_output_state(channel=channel, state=1)
                            init_log = self.awg.initiate_signal(channel=channel)

                        del_seg_log = self.awg.delete_segment(channel=channel)
                        self.log_box.append(f"Successfully processed {file_path}\n{abort_log}\n{output_log}\n{out_volt_log}\n{init_log}\n{del_seg_log}")
                    
                    except Exception as e:
                        self.log_box.append(f"{e}")

            elif wave_type == 'Noise':
                start = float(inputs['ch1_start_variance'].text().strip())
                stop = float(inputs['ch1_stop_variance'].text().strip())
                step = float(inputs['ch1_step_variance'].text().strip())

                for f in np.arange(start, stop + 0.0001, step):
                    try:                    
                        file_path = self.folder + f"{wave_type}_{f}_ch{channel}.csv" 
                    
                        self.log_box.append(f"Processing: {file_path}")
                        seg_log = self.awg.define_segment(channel=channel, segment_id=1, n_sample=720)
                        imp_log = self.awg.import_file(file_path)
                        self.log_box.append(f"{seg_log}")
                        self.log_box.append(f"no error")

                        for amplitude in np.arange(start_amp, stop_amp + 0.001, step_amp):
                            abort_log = self.awg.abort_wave_generation(channel=channel)
                            output_log = self.awg.set_output_state(channel=channel, state=0)
                            out_volt_log = self.awg.set_output_voltage_custom(channel=channel, value=amplitude)
                            self.log_box.append(f"no error!")
                        
                            output_log = self.awg.set_output_state(channel=channel, state=1)
                            init_log = self.awg.initiate_signal(channel=channel)

                        del_seg_log = self.awg.delete_segment(channel=channel)
                        self.log_box.append(f"Successfully processed {file_path}\n{abort_log}\n{output_log}\n{out_volt_log}\n{init_log}\n{del_seg_log}")
                    
                    except Exception as e:
                        self.log_box.append(f"{e}")
                        
        elif channel == 2:
            inputs = self.get_channel_inputs(channel=channel)
            wave_type = inputs['waveform_selector'].currentText()
            start_amp = float(inputs['ch2_start_amp'].text().strip())
            stop_amp = float(inputs['ch2_stop_amp'].text().strip())
            step_amp = float(inputs['ch2_step_amp'].text().strip())

            if wave_type == 'Sine':
                
                start = float(inputs['ch2_start_freq'].text().strip())
                stop = float(inputs['ch2_stop_freq'].text().strip())
                step = float(inputs['ch2_step_freq'].text().strip())

                for f in np.arange(start, stop + 0.0001, step):
                    try:                    
                        file_path = self.folder + f"{wave_type}_{f}GHz_ch{channel}.csv" 
                    
                        self.log_box.append(f"Processing: {file_path}")
                        seg_log = self.awg.define_segment(channel=channel, segment_id=1, n_sample=720)
                        imp_log = self.awg.import_file(file_path)
                        self.log_box.append(f"{seg_log}")
                        self.log_box.append(f"no error")

                        for amplitude in np.arange(start_amp, stop_amp + 0.001, step_amp):
                            abort_log = self.awg.abort_wave_generation(channel=channel)
                            output_log = self.awg.set_output_state(channel=channel, state=0)
                            out_volt_log = self.awg.set_output_voltage_custom(channel=channel, value=amplitude)
                            self.log_box.append(f"no error!")
                        
                            output_log = self.awg.set_output_state(channel=channel, state=1)
                            init_log = self.awg.initiate_signal(channel=channel)

                        del_seg_log = self.awg.delete_segment(channel=channel)
                        self.log_box.append(f"Successfully processed {file_path}\n{abort_log}\n{output_log}\n{out_volt_log}\n{init_log}\n{del_seg_log}")
                    
                    except Exception as e:
                        self.log_box.append(f"{e}")

            elif wave_type == 'PRBS':
                start = float(inputs['ch2_start_order'].text.strip())
                stop = float(inputs['ch2_stop_order'].text.strip())
                step = float(inputs['ch2_step_order'].text().strip())

                for f in np.arange(start, stop + 0.0001, step):
                    try:                    
                        file_path = self.folder + f"{wave_type}_{f}_ch{channel}.csv" 
                    
                        self.log_box.append(f"Processing: {file_path}")
                        seg_log = self.awg.define_segment(channel=channel, segment_id=1, n_sample=720)
                        imp_log = self.awg.import_file(file_path)
                        self.log_box.append(f"{seg_log}")
                        self.log_box.append(f"no error")

                        for amplitude in np.arange(start_amp, stop_amp + 0.001, step_amp):
                            abort_log = self.awg.abort_wave_generation(channel=channel)
                            output_log = self.awg.set_output_state(channel=channel, state=0)
                            out_volt_log = self.awg.set_output_voltage_custom(channel=channel, value=amplitude)
                            self.log_box.append(f"no error!")
                        
                            output_log = self.awg.set_output_state(channel=channel, state=1)
                            init_log = self.awg.initiate_signal(channel=channel)

                        del_seg_log = self.awg.delete_segment(channel=channel)
                        self.log_box.append(f"Successfully processed {file_path}\n{abort_log}\n{output_log}\n{out_volt_log}\n{init_log}\n{del_seg_log}")
                    
                    except Exception as e:
                        self.log_box.append(f"{e}")
                
            elif wave_type == 'LFM':
                start = float(inputs['ch2_start_center_freq'].text().strip())
                stop = float(inputs['ch2_stop_center_freq'].text().strip())
                step = float(inputs['ch2_step_center_freq'].text().strip())

                for f in np.arange(start, stop + 0.0001, step):
                    try:                    
                        file_path = self.folder + f"{wave_type}_{f}_ch{channel}.csv" 
                    
                        self.log_box.append(f"Processing: {file_path}")
                        seg_log = self.awg.define_segment(channel=channel, segment_id=1, n_sample=720)
                        imp_log = self.awg.import_file(file_path)
                        self.log_box.append(f"{seg_log}")
                        self.log_box.append(f"no error")

                        for amplitude in np.arange(start_amp, stop_amp + 0.001, step_amp):
                            abort_log = self.awg.abort_wave_generation(channel=channel)
                            output_log = self.awg.set_output_state(channel=channel, state=0)
                            out_volt_log = self.awg.set_output_voltage_custom(channel=channel, value=amplitude)
                            self.log_box.append(f"no error!")
                        
                            output_log = self.awg.set_output_state(channel=channel, state=1)
                            init_log = self.awg.initiate_signal(channel=channel)

                        del_seg_log = self.awg.delete_segment(channel=channel)
                        self.log_box.append(f"Successfully processed {file_path}\n{abort_log}\n{output_log}\n{out_volt_log}\n{init_log}\n{del_seg_log}")
                    
                    except Exception as e:
                        self.log_box.append(f"{e}")

            elif wave_type == 'Noise':
                start = float(inputs['ch2_start_variance'].text().strip())
                stop = float(inputs['ch2_stop_variance'].text().strip())
                step = float(inputs['ch2_step_variance'].text().strip())

                for f in np.arange(start, stop + 0.0001, step):
                    try:                    
                        file_path = self.folder + f"{wave_type}_{f}_ch{channel}.csv" 
                    
                        self.log_box.append(f"Processing: {file_path}")
                        seg_log = self.awg.define_segment(channel=channel, segment_id=1, n_sample=720)
                        imp_log = self.awg.import_file(file_path)
                        self.log_box.append(f"{seg_log}")
                        self.log_box.append(f"no error")

                        for amplitude in np.arange(start_amp, stop_amp + 0.001, step_amp):
                            abort_log = self.awg.abort_wave_generation(channel=channel)
                            output_log = self.awg.set_output_state(channel=channel, state=0)
                            out_volt_log = self.awg.set_output_voltage_custom(channel=channel, value=amplitude)
                            self.log_box.append(f"no error!")
                        
                            output_log = self.awg.set_output_state(channel=channel, state=1)
                            init_log = self.awg.initiate_signal(channel=channel)

                        del_seg_log = self.awg.delete_segment(channel=channel)
                        self.log_box.append(f"Successfully processed {file_path}\n{abort_log}\n{output_log}\n{out_volt_log}\n{init_log}\n{del_seg_log}")
                    
                    except Exception as e:
                        self.log_box.append(f"{e}")

    def update_waveform_inputs(self, waveform_type, channel):
        """Update input field availability based on waveform type and channel"""
        if channel == 1:
            # Channel 1 inputs
            self.ch1_sine_group.setVisible(waveform_type == 'Sine')            
            self.ch1_prbs_group.setVisible(waveform_type == "PRBS")
            self.ch1_lfm_group.setVisible(waveform_type == "LFM")
            self.ch1_noise_group.setVisible(waveform_type == "Noise")
        elif channel == 2:
            # Channel 1 inputs
            self.ch2_sine_group.setVisible(waveform_type == 'Sine')            
            self.ch2_prbs_group.setVisible(waveform_type == "PRBS")
            self.ch2_lfm_group.setVisible(waveform_type == "LFM")
            self.ch2_noise_group.setVisible(waveform_type == "Noise")

    def get_channel_inputs(self, channel):
        """Get input widgets for specified channel"""
        if channel == 1:
            return {
                'waveform_selector': self.ch1_waveform_selector,
                'ch1_start_freq': self.ch1_start_freq,
                'ch1_stop_freq': self.ch1_stop_freq,
                'ch1_step_freq': self.ch1_step_freq,
                'ch1_start_amp': self.ch1_start_amp,
                'ch1_stop_amp': self.ch1_stop_amp,
                'ch1_step_amp': self.ch1_step_amp,
                'ch1_start_order': self.ch1_start_order,
                'ch1_stop_order': self.ch1_stop_order,
                'ch1_step_order': self.ch1_step_order,
                'prbs_repetition_rate': self.ch1_prbs_repetition_rate,
                'ch1_start_noise': self.ch1_start_variance,
                'ch1_stop_noise': self.ch1_stop_variance,
                'ch1_step_noise': self.ch1_step_variance,
                'ch1_start_center_freq': self.ch1_start_center_freq,
                'ch1_stop_center_freq': self.ch1_stop_center_freq,
                'ch1_step_center_freq': self.ch1_step_center_freq,
                'lfm_pulse_width': self.ch1_lfm_pulse_width,
                'lfm_bandwidth': self.ch1_lfm_bandwidth,
                'canvas': self.ch1_canvas,
                'ax': self.ch1_ax,
                'ax_fft': self.ch1_ax_fft
            }
        elif channel == 2:
            return {
                'waveform_selector': self.ch2_waveform_selector,
                'ch2_start_freq': self.ch2_start_freq,
                'ch2_stop_freq': self.ch2_stop_freq,
                'ch2_step_freq': self.ch2_step_freq,
                'ch2_start_amp': self.ch2_start_amp,
                'ch2_stop_amp': self.ch2_stop_amp,
                'ch2_step_amp': self.ch2_step_amp,
                'ch2_start_order': self.ch2_start_order,
                'ch2_stop_order': self.ch2_stop_order,
                'ch2_step_order': self.ch2_step_order,
                'prbs_repetition_rate': self.ch2_prbs_repetition_rate,
                'ch2_start_noise': self.ch2_start_variance,
                'ch2_stop_noise': self.ch2_stop_variance,
                'ch2_step_noise': self.ch2_step_variance,
                'ch2_start_center_freq': self.ch2_start_center_freq,
                'ch2_stop_center_freq': self.ch2_stop_center_freq,
                'ch2_step_center_freq': self.ch2_step_center_freq,
                'lfm_pulse_width': self.ch2_lfm_pulse_width,
                'lfm_bandwidth': self.ch2_lfm_bandwidth,
                'canvas': self.ch2_canvas,
                'ax': self.ch2_ax,
                'ax_fft': self.ch2_ax_fft
            }

    def validate_inputs(self, channel, inputs, waveform_type):
        """Validate inputs based on waveform type"""
        if channel == 1:
            if waveform_type == "Sine":
                if (not inputs['ch1_start_freq'].text().strip() or
                    not inputs['ch1_stop_freq'].text().strip() or
                    not inputs['ch1_step_freq'].text().strip() or
                    not inputs['ch1_start_amp'].text().strip() or 
                    not inputs['ch1_stop_amp'].text().strip() or
                    not inputs['ch1_step_amp'].text().strip()):
                    
                    return False, "All inputs are required!!!"
                     
            
            elif waveform_type == "PRBS":
                if (not inputs['ch1_start_order'].text().strip() or
                    not inputs['ch1_stop_order'].text().strip() or
                    not inputs['ch1_step_order'].text().strip() or
                    not inputs['ch1_start_amp'].text().strip() or 
                    not inputs['ch1_stop_amp'].text().strip() or
                    not inputs['ch1_step_amp'].text().strip() or
                    not inputs['prbs_repetition_rate'].text().strip()):
                    return False, "All inputs are required!!!"
            elif waveform_type == "LFM":
                if (not inputs['ch1_start_center_freq'].text().strip() or
                    not inputs['ch1_stop_center_freq'].text().strip() or  
                    not inputs['ch1_step_center_freq'].text().strip() or 
                    not inputs['lfm_pulse_width'].text().strip() or 
                    not inputs['lfm_bandwidth'].text().strip() or
                    not inputs['ch1_start_amp'].text().strip() or
                    not inputs['ch1_stop_amp'].text().strip() or
                    not inputs['ch1_step_amp'].text().strip()):
                    return False, "All inputs are required!!!"
            elif waveform_type == "Noise":
                if (not inputs['ch1_start_variance'].text().strip() or
                    not inputs['ch1_stop_variance'].text().strip() or
                    not inputs['ch1_step_variance'].text().strip() or
                    not inputs['ch1_start_amp'].text().strip() or 
                    not inputs['ch1_stop_amp'].text().strip() or
                    not inputs['ch1_step_amp'].text().strip()):
                    return False, "All inputs are required!!!"
               
            return True, ""
        elif channel == 2:
            if waveform_type == "Sine":
                if (not inputs['ch2_start_freq'].text().strip() or
                    not inputs['ch2_stop_freq'].text().strip() or
                    not inputs['ch2_step_freq'].text().strip() or
                    not inputs['ch2_start_amp'].text().strip() or 
                    not inputs['ch2_stop_amp'].text().strip() or
                    not inputs['ch2_step_amp'].text().strip()):
                    return False, "All inputs are required!!!"
            
            elif waveform_type == "PRBS":
                if (not inputs['ch2_start_order'].text().strip() or
                    not inputs['ch2_stop_order'].text().strip() or
                    not inputs['ch2_step_order'].text().strip() or
                    not inputs['ch2_start_amp'].text().strip() or 
                    not inputs['ch2_stop_amp'].text().strip() or
                    not inputs['ch2_step_amp'].text().strip()):
                    return False, "All inputs are required!!!"
            elif waveform_type == "LFM":
                if (not inputs['ch2_start_center_freq'].text().strip() or
                    not inputs['ch2_stop_center_freq'].text().strip() or  
                    not inputs['ch2_step_center_freq'].text().strip() or 
                    not inputs['lfm_pulse_width'].text().strip() or 
                    not inputs['lfm_bandwidth'].text().strip() or
                    not inputs['ch2_start_amp'].text().strip() or
                    not inputs['ch2_stop_amp'].text().strip() or
                    not inputs['ch2_step_amp'].text().strip()):
                    return False, "All inputs are required!!!"
            elif waveform_type == "Noise":
                if (not inputs['ch2_start_variance'].text().strip() or
                    not inputs['ch2_stop_variance'].text().strip() or
                    not inputs['ch2_step_variance'].text().strip() or
                    not inputs['ch2_start_amp'].text().strip() or 
                    not inputs['ch2_stop_amp'].text().strip() or
                    not inputs['ch2_step_amp'].text().strip()):
                    return False, "All inputs are required!!!"
               
            return True, "Inputs are valid!!!"

    def save_waveform_to_csv(self, waveform_data, waveform_type, frequency, channel, folder):
        """Save waveform data to a CSV file."""
        self.folder = folder
        if not self.folder:
            self.log_box.append("⚠️ Save operation cancelled by user.")
            return None

        filename = f"{waveform_type.lower()}_{frequency}_ch{channel}.csv"
        full_path = os.path.join(self.folder, filename)

        try:
            with open(full_path, mode='a', newline='') as file:
                writer = csv.writer(file)
                writer.writerow(["Y1"])
                for value in waveform_data:
                    writer.writerow([value])
            self.log_box.append(f"✅ Channel {channel} waveform data saved to: {full_path}")
            return full_path
        except Exception as e:
            self.log_box.append(f"❌ Error saving waveform: {e}")
            return None


    def check_awg_connection(self):
        """Check if AWG is connected"""
        if not self.awg:
            self.log_box.append("❌ AWG not connected. Please connect first.")
            return False
        return True

    def handle_connect(self):
        """Handle AWG connection"""
        ip = self.ip_input.text().strip()
        # Enable tabs if AWG is connected

        if not ip:
            self.log_box.append("❌ Please enter AWG IP address")
            return
            
        try:
            self.awg = AWG_Controller(ip_address=ip)
            self.connected = self.awg.connect()
            response, status = self.awg.is_connected()
            if not self.connected:
                self.log_box.append("Device not found")
            else:
                self.status_light.set_connected(True)
                self.log_box.append(f"{status}")
                self.update_channel_buttons()
                self.logs_tab.setEnabled(True)
        except Exception as e:
            self.status_light.set_connected(False)
            self.log_box.append(f"❌ Connection failed: {e}")

    def handle_disconnect(self):
        """Handle AWG disconnection"""
        if self.awg:
            try:
                self.awg.disconnect()
                self.status_light.set_connected(False)
                self.awg = None
                self.log_box.append("🔌 Disconnected from AWG")

                self.update_channel_buttons()
            except Exception as e:
                self.log_box.append(f"❌ Disconnect error: {e}")

    def update_channel_buttons(self):
        """Update channel button states based on connection"""
        state = self.connected is not None
        self.ch1_on_btn.setEnabled(state)
        self.ch1_off_btn.setEnabled(state)
        self.ch2_on_btn.setEnabled(state)
        self.ch2_off_btn.setEnabled(state)
       

    def handle_channel_enable(self, channel):
        """Enable specified channel"""
        if not self.check_awg_connection():
            return
        try:
            # Add your channel enable logic here
            self.log_box.append(f"✅ Channel {channel} enabled")
            if channel == 1:
                self.tabs.setTabEnabled(1, True)
                self.tabs.setTabEnabled(3, True)
            elif channel == 2:
                self.tabs.setTabEnabled(2, True)
                self.tabs.setTabEnabled(4, True)
        except Exception as e:
            self.log_box.append(f"❌ Failed to enable channel {channel}: {e}")

    def handle_channel_disable(self, channel):
        """Disable specified channel"""
        if not self.check_awg_connection():
            return
        try:
            # Add your channel disable logic here
            self.log_box.append(f"🔴 Channel {channel} disabled")
            if channel == 1:
                self.tabs.setTabEnabled(1, False)
            elif channel == 2:
                self.tabs.setTabEnabled(2, False)
        except Exception as e:
            self.log_box.append(f"❌ Failed to disable channel {channel}: {e}")

    def handle_abort(self, channel):
        """Abort waveform generation for specified channel"""
        if not self.check_awg_connection():
            return
        
        try:
            self.awg.abort_wave_generation(channel=channel)
            self.log_box.append(f"🛑 Waveform generation aborted for channel {channel}")
        except Exception as e:
            self.log_box.append(f"❌ Failed to abort waveform generation: {e}")

    def closeEvent(self, event):

        """Handle application close event"""
        if self.awg:
            try:
                self.awg.disconnect()
            except:
                pass
        event.accept()

    def fft_signal(self, w, iota):
        N = 2 ** np.ceil(np.log2(len(w) * 4))
        f, x = signal.periodogram(w, window='hann', nfft=N, fs=1e9 * iota, scaling='spectrum')
        f = f / 1e9
        epsilon = 1e-10
        x = 10 * (np.log10((x + epsilon) / 50e-3))
        return [f, x]

    def handle_output_state(self, channel, state):
        if channel == 1:
            if state == 0:
                self.awg.set_output_state(channel= 1, state= 0)
            elif state == 1:
                self.awg.set_output_state(channel=1, state=1)
                self.ch1_set_output_group.setEnabled(True)
                self.ch1_set_output_high_group.setEnabled(True)
                self.ch1_set_output_low_group.setEnabled(True)
                self.ch1_set_output_offset_group.setEnabled(True)
                self.ch1_set_output_termination_group.setEnabled(True)

        elif channel == 2:
            if state == 0:
                self.awg.set_output_state(channel= 2, state= 0)
            elif state == 1:
                self.awg.set_output_state(channel=2, state=1)
                self.ch2_set_output_group.setEnabled(True)
                self.ch2_set_output_high_group.setEnabled(True)
                self.ch2_set_output_low_group.setEnabled(True)
                self.ch2_set_output_offset_group.setEnabled(True)
                self.ch2_set_output_termination_group.setEnabled(True)

    def toggle_custom_voltage_input(self, channel):

        if channel == 1:
            output_mode = self.ch1_output_mode_selector.currentText()
            offset_mode = self.ch1_output_offset_selector.currentText()
            minimum_mode = self.ch1_output_low_selector.currentText()
            maximum_mode = self.ch1_output_high_selector.currentText()
            termination_mode = self.ch1_output_termination_selector.currentText()
            if output_mode == "Custom": self.ch1_output_voltage_input.setEnabled(True)
            if offset_mode == "Custom": self.ch1_output_offsetvoltage_input.setEnabled(True)
            if minimum_mode == "Custom": self.ch1_output_lowvoltage_input.setEnabled(True)
            if maximum_mode == "Custom": self.ch1_output_highvoltage_input.setEnabled(True)
            if termination_mode == "Custom": self.ch1_output_terminationvoltage_input.setEnabled(True)
        elif channel == 2:
            output_mode = self.ch2_output_mode_selector.currentText()
            offset_mode = self.ch2_output_offset_selector.currentText()
            minimum_mode = self.ch2_output_low_selector.currentText()
            maximum_mode = self.ch2_output_high_selector.currentText()
            termination_mode = self.ch2_output_termination_selector.currentText()
            if output_mode == "Custom": self.ch2_output_voltage_input.setEnabled(True)
            if offset_mode == "Custom": self.ch2_output_offsetvoltage_input.setEnabled(True)
            if minimum_mode == "Custom": self.ch2_output_lowvoltage_input.setEnabled(True)
            if maximum_mode == "Custom": self.ch2_output_highvoltage_input.setEnabled(True)
            if termination_mode == "Custom": self.ch2_output_terminationvoltage_input.setEnabled(True)
    
    def handle_output_voltage(self, channel):
        if channel == 1:
            output_volt = self.ch1_output_mode_selector.currentText()
            if output_volt == 'Custom':
                output_voltage = float(self.ch1_output_voltage_input.text().strip())
                self.awg.set_output_voltage_custom(channel=channel, value=output_voltage)
            elif output_volt == "Minimum" or output_volt == "Maximum":
                self.awg.set_output_voltage_minmax(channel=channel, mode="MIN") if output_volt == "Minimum" else self.awg.set_output_voltage_minmax(channel=channel, mode = "MAX")

        elif channel == 2:
            output_volt = self.ch1_output_mode_selector.currentText()
            if output_volt == 'Custom':
                output_voltage = float(self.ch1_output_voltage_input.text().strip())
                self.awg.set_output_voltage_custom(channel=channel, value=output_voltage)
            elif output_volt == "Minimum" or output_volt == "Maximum":
                self.awg.set_output_voltage_minmax(channel=channel, mode="MIN") if output_volt == "Minimum" else self.awg.set_output_voltage_minmax(channel=channel, mode = "MAX")

    def handle_output_offset_voltage(self, channel):
        if channel == 1:
            offset_volt = self.ch1_output_offset_selector.currentText()
            if offset_volt == 'Custom':
                offset_voltage = float(self.ch1_output_offsetvoltage_input.text().strip())
                self.awg.set_output_offset_voltage(channel=channel, value=offset_voltage)
            elif offset_volt == "Minimum" or offset_volt == "Maximum":
                self.awg.set_output_offset_min_max(channel=channel, mode="MIN") if offset_volt == "Minimum" else self.awg.set_output_offset_min_max(channel=channel, mode = "MAX")

        elif channel == 2:
            offset_volt = self.ch2_output_offset_selector.currentText()
            if offset_volt == 'Custom':
                offset_voltage = float(self.ch1_output_offsetvoltage_input.text().strip())
                self.awg.set_output_offset_voltage(channel=channel, value=offset_voltage)
            elif offset_volt == "Minimum" or offset_volt == "Maximum":
                self.awg.set_output_offset_min_max(channel=channel, mode="MIN") if offset_volt == "Minimum" else self.awg.set_output_offset_min_max(channel=channel, mode = "MAX")

    def handle_output_low_voltage(self, channel):
        if channel == 1:
            low_volt = self.ch1_output_low_selector.currentText()
            if low_volt == 'Custom':
                low_voltage = float(self.ch1_output_lowvoltage_input.text().strip())
                self.awg.set_output_low_level_custom(channel=channel, value=low_voltage)
            elif low_volt == "Minimum" or low_volt == "Maximum":
                self.awg.set_output_low_level_minmax(channel=channel, mode="MIN") if low_volt == "Minimum" else self.awg.set_output_low_level_minmax(channel=channel, mode = "MAX")

        elif channel == 2:
            low_volt = self.ch1_output_low_selector.currentText()
            if low_volt == 'Custom':
                low_voltage = float(self.ch1_output_lowvoltage_input.text().strip())
                self.awg.set_output_low_level_custom(channel=channel, value=low_voltage)
            elif low_volt == "Minimum" or low_volt == "Maximum":
                self.awg.set_output_low_level_minmax(channel=channel, mode="MIN") if low_volt == "Minimum" else self.awg.set_output_low_level_minmax(channel=channel, mode = "MAX")

    def handle_output_high_voltage(self, channel):
        if channel == 1:
            high_volt = self.ch1_output_high_selector.currentText()
            if high_volt == 'Custom':
                high_voltage = float(self.ch1_output_highvoltage_input.text().strip())
                self.awg.set_output_high_level_custom(channel=channel, value=high_voltage)
            elif high_volt == "Minimum" or high_volt == "Maximum":
                self.awg.set_output_high_level_minmax(channel=channel, mode="MIN") if high_volt == "Minimum" else self.awg.set_output_high_level_minmax(channel=channel, mode = "MAX")

        elif channel == 2:
            high_volt = self.ch1_output_high_selector.currentText()
            if high_volt == 'Custom':
                high_voltage = float(self.ch1_output_highvoltage_input.text().strip())
                self.awg.set_output_high_level_custom(channel=channel, value=high_voltage)
            elif high_volt == "Minimum" or high_volt == "Maximum":
                self.awg.set_output_high_level_minmax(channel=channel, mode="MIN") if high_volt == "Minimum" else self.awg.set_output_high_level_minmax(channel=channel, mode = "MAX")

    def handle_output_termination_voltage(self, channel):
        if channel == 1:
            termination_volt = self.ch1_output_termination_selector.currentText()
            if termination_volt == 'Custom':
                termination_voltage = float(self.ch1_output_terminationvoltage_input.text().strip())
                self.awg.set_output_termination_custom(channel=channel, value=termination_voltage)
            elif termination_volt == "Minimum" or termination_volt == "Maximum":
                self.awg.set_output_termination_minmax(channel=channel, mode="MIN") if termination_volt == "Minimum" else self.awg.set_output_termination_minmax(channel=channel, mode = "MAX")

        elif channel == 2:
            termination_volt = self.ch1_output_termination_selector.currentText()
            if termination_volt == 'Custom':
                termination_voltage = float(self.ch1_output_terminationvoltage_input.text().strip())
                self.awg.set_output_termination_custom(channel=channel, value=termination_voltage)
            elif termination_volt == "Minimum" or termination_volt == "Maximum":
                self.awg.set_output_termination_minmax(channel=channel, mode="MIN") if termination_volt == "Minimum" else self.awg.set_output_termination_minmax(channel=channel, mode = "MAX")
    def toggle_upload_check(self, channel):
        if channel ==1:
            is_upload = self.ch1_upload_check_bx.isChecked()
            if is_upload:
                self.ch1_waveform_selector.setEnabled(False)
                self.ch1_sine_group.setEnabled(False)
                self.ch1_prbs_group.setEnabled(False)
                self.ch1_lfm_group.setEnabled(False)
                self.ch1_noise_group.setEnabled(False)
                self.ch1_browse_btn.setEnabled(True)
                self.ch1_upload_btn.setEnabled(True)
            else:
                self.ch1_waveform_selector.setEnabled(True)
                self.ch1_sine_group.setEnabled(True)
                self.ch1_prbs_group.setEnabled(True)
                self.ch1_lfm_group.setEnabled(True) 
                self.ch1_noise_group.setEnabled(True)
                self.ch1_browse_btn.setEnabled(False)
                self.ch1_upload_btn.setEnabled(False)


        
if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = AWGGui()
    window.show()
    sys.exit(app.exec_())