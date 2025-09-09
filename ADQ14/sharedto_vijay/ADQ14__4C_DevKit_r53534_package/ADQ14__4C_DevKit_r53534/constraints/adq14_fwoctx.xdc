create_pblock pblock_0
add_cells_to_pblock [get_pblocks pblock_0] [get_cells -quiet [list {system_inst/System_i/SPD_FFT4_0/inst/fft4_top_inst/fft4_xfft_wrapper_inst[0]}]]
resize_pblock [get_pblocks pblock_0] -add {SLICE_X0Y275:SLICE_X23Y349}
resize_pblock [get_pblocks pblock_0] -add {DSP48_X0Y110:DSP48_X1Y139}
resize_pblock [get_pblocks pblock_0] -add {RAMB18_X0Y110:RAMB18_X1Y139}
resize_pblock [get_pblocks pblock_0] -add {RAMB36_X0Y55:RAMB36_X1Y69}
create_pblock pblock_1
add_cells_to_pblock [get_pblocks pblock_1] [get_cells -quiet [list {system_inst/System_i/SPD_FFT4_0/inst/fft4_top_inst/fft4_xfft_wrapper_inst[1]}]]
resize_pblock [get_pblocks pblock_1] -add {SLICE_X0Y200:SLICE_X23Y274}
resize_pblock [get_pblocks pblock_1] -add {DSP48_X0Y80:DSP48_X1Y109}
resize_pblock [get_pblocks pblock_1] -add {RAMB18_X0Y80:RAMB18_X1Y109}
resize_pblock [get_pblocks pblock_1] -add {RAMB36_X0Y40:RAMB36_X1Y54}
create_pblock pblock_2
add_cells_to_pblock [get_pblocks pblock_2] [get_cells -quiet [list {system_inst/System_i/SPD_FFT4_0/inst/fft4_top_inst/fft4_xfft_wrapper_inst[2]}]]
resize_pblock [get_pblocks pblock_2] -add {SLICE_X0Y125:SLICE_X23Y199}
resize_pblock [get_pblocks pblock_2] -add {DSP48_X0Y50:DSP48_X1Y79}
resize_pblock [get_pblocks pblock_2] -add {RAMB18_X0Y50:RAMB18_X1Y79}
resize_pblock [get_pblocks pblock_2] -add {RAMB36_X0Y25:RAMB36_X1Y39}
create_pblock pblock_3
add_cells_to_pblock [get_pblocks pblock_3] [get_cells -quiet [list {system_inst/System_i/SPD_FFT4_0/inst/fft4_top_inst/fft4_xfft_wrapper_inst[3]}]]
resize_pblock [get_pblocks pblock_3] -add {SLICE_X0Y50:SLICE_X23Y124}
resize_pblock [get_pblocks pblock_3] -add {DSP48_X0Y20:DSP48_X1Y49}
resize_pblock [get_pblocks pblock_3] -add {RAMB18_X0Y20:RAMB18_X1Y49}
resize_pblock [get_pblocks pblock_3] -add {RAMB36_X0Y10:RAMB36_X1Y24}
