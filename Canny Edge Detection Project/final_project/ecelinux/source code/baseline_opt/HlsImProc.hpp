//==========================================================================
// HlsImProc_baseline_opt.hpp
//==========================================================================
// @brief: Implementation of every submodules of Canny Edge Detection algorithm


#pragma once

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

        //-- 5x5 Gaussian kernel (8bit left shift)
        const int GAUSS_KERNEL[KERNEL_SIZE][KERNEL_SIZE] = { {1,  4,  6,  4, 1},
                                                             {4, 16, 24, 16, 4},
                                                             {6, 24, 36, 24, 6},
                                                             {4, 16, 24, 16, 4},
                                                             {1,  4,  6,  4, 1} };

        #pragma HLS ARRAY_PARTITION variable=GAUSS_KERNEL complete dim=0
        // image proc loop
        for(int yi = 0; yi < HEIGHT + KERNEL_SIZE - 1; yi++) {
            for(int xi = 0; xi < WIDTH + KERNEL_SIZE - 1; xi++) {
                #pragma HLS PIPELINE II=1
                #pragma HLS LOOP_FLATTEN off
                //--- gaussian blur
                int pix_gauss;

                //-- convolution
                pix_gauss = 0;
                xi -= KERNEL_SIZE - 1;
                yi -= KERNEL_SIZE - 1;
                for(int yw = 0; yw < KERNEL_SIZE; yw++) {
                    for(int xw = 0; xw < KERNEL_SIZE; xw++) {
                        if(xi + xw < 0 || xi + xw >= WIDTH || yi + yw < 0 || yi + yw >= HEIGHT) {
                            continue;
                        }  
                        pix_gauss += src[xi + xw + (yi + yw)*WIDTH]* GAUSS_KERNEL[yw][xw];

                    }
                }
                xi += KERNEL_SIZE - 1;
                yi += KERNEL_SIZE - 1;

                // 8bit right shift
                pix_gauss >>= 8;

                // output
                dst[xi + yi * WIDTH] = pix_gauss;
            }
        }
    }

    template<uint32_t WIDTH, uint32_t HEIGHT>
    inline void HlsImProc::Sobel(uint8_t* src, GradPix* dst) {
        const int KERNEL_SIZE = 3;

        //-- 3x3 Horizontal Sobel kernel
        const int H_SOBEL_KERNEL[KERNEL_SIZE][KERNEL_SIZE] = {  { 1,  0, -1},
                                                                { 2,  0, -2},
                                                                { 1,  0, -1}   };
        //-- 3x3 vertical Sobel kernel
        const int V_SOBEL_KERNEL[KERNEL_SIZE][KERNEL_SIZE] = {  { 1,  2,  1},
                                                                { 0,  0,  0},
                                                                {-1, -2, -1}   };
        // image proc loop
        for(int yi = 0; yi < HEIGHT + KERNEL_SIZE - 1; yi++) {
            for(int xi = 0; xi < WIDTH + KERNEL_SIZE - 1; xi++) {
                #pragma HLS PIPELINE II=1
                #pragma HLS LOOP_FLATTEN off

                //--- sobel
                int pix_sobel;
                GradDir grad_sobel;


                //-- convolution
                int pix_h_sobel = 0;
                int pix_v_sobel = 0;

                xi -= KERNEL_SIZE - 1;
                yi -= KERNEL_SIZE - 1;


                // convolution using by holizonal kernel
                for(int yw = 0; yw < KERNEL_SIZE; yw++) {
                    for(int xw = 0; xw < KERNEL_SIZE; xw++) {
                        if(xi + xw < 0 || xi + xw >= WIDTH || yi + yw < 0 || yi + yw >= HEIGHT) {
                            continue;
                        }  
                        pix_h_sobel += src[xi + xw + (yi + yw)*WIDTH]* H_SOBEL_KERNEL[yw][xw];
                    }
                }

                // convolution using by vertical kernel
                for(int yw = 0; yw < KERNEL_SIZE; yw++) {
                    for(int xw = 0; xw < KERNEL_SIZE; xw++) {
                        if(xi + xw < 0 || xi + xw >= WIDTH || yi + yw < 0 || yi + yw >= HEIGHT) {
                            continue;
                        }  
                        pix_v_sobel += src[xi + xw + (yi + yw)*WIDTH]* V_SOBEL_KERNEL[yw][xw];
                    }
                }

                xi += KERNEL_SIZE - 1;
                yi += KERNEL_SIZE - 1;

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

        // image proc loop
        for(int yi = 0; yi < HEIGHT; yi++) {
            for(int xi = 0; xi < WIDTH; xi++) {
                #pragma HLS PIPELINE II=1
                #pragma HLS LOOP_FLATTEN off

                //--- non-maximum suppression
                uint8_t value_nms;
                GradDir grad_nms;


                xi -= WINDOW_SIZE - 1;
                yi -= WINDOW_SIZE - 1;


                if(xi < 0 || xi >= WIDTH || yi < 0 || yi >= HEIGHT 
                || xi + WINDOW_SIZE / 2 < 0 || yi + WINDOW_SIZE / 2 < 0 
                || xi + WINDOW_SIZE / 2 >= WIDTH || yi + WINDOW_SIZE / 2 >= HEIGHT
                ) {
                    
                } else {

                value_nms = src[xi + WINDOW_SIZE / 2 + (yi + WINDOW_SIZE / 2)*WIDTH].value;
                grad_nms = src[xi + WINDOW_SIZE / 2 + (yi + WINDOW_SIZE / 2)*WIDTH].grad;
                // grad 0° -> left, right
                if(grad_nms == DIR_0) {
                    if(value_nms < src[xi + WINDOW_SIZE / 2 + yi *WIDTH].value ||
                       value_nms < src[xi + WINDOW_SIZE / 2 + (yi + WINDOW_SIZE - 1)*WIDTH].value) {
                        value_nms = 0;
                    }
                }
                // grad 45° -> upper left, bottom right
                else if(grad_nms == DIR_45) {
                    if(value_nms < src[xi  + yi *WIDTH].value ||
                       value_nms < src[xi + WINDOW_SIZE - 1 + (yi + WINDOW_SIZE - 1)*WIDTH].value) {
                        value_nms = 0;
                    }
                }
                // grad 90° -> upper, bottom
                else if(grad_nms == DIR_90) {
                    if(value_nms < src[xi + (yi + WINDOW_SIZE - 1)*WIDTH].value ||
                       value_nms < src[xi + WINDOW_SIZE - 1 + (yi + WINDOW_SIZE / 2)*WIDTH].value) {
                        value_nms = 0;
                    }
                }
                // grad 135° -> bottom left, upper right
                else if(grad_nms == DIR_135) {
                    if(value_nms < src[xi + WINDOW_SIZE - 1 + yi*WIDTH].value ||
                       value_nms < src[xi + (yi + WINDOW_SIZE - 1)*WIDTH].value) {
                        value_nms = 0;
                    }
                }
                }



                xi += WINDOW_SIZE - 1;
                yi += WINDOW_SIZE - 1;

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

        uint8_t line_buf[WINDOW_SIZE][WIDTH];
        uint8_t window_buf[WINDOW_SIZE][WINDOW_SIZE];

        #pragma HLS ARRAY_RESHAPE variable=line_buf complete dim=1
        #pragma HLS ARRAY_PARTITION variable=window_buf complete dim=0

        // image proc loop
        for(int yi = 0; yi < HEIGHT; yi++) {
            for(int xi = 0; xi < WIDTH; xi++) {
                #pragma HLS PIPELINE II=1
                #pragma HLS LOOP_FLATTEN off

                //--- non-maximum suppression
                uint8_t pix_hyst = 0;


                xi -= WINDOW_SIZE - 1;
                yi -= WINDOW_SIZE - 1;


                //-- comparison operation
                for(int yw = 0; yw < WINDOW_SIZE; yw++) {
                    for(int xw = 0; xw < WINDOW_SIZE; xw++) {
                        // std:: cout << "!!!!" << std::endl;  
                        if(xi + xw < 0 || xi + xw >= WIDTH || yi + yw < 0 || yi + yw >= HEIGHT 
                        || xi + WINDOW_SIZE / 2 < 0 || yi + WINDOW_SIZE / 2 < 0 
                        || xi + WINDOW_SIZE / 2 >= WIDTH || yi + WINDOW_SIZE / 2 >= HEIGHT
                        ) {
                            continue;
                        }   
                        // std:: cout << "1111" << std::endl;

                        if(src[xi + WINDOW_SIZE / 2 + (yi + WINDOW_SIZE / 2)*WIDTH] != 0) {
                            // std:: cout << "2222" << std::endl;
                            if(src[xi + xw + (yi + yw)*WIDTH] == 0xFF) {
                                // std:: cout << "????" << std::endl;
                                pix_hyst = 0xFF;
                            }
                        }
                    }
                }
                //253
                xi += WINDOW_SIZE - 1;
                yi += WINDOW_SIZE - 1;
\ 
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

