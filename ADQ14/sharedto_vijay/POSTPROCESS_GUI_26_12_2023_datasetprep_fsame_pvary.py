import sys
from time import time
import time
import numpy as np
import numpy as np
import ctypes as ct
import sys
import os
from scipy import signal
from PyQt5 import QtCore, QtWidgets,QtGui
from PyQt5 import uic
from PyQt5.QtCore import pyqtSlot
import pyqtgraph as pg
sys.path.insert(1, os.path.dirname(os.path.realpath(__file__))+'/..')
from modules.example_helpers import *
import csv
import signal_core_operate as signalcore

# Record settings
number_of_records  = 1
samples_per_record = 110
sample_skip = 0
pretrigger = 0
triggerdelay = 0
channel_mask = 0xF

# Plot data if set to True
plot_data = False

# Print metadata in headers
print_headers = False
# ADQ Setup
# Load ADQAPI
ADQAPI = adqapi_load()

# Create ADQControlUnit
adq_cu = ct.c_void_p(ADQAPI.CreateADQControlUnit())

# Enable error logging from ADQAPI
ADQAPI.ADQControlUnit_EnableErrorTrace(adq_cu, 65536, '.')

# Find ADQ devices
ADQAPI.ADQControlUnit_FindDevices(adq_cu)
n_of_ADQ  = ADQAPI.ADQControlUnit_NofADQ(adq_cu)
n_of_failed_ADQ  = ADQAPI.ADQControlUnit_GetFailedDeviceCount(adq_cu)
if n_of_failed_ADQ > 0:
  print(n_of_failed_ADQ, 'connected devices failed initialization.')
print('Number of ADQ found:  {}'.format(n_of_ADQ))

# Exit if no devices were found
if n_of_ADQ < 1:
    print('No ADQ connected.')
    ADQAPI.DeleteADQControlUnit(adq_cu)
    sys.exit(1)

# Select ADQ
if n_of_ADQ > 1:
    adq_num = int(input('Select ADQ device 1-{:d}: '.format(n_of_ADQ)))
else:
    adq_num = 1

print_adq_device_revisions(ADQAPI, adq_cu, adq_num)

# Set clock source
ADQ_CLOCK_INT_INTREF = 0
ADQAPI.ADQ_SetClockSource(adq_cu, adq_num, ADQ_CLOCK_INT_INTREF)

# Setup test pattern
ADQAPI.ADQ_SetTestPatternMode(adq_cu, adq_num, 0)

# Set trig mode
SW_TRIG = 1
EXT_TRIG_1 = 2
EXT_TRIG_2 = 7
EXT_TRIG_3 = 8
LVL_TRIG = 3
INT_TRIG = 4
LVL_FALLING = 0
LVL_RISING = 1
TRIG_THRESHOLD = 0.020  #if external trigger applied. Trigger threshold should be less then the external trigger in our case it is 50mV
HIGH_IMPEDANCE = 1  
LOW_IMPEDANCE = 0
trig_type = EXT_TRIG_1

CHANNELS = ['A','B','C','D']



if trig_type == LVL_TRIG:
  success = ADQAPI.ADQ_SetLvlTrigLevel(adq_cu, adq_num, 0)
  if (success == 0):
      print('ADQ_SetLvlTrigLevel failed.')
  success = ADQAPI.ADQ_SetLvlTrigEdge(adq_cu, adq_num, LVL_RISING)
  if (success == 0):
      print('ADQ_SetLvlTrigEdge failed.')

#If Providing an external trigger input
if trig_type == EXT_TRIG_1:
    success = ADQAPI.ADQ_SetTriggerMode(adq_cu, adq_num, trig_type)   #setting the external trigger mode.
    if (success == 0):
        print('ADQ_SetTriggerMode failed.')
    print("......External Trigger applied......")
    success = ADQAPI.ADQ_SetTriggerInputImpedance(adq_cu, adq_num,1,HIGH_IMPEDANCE)   #Set to 1 for TRIG connector and 2 for SYNC connector
    if (success == 0):
        print('ADQ_SetTriggerInputImpedance failed.')
    success = ADQAPI.ADQ_SetExternTrigEdge(adq_cu,adq_num,LVL_RISING)  # Rising: 1, Falling: 0, both: 2 (for ADQ14 only)
    if (success == 0):
        print('ADQ_SetExternTrigEdge failed.')
    success = ADQAPI.ADQ_SetExternalTriggerDelay(adq_cu,adq_num,triggerdelay)
    if (success == 0):
        print('ADQ_SetExternalTriggerDelay failed.')

    # changing the external trigger threshold
    success = ADQAPI.ADQ_SetExtTrigThreshold(adq_cu,adq_num,1,ct.c_double(TRIG_THRESHOLD))
    if (success == 0):
        print('ADQ_SetExtTrigThreshold failed.')
    result=ct.c_uint(0)
    ADQAPI.ADQ_GetExternTrigEdge(adq_cu,adq_num,ct.pointer(result))
    if(result.value==1):
        print("....External trig edge rising edge....")

    ADQAPI.ADQ_GetTriggerInputImpedance(adq_cu,adq_num,1,ct.pointer(result))
    if(result.value==1):
        print("....External trig is at HIGH Impedance....")



class Adq14_LIVE_PLOT_APP3(QtWidgets.QMainWindow):
    def __init__(self):
        QtWidgets.QMainWindow.__init__(self)
        self.ui = uic.loadUi('FWDAQ/guilayouts_versions/ADQ14gui_whitebg.ui',self)
        self.resize(1920,720)
        self.showMaximized()
        
        self.threadpool = QtCore.QThreadPool()
        # self.setWindowIcon(QtGui.QIcon('images/iitmlogo_1.png'))
        
        self.pushButton.setIcon(self.style().standardIcon(getattr(QtWidgets.QStyle, 'SP_MediaPlay')))
        self.pushButton_2.setIcon(self.style().standardIcon(getattr(QtWidgets.QStyle, 'SP_MediaStop')))

        self.pushButton.setCursor(QtGui.QCursor(QtCore.Qt.PointingHandCursor))
        self.pushButton_2.setCursor(QtGui.QCursor(QtCore.Qt.PointingHandCursor))
        self.pushButton.setStyleSheet("QPushButton::hover"
                             "{"
                             "background-color : lightgreen;"
                             "}"
                             "QPushButton"
                             "{"
                             "background-color : lightblue; border-style: outset;border-width: 0.2px;border-radius: 5px;padding: 10px;"
                             "}"
                             "QPushButton::pressed"
                             "{"
                             "background-color : lightgreen;"
                             "}"
                             "QPushButton::disabled"
                             "{"
                             "background-color : lightgreen;"
                             "}")
        self.pushButton_2.setStyleSheet("QPushButton::hover"
                             "{"
                             "background-color : red;"
                             "}"
                             "QPushButton"
                             "{"
                             "background-color : lightblue; border-style: outset;border-width: 0.2px;border-radius: 5px;padding: 10px; "
                             "}"
                             "QPushButton::pressed"
                             "{"
                             "background-color : red;"
                             "}"
                             "QPushButton::disabled"
                             "{"
                             "background-color : red;"
                             "}")
        self.pushButton.setToolTip('Start Stream')
        self.pushButton_2.setToolTip('Stop Stream')
        # set the title
        self.setWindowTitle("ADQ14 POST PROCESSING")
       
        self.thread={}


        #Unchecked the channel checkbox button as
        self.ch_a_checkbox.setChecked(False)
        self.ch_b_checkbox.setChecked(False)
        self.ch_c_checkbox.setChecked(False)
        self.ch_d_checkbox.setChecked(False)
        self.ch_fft_checkbox.setChecked(False)

        #set the radio buttons
        self.algo_radio_btn_1.setChecked(False)
        self.algo_radio_btn_none.setChecked(True)

        #Set the ADQ14 parameters
        self.device = 0
        self.window_length = samples_per_record
        self.interval= 1
        self.samples = samples_per_record
        self.sample_skip_post_process = 1
        self.interpolation_rate = 1
        self.skip_start_samples = 0
        

        length = int(self.samples)
        self.plotdata = np.zeros(number_of_records*samples_per_record, dtype=np.int16)


        self.sample_line_edit.textChanged['QString'].connect(self.update_sample_number)
        self.sample_skip_line_edit.textChanged['QString'].connect(self.update_sample_skip_post_processing)
        self.skip_start_line_edit.textChanged['QString'].connect(self.skip_start_samples_on_rawdata)
        self.interpolation_line_edit.textChanged['QString'].connect(self.update_interpolation_rate)        

        self.label_4.setText("External Trigger Activated")
        if n_of_ADQ == 1:
            self.DeviceConnected=True
            self.label_2.setText("1")
        else:
            self.label_2.setText("No Device Connected.")
        
        self.worker = None
        self.continue_stream = False
        self.widget.setBackground(background='w')
        self.channels_plot = self.widget.addPlot(title="title_plot")
        self.channels_plot.showGrid(x=True, y=True,alpha=2)
        font=QtGui.QFont()
        font.setPixelSize(25)
        self.channels_plot.getAxis("bottom").setStyle(tickFont = font)
        self.channels_plot.getAxis("left").setStyle(tickFont = font)
        self.widget.nextRow()
        self.channels_plot2 = self.widget.addPlot(title="title_plot")
        self.channels_plot2.showGrid(x=True, y=True,alpha=2)
        self.channels_plot2.getAxis("bottom").setStyle(tickFont = font)
        self.channels_plot2.getAxis("left").setStyle(tickFont = font)
        self.channels_plot2.hide()
        self.update_plot1_setTitle("","Time","ns","Voltage","v")
        self.frequencies = list()
        self.arcsine_data1 = list()
        self.test_data = list()
        self.expected_recovered_freq = list()
        self.start_pow = -22 # dBm
        # self.stop_pow = 0.7233
        self.stop_pow = 14 # dBm
        self.step_size = 1  # dBm
        self.powercounter = 0
        self.frequency_in = 0.1 # GHz
        self.freqcapture = True
        self.savedata = True
        self.freqon = True
        # self.update_plot1_setRanges(self.samplerate,25000)
# , symbol='o', symbolPen='b', symbolBrush=0.01, name='blue'
        self.ch_a_plot = self.channels_plot.plot(pen={'color':'g','width':3}, symbol='o', symbolPen='g', symbolBrush='g')

        self.ch_b_plot = self.channels_plot.plot(pen={'color':'r','width':3}, symbol='o', symbolPen='r', symbolBrush='r')
        self.ch_c_plot = self.channels_plot.plot(pen={'color':'b','width':3}, symbol='o', symbolPen='b', symbolBrush='b')
        self.ch_d_plot = self.channels_plot.plot(pen={'color':'k','width':3}, symbol='o', symbolPen='k', symbolBrush='k')
        self.fft_plot = self.channels_plot.plot(pen={'color':'r', 'width':3})
        # self.ch6_plot = self.channels_plot2.plot(pen={'color':'r','width':2}, symbol='o', symbolPen='r', symbolBrush=0.01)
        self.differential_plot = self.channels_plot2.plot(pen={'color':'b','width':3}, symbol='o', symbolPen='b', symbolBrush=0.02)
        
        self.ch_a_plot.setSymbolSize(10)
        self.ch_b_plot .setSymbolSize(10)
        self.ch_c_plot .setSymbolSize(10)
        self.ch_d_plot .setSymbolSize(10)
        self.fft_plot .setSymbolSize(10)
        self.differential_plot .setSymbolSize(10)

        self.pushButton.clicked.connect(self.start_worker_1)
        self.pushButton_2.clicked.connect(self.stop_worker)
        finish = QtWidgets.QAction("Quit", self)
        finish.triggered.connect(self.closeEvent)

        
    def start_worker_1(self):
        self.thread[1] = ThreadClass(parent=None,index=1)
        self.thread[1].start()
        self.thread[1].any_channel.connect(self.process_function)
        self.thread[2] = ThreadClass(parent=None,index=2)
        self.thread[2].start()
        self.thread[2].process_channel.connect(self.plot_function)
        self.sample_line_edit.setEnabled(True)
        self.sample_skip_line_edit.setEnabled(True)
        self.skip_start_line_edit.setEnabled(True)
        self.interpolation_line_edit.setEnabled(True)
        self.pushButton.setEnabled(False)
        self.pushButton_2.setEnabled(True)
        self.f = open('C:/Users/USER/ADQ14 Python development/FWDAQ/MLdataset/26_12_2023_dataset_pvary_fsame/data_26_12_f_1_00_GHz.csv','w')
        self.w = csv.writer(self.f)
        self.w.writerow(['Numbers','Power','arcsin_results','test_data','expected_recovered_pow'])
        self.freqon = True

        
    def stop_worker(self):
        self.thread[1].stop()
        self.thread[2].stop()

        self.sample_line_edit.setEnabled(True)
        self.sample_skip_line_edit.setEnabled(True)
        self.skip_start_line_edit.setEnabled(True)
        self.interpolation_line_edit.setEnabled(True)
        self.pushButton.setEnabled(True)
        self.pushButton_2.setEnabled(False)

        # self.ch_b_plot.setData(np.array([0]))
        # self.ch_d_plot.setData(np.array([0]))
        self.update_plot1_setTitle("Streaming Window","Time","ns","Voltage","v")
        self.freqon = True
        # self.update_plot1_setRanges(self.samplerate,16000)
        # print('ACTIVE THREAS: ', self.threadpool.activeThreadCount(),end="\r")

    def gain_correction(self,even_data_gain, odd_data_gain):
        even_max = max(even_data_gain)
        odd_max = max(odd_data_gain)
        print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
        if (even_max>=odd_max):
            ratio1 = even_max/odd_max
            odd_data_gain = odd_data_gain * ratio1
            print("EVEN")
            print(np.shape(odd_data_gain))
        elif (even_max<odd_max):
            ratio = odd_max/even_max
            even_data_gain = even_data_gain * ratio 
            print("ODD")
            print(np.shape(odd_data_gain))

        return even_data_gain,odd_data_gain

    def stitch_four_channel(self,channelA,channelB,channelC,channelD,sample_rate,skip_data=1,interp_rate = 1):
        # The length of the four channels
        lenA = len(channelA)
        lenB = len(channelB)
        lenC = len(channelC)
        lenD = len(channelD)
        # The shortest channel
        minlen = min(lenA,lenB,lenC,lenD)

        loop = int(minlen/(10*interp_rate))

        skip_data= skip_data

        channel_array_1 = np.zeros((loop,10*interp_rate))
        channel_array_2 = np.zeros((loop,10*interp_rate))
        channel_array_3 = np.zeros((loop,10*interp_rate))
        channel_array_4 = np.zeros((loop,10*interp_rate))
        
        channel_array_1_skip = np.zeros((loop,10*interp_rate -skip_data))
        channel_array_2_skip = np.zeros((loop,10*interp_rate -(skip_data* 2)))
        channel_array_3_skip = np.zeros((loop,10*interp_rate - (skip_data* 2)))
        channel_array_4_skip = np.zeros((loop,10*interp_rate - skip_data))
        sample = minlen

        even_data_test,odd_data_test = list(),list()
        even_data_test_skip,odd_data_test_skip = list(),list()

        time_axis = np.linspace(0,((1/(sample_rate*interp_rate))*1e9)*((sample*2)-1),sample*2,endpoint=True)
        time_axis_new = list()


        positions = [i for i in range(10*interp_rate, sample*2, 10*interp_rate)]

        time_splitted = np.split(time_axis, positions)

        counter = 0
        for i in range(loop):
            channel_array_1[i,:] = channelA[i*10*interp_rate:(i+1)*10*interp_rate]
            channel_array_2[i,:] = channelB[i*10*interp_rate:(i+1)*10*interp_rate]
            channel_array_3[i,:] = channelC[i*10*interp_rate:(i+1)*10*interp_rate]
            channel_array_4[i,:] = channelD[i*10*interp_rate:(i+1)*10*interp_rate]

            # even_max = max(channel_array_2[i,:])
            # odd_max = max(channel_array_3[i,:])
            # if (even_max>=odd_max):
            #     ratio1 = even_max/odd_max
            #     channel_array_3[i,:] = channel_array_3[i,:] * ratio1
            #     # print("Gain Ratio: ", ratio1)
            # elif (even_max<odd_max):
            #     ratio = odd_max/even_max
            #     channel_array_2[i,:] = channel_array_2[i,:]* ratio

            # rat  =1.6 * np.max(channel_array_1[i,:]) / np.max(channel_array_2[i,:])
            # rat2  =1.6 * np.max(channel_array_3[i,:]) / np.max(channel_array_4[i,:])

            # channel_array_1[i,:] = channel_array_1[i,:] / rat
            # channel_array_4[i,:] = channel_array_4[i,:] / rat2


            channel_array_1_skip[i,:] = channel_array_1[i][:-skip_data]
            channel_array_2_skip[i,:] = channel_array_2[i][skip_data:-skip_data]
            channel_array_3_skip[i,:] = channel_array_3[i][skip_data:-skip_data]
            channel_array_4_skip[i,:] = channel_array_4[i][skip_data:]


            if i*4 < len(time_splitted):
                time_axis_new.append(np.concatenate((time_splitted[i*4][:-skip_data],time_splitted[(i*4)+1][skip_data:-skip_data],time_splitted[(i*4)+2][skip_data:-skip_data],time_splitted[(i*4)+3][skip_data:])))
            
            temp = np.concatenate((channel_array_1[i,:],channel_array_2[i,:],channel_array_3[i,:],channel_array_4[i,:]))
            temp_skip = np.concatenate((channel_array_1_skip[i,:],channel_array_2_skip[i,:],channel_array_3_skip[i,:],channel_array_4_skip[i,:]))
            if i%2==0:
                even_data_test.append(temp)
                even_data_test_skip.append(temp_skip)

            else:
                odd_data_test.append(temp)
                odd_data_test_skip.append(temp_skip)
           
            counter = i +1
            if counter%2 == 0 and len(odd_data_test) >= 1:
                j = (counter//2)-1
                a,b = self.gain_correction(even_data_test_skip[j][0:(10*interp_rate)-skip_data], odd_data_test_skip[j][0:(10*interp_rate)-skip_data])
                even_data_test_skip[j][0:(10*interp_rate)-skip_data] = a
                odd_data_test_skip[j][0:(10*interp_rate)-skip_data] = b

                c,d = self.gain_correction(even_data_test_skip[j][(10*interp_rate)-skip_data:(20*interp_rate)-(2*skip_data)], odd_data_test_skip[j][(10*interp_rate)-skip_data:(20*interp_rate)-(2*skip_data)])
                even_data_test_skip[j][(10*interp_rate)-skip_data:(20*interp_rate)-(2*skip_data)] = c
                odd_data_test_skip[j][(10*interp_rate)-skip_data:(20*interp_rate)-(2*skip_data)] = d

                e,f = self.gain_correction(even_data_test_skip[j][(20*interp_rate)-(2*skip_data):(30*interp_rate)-(2*skip_data)], odd_data_test_skip[j][(20*interp_rate)-(2*skip_data):(30*interp_rate)-(2*skip_data)])
                even_data_test_skip[j][(20*interp_rate)-(2*skip_data):(30*interp_rate)-(2*skip_data)] = e
                odd_data_test_skip[j][(20*interp_rate)-(2*skip_data):(30*interp_rate)-(2*skip_data)] = f

                g,h = self.gain_correction(even_data_test_skip[j][(30*interp_rate)-(2*skip_data):], odd_data_test_skip[j][(30*interp_rate)-(2*skip_data):])
                even_data_test_skip[j][(30*interp_rate)-(2*skip_data):] = g
                odd_data_test_skip[j][(30*interp_rate)-(2*skip_data):] = h
                

                print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
                
        return loop,[even_data_test,odd_data_test],[even_data_test_skip,odd_data_test_skip],time_axis_new

    def set_axis_font(self, fontsize):
        font=QtGui.QFont()
        font.setPixelSize(fontsize)
        return font

    def sinc_interpolation(self,data_ch,interpolationRate=2):
        x2 = np.r_[0:len(data_ch):len(data_ch) * 1j]
        v = len(data_ch) * interpolationRate
        x2_new = np.r_[0:len(data_ch):(v) * 1j]
        x = data_ch
        s = x2
        u = x2_new
        if len(x) != len(s):
            raise ValueError('x and s must be the same length')

        # Find the period
        T = s[1] - s[0]

        sincM = np.tile(u, (len(s), 1)) - np.tile(s[:, np.newaxis], (1, len(u)))
        y = np.dot(x, np.sinc(sincM / T))
        return y


    def process_1(self,data,SAMPLE_acquired,s_idata,delay_ch,skip1,skip2):
        data = data[:SAMPLE_acquired]
        data = (data/2**15)*(1.9/2)

        try:
            data = np.roll(data, delay_ch)

            if skip1==0 and skip2==0:
                data = data
            elif skip1 == 0 or skip2==0:
                if skip1==0:
                    data = data[:-skip2]
                if skip2 == 0:
                    data = data[skip1:]

            else:
                data = data[skip1:-skip2]

            data = self.sinc_interpolation(data, interpolationRate=s_idata)
            data = data - min(data) + 0.1
            return data
        
        except ValueError as e:
            print(e)

                                                                         
    def arcSine_diff(self,data1_,data2_):                                     
        arcSine_diff_result = []                                         
        print(np.shape(data1_),np.shape(data2_))                         
        for Ip, In in zip(data1_,data2_):                                
            array1 = np.array(Ip)                                        
            array2 = np.array(In)                                        
            subtracted_array = np.subtract(array1,array2)                
            added_array = np.add(array1,array2)                          
            divided_array = np.divide(subtracted_array,added_array)      
            arcSine_diff_result.append(np.arcsin(divided_array))         

        return arcSine_diff_result   
                                        
    def butter_lowpass_filter(self, data, cutoff, fs, order):
        normal_cutoff = cutoff / (fs*0.5)
        # Get the filter coefficients 
        b, a = signal.butter(order, normal_cutoff, btype='low', analog=False)
        y = signal.filtfilt(b, a, data)
        return y

    def fft_signal(self,data_,interp_rate):
        """
        scaling{ ‘density’, ‘spectrum’ }, optional Selects between computing the power spectral density (‘density’) 
        where Pxx has units of V**2/Hz and computing the power spectrum (‘spectrum’) where Pxx has units of V**2, 
        if x is measured in V and fs is measured in Hz. Default is set to ‘density’.
        """
        f, x = signal.periodogram(data_, window='hann',nfft=1024, fs=1e9*interp_rate, scaling='spectrum')
        f = f/1e6
        x = 10*(np.log10(np.divide(x,50e-3)))
        return np.array([f,x])                                                  

    def time_axis_gen2(self,dataLength,sample_rates):
        return np.linspace(0,((1/sample_rates)*1e9)*(dataLength-1),dataLength,endpoint=True)
    
    def update_plot1_setTitle(self,title_plot,xLabel,unitXlabel,yLabel,unitYlabel):
        self.channels_plot.setTitle(title_plot, color="k", fontsize="35")
        labelStyle = {'color': '#000', 'font-size': '18pt'}
        self.channels_plot.setLabel('left',text=yLabel, units=unitYlabel,unitPrefix=None, **labelStyle)
        self.channels_plot.setLabel('bottom', text=xLabel,  units=unitXlabel,unitPrefix=None, **labelStyle)
        self.channels_plot.getAxis('bottom').setPen('k')
        self.channels_plot.getAxis("bottom").setStyle(tickFont=self.set_axis_font(25),tickTextOffset = 10)
        self.channels_plot.getAxis('bottom').setTextPen('k')
        self.channels_plot.getAxis('left').setTextPen('k')   
        self.channels_plot.getAxis("left").setStyle(tickFont=self.set_axis_font(25),tickTextOffset = 10)


    def update_plot1_setRanges(self,xMinLim,xMaxLim,yMinLim,yMaxLim):
        self.channels_plot.setLimits(xMin=xMinLim,xMax=xMaxLim,yMin=yMinLim,yMax=yMaxLim)
        # self.channels_plot.setDefaultPadding(padding=0.08)

    def update_plot2_setTitle(self,title_plot,xLabel,unitXlabel,yLabel,unitYlabel):
        self.channels_plot2.setTitle(title_plot, color="k", fontsize="35")
        labelStyle = {'color': '#000', 'font-size': '18pt'}
        self.channels_plot2.setLabel('left',text=yLabel, units=unitYlabel,unitPrefix=None, **labelStyle)
        self.channels_plot2.setLabel('bottom', text=xLabel,  units=unitXlabel,unitPrefix=None, **labelStyle)
        self.channels_plot2.getAxis('bottom').setPen('k')
        self.channels_plot2.getAxis('bottom').setTextPen('k')
        self.channels_plot2.getAxis("bottom").setStyle(tickFont=self.set_axis_font(25),tickTextOffset = 10)
        self.channels_plot2.getAxis('left').setTextPen('k')  
        self.channels_plot2.getAxis("left").setStyle(tickFont=self.set_axis_font(25),tickTextOffset = 10)
        

    def update_plot2_setRanges(self,xrange,yrange):
        self.channels_plot2.setXRange(0, xrange, padding=0)
        self.channels_plot2.setYRange(0, yrange, padding=0)
    

    def update_sample_number(self,value):
        tmp = int(value)
        if tmp >= 80:
            self.samples = tmp +10
        else:
            self.samples = self.samples
    

    def update_sample_skip_post_processing(self,value):
        tmp= int(value)
        if tmp >0:
            self.sample_skip_post_process = tmp
        else:
            self.sample_skip_post_process = self.sample_skip_post_process 


    def skip_start_samples_on_rawdata(self,value):
        temp = int(value)
        if 1<=temp <=9:
            self.skip_start_samples = temp
        else:
            self.skip_start_samples = self.skip_start_samples


    def update_interpolation_rate(self,value):
        value = int(value)
        if value >0:
            self.interpolation_rate = int(value)
        else:
            self.interpolation_rate = self.interpolation_rate

    def closeEvent(self, event):
        close = QtWidgets.QMessageBox.question(self,
                                     "QUIT",
                                     "Sure?",
                                      QtWidgets.QMessageBox.Yes | QtWidgets.QMessageBox.No)
        if close == QtWidgets.QMessageBox.Yes:
            ADQAPI.DeleteADQControlUnit(adq_cu)
            event.accept()
            print("Application Quit")
        else:
            event.ignore()


    def process_function(self,channel_data):
        samples_per_record = self.samples
        interpolation_rate = self.interpolation_rate
        skip_start_left = self.skip_start_samples
        sample_skip_post_process = self.sample_skip_post_process
        delay = 8
        sample_rate = 1e9
        skip_start_right = 10-skip_start_left
        
        if self.signal_on_button.isChecked():
            if self.freqon:
                signalcore.signalOn()
                self.freqon = False
            if self.powercounter>=20:  # change 1 to 100 to get 100 sample set of each frequencies
                self.powercounter =0
                self.freqcapture = True
            if self.freqcapture:
                self.start_pow+=self.step_size
                self.start_pow = self.start_pow
                signalcore.setPower(self.start_pow)
                
                print("Set Power {} dBm".format(self.start_pow))
                print("Signal ON")
                self.freqcapture = False

            if self.start_pow >=self.stop_pow:
                self.powercounter = 0
                self.start_pow= -22
                self.freqcapture = False
                self.savedata = False
                self.signal_on_button.setChecked(False)
                self.f.close()
                signalcore.signalOff()
                 
                

        ADQAPI.ADQ_SetSampleSkip(adq_cu, adq_num, sample_skip)
        ADQAPI.ADQ_SetPreTrigSamples(adq_cu, adq_num, pretrigger)
        ADQAPI.ADQ_SetTriggerDelay(adq_cu, adq_num, triggerdelay)

        # Setup multirecord
        ADQAPI.ADQ_MultiRecordSetChannelMask(adq_cu, adq_num, channel_mask)
        ADQAPI.ADQ_MultiRecordSetup(adq_cu, adq_num, number_of_records, samples_per_record)

        # Get number of channels from device
        number_of_channels = ADQAPI.ADQ_GetNofChannels(adq_cu, adq_num)

        # Arm acquisition
        # print('Arming device')
        ADQAPI.ADQ_DisarmTrigger(adq_cu, adq_num)
        ADQAPI.ADQ_ArmTrigger(adq_cu, adq_num)

        # Allocate target buffers for intermediate data storage
        target_buffers = (ct.POINTER(ct.c_int16*(number_of_records*samples_per_record))*number_of_channels)()
        for bufp in target_buffers:
            bufp.contents = (ct.c_int16*(number_of_records*samples_per_record))()

        # Create some buffers for the full records
        # data_numpy = [np.zeros(number_of_records*samples_per_record, dtype=np.int16),
        #                 np.zeros(number_of_records*samples_per_record, dtype=np.int16),
        #                 np.zeros(number_of_records*samples_per_record, dtype=np.int16),
        #                 np.zeros(number_of_records*samples_per_record, dtype=np.int16)]  
        # Create some buffers for the full records
        data_numpy = [np.zeros(number_of_records*samples_per_record, dtype=np.int16),
                        np.zeros(number_of_records*samples_per_record, dtype=np.int16),
                        np.zeros(number_of_records*samples_per_record, dtype=np.int16),
                        np.zeros(number_of_records*samples_per_record, dtype=np.int16)]
        # Allocate target buffers for headers
        header_list = (HEADER*number_of_records)()
        target_headers = ct.POINTER(HEADER*number_of_records)()
        target_headers.contents = header_list
        target_headers_vp = ct.cast(ct.pointer(target_headers), ct.POINTER(ct.c_void_p))

        # Generate triggers if software trig is used
        if (trig_type == SW_TRIG):
            for trig in range(number_of_records):
                ADQAPI.ADQ_SWTrig(adq_cu, adq_num)

        # print('Waiting for data...')
        # Collect data until all requested records have been recieved
        records_completed = 0
        records_available = 0


        # Read out data until records_completed for ch A is number_of_records
        while (records_completed < number_of_records):
            records_available = ADQAPI.ADQ_GetAcquiredRecords(adq_cu, adq_num)
            new_records = records_available - records_completed

            if new_records > 0:
                # Fetch data and headers into target buffers
                status = ADQAPI.ADQ_GetDataWHTS(adq_cu, adq_num,
                                                    target_buffers,
                                                    target_headers,
                                                    None,
                                                    number_of_records*samples_per_record,
                                                    2,
                                                    records_completed,
                                                    new_records,
                                                    channel_mask,
                                                    0,
                                                    samples_per_record,
                                                    0x00)

                if status == 0:
                    # print('GetDataWH failed!')
                    ADQAPI.DeleteADQControlUnit(adq_cu)
                    sys.exit()

                for ch in range(0,number_of_channels):
                    data_buf = np.frombuffer(target_buffers[ch].contents, dtype=np.int16, count=(samples_per_record*new_records))
                    for rec in range(0,new_records):
                        for s in range(0,samples_per_record):
                            data_numpy[ch][(records_completed+rec)*samples_per_record + s] = data_buf[rec*samples_per_record + s]
                records_completed += new_records
                target_headers_vp.contents.value += new_records*ct.sizeof(HEADER)

        ADQAPI.ADQ_MultiRecordClose(adq_cu, adq_num)

        channel_data = data_numpy
        
        print("......................")
        print(np.shape(channel_data))
        print("......................")
        
        data1 = np.array(channel_data[0])
        data2 = np.array(channel_data[1])
        data3 = np.array(channel_data[2])
        data4 = np.array(channel_data[3])

        
    
        data1_processed1 = self.process_1(data1, SAMPLE_acquired=samples_per_record,s_idata=interpolation_rate,delay_ch= 0,skip1=skip_start_left,skip2=skip_start_right)
        data2_processed1 = self.process_1(data2, SAMPLE_acquired=samples_per_record,s_idata=interpolation_rate,delay_ch= -(1*delay),skip1=skip_start_left,skip2=skip_start_right)
        data3_processed1 = self.process_1(data3, SAMPLE_acquired=samples_per_record,s_idata=interpolation_rate,delay_ch= -((2*delay)+1),skip1=skip_start_left,skip2=skip_start_right)
        data4_processed1 = self.process_1(data4, SAMPLE_acquired=samples_per_record,s_idata=interpolation_rate,delay_ch= -((3*delay)+2),skip1=skip_start_left,skip2=skip_start_right)
        

        data1_dc_Shifted = data1_processed1
        data2_dc_Shifted = data2_processed1
        data3_dc_Shifted = data3_processed1
        data4_dc_Shifted = data4_processed1
        #until done
        
        if self.algo_radio_btn_1.isChecked():
            self.ch_a_checkbox.setChecked(False)
            self.ch_b_checkbox.setChecked(False)
            self.ch_c_checkbox.setChecked(False)
            self.ch_d_checkbox.setChecked(False)
            self.ch_a_checkbox.setEnabled(False)
            self.ch_b_checkbox.setEnabled(False)
            self.ch_c_checkbox.setEnabled(False)
            self.ch_d_checkbox.setEnabled(False)
            start_time = time.time()
          # Performing even and odd segregation, gain correction and stitching of even and odd data with without skip data at every stitch point
            loop,evenodd,evenoddskip,time_skip_evenodd = self.stitch_four_channel(   data1_dc_Shifted,
                                                                              data2_dc_Shifted,
                                                                              data3_dc_Shifted,
                                                                              data4_dc_Shifted,
                                                                              sample_rate = sample_rate,
                                                                              skip_data=sample_skip_post_process,
                                                                              interp_rate=interpolation_rate)

            data_stitched_even =  np.concatenate(evenodd[0], axis=0)
            data_stitched_odd = np.concatenate(evenodd[1], axis=0)
            data_stitched_even_striped = np.concatenate(evenoddskip[0], axis=0)
            data_stitched_odd_striped = np.concatenate(evenoddskip[1], axis=0)  
            data_stitched_even_striped = data_stitched_even_striped[:-((40*interpolation_rate)-(6*sample_skip_post_process))]
            data_stitched_odd_striped = data_stitched_odd_striped[:-((40*interpolation_rate)-(6*sample_skip_post_process))]
            time_data_stitched_even_striped =  np.concatenate(time_skip_evenodd, axis=0)
            time_data_stitched_even_striped =  time_data_stitched_even_striped[:-((40*interpolation_rate)-(6*sample_skip_post_process))]
            


            # even_filtered_stripped = self.butter_lowpass_filter(data_stitched_even_striped, 100e6, sample_rate*interpolation_rate, order=8)
            # odd_filtered_stripped = self.butter_lowpass_filter(data_stitched_odd_striped, 100e6, sample_rate*interpolation_rate, order=8)
            # data_stitched_even_striped = data_stitched_even_striped/even_filtered_stripped
            # data_stitched_odd_striped = data_stitched_odd_striped/odd_filtered_stripped







            arcSine_diff_result = self.arcSine_diff(data_stitched_even_striped,data_stitched_odd_striped)




            if self.signal_on_button.isChecked():
                if self.savedata:
                    print("Counter: ".format(self.powercounter))
                    self.powercounter +=1
                    stretch_factor = 3.132 # -> AVG # previous -> 3.0574 
                    frequency_input = round(self.frequency_in,6)
                    frequency_recovered = np.divide(frequency_input, stretch_factor)
                    frequency_recovered = round(frequency_recovered,6)
                    fs =  2e9
                    Rs = 50
                    In_power = self.start_pow  # dBm
                    V_rms = np.sqrt(Rs/1000) * 10**(In_power/20)
                    Vm = np.sqrt(2) * V_rms
                    Stop_Time = 200.00000 * 1e-9  # in seconds (set according to the length of opt
                    Frequency = frequency_recovered * 1e9 # in GHz
                    time_RF =  np.arange(0, Stop_Time, 1/fs)
                    
                    sign_of_arcsin_data = np.sign(arcSine_diff_result[0])
                    # if (sign_of_arcsin_data==-1):
                    #     Vm = -Vm
                    Output_RF = Vm * np.sin(2 * np.pi * Frequency * time_RF)  # RF signal in volts
                    Output_RF = Output_RF.tolist()
                
                    # print(Output_RF.shape)
                    self.w.writerow([self.powercounter,In_power,arcSine_diff_result,Output_RF,frequency_recovered])
                    print("Saving....Counter-> {},Freq-> {}, Power-> {}".format(self.powercounter,self.frequency_in,self.start_pow))
            # analytic_signal = signal.hilbert(arcSine_diff_result)
            # amplitude_envelope = np.abs(analytic_signal)
            # arcSine_diff_result = arcSine_diff_result/amplitude_envelope

            stop_time = time.time()
            print("Time taken for even and odd stitch and diff arcsine: {}".format(stop_time-start_time))
            if self.ch_fft_checkbox.isChecked():
                self.ch_fft_checkbox.setEnabled(True)
                applied_fft = self.fft_signal(arcSine_diff_result,interpolation_rate)
                ch_plot_data = applied_fft
            else:
                self.ch_fft_checkbox.setEnabled(True)
                ch_plot_data = np.array([data_stitched_even_striped,data_stitched_odd_striped,arcSine_diff_result,time_data_stitched_even_striped])

            self.thread[2].process_channel.emit(ch_plot_data)

        if self.algo_radio_btn_none.isChecked():
            self.ch_a_checkbox.setEnabled(True)
            self.ch_b_checkbox.setEnabled(True)
            self.ch_c_checkbox.setEnabled(True)
            self.ch_d_checkbox.setEnabled(True)
            self.ch_fft_checkbox.setEnabled(False)

            time_axis_chA = self.time_axis_gen2(len(data1_dc_Shifted),sample_rates = sample_rate*interpolation_rate)
            ch_plot_data = np.array([data1_dc_Shifted,data2_dc_Shifted,data3_dc_Shifted,data4_dc_Shifted,time_axis_chA])
            self.thread[2].process_channel.emit(ch_plot_data)



        # print("..........Thread  1 STOP ...........")


    def plot_function(self,ch_plot_data):
        # print("..........Thread  2 START ...........")
        if self.algo_radio_btn_none.isChecked():
            self.channels_plot2.hide()
            self.update_plot1_setTitle("Four Channel Stream Window","Time","ns","Voltage","v")
       
  
  
  
            timeaxis_CH = ch_plot_data[4]
            xMinLim,xMaxLim,yMinLim,yMaxLim = 0,len(timeaxis_CH),0,2
            self.update_plot1_setRanges(xMinLim,xMaxLim,yMinLim,yMaxLim)



            if self.ch_a_checkbox.isChecked():
                self.ch_a_plot.setData(timeaxis_CH,ch_plot_data[0])
                self.ch_a_plot.show()
            else:
                self.ch_a_plot.hide()

            if self.ch_b_checkbox.isChecked():
                self.ch_b_plot.setData(timeaxis_CH,ch_plot_data[1])
                self.ch_b_plot.show()
            else:
                self.ch_b_plot.hide()

            if self.ch_c_checkbox.isChecked():
                self.ch_c_plot.setData(timeaxis_CH,ch_plot_data[2])
                self.ch_c_plot.show()
            else:
                self.ch_c_plot.hide()

            if self.ch_d_checkbox.isChecked():
                self.ch_d_plot.setData(timeaxis_CH,ch_plot_data[3])
                self.ch_d_plot.show()
            else:
                self.ch_d_plot.hide()
        if self.algo_radio_btn_1.isChecked():
            # self.update_plot_view("Post Processed Streaming Window",len(ch_plot_data[0]),100)
            # self.ch_a_plot.setData(np.asarray([0]))
            # Adjusts the Amplitude of the FFT
            self.update_plot1_setTitle("Post Processing Window","Time","ns","Voltage","v")

            
            if self.ch_fft_checkbox.isChecked():
                self.channels_plot2.hide()
                self.update_plot1_setTitle("Post Processing Window with FFT","Frequency", "MHz","Power","dBm")
                self.update_plot1_setRanges(0,505,-90,10)
                Final_results = ch_plot_data
                # Final_results1 = np.concatenate(Final_results, axis=0)
                # Final_results2 = np.concatenate(Final_results, axis=0)  
                # Create a linear scale based on the Sample Rate and Number of Samples.
                # self.channels_plot.addLegend(labelTextColor='k',labelTextSize='15pt')
                # print(np.shape(Final_results))
                self.fft_plot.setData(Final_results[0],Final_results[1])
                self.fft_plot.show()
                self.ch_b_plot.hide()
                self.ch_c_plot.hide()
                self.differential_plot.hide()
            else:
                self.channels_plot2.show()
                
                timeaxis_striped_stitched = ch_plot_data[3]
                xMinLim,xMaxLim,yMinLim,yMaxLim = 0,np.max(timeaxis_striped_stitched)+5,0,2
                self.update_plot1_setRanges(xMinLim,xMaxLim,yMinLim,yMaxLim)
                self.update_plot1_setTitle("Even and Odd Signal After Even Odd Segregation","Time","ns","Voltage","v")
                self.update_plot2_setTitle("Even and Odd Signal After Arcsine And Differential","Time","ns","Voltage","v")
                
                self.ch_b_plot.setData(timeaxis_striped_stitched,ch_plot_data[0])
                self.ch_c_plot.setData(timeaxis_striped_stitched,ch_plot_data[1])
                # self.ch6_plot.setData(ch_plot_data[2])
                self.differential_plot.setData(timeaxis_striped_stitched,ch_plot_data[2])
                self.ch_b_plot.show()
                self.differential_plot.show()
                self.ch_c_plot.show()
                self.fft_plot.hide()
            
            self.ch_d_plot.hide()
        self.widget.show()



class ThreadClass(QtCore.QThread):

    any_channel = QtCore.pyqtSignal(np.ndarray)
    process_channel = QtCore.pyqtSignal(np.ndarray)
    def __init__(self, parent=None,index=0):
        super(ThreadClass, self).__init__(parent)
        self.index=index
        self.is_running = True
        
    def run(self):
        # print('Starting thread...',self.index)

        while (True):
            channel_data = np.zeros(100, dtype=np.int16)
            time.sleep(0.1)
            self.any_channel.emit(channel_data)
            
    def stop(self):
        self.is_running = False
        # print('Stopping thread...',self.index)
        self.terminate()		


pg.setConfigOptions(useOpenGL=True)
app = QtWidgets.QApplication(sys.argv)
mainWindow = Adq14_LIVE_PLOT_APP3()
mainWindow.show()
sys.exit(app.exec_())
