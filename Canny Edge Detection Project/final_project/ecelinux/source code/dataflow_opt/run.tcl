#=============================================================================
# run_base.tcl 
#=============================================================================
# @brief: A Tcl script for synthesizing the baseline digit recongnition design.

# Project name
set hls_prj canny.prj

# Open/reset the project
open_project ${hls_prj} -reset

# Top function of the design is "dut"
set_top dut

# Add design and testbench files
add_files canny.cpp -cflags "-std=c++11"
add_files -tb canny_test.cpp -cflags "-std=c++11"
add_files -tb data

open_solution "solution1"
# Use Zynq device
set_part {xc7z020clg484-1}





#=============================================================================

# unroll for fix optimization
# set_directive_unroll cordic/FIXED_STEP_LOOP
# pipeline for fix optimization
# set_directive_pipeline cordic/FIXED_STEP_LOOP


# canny.cpp
set_directive_pipeline -II 1 dut/Canny_Pip_1


# HlsImProc.hpp
set_directive_pipeline -II 1 GaussianBlur/HlsImProc_Pip_1
set_directive_pipeline -II 1 Sobel/HlsImProc_Pip_3
set_directive_pipeline -II 1 Sobel/HlsImProc_Pip_4
set_directive_pipeline -II 1 Sobel/HlsImProc_Pip_5





set_directive_stream -depth 1 GaussianBlur/Stream_1 src
set_directive_stream -depth 1 GaussianBlur/Stream_2 dst
set_directive_stream -depth 1 Sobel/Stream_3 src
set_directive_stream -depth 1 Sobel/Stream_4 dst
set_directive_stream -depth 1 NonMaxSuppression/Stream_5 src
set_directive_stream -depth 1 NonMaxSuppression/Stream_6 dst
set_directive_stream -depth 1 HystThreshold/Stream_7 src
set_directive_stream -depth 1 HystThreshold/Stream_8 dst
set_directive_stream -depth 1 HystThreshold/Stream_7 src
set_directive_stream -depth 1 HystThreshold/Stream_8 dst
set_directive_stream -depth 1 HystThresholdComp/Stream_9 src
set_directive_stream -depth 1 HystThresholdComp/Stream_10 dst
set_directive_stream -depth 1 ZeroPadding/Stream_11 src
set_directive_stream -depth 1 ZeroPadding/Stream_12 dst


set_directive_array_reshape   -type complete -dim 1 GaussianBlur/Reshape_1   line_buf
set_directive_array_partition -type complete -dim 0 GaussianBlur/Partition_1 window_buf
set_directive_array_partition -type complete -dim 0 GaussianBlur/Partition_1_2 GAUSS_KERNEL

set_directive_array_reshape   -type complete -dim 1 Sobel/Reshape_2   line_buf
set_directive_array_partition -type complete -dim 0 Sobel/Partition_2 window_buf
set_directive_array_partition -type complete -dim 0 Sobel/Partition_2_2 H_SOBEL_KERNEL
set_directive_array_partition -type complete -dim 0 Sobel/Partition_2_3 V_SOBEL_KERNEL

set_directive_array_reshape   -type complete -dim 1 Sobel/Reshape_3   line_buf
set_directive_array_partition -type complete -dim 0 NonMaxSuppression/Partition_3 window_buf

set_directive_array_reshape   -type complete -dim 1 HystThresholdComp/Reshape_4   line_buf
set_directive_array_partition -type complete -dim 0 HystThresholdComp/Partition_4 window_buf
#=============================================================================




# Target clock period is 10ns
create_clock -period 10

### You can insert your own directives here ###

############################################

# Simulate the C++ design
csim_design -O
# Synthesize the design
csynth_design
# Co-simulate the design
#cosim_design
exit