//==========================================================================
// canny_dataflow_unopt.cpp
//==========================================================================
// @brief: Implementation of Canny edge detection

#include "canny.h"
#include "HlsImProc.hpp"


using namespace hls;
using namespace hlsimproc;
using namespace std;


uint8_t hist_hthr = 90;
uint8_t hist_lthr = 30;

hls::stream<bit24_t> stream1;
hls::stream<bit32_t> stream2;
hls::stream<bit24_t> stream3;
hls::stream<bit24_t> stream4;
hls::stream<bit24_t> stream5;



//----------------------------------------------------------
// Canny Accelerator
//----------------------------------------------------------

void canny(hls::stream<bit24_t> &input, hls::stream<uint8_t> &output){

    // exe gaussian blur
    HlsImProc::GaussianBlur<MAX_WIDTH, MAX_HEIGHT>(input, stream1);

    // exe sobel filter
    HlsImProc::Sobel<MAX_WIDTH, MAX_HEIGHT>(stream1, stream2);

    // exe non-maximum suppression
    HlsImProc::NonMaxSuppression<MAX_WIDTH, MAX_HEIGHT>(stream2, stream3);

    // exe zero padding at boundary pixel
    const uint32_t PADDING_SIZE = 5;
    HlsImProc::ZeroPadding<MAX_WIDTH, MAX_HEIGHT>(stream3, stream4, PADDING_SIZE);

    // exe hysteresis threshold
    HlsImProc::HystThreshold<MAX_WIDTH, MAX_HEIGHT>(stream4, stream5, hist_hthr, hist_lthr);

    // exe comparison operation at neighboring pixels after exe hysteresis threshold
    HlsImProc::HystThresholdComp<MAX_WIDTH, MAX_HEIGHT>(stream5, output);
}



//----------------------------------------------------------
// Top function
//----------------------------------------------------------
void dut(hls::stream<bit32_t> &strm_in, hls::stream<bit32_t> &strm_out) {
  bit32_t input_l;
  bit32_t output_l;
  bit24_t pixel_in;
  uint8_t pixel_out;
  hls::stream<bit24_t> pixel_in_stream;
  hls::stream<uint8_t> pixel_out_stream;


  for (int i = 0; i < I_WIDTH1 * I_WIDTH1 / (BUS_WIDTH / 8); ++i) {

    input_l = strm_in.read();

    for (int j = 0; j < BUS_WIDTH / 8; j++) {

      Canny_Pip_1:

      uint8_t xi = j + (i % (I_WIDTH1 / (BUS_WIDTH / 8))) * (BUS_WIDTH / 8);
      uint8_t yi = i / (I_WIDTH1 / (BUS_WIDTH / 8));

      pixel_in(7, 0) = input_l(j * 8 + 7, j * 8);
      pixel_in(15, 8) = xi;
      pixel_in(23, 16) = yi;

      pixel_in_stream.write(pixel_in);

      canny(pixel_in_stream, pixel_out_stream);

      pixel_out = pixel_out_stream.read();

      output_l(j * 8 + 7, j * 8) = pixel_out;

    }

    strm_out.write(output_l);
  }

}




