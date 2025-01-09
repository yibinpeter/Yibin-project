######################################################################
#   ECE-4750 Makefile
#   Copyright (c) 2023 Socrates Wong / Cornell University 
#   Redistribution prohibited without explicited permisison 
#   from copyright holder. 
#   Download and use of these materials are permitted by Cornell 
#   students enrolled in ECE-4750 for individual educational 
#   noncommercial purposes only. Redistribution either in part or in 
#   whole via both commercial (e.g., Course Hero) or non-commercial 
#   (e.g., public website) requires written permission from the 
#   copyright holder.
#   Usage:
#       make / run-all: To automatically execute all the top_level 
#           testbench, and all unit testbenches.  Tabulates and 
#           outputs results and report
#
#       run-design: To automatically execute all top level testbench  
#            of a design group.  DESIGN_CONFIG is expected to be set
#            and it tells the Makefile which testbench are associated
#            with which modules.
#
#       tb_%.v.sim utb_%.v.sim ub_%.v.sim: To execute a testbench.
#            Use with enviroment variables DESIGN for testbench that
#            can support mutiple modules.
#
#       %.hex.sim: To execute an assembly program with the processor
#            design set by enviroment variables DESIGN.
#
#       %.hex.diff: To execute an assembly program with the processor
#            design set by enviroment variables DESIGN and compare
#            with the FL design.
#
#       coverage-report: To aggerate all the covreage reports and 
#           generate and html report of the coverage.
#
#       show-results: To aggerate all the pass/fail results of all
#           the testbenches and display it in a formatted manner
#
#       check-setup: Check if there is something wrong with setup
#
#       setup: Setup the directory layout
#
#       help: Display this message
#
#       clean: Remove all temporary files
#
#       build-tar: Build the tar.gz file for lab submission
#
#   Enviroment Variables:
#       RUN_ARG: Arguments to pass to simulator at execution useful 
#           for "--trace" to enable line tracing.
#
#       DESIGN_CONFIG: Used to tell the Makefile which designs are
#           are associated with which testbench when expending
#           macros. Is automatically set in run-all 
#
#       DESIGN: Used to set the design in case a testbench supports
#           more then one design.  Not used for unit testbench. Is
#           automatically set in run-all and can be manually set with
#           tb_%.v.sim , %.hex.sim and %.hex.diff
#
#       COVERAGE: Used to set what kind of corverage report (full/line
#           toggle)
#
#       OUTDIR: Used to set verilator output directory used in make 
#           tb_%.v.sim and is automatically set for run-all or run-design
#
#       NOPT: Used to disable the optimizer
#
#       MEM:  Use to set the memory image for system level tb
#
#       MEMDUMP:  Use to set the memory dump for system level tb
#
#       VCD:  Set this to swith to VCD trace
######################################################################
######################################################################
# !!!!You should not need to modify this file!!!!  If you believe
# otherwise, please ask in Ed before you do so.
######################################################################

ifneq ($(words $(CURDIR)),1)
 $(error Unsupported: GNU Make cannot build in directories containing spaces, build elsewhere: '$(CURDIR)')
endif

CXX = g++-10
CC = gcc-10
GENHTML = genhtml

ifeq ($(VERILATOR_ROOT),)
	VERILATOR = verilator
	VERILATOR_COVERAGE = verilator_coverage
else
export VERILATOR_ROOT
	VERILATOR = $(VERILATOR_ROOT)/bin/verilator
	VERILATOR_COVERAGE = $(VERILATOR_ROOT)/bin/verilator_coverage
endif
VERSION= 2.3 

VERILATOR_FLAGS =
VERILATOR_FLAGS += -cc --exe
ifndef NOPT
VERILATOR_FLAGS += -O3 
else
VERILATOR_FLAGS += -O0
endif


VERILATOR_FLAGS += -x-assign 0
VERILATOR_FLAGS += -Wall
VERILATOR_FLAGS += --assert
VERILATOR_FLAGS += --timing
VERILATOR_FLAGS +=  -y ..
VERILATOR_FLAGS +=  -y test
VERILATOR_FLAGS +=  -y ../lab1_imul
VERILATOR_FLAGS +=  -y ../lab2_proc
VERILATOR_FLAGS +=  -Wno-DECLFILENAME
VERILATOR_FLAGS +=  -Wno-UNUSEDSIGNAL
VERILATOR_FLAGS +=  -Wno-VARHIDDEN
VERILATOR_FLAGS +=  -Wno-UNDRIVEN
VERILATOR_FLAGS +=  -Wno-GENUNNAMED
VERILATOR_FLAGS +=  -Wno-UNUSEDPARAM
VERILATOR_FLAGS +=  -Wno-PINCONNECTEMPTY
ifndef VCD
VERILATOR_FLAGS += --trace-fst
else
VERILATOR_FLAGS += --trace
endif

SOURCES := $(wildcard  obj_dir/*/tb_*) $(wildcard  obj_dir/*/ub_*)
UTB_SOURCES := $(wildcard  obj_dir/utb_*)
ifndef DESIGN
	DESIGN  = Unit_Test
endif
ifndef MEM
	MEM=hex/add.hex 
endif
ifndef MEMDUMP
	MEMDUMP=memdump.hex
endif
ifndef RUN_ARG
	RUN_ARG= 
endif
ifndef SYS_TB
	SYS_TB=tb_Proc.v
endif
ifndef FL
	FL=ProcFLMultiCycle
endif
ifndef FL_CACHE
	FL_CACHE=CacheNone
endif
ifndef SYS_TB_CACHE
	SYS_TB_CACHE=tb_Cache.v
endif

COMMAND_ARG=$(RUN_ARG) +mem=$(MEM) +memdump=$(MEMDUMP)
ifndef COVERAGE
	COVERAGE = coverage
endif

ifndef OUTDIR
	OUTDIR=obj_dir
endif

DESIGN_CONFIG_LIST := $(wildcard  ./*.config)
ifndef DESIGN_CONFIG
	DESIGN_CONFIG = default.config
endif
DESIGN_LIST  := $$(head -1 $(DESIGN_CONFIG) | cut -f1 -d"\#" )
TOP_TB := $$(head -2 $(DESIGN_CONFIG) | tail -1 | cut -f1 -d"\#")
TOP_UB := $$(head -3 $(DESIGN_CONFIG) | tail -1 | cut -f1 -d"\#")
UTB := $(wildcard  utb_*)
HEX_LIST := $(addsuffix .hex,$(notdir $(basename $(wildcard  asm/*.asm))))


######################################################################
# Starting Makefile Rules
######################################################################

.ONESHELL:

.PRECIOUS: %.v %.sv

default: run-all
$(SOURCES) $(UTB_SOURCES): FORCE
	$(MAKE) $(basename $(@F)).v.sim DESIGN=$(notdir $(@D)) OUTDIR=$(@)


run-all: check-setup $(HEX_LIST)
		@echo $(CURDIR)
		@echo $(DESIGN_LIST)
ifeq ($(notdir $(CURDIR) ), lab2_proc) 
		for hex in $(HEX_LIST); do \
			for designs in $(DESIGN_LIST) ; do \
				mkdir -p obj_dir/$$designs ;\
				$(MAKE) $$hex.diff DESIGN=$$designs OUTDIR=obj_dir/$$designs ; \
			done; \
		done;
else ifeq ($(notdir $(CURDIR) ), lab3_cache) 
		for hex in $(HEX_LIST); do \
			for designs in $(DESIGN_LIST) ; do \
				mkdir -p obj_dir/$$designs ;\
				$(MAKE) $$hex.diff DESIGN=$$designs OUTDIR=obj_dir/$$designs ; \
			done; \
		done;
else
		for designs in $(DESIGN_CONFIG_LIST) ; do \
			$(MAKE) run-design DESIGN_CONFIG=$$designs --no-print-directory; \
		done; 
endif
	for utb in $(UTB) ; do \
		mkdir -p obj_dir/$$(basename $$utb); \
		$(MAKE) obj_dir/$$(basename $$utb) --no-print-directory; \
	done;
	$(MAKE) coverage-report --no-print-directory
	$(MAKE) show-results --no-print-directory
run-design: check-setup
	for tb in $(TOP_TB) ; do \
		for number in $(DESIGN_LIST) ; do \
		mkdir -p obj_dir/$$number/$$tb; \
		$(MAKE) obj_dir/$$number/$$tb --no-print-directory; \
		done; \
	done; 
	for ub in $(TOP_UB) ; do \
		for number in $(DESIGN_LIST) ; do \
		mkdir -p obj_dir/$$number/$$ub; \
		$(MAKE) obj_dir/$$number/$$ub --no-print-directory; \
		done; \
	done; 

%.hex:
	@mkdir -p hex 
	@python3 tinyrv2_encoding_assembler.py asm/$(basename $@ ).asm hex/$@  
%.hex.sim: %.hex FORCE  check-setup
ifeq ($(notdir $(CURDIR) ), lab3_cache) 
	@echo $(basename $@)
	@echo "-- VERILATE ----------------"
	$(VERILATOR) $(VERILATOR_FLAGS)  --Mdir $(OUTDIR) --$(COVERAGE) --top-module top $(SYS_TB_CACHE) verilator.cpp  +define+DESIGN=$(DESIGN)  
	cp verilator.?pp $(OUTDIR) 

	@echo
	@echo "-- COMPILE -----------------"

	$(MAKE)  -C $(OUTDIR) -f Vtop.mk 

	@echo
	@echo "-- RUN ---------------------"
	@mkdir -p logs
	@echo 
	$(OUTDIR)/Vtop +trace --all --design $(DESIGN) $(RUN_ARG) +mem=hex/$(basename $@) +memdump=$(MEMDUMP) --outname $(DESIGN).$(SYS_TB_CACHE).$(basename $@) 

	@echo $(basename $@)
	@echo "-- VERILATE ----------------"
	$(VERILATOR) $(VERILATOR_FLAGS)  --Mdir $(OUTDIR) --$(COVERAGE) --top-module top $(SYS_TB_CACHE) verilator.cpp  +define+DESIGN=$(DESIGN)  
	cp verilator.?pp $(OUTDIR) 

	@echo
	@echo "-- COMPILE -----------------"

	$(MAKE)  -C $(OUTDIR) -f Vtop.mk 

	@echo
	@echo "-- RUN ---------------------"
	@mkdir -p logs
	@echo 
	$(OUTDIR)/Vtop +trace --all --design $(DESIGN) $(RUN_ARG) +mem=hex/$(basename $@) +memdump=$(MEMDUMP) --outname $(DESIGN).$(SYS_TB_CACHE).$(basename $@) 
	@echo
	@echo "-- DONE --------------------"
	printf "To see waveforms, open waves/%s.waves.fst in a waveform viewer" $(DESIGN).$(SYS_TB_CACHE).$(basename $@)
	@echo
else
	@echo $(basename $@)
	@echo "-- VERILATE ----------------"
	$(VERILATOR) $(VERILATOR_FLAGS)  --Mdir $(OUTDIR) --$(COVERAGE) --top-module top $(SYS_TB) verilator.cpp  +define+DESIGN=$(DESIGN)  
	cp verilator.?pp $(OUTDIR) 

	@echo
	@echo "-- COMPILE -----------------"

	$(MAKE)  -C $(OUTDIR) -f Vtop.mk 

	@echo
	@echo "-- RUN ---------------------"
	@mkdir -p logs
	@echo 
	$(OUTDIR)/Vtop +trace --all --design $(DESIGN) $(RUN_ARG) +mem=hex/$(basename $@) +memdump=$(MEMDUMP) --outname $(DESIGN).$(SYS_TB).$(basename $@) 

	@echo $(basename $@)
	@echo "-- VERILATE ----------------"
	$(VERILATOR) $(VERILATOR_FLAGS)  --Mdir $(OUTDIR) --$(COVERAGE) --top-module top $(SYS_TB) verilator.cpp  +define+DESIGN=$(DESIGN)  
	cp verilator.?pp $(OUTDIR) 

	@echo
	@echo "-- COMPILE -----------------"

	$(MAKE)  -C $(OUTDIR) -f Vtop.mk 

	@echo
	@echo "-- RUN ---------------------"
	@mkdir -p logs
	@echo 
	$(OUTDIR)/Vtop +trace --all --design $(DESIGN) $(RUN_ARG) +mem=hex/$(basename $@) +memdump=$(MEMDUMP) --outname $(DESIGN).$(SYS_TB).$(basename $@) 
	@echo
	@echo "-- DONE --------------------"
	printf "To see waveforms, open waves/%s.waves.fst in a waveform viewer" $(DESIGN).$(SYS_TB).$(basename $@)
	@echo
endif

%.hex.diff: %.hex FORCE  check-setup
ifeq ($(notdir $(CURDIR) ), lab3_cache) 
	@echo $(basename $@)
	@echo "-- VERILATE FL ----------------"
	$(VERILATOR) $(VERILATOR_FLAGS)  --Mdir $(OUTDIR)_FL --$(COVERAGE) --top-module top $(SYS_TB_CACHE) verilator.cpp  +define+DESIGN=$(FL_CACHE)  
	cp verilator.?pp $(OUTDIR)_FL 

	@echo
	@echo "-- COMPILE FL-----------------"

	$(MAKE)  -C $(OUTDIR)_FL -f Vtop.mk 

	@echo
	@echo "-- RUN FL ---------------------"
	@mkdir -p logs
	@echo 
	$(OUTDIR)_FL/Vtop +trace --all --design $(FL) $(RUN_ARG) +mem=hex/$(basename $@) +memdump=$(MEMDUMP).fl --outname $(FL_CACHE).$(SYS_TB_CACHE).$(basename $@) 

	@echo $(basename $@)
	@echo "-- VERILATE ----------------"
	$(VERILATOR) $(VERILATOR_FLAGS)  --Mdir $(OUTDIR) --$(COVERAGE) --top-module top $(SYS_TB_CACHE) verilator.cpp  +define+DESIGN=$(DESIGN)  
	cp verilator.?pp $(OUTDIR) 

	@echo
	@echo "-- COMPILE -----------------"

	$(MAKE)  -C $(OUTDIR) -f Vtop.mk 

	@echo
	@echo "-- RUN ---------------------"
	@mkdir -p logs
	@echo 
	$(OUTDIR)/Vtop +trace --all --design $(DESIGN) $(RUN_ARG) +mem=hex/$(basename $@) +memdump=$(MEMDUMP) --outname $(DESIGN).$(SYS_TB_CACHE).$(basename $@) 

	@echo
	@echo "-- Diff ---------------------"
	@mkdir -p logs
	@echo 
	@diff -y $(MEMDUMP) $(MEMDUMP).fl ;
	@if [ $$? -eq 0 ] ; then \
	printf "+" >>results/$(DESIGN).$(SYS_TB_CACHE).$(basename $@).txt ;\
	echo "[ passed ] Memory Image is the same" ;\
	else \
	printf "-" >>results/$(DESIGN).$(SYS_TB_CACHE).$(basename $@).txt ; \
	echo "[ failed ] Memory Image is different" ;\
	fi
	@echo
	@echo "-- DONE --------------------"
	@printf "To see waveforms, open waves/%s.waves.fst in a waveform viewer" $(DESIGN).$(SYS_TB_CACHE).$(basename $@)
	@echo
else
	@echo $(basename $@)
	@echo "-- VERILATE FL ----------------"
	$(VERILATOR) $(VERILATOR_FLAGS)  --Mdir $(OUTDIR)_FL --$(COVERAGE) --top-module top $(SYS_TB) verilator.cpp  +define+DESIGN=$(FL)  
	cp verilator.?pp $(OUTDIR)_FL 

	@echo
	@echo "-- COMPILE FL-----------------"

	$(MAKE)  -C $(OUTDIR)_FL -f Vtop.mk 

	@echo
	@echo "-- RUN FL ---------------------"
	@mkdir -p logs
	@echo 
	$(OUTDIR)_FL/Vtop +trace --all --design $(FL) $(RUN_ARG) +mem=hex/$(basename $@) +memdump=$(MEMDUMP).fl --outname $(FL).$(SYS_TB).$(basename $@) 

	@echo $(basename $@)
	@echo "-- VERILATE ----------------"
	$(VERILATOR) $(VERILATOR_FLAGS)  --Mdir $(OUTDIR) --$(COVERAGE) --top-module top $(SYS_TB) verilator.cpp  +define+DESIGN=$(DESIGN)  
	cp verilator.?pp $(OUTDIR) 

	@echo
	@echo "-- COMPILE -----------------"

	$(MAKE)  -C $(OUTDIR) -f Vtop.mk 

	@echo
	@echo "-- RUN ---------------------"
	@mkdir -p logs
	@echo 
	$(OUTDIR)/Vtop +trace --all --design $(DESIGN) $(RUN_ARG) +mem=hex/$(basename $@) +memdump=$(MEMDUMP) --outname $(DESIGN).$(SYS_TB).$(basename $@) 

	@echo
	@echo "-- Diff ---------------------"
	@mkdir -p logs
	@echo 
	@diff -y $(MEMDUMP) $(MEMDUMP).fl ;
	@if [ $$? -eq 0 ] ; then \
	printf "+" >>results/$(DESIGN).$(SYS_TB).$(basename $@).txt ;\
	echo "[ passed ] Memory Image is the same" ;\
	else \
	printf "-" >>results/$(DESIGN).$(SYS_TB).$(basename $@).txt ; \
	echo "[ failed ] Memory Image is different" ;\
	fi
	@echo
	@echo "-- DONE --------------------"
	@printf "To see waveforms, open waves/%s.waves.fst in a waveform viewer" $(DESIGN).$(SYS_TB).$(basename $@)
	@echo
endif
ub_%.v utb_%.v tb_%.v: FORCE  
	@echo decapitated call.  Use make $@.sim instead 

ub_%.v.sim utb_%.v.sim tb_%.v.sim: FORCE  check-setup 
	@echo
	@echo "-- VERILATE ----------------"
	$(VERILATOR) $(VERILATOR_FLAGS)  --Mdir $(OUTDIR) --$(COVERAGE) --top-module top $(basename $@) verilator.cpp  +define+DESIGN=$(DESIGN)  
	cp verilator.?pp $(OUTDIR) 

	@echo
	@echo "-- COMPILE -----------------"

	$(MAKE)  -C $(OUTDIR) -f Vtop.mk 

	@echo
	@echo "-- RUN ---------------------"
	@mkdir -p logs
	@echo 
	$(OUTDIR)/Vtop +trace --all --design $(DESIGN) $(COMMAND_ARG) --outname $(DESIGN).$(basename $(@F) .v) 

	@echo
	@echo "-- DONE --------------------"
	printf "To see waveforms, open waves/%s.waves.fst in a waveform viewer" $(DESIGN).$(basename $(@F) .v)
	@echo
	
coverage-report: FORCE check-setup
	@echo
	@echo "-- COVERAGE ----------------"

	$(VERILATOR_COVERAGE) --annotate-min 1 --annotate-all --annotate logs/annotated logs/*.dat --write-info logs/coverage.info

	@echo
	@echo "-- GENHTML --------------------"
	$(GENHTML) logs/coverage.info --output-directory logs/$(COVERAGE)/html

lab1_exist=$(wildcard lab1_imul/.)
lab2_exist=$(wildcard lab2_proc/.)
lab3_exist=$(wildcard lab3_cache/.)
tut4_exist=$(wildcard tut4_verilog/.)
show-results: FORCE check-setup
	@echo
	@echo "-- Results ----------------"
	for res in $(wildcard results/*.txt) ; do  \
		printf "[%70s]" $$(basename -- $$res) ;\
		result=$$(GREP_COLORS="ms=32" grep --color=always -E '^|\+' $$res  );\
		echo $$result | GREP_COLORS="ms=01;31" grep --color=always -E '^|\-' ;\
	done;
show-config:
	$(VERILATOR) -V
	$(MAKE) check-setup
setup: real 
	@echo Removing all symlink
	@find . -maxdepth 10 -type l -delete
	
ifneq ($(lab1_exist), ) 
		@echo Creating symlink for lab1_imul
		@ln -s ../Makefile lab1_imul/Makefile 
		@ln -s ../verilator.cpp lab1_imul/verilator.cpp 
endif 
	
ifneq ($(lab2_exist),) 
		@echo Creating symlink for lab2_proc
		@ln -s ../Makefile lab2_proc/Makefile
		@ln -s ../verilator.cpp lab2_proc/verilator.cpp
endif 

ifneq ($(lab3_exist),) 
		@echo Creating symlink for lab3_cache
		@ln -s ../Makefile lab3_cache/Makefile
		@ln -s ../verilator.cpp lab3_cache/verilator.cpp
		@ln -s ../lab2_proc/asm lab3_cache/asm
		@ln -s ../lab2_proc/tinyrv2_encoding_assembler.py lab3_cache/tinyrv2_encoding_assembler.py
endif 

ifneq ($(tut4_exist),) 
		@echo Creating symlink for tut4_verilog
		@ln -s ../Makefile tut4_verilog/Makefile
		@ln -s ../verilator.cpp tut4_verilog/verilator.cpp
endif 

	@echo v.$(VERSION) "("$$(sha1sum Makefile)")" > .ece-4750-setup
	@echo "("$$(sha1sum verilator.cpp)")" >> .ece-4750-setup
	find . -maxdepth 1 -mindepth 1 -type d -exec ln -s ../.ece-4750-setup {}/.ece-4750-setup \;

	
check-setup: FORCE
	@if (! [ -L ./Makefile ]); then \
	echo "Makefile detected not a symlink!" ;\
	echo "You are either 1) attepting to check your setup in your labroot, which is ok, but you will need to cd to the appropriate subdirectory to work on the labs or tutorials, or " ;\
	echo "2) have manually copy the make file to the a subdirectory which you should not have done. " ;\
	echo "If you are unsure please ask a member of course staff for assistance" ;\
	fi
	@echo ""
	@a=$$(echo v.$(VERSION) "("$$(sha1sum Makefile)")"); \
	if [ "$$a" != "$$(head -n 1 .ece-4750-setup)" ]; then \
		echo "The makefile script has been modified since setup!";\
		echo "Please revert your changes, or rerun setup if the changes are intended. ";\
		echo "If you are unsure how to proceed please contact a member of course staff.";\
		echo "Your current version is " $$a ; \
		echo "Your setup version is  " $$(head -n 1 .ece-4750-setup) ; \
		exit 1 ;\
	fi
	@a=$$(echo "("$$(sha1sum verilator.cpp)")"); \
	if [ "$$a" != "$$(tail -n 1 .ece-4750-setup)" ]; then \
		echo "The verilator.cpp file has been modified since setup!";\
		echo "Please revert your changes, or rerun setup if the changes are intended. ";\
		echo "If you are unsure how to proceed please contact a member of course staff.";\
		echo "Your current version is " $$a ; \
		echo "Your setup version is  " $$(tail -n 1 .ece-4750-setup) ; \
		exit 1 ;\
	fi
check-setup-root-ignore:
	@echo ""
	@a=$$(echo v.$(VERSION) "("$$(sha1sum Makefile)")"); \
	if [ "$$a" != "$$(head -n 1 .ece-4750-setup)" ]; then \
		echo "The makefile script has been modified since setup!";\
		echo "Please revert your changes, or rerun setup if the changes are intended. ";\
		echo "If you are unsure how to proceed please contact a member of course staff.";\
		echo "Your current version is " $$a ; \
		echo "Your setup version is  " $$(head -n 1 .ece-4750-setup) ; \
		exit 1 ;\
	fi
	@a=$$(echo "("$$(sha1sum verilator.cpp)")"); \
	if [ "$$a" != "$$(tail -n 1 .ece-4750-setup)" ]; then \
		echo "The verilator.cpp file has been modified since setup!";\
		echo "Please revert your changes, or rerun setup if the changes are intended. ";\
		echo "If you are unsure how to proceed please contact a member of course staff.";\
		echo "Your current version is " $$a ; \
		echo "Your setup version is  " $$(tail -n 1 .ece-4750-setup) ; \
		exit 1 ;\
	fi
remove-symlink: real
	find . -maxdepth 10 -type l -delete
real: FORCE
	@if [ -L ./Makefile ]; then \
		echo "You cannot run this command using a symlink of the make file" ;\
		echo "please rerun this command at the base directory (labroot)" ;\
		echo "or ask a member of course staff for assistance" ;\
		exit 1 ;\
	fi

build-tar: real FORCE check-setup-root-ignore
	@echo "######################################################################"
	@echo "#This is a command to help you build your tar.gz file for submission #" 
	@echo "#This script is deemed deemed reliable but not guaranteed. Ultimately#" 
	@echo "#you are responsible to ensure all the files you wish to submit to be#" 
	@echo "#in the tar.gz file.  Please verify the files before submitting and  #" 
	@echo "#included any other files you deemed nesscary manually and/or contact#" 
	@echo "#a member of course staff for assistance.                            #" 
	@echo "######################################################################" 
	
	lab1_files="lab1_imul/*.v lab1_imul/*.config" 
	lab2_files="lab1_imul/*.v lab1_imul/*.config lab2_proc/*.v lab2_proc/*.config lab2_proc/asm " 
	lab3_files="lab1_imul/*.v lab1_imul/*.config lab2_proc/*.v lab2_proc/*.config lab2_proc/asm lab3_cache/*.v lab3_cache/*.config" 
	echo "Enter your group number: [1-99]"
	read groupnum 
	echo "Enter partner #1 netID:"
	read netIDA 
	echo "Enter partner #2 netID, leave empty if you have no more partners:"
	read netIDB 
	echo "Enter partner #3 netID, leave empty if you have no more partners:"
	read netIDC 
	echo "Enter the lab number you want to build: [1]";\
	read input 
	echo $$netIDA >group$$groupnum.txt 
	echo $$netIDB >>group$$groupnum.txt 
	echo $$netIDC >>group$$groupnum.txt 
	if [ "$$input" -eq "1" ] ; then 
		tar czf lab1.tar.gz $$lab1_files Makefile verilator.cpp group$$groupnum.txt 
	elif [ "$$input" -eq "2" ] ; then 
		tar czf lab2.tar.gz $$lab2_files Makefile verilator.cpp group$$groupnum.txt 
	elif [ "$$input" -eq "3" ] ; then 
		tar czf lab3.tar.gz $$lab3_files Makefile verilator.cpp group$$groupnum.txt 
	else 
		echo "Unkown lab number. Contact a member of course staff if you need assistance." 
	fi
help:
	@head -n 79 Makefile 

clean:
	-rm -rf obj_dir obj_dir_FL logs *.log *.dmp *.vpd coverage.dat core.* results waves *hex

FORCE:
