#==========================================================================
# Makefile
#==========================================================================
# @brief: A makefile the compiles and runs the canny program
#
# @desc: 1. "make" or "make sw" runs software execution by default
#        2. "make fpga" invokes the HW accelerator
#        3. "make clean" cleans up the directory


INC_PATH=/usr/include/vivado_hls
CFLAGS =-I${INC_PATH} -DHLS_NO_XIL_FPO_LIB 

.PHONY: all sw fpga

all: sw

canny-arm: canny.cpp canny_test.cpp
	@echo "Compiling & executing canny software program on ARM ..."
	g++ ${CFLAGS} $^ -o $@

result/canny_arm_sim.txt: canny-arm
	mkdir -p result
	./$< | tee $@

sw: result/canny_arm_sim.txt
	@echo "Result saved to $@"

canny-fpga: host.cpp
	@echo "Compiling host program"
	g++ ${CFLAGS} $^ -o $@
	@echo "Make sure bitstream is loaded!"

fpga: canny-fpga
	@echo "Running canny accelerator ..."
	./$<

# Clean up the directory before submission
clean:
	@echo "Clean up output files"
	rm -rf canny-arm vivado_hls.log *.prj result out.dat *~
	rm -rf canny-fpga
