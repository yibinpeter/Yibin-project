//==========================================================================
// HlsImProc_buffer_opt.hpp
//==========================================================================
// @brief: Implementation of every submodules of Canny Edge Detection algorithm


#pragma once

typedef  ap_uint<32>  HLS_SIZE_T;
#include <cassert>
#include "hls/hls_video_mem.h"
#include <stdint.h>
#include <cmath>
#include <hls_stream.h>
#include <hls_math.h>

namespace hlsimproc {
    // definition of gradient direction
    enum GradDir {
        DIR_0,
        DIR_45,
        DIR_90,
        DIR_135
    };

    // struct for image flowing through AXI4-Stream
    template<int D>
    struct ImAxis {
        ap_uint<D> data;
        ap_uint<1> user;
        ap_uint<1> last;
    };

    // struct of pixel that have gradient info
    struct GradPix {
        uint8_t value;
        GradDir grad;
    };

    class HlsImProc {
        public:

        // gaussian blur 
        template<uint32_t WIDTH, uint32_t HEIGHT>
        static void GaussianBlur(uint8_t* src, uint8_t* dst);

        // sobel filter
        template<uint32_t WIDTH, uint32_t HEIGHT>
        static void Sobel(uint8_t* src, GradPix* dst);

        // non-maximum suppression
        template<uint32_t WIDTH, uint32_t HEIGHT>
        static void NonMaxSuppression(GradPix* src, uint8_t* dst);

        // hysteresis threshold
        template<uint32_t WIDTH, uint32_t HEIGHT>
        static void HystThreshold(uint8_t* src, uint8_t* dst, uint8_t hthr, uint8_t lthr);

        // comparison operation at neighboring pixels after exe hysteresis threshold
        template<uint32_t WIDTH, uint32_t HEIGHT>
        static void HystThresholdComp(uint8_t* src, uint8_t* dst);

        // zero padding at boundary pixel
        template<uint32_t WIDTH, uint32_t HEIGHT>
        static void ZeroPadding(uint8_t* src, uint8_t* dst, uint32_t padding_size);
    };

    template<uint32_t WIDTH, uint32_t HEIGHT>
    inline void HlsImProc::GaussianBlur(uint8_t* src, uint8_t* dst) {
        const int KERNEL_SIZE = 5;

        hls::LineBuffer<KERNEL_SIZE,WIDTH, uint8_t> line_buf;
        hls::Window<KERNEL_SIZE, KERNEL_SIZE, uint8_t> window_buf;

        #pragma HLS ARRAY_RESHAPE variable=line_buf complete dim=1
        #pragma HLS ARRAY_PARTITION variable=window_buf complete dim=0

        //-- 5x5 Gaussian kernel (8bit left shift)
        const int GAUSS_KERNEL[KERNEL_SIZE][KERNEL_SIZE] = { {1,  4,  6,  4, 1},
                                                             {4, 16, 24, 16, 4},
                                                             {6, 24, 36, 24, 6},
                                                             {4, 16, 24, 16, 4},
                                                             {1,  4,  6,  4, 1} };

        #pragma HLS ARRAY_PARTITION variable=GAUSS_KERNEL complete dim=0

        // image proc loop
        for(int yi = 0; yi < HEIGHT; yi++) {
            for(int xi = 0; xi < WIDTH; xi++) {
                #pragma HLS PIPELINE II=1
                #pragma HLS LOOP_FLATTEN off

                //--- gaussian blur
                int pix_gauss;

                line_buf.shift_pixels_up(xi);

                // write to line buffer
                line_buf.insert_bottom_row(src[xi + yi*WIDTH], xi);


                window_buf.shift_pixels_left();


                // write to window buffer
                for(int yw = 0; yw < KERNEL_SIZE; yw++) {
                    window_buf.insert_pixel(line_buf.getval(yw,xi),yw,KERNEL_SIZE - 1);
                }



                //-- convolution
                pix_gauss = 0;
                for(int yw = 0; yw < KERNEL_SIZE; yw++) {
                    for(int xw = 0; xw < KERNEL_SIZE; xw++) {
                        pix_gauss += window_buf.getval(yw, xw) * GAUSS_KERNEL[yw][xw];
                    }
                }

                // 8bit right shift
                pix_gauss >>= 8;

                // output
                dst[xi + yi*WIDTH] = pix_gauss;
            }
        }
    }

    template<uint32_t WIDTH, uint32_t HEIGHT>
    inline void HlsImProc::Sobel(uint8_t* src, GradPix* dst) {
        const int KERNEL_SIZE = 3;

        hls::LineBuffer<KERNEL_SIZE,WIDTH, uint8_t> line_buf;
        hls::Window<KERNEL_SIZE, KERNEL_SIZE, uint8_t> window_buf;

        #pragma HLS ARRAY_RESHAPE variable=line_buf complete dim=1
        #pragma HLS ARRAY_PARTITION variable=window_buf complete dim=0

        //-- 3x3 Horizontal Sobel kernel
        const int H_SOBEL_KERNEL[KERNEL_SIZE][KERNEL_SIZE] = {  { 1,  0, -1},
                                                                { 2,  0, -2},
                                                                { 1,  0, -1}   };
        //-- 3x3 vertical Sobel kernel
        const int V_SOBEL_KERNEL[KERNEL_SIZE][KERNEL_SIZE] = {  { 1,  2,  1},
                                                                { 0,  0,  0},
                                                                {-1, -2, -1}   };

        #pragma HLS ARRAY_PARTITION variable=H_SOBEL_KERNEL complete dim=0
        #pragma HLS ARRAY_PARTITION variable=V_SOBEL_KERNEL complete dim=0

        // image proc loop
        for(int yi = 0; yi < HEIGHT; yi++) {
            for(int xi = 0; xi < WIDTH; xi++) {
                #pragma HLS PIPELINE II=1
                #pragma HLS LOOP_FLATTEN off

                //--- sobel
                int pix_sobel;
                GradDir grad_sobel;

                //-- line buffer
                line_buf.shift_pixels_up(xi);


                // write to line buffer
                line_buf.insert_bottom_row(src[xi + yi*WIDTH], xi);

                //-- window buffer
                window_buf.shift_pixels_left();



                // write to window buffer
                for(int yw = 0; yw < KERNEL_SIZE; yw++) {
                    window_buf.insert_pixel(line_buf.getval(yw,xi),yw,KERNEL_SIZE - 1);
                }

                //-- convolution
                int pix_h_sobel = 0;
                int pix_v_sobel = 0;

                // convolution using by holizonal kernel
                for(int yw = 0; yw < KERNEL_SIZE; yw++) {
                    for(int xw = 0; xw < KERNEL_SIZE; xw++) {
                        pix_h_sobel += window_buf.getval(yw, xw) * H_SOBEL_KERNEL[yw][xw];
                    }
                }

                // convolution using by vertical kernel
                for(int yw = 0; yw < KERNEL_SIZE; yw++) {
                    for(int xw = 0; xw < KERNEL_SIZE; xw++) {
                        pix_v_sobel += window_buf.getval(yw, xw) * V_SOBEL_KERNEL[yw][xw];
                    }
                }

                pix_sobel = sqrt(float(pix_h_sobel * pix_h_sobel + pix_v_sobel * pix_v_sobel));
                // pix_sobel = hls::sqrt(float(pix_h_sobel * pix_h_sobel + pix_v_sobel * pix_v_sobel));

                // to consider saturation
                if(255 < pix_sobel) {
                    pix_sobel = 255;
                }

                // evaluate gradient direction
                int t_int;
                if(pix_h_sobel != 0) {
                    t_int = pix_v_sobel * 256 / pix_h_sobel;
                }
                else {
                    t_int = 0x7FFFFFFF;
                }

                // 112.5° ~ 157.5° (tan 112.5° ~= -2.4142, tan 157.5° ~= -0.4142)
                if(-618 < t_int && t_int <= -106) {
                    grad_sobel = DIR_135;
                }
                // -22.5° ~ 22.5° (tan -22.5° ~= -0.4142, tan 22.5° = 0.4142)
                else if(-106 < t_int && t_int <= 106) {
                    grad_sobel = DIR_0;
                }
                // 22.5° ~ 67.5° (tan 22.5° ~= 0.4142, tan 67.5° = 2.4142)
                else if(106 < t_int && t_int < 618) {
                    grad_sobel = DIR_45;
                }
                // 67.5° ~ 112.5° (to inf)
                else {
                    grad_sobel = DIR_90;
                }

                // output
                if((KERNEL_SIZE < xi && xi < WIDTH - KERNEL_SIZE) &&
                   (KERNEL_SIZE < yi && yi < HEIGHT - KERNEL_SIZE)) {
                    dst[xi + yi*WIDTH].value = pix_sobel;
                    dst[xi + yi*WIDTH].grad  = grad_sobel;
                }
                else {
                    dst[xi + yi*WIDTH].value = 0;
                    dst[xi + yi*WIDTH].grad  = grad_sobel;
                }
            }
        }
    }

    template<uint32_t WIDTH, uint32_t HEIGHT>
    inline void HlsImProc::NonMaxSuppression(GradPix* src, uint8_t* dst) {
        const int WINDOW_SIZE = 3;

        hls::LineBuffer<WINDOW_SIZE,WIDTH, GradPix> line_buf;
        hls::Window<WINDOW_SIZE, WINDOW_SIZE, GradPix> window_buf;

        #pragma HLS ARRAY_RESHAPE variable=line_buf complete dim=1
        #pragma HLS ARRAY_PARTITION variable=window_buf complete dim=0

        // image proc loop
        for(int yi = 0; yi < HEIGHT; yi++) {
            for(int xi = 0; xi < WIDTH; xi++) {
                #pragma HLS PIPELINE II=1
                #pragma HLS LOOP_FLATTEN off

                //--- non-maximum suppression
                uint8_t value_nms;
                GradDir grad_nms;

                //-- line buffer
                line_buf.shift_pixels_up(xi);


                // write to line buffer
                line_buf.insert_bottom_row(src[xi + yi*WIDTH], xi);



                //-- window buffer
                window_buf.shift_pixels_left();

                
                // write to window buffer
                for(int yw = 0; yw < WINDOW_SIZE; yw++) {
                    window_buf.insert_pixel(line_buf.getval(yw,xi),yw,WINDOW_SIZE - 1);
                }

                value_nms = window_buf.getval(WINDOW_SIZE / 2, WINDOW_SIZE / 2).value;
                grad_nms = window_buf.getval(WINDOW_SIZE / 2, WINDOW_SIZE / 2).grad;
                // grad 0° -> left, right
                if(grad_nms == DIR_0) {
                    if(value_nms < window_buf.getval(WINDOW_SIZE / 2, 0).value ||
                       value_nms < window_buf.getval(WINDOW_SIZE / 2, WINDOW_SIZE - 1).value) {
                        value_nms = 0;
                    }
                }
                // grad 45° -> upper left, bottom right
                else if(grad_nms == DIR_45) {
                    if(value_nms < window_buf.getval(0, 0).value ||
                       value_nms < window_buf.getval(WINDOW_SIZE - 1, WINDOW_SIZE - 1).value) {
                        value_nms = 0;
                    }
                }
                // grad 90° -> upper, bottom
                else if(grad_nms == DIR_90) {
                    if(value_nms < window_buf.getval(0, WINDOW_SIZE - 1).value ||
                       value_nms < window_buf.getval(WINDOW_SIZE - 1, WINDOW_SIZE / 2).value) {
                        value_nms = 0;
                    }
                }
                // grad 135° -> bottom left, upper right
                else if(grad_nms == DIR_135) {
                    if(value_nms < window_buf.getval(WINDOW_SIZE - 1, 0).value ||
                       value_nms < window_buf.getval(0, WINDOW_SIZE - 1).value) {
                        value_nms = 0;
                    }
                }

                // output
                if((WINDOW_SIZE < xi && xi < WIDTH - WINDOW_SIZE) &&
                   (WINDOW_SIZE < yi && yi < HEIGHT - WINDOW_SIZE)) {
                    dst[xi + yi*WIDTH] = value_nms;
                }
                else {
                    dst[xi + yi*WIDTH] = 0;
                }
            }
        }
    }

    template<uint32_t WIDTH, uint32_t HEIGHT>
    inline void HlsImProc::HystThreshold(uint8_t* src, uint8_t* dst, uint8_t hthr, uint8_t lthr) {
        // image proc loop
        for(int yi = 0; yi < HEIGHT; yi++) {
            for(int xi = 0; xi < WIDTH; xi++) {
                #pragma HLS PIPELINE II=1
                #pragma HLS LOOP_FLATTEN off

                //--- hysteresis threshold
                int pix_hyst;

                if(src[xi + yi*WIDTH] < lthr) {
                    pix_hyst = 0;
                }
                else if(src[xi + yi*WIDTH] > hthr) {
                    pix_hyst = 255;
                }
                else {
                    pix_hyst = 1;
                }

                // output
                dst[xi + yi*WIDTH] = pix_hyst;
            }
        }
    }

    template<uint32_t WIDTH, uint32_t HEIGHT>
    inline void HlsImProc::HystThresholdComp(uint8_t* src, uint8_t* dst) {
        const int WINDOW_SIZE = 3;

        hls::LineBuffer<WINDOW_SIZE,WIDTH, uint8_t> line_buf;
        hls::Window<WINDOW_SIZE, WINDOW_SIZE, uint8_t> window_buf;

        #pragma HLS ARRAY_RESHAPE variable=line_buf complete dim=1
        #pragma HLS ARRAY_PARTITION variable=window_buf complete dim=0

        // image proc loop
        for(int yi = 0; yi < HEIGHT; yi++) {
            for(int xi = 0; xi < WIDTH; xi++) {
                #pragma HLS PIPELINE II=1
                #pragma HLS LOOP_FLATTEN off

                //--- non-maximum suppression
                uint8_t pix_hyst = 0;

                //-- line buffer
                line_buf.shift_pixels_up(xi);


                // write to line buffer
                line_buf.insert_bottom_row(src[xi + yi*WIDTH], xi);


                //-- window buffer
                window_buf.shift_pixels_left();


                // write to window buffer
                for(int yw = 0; yw < WINDOW_SIZE; yw++) {
                    window_buf.insert_pixel(line_buf.getval(yw,xi),yw,WINDOW_SIZE - 1);
                }

                //-- comparison operation
                for(int yw = 0; yw < WINDOW_SIZE; yw++) {
                    for(int xw = 0; xw < WINDOW_SIZE; xw++) {
                        if(window_buf.getval(WINDOW_SIZE / 2, WINDOW_SIZE / 2) != 0) {
                            if(window_buf.getval(yw, xw) == 0xFF) {
                                pix_hyst = 0xFF;
                            }
                        }
                    }
                }

                // output
                dst[xi + yi*WIDTH] = pix_hyst;
            }
        }
    }

    template<uint32_t WIDTH, uint32_t HEIGHT>
    inline void HlsImProc::ZeroPadding(uint8_t* src, uint8_t* dst, uint32_t padding_size) {
        // image proc loop
        for(int yi = 0; yi < HEIGHT; yi++) {
            for(int xi = 0; xi < WIDTH; xi++) {
                #pragma HLS PIPELINE II=1
                #pragma HLS LOOP_FLATTEN off

                // output
                uint8_t pix = src[xi + yi*WIDTH];
                if((padding_size < xi && xi < WIDTH - padding_size) &&
                   (padding_size < yi && yi < HEIGHT - padding_size)) {
                    dst[xi + yi*WIDTH] = pix;
                }
                else {
                    dst[xi + yi*WIDTH] = 0;
                }
            }
        }
    }
}

