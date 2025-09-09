// File: ADQ_simple_example.cpp
// Description: A simple example of how to use the ADQAPI together with a custom acquisition logic in user_logic2.
// This example was written for ADQ14-4C but it can be easily modified to work for all ADQ14 variants from SP Devices.
// The example sets some basic settings and collects data. This requires that the FPGA must have the correct example firmware.

#define _CRT_SECURE_NO_WARNINGS // This define removes warnings for printf

#include "ADQAPI.h"
#include "os.h"
#include <stdio.h>
#include <time.h>

#ifdef LINUX
    #include <stdlib.h>
    #include <string.h>
    #include <unistd.h>
    #define Sleep(interval) usleep(1000*interval)
#endif

void adq14_simple_streaming_acquisition(void *adq_cu, int adq_num);
#define CHECKADQ(f) if(!(f)){printf("Error in " #f "\n"); goto error;}

#define MIN(a,b) ((a) > (b) ? (b) : (a))
#define MAX(a,b) ((a) > (b) ? (a) : (b))

void adq14(void *adq_cu, int adq_num)
{
  int mode;
  int* revision = ADQ_GetRevision(adq_cu, adq_num);
  printf("\nConnected to ADQ14 #1\n\n");

  //Print revision information

  printf("FPGA Revision: %d, ", revision[0]);
  if (revision[1])
    printf("Local copy");
  else
  printf("SVN Managed");
  printf(", ");
  if (revision[2])
    printf("Mixed Revision");
  else
    printf("SVN Updated");
  printf("\n\n");

  ADQ_SetDirectionGPIO(adq_cu, adq_num,31,0);
  ADQ_WriteGPIO(adq_cu, adq_num, 31,0);
  while(1) {
  printf("\nChoose collect mode. (0 = exit)\n 1 = Simple Devkit Streaming Example\n\n");
  scanf("%d", &mode);

  switch (mode)
  {
  case 1:
    adq14_simple_streaming_acquisition(adq_cu, adq_num);
    break;
  default:
    return;
    break;
  }
  }
}

void adq14_simple_streaming_acquisition(void *adq_cu, int adq_num)
{
  unsigned int trigger_mode;
  unsigned int trigger_edge;
  unsigned int trigger_level;   //For level trigger
  unsigned int sampleskip;
  unsigned int buffers_filled;
  unsigned int samples_per_waveform;
  unsigned int waveforms_to_collect;
  unsigned int nofchannels;
  unsigned int nof_buffers;

  int collect_result;
  signed short* data_stream_target = NULL;
  signed short* data_channel_target[4] ={NULL, NULL, NULL, NULL};
  unsigned int LoopVar;
  unsigned int ch;
  unsigned int overflow = 0;
  unsigned int waveform_counter = 0;
  char fname[256];
  FILE* outfile = NULL, *outfileBin = NULL;

  //ADQ14-2X: 8 parallel samples per clock cycle
  //ADQ14-1X: 8 parallel samples per clock cycle

  //ADQ14-4C: 4 parallel samples per clock cycle
  //ADQ14-2C: 4 parallel samples per clock cycle

  //ADQ14-4A: 2 parallel samples per clock cycle
  //ADQ14-2A: 2 parallel samples per clock cycle

  //CHANGE THIS PARAMETER TO MATCH YOUR PRODUCT! See the lines above!
  unsigned int parallel_samples_per_cycle = 2;

  int exit=0;
  unsigned int test_pattern; //0 or 2
  unsigned int en_A;
  unsigned int en_B;
  unsigned int en_C;
  unsigned int en_D;

  /* ===========================================Acquisition parameters ==============================*/
  trigger_mode = 1;
  trigger_edge = 0;                   // 0 = falling edge, 1 = rising edge;
  trigger_level = 0;                  //For level trigger
  sampleskip = 1;                     // 1 = No sample skip. DO NOT USE ZERO!!!

  //NOTE! The data is grouped in 1024 bytes from each channel in the buffer.
  //So if the waveform size is not modulo of 1024 bytes, the buffer cannot be filled and will wait forever.
  //Make sure your waveform size is in modulo of 1024 bytes. I.E 512 samples if each sample is 16 bits (2 bytes).
  samples_per_waveform = 512*100;

  waveforms_to_collect = 1;
  nof_buffers = 8;
  test_pattern = 0; //0 or 2

  //Enable all channels
  en_A = 1;
  en_B = 1;
  en_C = 1;
  en_D = 1;
  /* ================================================================================================*/

  // Reset all control registers in ul2 and stop streaming. This is normally not needed but incase the 
  // user has interrupted the data transfer by aborting the previous run, this code block will be needed
  // to get this example working again. Otherwise the data path might be blocked in ul2.
  CHECKADQ(ADQ_WriteUserRegister(adq_cu, adq_num, 2, 0x10, 0, 0, NULL));
  CHECKADQ(ADQ_WriteUserRegister(adq_cu, adq_num, 2, 0x11, 0, 0 , NULL));
  CHECKADQ(ADQ_WriteUserRegister(adq_cu, adq_num, 2, 0x12, 0, 0, NULL));
  CHECKADQ(ADQ_StopStreaming(adq_cu, adq_num));
  CHECKADQ(ADQ_SetStreamStatus(adq_cu, adq_num, 0));

  CHECKADQ(ADQ_SetTriggerMode(adq_cu, adq_num, trigger_mode));
  CHECKADQ(ADQ_SetTriggerEdge(adq_cu, adq_num, trigger_mode, trigger_edge));
  CHECKADQ(ADQ_SetLvlTrigLevel(adq_cu, adq_num, trigger_level));
  CHECKADQ(ADQ_SetSampleSkip(adq_cu, adq_num, sampleskip));                           //This is needed to reduce the data rate to avoid overflow

  // User logic 2 acquisition control registers
  ADQ_WriteUserRegister(adq_cu, adq_num, 2, 0x11, 0, samples_per_waveform/parallel_samples_per_cycle , NULL);   //Program number of sample clock cycles
  ADQ_WriteUserRegister(adq_cu, adq_num, 2, 0x12, 0, waveforms_to_collect, NULL);                               //Program number of repetitions (number of waveforms)
  ADQ_WriteUserRegister(adq_cu, adq_num, 2, 0x10, ~(1), 1, NULL);                                               //Optional, reset the counters, can be used in a loop to restart the counter
  
  nofchannels = ADQ_GetNofChannels(adq_cu, adq_num);
  // Allocate temporary buffer for streaming data for all data channels
  CHECKADQ(data_stream_target = (signed short*)malloc(samples_per_waveform*nofchannels*sizeof(signed short)));

  // Allocate channels buffer to separate data
  for(ch = 0; ch < nofchannels; ch++)
    data_channel_target[ch] = (signed short*)malloc(samples_per_waveform*sizeof(signed short*));

  //Setup ADQAPI transferbuffers
  CHECKADQ(ADQ_SetTransferBuffers(adq_cu, adq_num, nof_buffers, samples_per_waveform*nofchannels*sizeof(signed short)));

  printf("\nSetting up streaming...\n");
  // Enable streaming
  CHECKADQ(ADQ_SetTestPatternMode(adq_cu,adq_num, test_pattern));
  CHECKADQ(ADQ_SetStreamStatus(adq_cu, adq_num, 1));
  CHECKADQ(ADQ_SetStreamConfig(adq_cu, adq_num, 1, 0)); //USe DRAM as giant FIFO
  CHECKADQ(ADQ_SetStreamConfig(adq_cu, adq_num, 2, 1)); //RAW mode
  CHECKADQ(ADQ_SetStreamConfig(adq_cu, adq_num, 3,  1*en_A + 2*en_B + 4*en_C+8*en_D)); //mask

  printf("Collecting data, please wait...\n");

  CHECKADQ(ADQ_StopStreaming(adq_cu, adq_num));
  CHECKADQ(ADQ_StartStreaming(adq_cu, adq_num));

  while (waveform_counter < waveforms_to_collect)
  {

    if (trigger_mode == 1)
    {
      ADQ_SWTrig(adq_cu, adq_num);
    }

    do
    {
      collect_result = ADQ_GetTransferBufferStatus(adq_cu, adq_num, &buffers_filled);
      printf("Filled: %2u\n", buffers_filled);

    } while ((buffers_filled == 0) && (collect_result));

    collect_result = ADQ_CollectDataNextPage(adq_cu, adq_num);
    //samples_in_buffer = MIN(ADQ_GetSamplesPerPage(adq_cu, adq_num), samples_to_collect);


    if (overflow = ADQ_GetStreamOverflow(adq_cu, adq_num))
    {
      printf("Warning: Streaming Overflow 1!\n");
      collect_result = 0;
    }

    if (collect_result)
    {
      memcpy((void*)data_stream_target, ADQ_GetPtrStream(adq_cu, adq_num), samples_per_waveform*nofchannels*sizeof(signed short));

      //Separate data into channels
      //The data is grouped in 1024 bytes from each channel in the buffer.
      //[1024 bytes from A, 1024 bytes from B, 1024 bytes from C, 1024 bytes from D, 1024 bytes from A,...repeat]
      //Note: 512 samples * 2 bytes = 1024 bytes
      for(LoopVar = 0; LoopVar < samples_per_waveform*nofchannels; LoopVar = LoopVar + 2048)
      {
        memcpy((void*)&(data_channel_target[0])[LoopVar/4], &data_stream_target[LoopVar], 512*sizeof(signed short));
        memcpy((void*)&(data_channel_target[1])[LoopVar/4], &data_stream_target[LoopVar + 512*1], 512*sizeof(signed short));
        memcpy((void*)&(data_channel_target[2])[LoopVar/4], &data_stream_target[LoopVar + 512*2], 512*sizeof(signed short));
        memcpy((void*)&(data_channel_target[3])[LoopVar/4], &data_stream_target[LoopVar + 512*3], 512*sizeof(signed short));
      }

      for(ch = 0; ch < nofchannels; ch++)
      {
        sprintf(fname, "waveform_%05d_ch%d.out", waveform_counter, ch);

        // Use binary file format if you want to save data in real-time. Because ASCII output is too slow for realtime.
        // If you want to save data as ascii you should save it outside of this acquisition loop, after streaming to RAM is done
        //sprintf(fname, "data.bin");
        outfileBin = fopen(fname, "wb");
        if(outfileBin != NULL)
        {
           fwrite((void*)data_channel_target[ch], sizeof(signed short), samples_per_waveform, outfileBin);
           //fwrite((void*)data_stream_target, sizeof(signed short), samples_per_waveform*nofchannels, outfileBin);     Analyze this buffer to see how data for each channel is ordered
           printf("  - wrote waveform %lld for channel %d to file %s\n", waveform_counter, ch, fname);
           fclose(outfileBin);
           outfileBin = NULL;
        }
      }

      waveform_counter++;
    }
    else
    {
      printf("Collect next data page failed!\n");
    }
  }

  CHECKADQ(ADQ_StopStreaming(adq_cu, adq_num));
  CHECKADQ(ADQ_SetStreamStatus(adq_cu, adq_num, 0));

  printf("\n\nDone. Samples stored.\n");

error:

  nofchannels = ADQ_GetNofChannels(adq_cu, adq_num);

  if (data_stream_target != NULL)
    free(data_stream_target);

  for(ch = 0; ch < nofchannels; ch++)
  {
    if (data_channel_target[ch] != NULL)
      free(data_channel_target[ch]);
  }

  if(NULL != outfile)
    fclose(outfile);
  if(NULL != outfileBin)
    fclose(outfileBin);

  //Important to restore all user registers to original state before exit.
  ADQ_WriteUserRegister(adq_cu, adq_num, 2, 0x10, 0, 0, NULL);
  ADQ_WriteUserRegister(adq_cu, adq_num, 2, 0x11, 0, 0 , NULL);
  ADQ_WriteUserRegister(adq_cu, adq_num, 2, 0x12, 0, 0, NULL);

  if(  (overflow > 0) || (collect_result == 0) )
  {
    printf("\nERROR: Something went wrong!!!\n\n");
    printf("\noverflow = %d\ncollect_result = %d\nwaveform_counter = %d\n\n", overflow, collect_result, waveform_counter);
    printf("Press any key followed by ENTER to exit\n");
    scanf("%d", &exit);  
  }

  return;
}