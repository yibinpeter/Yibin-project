#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <math.h>
#include <assert.h>

#include <iostream>
#include <fstream>
//#include <cstdint>

#include "timer.h"
#include "canny.h"
#include "typedefs.h"


//------------------------------------------------------------------------
// Helper function for reading images and labels
//------------------------------------------------------------------------
const int TEST_SIZE = 4; // number of test instances

void read_test_images(int8_t test_images[TEST_SIZE][I_WIDTH1 * I_WIDTH1]) {
  std::ifstream infile("data/test_images.dat");
  if (infile.is_open()) {
    for (int index = 0; index < TEST_SIZE; index++) {
      for (int pixel = 0; pixel < I_WIDTH1 * I_WIDTH1; pixel++) {
        int i;
        infile >> i;
        test_images[index][pixel] = i;
      }
    }
    infile.close();
  }
}

//--------------------------------------
// main function
//--------------------------------------
int main(int argc, char **argv) {
  // Open channels to the FPGA board.
  // These channels appear as files to the Linux OS
  int fdr = open("/dev/xillybus_read_32", O_RDONLY);
  int fdw = open("/dev/xillybus_write_32", O_WRONLY);

  // Check that the channels are correctly opened
  if ((fdr < 0) || (fdw < 0)) {
    fprintf(stderr, "Failed to open Xillybus device channels\n");
    exit(-1);
  }

  // Arrays to store test data and expected results 
  int8_t test_images[TEST_SIZE][I_WIDTH1 * I_WIDTH1];
  bit32_t test_image;
  bit32_t result_image;

  // Timer
  Timer timer("Canny Edge on FPGA");
  // intermediate results
  int nbytes;

  //--------------------------------------------------------------------
  // Read data from the input file into two arrays
  //--------------------------------------------------------------------
  read_test_images(test_images);

  std::ofstream myfile ("result_images.dat");
  if (myfile.is_open()) {

  timer.start();
  //--------------------------------------------------------------------
  // Send data to accelerator
  //--------------------------------------------------------------------
  for (int test = 0; test < TEST_SIZE; ++test) {
    // Send 32-bit value through the write channel
    for (int i = 0; i < I_WIDTH1 * I_WIDTH1;) {
      for (int j = 0; j < BUS_WIDTH / 8; j++) {
        test_image(j * 8 + 7, j * 8) = test_images[test][i];
        ++ i;
      }
      nbytes = write(fdw, (void *)&test_image, sizeof(test_image));
      assert(nbytes == sizeof(test_image));
    }
  

  //--------------------------------------------------------------------
  // Receive data from the accelerator
  //--------------------------------------------------------------------
  //for (int test = 0; test < TEST_SIZE; ++test) {
    for (int i = 0; i < I_WIDTH1 * I_WIDTH1 / (BUS_WIDTH / 8); i++) {
      nbytes = read(fdr, (void *)&result_image, sizeof(result_image));
      assert(nbytes == sizeof(result_image));
      for (int j = 0; j < BUS_WIDTH / 8; j++) {
        uint8_t result_data;
        result_data = result_image(j * 8 + 7, j * 8);
        // cout << "result_data: " << static_cast<int>(result_data) << endl;
        myfile <<  static_cast<int>(result_data) << "\n";
      }
    }
  }
  timer.stop();
  myfile.close();
  }

  return 0;
}
