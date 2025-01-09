- Project Structure
   The project structure is shown below
```
final_project
├─ ecelinux
│  ├─ canny.cpp                 // Implementation of Canny edge detection
│  ├─ canny.h                   // Header file defines the interface for the core functions
│  ├─ canny_test.cpp            // Testbench for Canny Edge Detection
│  ├─ convert_img.py            // Converting .dat file to the real picture(256*256)
│  ├─ data                      // Source data, containing four test pictures
│  │  ├─ image_src_0.png
│  │  ├─ image_src_1.png
│  │  ├─ image_src_2.png
│  │  ├─ image_src_3.png
│  │  └─ test_images.dat        // Source .dat file
│  ├─ HlsImProc.hpp             // Implementation of every submodules of Canny Edge Detection algorithm
│  ├─ Makefile
│  ├─ result                    // Csim result
│  │  └─ canny_csim.txt       
│  ├─ run.tcl         
│  ├─ run_bitstream.sh
│  ├─ source code               // Six versions of our designs, used to replace the canny.cpp and HlsImProc.hpp above
│  │  ├─ baseline_opt               // Baseline design with loop/function pipeline, loop unroll, array partition and reshape
│  │  │  ├─ canny.cpp                   // Corresponding implementation of Canny edge detection, replace the above canny.cpp
│  │  │  ├─ dut_csynth.rpt              // Top function design report
│  │  │  └─ HlsImProc.hpp               // Corresponding implementation of every submodules of Canny algorithm, replace the above HlsImProc.hpp
│  │  ├─ baseline_unopt             // Baseline design without loop/function pipeline, loop unroll, array partition and reshape
│  │  │  ├─ canny.cpp
│  │  │  ├─ dut_csynth.rpt
│  │  │  └─ HlsImProc.hpp
│  │  ├─ buffer_opt                 // Design with Line buffer & Window buffer, using loop/function pipeline, loop unroll, array partition and reshape
│  │  │  ├─ canny.cpp
│  │  │  ├─ dut_csynth.rpt
│  │  │  └─ HlsImProc.hpp
│  │  ├─ buffer_unopt               // Design with Line buffer & Window buffer, not using loop/function pipeline, loop unroll, array partition and reshape
│  │  │  ├─ canny.cpp
│  │  │  ├─ dut_csynth.rpt
│  │  │  └─ HlsImProc.hpp
│  │  ├─ dataflow_opt              // Design with Line buffer & Window buffer, and dataflow, using loop/function pipeline, loop unroll, array partition and reshape
│  │  │  ├─ canny.cpp
│  │  │  ├─ dut_csynth.rpt
│  │  │  ├─ HlsImProc.hpp
│  │  │  └─ run.tcl               // Special tcl file for dataflow_opt design
│  │  └─ dataflow_unopt           // Design with Line buffer & Window buffer, and dataflow, not using loop/function pipeline, loop unroll, array partition and reshape
│  │     ├─ canny.cpp
│  │     ├─ dut_csynth.rpt
│  │     └─ HlsImProc.hpp
│  ├─ timer.h                     
│  └─ typedefs.h               // Data type definition
├─ Makefile
└─ zedboard                    // Corresponding files have been linked with the "ecelinux"
   ├─ canny.cpp
   ├─ canny.h
   ├─ canny_test.cpp
   ├─ data
   │  ├─ image_src_0.png
   │  ├─ image_src_1.png
   │  ├─ image_src_2.png
   │  ├─ image_src_3.png
   │  └─ test_images.dat
   ├─ HlsImProc.hpp
   ├─ host.cpp                 // Communication interface between ARM processor and FPGA
   ├─ Makefile
   ├─ timer.h
   └─ typedefs.h

```

- Instruction
   To run our codes, first, copy the "canny.cpp" and "HlsImProc.hpp" files under corresponding designs directory("source code"), and paste them under "ecelinux" to replace the existing "canny.cpp" and "HlsImProc.hpp" files. Specially, for "dataflow_opt", the "run.tcl" file also needs to be replaced. 
   Then, by entering "make" or "make csim" in the terminal, first a file called "result_images.dat" will be created under "ecelinux", which contains a series of pixels of four 256*256 pictures, then running the python script "convert_img.py" to convert the .dat file to four .png files to visualize the corresponding four result pictures after canny edge detection. 
   By entering "vivado_hls -f run.tcl", the corresponding synthesis report and hardware project will be created. And we've included the report under different design version directories shown above if there is need to directly check the overview report.
   To run it on FPGA, similar to the previous labs, after replacing "canny.cpp" and "HlsImProc.hpp" and "run.tcl"(if needed), generate the bitstream, and transfer it to the board along with whole project, then enter "ecelinux" directory and run "make fpga". Then, similarly, a file called "result_images.dat" will be created under "ecelinux", using "convert_img.py" to convert it to four .png files, which are just the edge detection results.
