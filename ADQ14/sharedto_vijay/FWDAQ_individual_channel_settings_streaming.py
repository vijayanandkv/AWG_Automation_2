#!/usr/bin/env python3
#
# Copyright 2020 Signal Processing Devices Sweden AB. All rights reserved.
#
# Description:    FWDAQ - Streaming with individual channel settings
# Documentation:
#
# This example shows how to set up a streaming data acquisition with channel-specific
# settings, such as record length, sample skip factor, pretrigger and trigger delay.

import numpy as np
import ctypes as ct
import matplotlib.pyplot as plt
import sys
import time
import os

sys.path.insert(1, os.path.dirname(os.path.realpath(__file__))+'/..')
from modules.example_helpers import *

# Trrig mode definitions
SW_TRIG = 1
EXT_TRIG_1 = 2
EXT_TRIG_2 = 7
EXT_TRIG_3 = 8
LVL_TRIG = 3
INT_TRIG = 4
LVL_FALLING = 0
LVL_RISING = 1

# Channel settings, change as desired:
# Horizontal parameters
#                      Ch 1     Ch 2      Ch 3      Ch4
number_of_records   = [1,       2,        3,        4]
recordlength        = [5*65536, 4096,     2048,     4096]
pretrigger          = [0,       0,     0,        0]
triggerdelay        = [0,       0,        1024,     2048]
sampleskip          = [1,       1,       16,       16]
# Note: Pretrigger, record length and trigger delay are all set in units of samples.
#       When measured in units of time, they will be affected by the sample skip factor.
#       A pretrigger of 512 samples with sample skip 1 is the same amount of time
#       as a pretrigger of 256 with a sample skip of 2

# Event source parameters (per channel)
#                      Ch 1     Ch 2      Ch 3      Ch4
triggermode         = [4,       3,        4,        4]
lvltrigmask         = [1,      3,       15,       15]
lvltriglevel        = [10000,   0,        0,        0]
lvltrigresetlevel   = [10,     10,       10,       10]
lvltrigedge         = [1,       1,        1,        1] 

# Zeroing bits in the channel mask will disable data transfers for the corresponding channels
# Must be set to reflect number of available channels
channelmask = 0x3

# This example uses a triangle-wave test pattern by default to make it easier to interpret
# the timing relationship between channels and records. Change to 0 to acquire actual analog data
testpatternmode = 4
internal_trigger_period = 2*65536 # Triggers once per test pattern cycle

# Print metadata in headers
print_headers = False

# DMA transfer buffer settings
transfer_buffer_size = 65536
num_transfer_buffers = 8

# DMA flush timeout in seconds
flush_timeout        = 0.5

# Load ADQAPI
ADQAPI = adqapi_load()

# Create ADQControlUnit
adq_cu = ct.c_void_p(ADQAPI.CreateADQControlUnit())

# Enable error logging from ADQAPI
ADQAPI.ADQControlUnit_EnableErrorTrace(adq_cu, 65536, '.')

# Find ADQ devices
ADQAPI.ADQControlUnit_FindDevices(adq_cu)
n_of_ADQ  = ADQAPI.ADQControlUnit_NofADQ(adq_cu)
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

# Set device-dependent script parameters
productname = ADQAPI.ADQ_GetBoardProductName(adq_cu, adq_num).decode('ascii')
if productname == 'ADQ7DC' or productname == 'ADQ7AC':
  timeunit = 0.025 # Timestamp on ADQ7 counts in 25 ps steps
elif productname == 'ADQ14AC' or productname == 'ADQ14DC':
  timeunit = 0.125 # Timestamp on ADQ14 counts in 125 ps steps
else:
  print('ERROR: This example script does not support this product (%s)' % productname)
  ADQAPI.DeleteADQControlUnit(adq_cu)
  sys.exit(1)

# Get number of channels
number_of_channels = ADQAPI.ADQ_GetNofChannels(adq_cu, adq_num)

# Setup test pattern
#     0 enables the analog input from the ADCs
#   > 0 enables a specific test pattern
# Note: Default is to enable a test pattern (4) and disconnect the
#       analog inputs inside the FPGA.
ADQAPI.ADQ_SetTestPatternMode(adq_cu, adq_num, testpatternmode)

trig_type = INT_TRIG
success = ADQAPI.ADQ_SetTriggerMode(adq_cu, adq_num, trig_type)
if (success == 0):
    print('ADQ_SetTriggerMode failed.')

ADQAPI.ADQ_SetInternalTriggerPeriod(adq_cu, adq_num, internal_trigger_period)

# Copy level trigger settings and setup if required through API (individual mode)
# SetupLevelTrigger(int* levels, int* edges, int* resetlevels, unsigned int channelsmask, unsigned int individual_mode)
lvltrig_levels = (4*ct.c_int)(0)
lvltrig_edges = (4*ct.c_int)(0)
lvltrig_resetlevels = (4*ct.c_int)(0)
ts = ct.c_uint64(0)

for ch in range(number_of_channels):
    lvltrig_levels[ch] = lvltriglevel[ch]
    lvltrig_edges[ch] = lvltrigedge[ch]
    lvltrig_resetlevels[ch] = lvltrigresetlevel[ch]

ADQAPI.ADQ_SetupLevelTrigger(adq_cu, adq_num, ct.byref(lvltrig_levels), ct.byref(lvltrig_edges), ct.byref(lvltrig_resetlevels), 0xF, 1)
    
# Upload channel settings (must be done prior to InitializeStreaming)
for ch in range(number_of_channels):
  ADQAPI.ADQ_SetChannelNumberOfRecords(adq_cu, adq_num, ch+1, number_of_records[ch], 0)
  ADQAPI.ADQ_SetChannelRecordLength(adq_cu, adq_num, ch+1, recordlength[ch], 0)
  ADQAPI.ADQ_SetChannelPretrigger(adq_cu, adq_num, ch+1, pretrigger[ch])
  ADQAPI.ADQ_SetChannelTriggerDelay(adq_cu, adq_num, ch+1, triggerdelay[ch])
  ADQAPI.ADQ_SetChannelSampleSkip(adq_cu, adq_num, ch+1, sampleskip[ch])
  ADQAPI.ADQ_SetChannelTriggerMode(adq_cu, adq_num, ch+1, triggermode[ch])  # Note: this overrides the ADQ_SetTriggerMode given above
  if triggermode[ch] == LVL_TRIG:
      ADQAPI.ADQ_SetChannelLevelTriggerMask(adq_cu, adq_num, ch+1, lvltrigmask[ch])
  
# Set channel mask (must be done prior to InitializeStreaming)
ADQAPI.ADQ_SetStreamingChannelMask(adq_cu, adq_num, channelmask)

# Initialize streaming
ADQAPI.ADQ_InitializeStreaming(adq_cu, adq_num)

# Setup size of transfer buffers
print('Setting up streaming...')
ADQAPI.ADQ_SetTransferBuffers(adq_cu, adq_num, num_transfer_buffers, transfer_buffer_size)

ADQAPI.ADQ_GetTimestampValue(adq_cu, adq_num, ct.byref(ts))
tstart = ts.value
tstart_t = time.time()

# Start streaming
print('Collecting data, please wait...')
ADQAPI.ADQ_StopStreaming(adq_cu, adq_num)
ADQAPI.ADQ_StartStreaming(adq_cu, adq_num)

# Allocate target buffers for intermediate data storage
target_buffers = (ct.POINTER(ct.c_int16*transfer_buffer_size)*number_of_channels)()
for bufp in target_buffers:
  bufp.contents = (ct.c_int16*transfer_buffer_size)()

# Create some buffers for the full records
data_16bit = [np.array([], dtype=np.int16),
              np.array([], dtype=np.int16),
              np.array([], dtype=np.int16),
              np.array([], dtype=np.int16)]

# Allocate target buffers for headers
headerbuf_list = [(HEADER*max(number_of_records))() for ch in range(number_of_channels)]
# Create an C array of pointers to header buffers
headerbufp_list = ((ct.POINTER(HEADER*max(number_of_records)))*number_of_channels)()
# Initiate pointers with allocated header buffers
for ch,headerbufp in enumerate(headerbufp_list):
    headerbufp.contents = headerbuf_list[ch]
# Create a second level pointer to each buffer pointer,
# these will only be used to change the bufferp_list pointer values
headerbufvp_list = [ct.cast(ct.pointer(headerbufp_list[ch]), ct.POINTER(ct.c_void_p)) for ch in range(number_of_channels)]

# Allocate length output variable
samples_added = (4*ct.c_uint)()
for ind in range(len(samples_added)):
  samples_added[ind] = 0

headers_added = (4*ct.c_uint)()
for ind in range(len(headers_added)):
  headers_added[ind] = 0

header_status = (4*ct.c_uint)()
for ind in range(len(header_status)):
  header_status[ind] = 0

# Generate triggers if software trig is used
if (trig_type == 1):
  for trig in range(max(number_of_records)):
    ADQAPI.ADQ_SWTrig(adq_cu, adq_num)

print('Waiting for data...')
# Collect data until all requested records have been recieved
records_completed = [0, 0, 0, 0]
headers_completed = [0, 0, 0, 0]
ltime = time.time()
buffers_filled = ct.c_uint(0)

# Read out data until records_completed for ch A is number_of_records
all_records_completed = False
while not all_records_completed:
  buffers_filled.value = 0
  collect_result = 1
  poll_time_diff_prev = time.time()
  # Wait for next data buffer
  while ((buffers_filled.value == 0) and (collect_result)):
    collect_result = ADQAPI.ADQ_GetTransferBufferStatus(adq_cu, adq_num,
                                                        ct.byref(buffers_filled))
    poll_time_diff = time.time()

    if ((poll_time_diff - poll_time_diff_prev) > flush_timeout):
      # Force flush
      print('No data for {}s, flushing the DMA buffer.'.format(flush_timeout))
      status = ADQAPI.ADQ_FlushDMA(adq_cu, adq_num);
      print('ADQAPI.ADQ_FlushDMA returned {}'.format(adq_status(status)))
      poll_time_diff_prev = time.time()


  # Fetch data and headers into target buffers
  status = ADQAPI.ADQ_GetDataStreaming(adq_cu, adq_num,
                                       target_buffers,
                                       headerbufp_list,
                                       channelmask,
                                       ct.byref(samples_added),
                                       ct.byref(headers_added),
                                       ct.byref(header_status))
  if status == 0:
    print('GetDataStreaming failed!')
    sys.exit()

  all_records_completed = True
  for ch in range(number_of_channels):
    if (headers_added[ch] > 0):
      # The last call to GetDataStreaming has generated header data
      if  (header_status[ch]):
        headers_done = headers_added[ch]
      else:
        # One incomplete header
        headers_done = headers_added[ch]-1
      # Update counter counting completed records
      headers_completed[ch] += headers_done

      # Update the number of completed records if at least one header has completed
      if (headers_done > 0):
        records_completed[ch] = headerbuf_list[ch][headers_completed[ch]-1].RecordNumber + 1

      # Update header pointer so that it points to the current header
      headerbufvp_list[ch].contents.value += headers_done*ct.sizeof(headerbuf_list[ch]._type_)

    if (samples_added[ch] > 0):
      # Copy channel data to continuous buffer
      data_buf          = np.frombuffer(target_buffers[ch].contents, dtype=np.int16, count=samples_added[ch])
      data_16bit[ch]    = np.append(data_16bit[ch], data_buf)

    if records_completed[ch] < number_of_records[ch]:
      if channelmask & (1 << ch):
        all_records_completed = False

# Stop streaming
print('All records collected, stopping streaming.')
ADQAPI.ADQ_StopStreaming(adq_cu, adq_num)

ADQAPI.ADQ_GetTimestampValue(adq_cu, adq_num, ct.byref(ts))
tstop = ts.value
telapsed = tstop-tstart
telapsed_t = time.time()-tstart_t;
print('Elapsed time {} ticks which corresponds to {:5.2} seconds (py gives {:5.2} seconds).'.format(telapsed, telapsed*125e-12, telapsed_t))

# Plot data
fig, ax = plt.subplots(number_of_channels,1, sharex = True, sharey=True, figsize=(20,8))
if number_of_channels == 1:
  ax = [ax]

for ch in range(number_of_channels):
  ax[ch].set_ylabel('Ch %d' % (ch+1))

ax[-1].set_xlabel('Time [ns]')

for ch in range(number_of_channels):
  if print_headers:
    print('------------------')
    print('Headers channel {}'.format(ch))
    print('------------------')

  for rec in range(records_completed[ch]):
    header = headerbuf_list[ch][rec]

    # Calculate time stamp, relative to the first record of channel 1 in order to avoid very large numbers
    timestamp_ns = header.Timestamp * timeunit - headerbuf_list[0][0].Timestamp * timeunit
    sample_period_ns = header.SamplePeriod * timeunit
    record_start_ns = timestamp_ns + header.RecordStart * timeunit

    if print_headers:
      print('Channel:       {}'.format(header.Channel))
      print('RecordNumber:  {}'.format(header.RecordNumber))
      print('Timestamp:     {} ns'.format(header.Timestamp * timeunit))
      print('Timestamp(r):  {} ns'.format(timestamp_ns))
      print('RecordStart:   {} ns'.format(header.RecordStart * timeunit))
      print('SamplePeriod:  {} ns'.format(header.SamplePeriod * timeunit))
      print('RecordLength:  {} ns'.format(header.RecordLength * (header.SamplePeriod* timeunit)))
      print('------------------')

    record_data = data_16bit[ch][rec*recordlength[ch]:(rec+1)*recordlength[ch]]

    # Plot the record data at the correct start time
    ax[ch].plot(record_start_ns + np.arange(recordlength[ch])*sample_period_ns, record_data,'.-')

    # Plot a dashed line where the trigger occurred for each record
    ax[ch].axvline(timestamp_ns, linestyle='--')

plt.show()

# Delete ADQ device handle
ADQAPI.ADQControlUnit_DeleteADQ(adq_cu, adq_num)
# Delete ADQControlunit
ADQAPI.DeleteADQControlUnit(adq_cu)
