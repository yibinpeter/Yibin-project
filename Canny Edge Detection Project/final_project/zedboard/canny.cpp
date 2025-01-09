//==========================================================================
// canny_buffer_opt.cpp
//==========================================================================
// @brief: Implementation of Canny edge detection

#include "canny.h"
#include "HlsImProc.hpp"


using namespace hls;
using namespace hlsimproc;
using namespace std;


uint8_t fifo2[MAX_WIDTH * MAX_HEIGHT];
GradPix fifo3[MAX_WIDTH * MAX_HEIGHT];
uint8_t fifo4[MAX_WIDTH * MAX_HEIGHT];
uint8_t fifo5[MAX_WIDTH * MAX_HEIGHT];
uint8_t fifo6[MAX_WIDTH * MAX_HEIGHT];
uint8_t hist_hthr = 90;
uint8_t hist_lthr = 30;


//----------------------------------------------------------
// Canny Accelerator
//----------------------------------------------------------

void canny(uint8_t* input, uint8_t* output){

    // exe gaussian blur
    HlsImProc::GaussianBlur<MAX_WIDTH, MAX_HEIGHT>(input, fifo2);

    // exe sobel filter
    HlsImProc::Sobel<MAX_WIDTH, MAX_HEIGHT>(fifo2, fifo3);

    // exe non-maximum suppression
    HlsImProc::NonMaxSuppression<MAX_WIDTH, MAX_HEIGHT>(fifo3, fifo4);

    // exe zero padding at boundary pixel
    const uint32_t PADDING_SIZE = 5;
    HlsImProc::ZeroPadding<MAX_WIDTH, MAX_HEIGHT>(fifo4, fifo5, PADDING_SIZE);

    // exe hysteresis threshold
    HlsImProc::HystThreshold<MAX_WIDTH, MAX_HEIGHT>(fifo5, fifo6, hist_hthr, hist_lthr);

    // exe comparison operation at neighboring pixels after exe hysteresis threshold
    HlsImProc::HystThresholdComp<MAX_WIDTH, MAX_HEIGHT>(fifo6, output);
}



//----------------------------------------------------------
// Top function
//----------------------------------------------------------
void dut(hls::stream<bit32_t> &strm_in, hls::stream<bit32_t> &strm_out) {
  uint8_t input[I_WIDTH1 * I_WIDTH1];
  bit32_t input_l;
  bit32_t output_l;

  uint8_t output[I_WIDTH1 * I_WIDTH1];

  for (int i = 0; i < I_WIDTH1 * I_WIDTH1;) {
    input_l = strm_in.read();
    for (int j = 0; j < BUS_WIDTH / 8; j++) {
      input[i] = input_l(j * 8 + 7, j * 8);
      ++ i;
    }
  }

  canny(input, output);

  for (int i = 0; i < I_WIDTH1 * I_WIDTH1;) {
    for (int j = 0; j < BUS_WIDTH / 8; j++) {
      output_l(j * 8 + 7, j * 8) = output[i];
      ++ i;
    }
    strm_out.write(output_l);
  }
 
}





