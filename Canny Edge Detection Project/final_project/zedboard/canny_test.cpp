//=========================================================================
// canny_test.cpp
//=========================================================================
// @brief: testbench for Canny Edge Detection
// application

//#include <iostream>
#include <fstream>
//#include <cstdint>
#include "canny.h"
#include "timer.h"
#include "typedefs.h"

using namespace std;

// Number of test instances
const int TEST_SIZE = 4;

//------------------------------------------------------------------------
// Helper function for reading images and labels
//------------------------------------------------------------------------

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

//------------------------------------------------------------------------
// Canny testbench
//------------------------------------------------------------------------

int main() {
  // HLS streams for communicating with the cordic block
  hls::stream<bit32_t> digitrec_in;
  hls::stream<bit32_t> digitrec_out;

  int8_t test_images[TEST_SIZE][I_WIDTH1 * I_WIDTH1];
  int8_t test_images_out[TEST_SIZE][I_WIDTH1 * I_WIDTH1];

  // read test images and labels
  read_test_images(test_images);

  bit32_t test_image;
  bit32_t result_image;
  ofstream myfile ("result_images.dat");
  if (myfile.is_open()) {
  // Timer
  Timer timer("Canny Edge Start");
  timer.start();

  // pack images to 32-bit and transmit to dut function
  for (int test = 0; test < TEST_SIZE; test++) {
    for (int i = 0; i < I_WIDTH1 * I_WIDTH1;) {
      for (int j = 0; j < BUS_WIDTH / 8; j++) {
        test_image(j * 8 + 7, j * 8) = test_images[test][i];
        ++ i;
      }
      digitrec_in.write(test_image);
    }

    // perform prediction
    dut(digitrec_in, digitrec_out);

    // check results
    for (int i = 0; i < I_WIDTH1 * I_WIDTH1 / (BUS_WIDTH / 8); i++) {
      result_image = digitrec_out.read();
      for (int j = 0; j < BUS_WIDTH / 8; j++) {
        uint8_t result_data;
        result_data = result_image(j * 8 + 7, j * 8);
        //cout << "result_data: " << static_cast<int>(result_data) << endl;
        myfile <<  static_cast<int>(result_data) << "\n";
      }

    }

  }
  timer.stop();
  myfile.close();
  }

  return 0;
}





