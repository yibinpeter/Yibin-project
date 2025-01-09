//===========================================================================
// canny.h
//===========================================================================
// @brief: This header file defines the interface for the core functions.

#pragma once
#include "typedefs.h"
#include <hls_stream.h>

#define MAX_WIDTH  256
#define MAX_HEIGHT 256

const int I_WIDTH1 = 256;
const int BUS_WIDTH = 32;

// Top function for synthesis

void dut(hls::stream<bit32_t> &strm_in, hls::stream<bit32_t> &strm_out);

