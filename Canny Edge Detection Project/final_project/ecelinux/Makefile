#==========================================================================
# Makefile
#==========================================================================
# @brief: A makefile the compiles and synthesizes the canny program
#
# @desc: 1. "make" runs csim by default
#        2. "make csim" compiles & executes the software implementation
#        3. "make clean" cleans up the directory


# Extract Vivado HLS include path
XILINX_VIVADO?=/opt/xilinx/Xilinx_Vivado_vitis_2019.2/Vivado/2019.2
XIL_HLS=source $(XILINX_VIVADO)/settings64.sh; vivado_hls
VHLS_INC=$(XILINX_VIVADO)/include
# Specify compilation flags
CFLAGS=-g -I${VHLS_INC} -DHLS_NO_XIL_FPO_LIB -std=c++11 

TCL_SCRIPT=run.tcl

.PHONY: all csim bitstream clean

all: csim

canny: canny.cpp canny_test.cpp
	g++ ${CFLAGS} $^ -o $@ -lrt

result/canny_csim.txt: canny
	@echo "Running canny sim..."
	mkdir -p result
	./$< | tee $@

csim: result/canny_csim.txt
	@echo "Result recorded to $<"

xillydemo.bit:
	@echo "=================================================================" 
	@echo "Synthesizing canny and creating bitstream with $(TCL_SCRIPT)..."
	@echo "=================================================================" 
	$(XIL_HLS) -f $(TCL_SCRIPT)
	source $(XILINX_VIVADO)/settings64.sh; ./run_bitstream.sh

bitstream: xillydemo.bit
	@echo "Bitstream saved to $<"

clean:
	rm -rf canny *.dat *.prj *.log
	rm -rf zedboard_project* xillydemo.bit
