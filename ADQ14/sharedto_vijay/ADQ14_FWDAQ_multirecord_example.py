#!/usr/bin/env python3
#
# Copyright 2015-2019 Signal Processing Devices Sweden AB. All rights reserved.
#
# Description:    ADQ14/ADQ12 FWDAQ streaming example
# Documentation:
#
# Note: Also valid for ADQ12
#

import matplotlib
import numpy as np
import ctypes as ct
import matplotlib.pyplot as plt
import sys
import os
from matplotlib.widgets import Button
import time
import keyboard


def even_odd_segragation(signal):
        even_signal = signal[::2]
        odd_signal = signal[1::2]
        return [even_signal,odd_signal]

def peakdetect(y_axis, x_axis=None, lookahead=5, delta=0):
    """
    keyword arguments:
    y_axis -- A list containg the signal over which to find peaks
    x_axis -- A x-axis whose values correspond to the 'y_axis' list and is used
        in the return to specify the postion of the peaks. If omitted the index
        of the y_axis is used. (default: None)
    lookahead -- (optional) distance to look ahead from a peak candidate to
        determine if it is the actual peak (default: 500)
        '(sample / period) / f' where '4 >= f >= 1.25' might be a good value
    delta -- (optional) this specifies a minimum difference between a peak and
        the following points, before a peak may be considered a peak. Useful
        to hinder the algorithm from picking up false peaks towards to end of
        the signal. To work well delta should be set to 'delta >= RMSnoise * 5'.
        (default: 0)
            Delta function causes a 20% decrease in speed, when omitted
            Correctly used it can double the speed of the algorithm

    return -- two lists [maxtab, mintab] containing the positive and negative
        peaks respectively. Each cell of the lists contains a tupple of:
        (position, peak_value)
        to get the average peak value do 'np.mean(maxtab, 0)[1]' on the results
    """
    maxtab = []
    mintab = []
    mxpos,mnpos=0,0
    dump = []  # Used to pop the first hit which always if false

    length = len(y_axis)
    if x_axis is None:
        x_axis = range(length)

    # perform some checks
    if length != len(x_axis):
        raise ValueError("Input vectors y_axis and x_axis must have same length")
    if lookahead < 1:
        raise ValueError("Lookahead must be above '1' in value")
    if not (np.isscalar(delta) and delta >= 0):
        raise ValueError("delta must be a positive number")

    # needs to be a numpy array
    y_axis = np.asarray(y_axis)

    # maxima and minima candidates are temporarily stored in
    # mx and mn respectively
    mn, mx = np.Inf, -np.Inf

    # Only detect peak if there is 'lookahead' amount of points after it
    for index, (x, y) in enumerate(zip(x_axis[:-lookahead], y_axis[:-lookahead])):

        if y > mx:
            mx = y
            mxpos = x
        if y < mn:
            mn = y
            mnpos = x

        ####look for max####
        if y < mx - delta and mx != np.Inf:
            # Maxima peak candidate found
            # look ahead in signal to ensure that this is a peak and not jitter
            if y_axis[index:index + lookahead].max() < mx:
                maxtab.append((mxpos, mx))
                dump.append(True)
                # set algorithm to only find minima now
                mx = np.Inf
                mn = np.Inf

        ####look for min####
        if y > mn + delta and mn != -np.Inf:
            # Minima peak candidate found
            # look ahead in signal to ensure that this is a peak and not jitter
            if y_axis[index:index + lookahead].min() > mn:
                mintab.append((mnpos,mn))
                dump.append(False)
                # set algorithm to only find maxima now
                mn = -np.Inf
                mx = -np.Inf

    # Remove the false hit on the first value of the y_axis
    try:
        if dump[0]:
            maxtab.pop(0)
            # print "pop max"
        else:
            mintab.pop(0)
            # print "pop min"
        del dump
    except IndexError:
        # no peaks were found, should the function return empty lists?
        return [-1],[-1]

    return maxtab, mintab


sys.path.insert(1, os.path.dirname(os.path.realpath(__file__))+'/..')
from modules.example_helpers import *

# Record settings
number_of_records  = 1
samples_per_record = 100
sample_skip = 0;
pretrigger = 0;
triggerdelay = 10;
channel_mask = 0xF;

# Plot data if set to True
plot_data = True

# Print metadata in headers
print_headers = True

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
TRIG_THRESHOLD = 0.05  #if external trigger applied. Trigger threshold should be less then the external trigger
HIGH_IMPEDANCE = 1  
LOW_IMPEDANCE = 0
trig_type = EXT_TRIG_1

CHANNELS = ['A','B','C','D']

success = ADQAPI.ADQ_SetTriggerMode(adq_cu, adq_num, trig_type)   #setting the external trigger mode.
if (success == 0):
    print('ADQ_SetTriggerMode failed.')

if trig_type == LVL_TRIG:
  success = ADQAPI.ADQ_SetLvlTrigLevel(adq_cu, adq_num, 0)
  if (success == 0):
      print('ADQ_SetLvlTrigLevel failed.')
  success = ADQAPI.ADQ_SetLvlTrigEdge(adq_cu, adq_num, LVL_RISING)
  if (success == 0):
      print('ADQ_SetLvlTrigEdge failed.')

#If Providing an external trigger input
if trig_type == EXT_TRIG_1:
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

 
fig = plt.gcf()
fig.show()
fig.canvas.draw() 
CLOSE_GRAPH_STATE = False
# Continuous data stream in infinte loop. To close the loop press any keyboard key

while True:
  
  # Setup data processing (should be done before multirecord setup)
  if CLOSE_GRAPH_STATE:
    break
  ADQAPI.ADQ_SetSampleSkip(adq_cu, adq_num, sample_skip)
  ADQAPI.ADQ_SetPreTrigSamples(adq_cu, adq_num, pretrigger)
  ADQAPI.ADQ_SetTriggerDelay(adq_cu, adq_num, triggerdelay)

  # Setup multirecord
  ADQAPI.ADQ_MultiRecordSetChannelMask(adq_cu, adq_num, channel_mask)
  ADQAPI.ADQ_MultiRecordSetup(adq_cu, adq_num, number_of_records, samples_per_record)

  # Get number of channels from device
  number_of_channels = ADQAPI.ADQ_GetNofChannels(adq_cu, adq_num)

  # Arm acquisition
  print('Arming device')
  ADQAPI.ADQ_DisarmTrigger(adq_cu, adq_num)
  ADQAPI.ADQ_ArmTrigger(adq_cu, adq_num)

  # Allocate target buffers for intermediate data storage
  target_buffers = (ct.POINTER(ct.c_int16*(number_of_records*samples_per_record))*number_of_channels)()
  for bufp in target_buffers:
    bufp.contents = (ct.c_int16*(number_of_records*samples_per_record))()

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
  if (trig_type == 1):
    for trig in range(number_of_records):
      ADQAPI.ADQ_SWTrig(adq_cu, adq_num)

  print('Waiting for data...')
  # Collect data until all requested records have been recieved
  records_completed = 0
  records_available = 0;



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
        print('GetDataWH failed!')
        ADQAPI.DeleteADQControlUnit(adq_cu)
        sys.exit()

      for ch in range(0,number_of_channels):
        data_buf = np.frombuffer(target_buffers[ch].contents, dtype=np.int16, count=(samples_per_record*new_records))
        for rec in range(0,new_records):
          for s in range(0,samples_per_record):
            data_numpy[ch][(records_completed+rec)*samples_per_record + s] = data_buf[rec*samples_per_record + s]
          
      records_completed += new_records
      target_headers_vp.contents.value += new_records*ct.sizeof(HEADER)

      # print('Records read out:',records_completed)
 
  # Close multirecord
  ADQAPI.ADQ_MultiRecordClose(adq_cu, adq_num)

  channel_data = data_numpy

  data1 = list(channel_data[0][4:])
  data2 = list(channel_data[1][:])
  data3 = list(channel_data[2][:])
  data4 = list(channel_data[3][:])
  abs_min_data1 = abs(min(data1))
  abs_min_data2 = abs(min(data2))
  abs_min_data3 = abs(min(data3))
  abs_min_data4 = abs(min(data4))

  data1_inverted = abs_min_data1 - data1
  data1_inverted = data1_inverted - min(data1_inverted) - 1e-10
  data2_inverted = abs_min_data2 - data2
  data2_inverted = data2_inverted - min(data2_inverted) - 1e-10
  data3_inverted = abs_min_data3 - data3
  data3_inverted = data3_inverted - min(data3_inverted) - 1e-10
  data4_inverted = abs_min_data4 - data4
  data4_inverted = data4_inverted - min(data4_inverted) - 1e-10

  data1_inverted_splitted = np.split(data1_inverted, [i for i in range(10,len(data1_inverted),10)])
  data2_inverted_splitted = np.split(data2_inverted, [i for i in range(10,len(data2_inverted),10)])
  data3_inverted_splitted = np.split(data3_inverted,  [i for i in range(10,len(data3_inverted),10)])
  data4_inverted_splitted = np.split(data4_inverted,  [i for i in range(10,len(data4_inverted),10)])


  data1_inverted_splitted_even_odd = even_odd_segragation(data1_inverted_splitted)
  data2_inverted_splitted_even_odd = even_odd_segragation(data2_inverted_splitted)
  data3_inverted_splitted_even_odd = even_odd_segragation(data3_inverted_splitted)
  data4_inverted_splitted_even_odd = even_odd_segragation(data4_inverted_splitted)
  data_stitched_even,data_stitched_odd = [],[]
  data_stitched_even_striped, data_stitched_odd_striped,data_stitched_even_striped2 = [],[],[]
  FINAL_POSTPROCESSED_EVEN_DATA = np.empty(0,int)
  FINAL_POSTPROCESSED_ODD_DATA = np.empty(0,int)
  # for i in range(len(data1_inverted_splitted)):
  #     data_stitched.append(np.concatenate((data1_inverted_splitted[i],data2_inverted_splitted[i],data3_inverted_splitted[i],data4_inverted_splitted[i])).tolist())
  # print(len(data_stitched))
  skip_value = 2
  for i in range(len(data1_inverted_splitted_even_odd[0])):
      data_stitched_even.append(np.concatenate((data1_inverted_splitted_even_odd[0][i][:],data2_inverted_splitted_even_odd[0][i][:],data3_inverted_splitted_even_odd[0][i][:],data4_inverted_splitted_even_odd[0][i][:])).tolist())
      data_stitched_odd.append(np.concatenate((data1_inverted_splitted_even_odd[1][i][:],data2_inverted_splitted_even_odd[1][i][:],data3_inverted_splitted_even_odd[1][i][:],data4_inverted_splitted_even_odd[1][i][:])).tolist())
      
      skipped_data1_even_final = data1_inverted_splitted_even_odd[0][i]
      skipped_data2_even_final = data2_inverted_splitted_even_odd[0][i]
      skipped_data3_even_final = data3_inverted_splitted_even_odd[0][i]
      skipped_data4_even_final = data4_inverted_splitted_even_odd[0][i]


      skipped_data1_even_final = skipped_data1_even_final[:-8]
      skipped_data2_even_final = skipped_data2_even_final[:-7]
      skipped_data3_even_final = skipped_data3_even_final[7:-4]
      skipped_data4_even_final = skipped_data4_even_final[9:]   
      
        
        
      


      
      
      
      
      
      skipped_data1_odd_final = data1_inverted_splitted_even_odd[1][i][:-skip_value]
      skipped_data2_odd_final = data2_inverted_splitted_even_odd[1][i][skip_value:-(skip_value)]
      skipped_data3_odd_final = data3_inverted_splitted_even_odd[1][i][1:-skip_value]
      skipped_data4_odd_final = data4_inverted_splitted_even_odd[1][i][skip_value:]
      
      # FINAL_POSTPROCESSED_EVEN_DATA = np.append(FINAL_POSTPROCESSED_EVEN_DATA,skipped_data1_even_final, axis=0)
      # FINAL_POSTPROCESSED_EVEN_DATA = np.append(FINAL_POSTPROCESSED_EVEN_DATA,skipped_data2_even_final, axis=0)
      # FINAL_POSTPROCESSED_EVEN_DATA = np.append(FINAL_POSTPROCESSED_EVEN_DATA,skipped_data3_even_final, axis=0)
      # FINAL_POSTPROCESSED_EVEN_DATA = np.append(FINAL_POSTPROCESSED_EVEN_DATA,skipped_data4_even_final, axis=0)
      # print(skipped_data1_even_final)
      # print(skipped_data2_even_final)
      # print(skipped_data3_even_final)
      # print(skipped_data4_even_final)
      # print(FINAL_POSTPROCESSED_EVEN_DATA)

      # print(skipped_data1_even_final)
      # r = skipped_data1_even_final[-1:]-1e-10
      # print(r)
      data_stitched_even_striped.append(np.concatenate((skipped_data1_even_final,skipped_data2_even_final,skipped_data3_even_final,skipped_data4_even_final)).tolist())


      data_stitched_odd_striped.append(np.concatenate((skipped_data1_odd_final,
                                                      skipped_data2_odd_final,
                                                      skipped_data3_odd_final,
                                                      skipped_data4_odd_final)).tolist())



      # data_stitched_even_striped2.append(np.concatenate((skipped_data1_even_final,skipped_data2_even_final,skipped_data3_even_final,skipped_data4_even_final)))
      # value1_index = data_stitched_even_striped.index(skipped_data1_even_final[-1:])
      # value2_index = skipped_data2_even_final[1]
      # value3_index = skipped_data3_even_final[-1]
      # value4_index = skipped_data4_even_final[-1]
      # self.ch4_plot.setData(np.asarray([value1_index]))
      # print(data_stitched_even_striped)
      
      
      # Applying interpolation for even data



  # for i in range(len(data1_inverted_splitted_even_odd[1])):
  #     data_stitched_odd.append(np.concatenate((data1_inverted_splitted_even_odd[1][i][:],data2_inverted_splitted_even_odd[1][i][:],data3_inverted_splitted_even_odd[1][i][:],data4_inverted_splitted_even_odd[1][i][:])).tolist())
  #     data_stitched_odd_striped.append(np.concatenate((data1_inverted_splitted_even_odd[1][i][:-skip_value],
  #                                                     data2_inverted_splitted_even_odd[1][i][skip_value:-(skip_value)],
  #                                                     data3_inverted_splitted_even_odd[1][i][1:-skip_value],
  #                                                     data4_inverted_splitted_even_odd[1][i][skip_value:])).tolist())

  # print(len(data_stitched_even))
  # print(len(data_stitched_odd))
  Final_result = []
  for Ip,In in zip(data_stitched_even,data_stitched_odd):
      array1 = np.array(Ip)
      array2 = np.array(In)
      subtracted_array = np.subtract(array1, array2)
      added_array = np.add(array1,array2)
      
      # print(np.shape(subtracted_array))
      
      # print(np.shape(added_array))
      

      divided_array = np.divide(subtracted_array,added_array)
      Final_result.append(np.arcsin(divided_array))

  
  data_stitched_even = np.concatenate(data_stitched_even,axis=0)
  data_stitched_odd = np.concatenate(data_stitched_odd, axis=0)
  
  Final_result = np.concatenate(Final_result,axis=0)
  
  Final_result = [i+5 for i in Final_result if ~np.isnan(i)]
  # print(Final_result)
  
  
  applied_fft = np.fft.fft(Final_result)
  applied_fft = np.absolute(applied_fft)
  
  

  # print(type(applied_fft))
  # print(applied_fft)
  data_stitched_even_striped = np.concatenate(data_stitched_even_striped, axis=0)
  data_stitched_odd_striped = np.concatenate(data_stitched_odd_striped, axis=0)   
  ch_plot_data = np.asarray([data_stitched_even,data_stitched_odd,data_stitched_even_striped,data_stitched_odd_striped,Final_result,applied_fft]).tolist()
  # # Print recieved headers
  # if print_headers:
  #   for header in header_list:
  #     print('RecordStatus:  {}'.format(header.RecordStatus))
  #     print('UserID:        {}'.format(header.UserID))
  #     print('SerialNumber:  {}'.format(header.SerialNumber))
  #     print('Channel:       {}'.format(header.Channel))
  #     print('DataFormat:    {}'.format(header.DataFormat))
  #     print('RecordNumber:  {}'.format(header.RecordNumber))
  #     print('Timestamp:     {} ns'.format(header.Timestamp * 0.125))
  #     print('RecordStart:   {} ns'.format(header.RecordStart * 0.125))
  #     print('SamplePeriod:  {} ns'.format(header.SamplePeriod * 0.125))
  #     print('RecordLength:  {} ns'.format(header.RecordLength * (header.SamplePeriod * 0.125)))
  #     print('------------------')


  #plt.figure(1)
  #plt.clf()
  # Plot data
  #plt.plot(data_numpy[0], '.-')
  # Show plot
  #plt.show()

  # Plot data
  # if plot_data:
  #   fig.canvas.draw()
  #   fig.canvas.flush_events()
    

  #   if number_of_records > 0:
      
      # ch=0
      # widths = np.array([], dtype=np.uint32)
      # record_end_offset = 0
      # # Extract record lengths from headers
      # for rec in range(number_of_records):
      #   header = header_list[rec]
      #   widths = np.append(widths, header.RecordLength)
      # final_out = final[0]
      # d1_pos_peaks = final[1]
      # d2_pos_peaks = final[2]
      # fig, ax1 = plt.subplots(3, 1)

      # for ax in ax1.flat:
      #     ax.set(xlabel='Time', ylabel='Amp')
      #     ax.label_outer()

      # ax1[0].plot(data1_inverted, marker='o', markersize=2, linewidth=1)

      # ax1[0].plot(d1_pos_peaks[0], d1_pos_peaks[1], "o")

      # ax1[1].plot(data2_inverted, marker='o', markersize=2, linewidth=1)

      # ax1[1].plot(d2_pos_peaks[0], d2_pos_peaks[1], "o")

      # ax1[2].plot(final_out, marker='o', markersize=2, linewidth=1)
    
      # # plt.savefig(save_path+'Ch_'+CHANNELS[ch-1]+'_'+CHANNELS[ch]+'_'+str(samples_per_record)+'_'+str(number_of_records)+'_'+str(triggerdelay)+'.png',dpi=1080)
      # # Show plot
      # plt.show() 
      # # plt.savefig('Ch_'+CHANNELS[ch]+'_'+str(samples_per_record)+'_'+str(number_of_records)+'.png',dpi=1080)
  
      # # with open(save_path+'Ch_'+CHANNELS[ch-1]+'_'+CHANNELS[ch]+'_'+str(samples_per_record)+'_'+str(number_of_records)+'_'+str(triggerdelay)+'_'+str(sample_skip)+'.txt', 'a') as f:
      # #   for data in data_numpy[ch].T:
      # #     f.write(str(data))
      # #     f.write('\n')
      # #   print("data saved")
  # abs_min_data1 = abs(min(data_numpy[0]))
  # abs_min_data2 = abs(min(data_numpy[1]))
  # data1_inverted = abs_min_data1 -data_numpy[0]
  # data1_inverted = data1_inverted - min(data1_inverted) -1e-10
  # data2_inverted = abs_min_data2 -data_numpy[1]
  # data2_inverted = data2_inverted - min(data2_inverted) -1e-10

    
  # # print(data2_inverted)

  # final = stitching_two(data1_inverted, data2_inverted, final_list=[], delt=[2, 0])
  # final_out = final[0]
    # d1_pos_peaks = final[1]
    # d2_pos_peaks = final[2]
  plt.plot(data1_inverted,'o-',linewidth=1,markersize=3)
  plt.plot(data2_inverted,'o-',linewidth=1,markersize=3)
  # plt.xlim([0,samples_per_record*4])
  # plt.ylim([0,15000])
  plt.xlabel("Time (ns) --->")
  plt.ylabel("ADC Sample Values --->")
  plt.pause(0.001)
  fig.canvas.draw()

  plt.cla()

  if keyboard.is_pressed("q"):
    print("closing....")
    break
    

  # Delete ADQControlunit
plt.close()
ADQAPI.DeleteADQControlUnit(adq_cu)
print('Done.')
