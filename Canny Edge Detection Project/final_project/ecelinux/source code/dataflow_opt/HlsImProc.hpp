//==========================================================================
// HlsImProc_dataflow_opt.hpp
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

using namespace std;
namespace hlsimproc {
    // definition of gradient direction
    enum GradDir : uint8_t {
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
        static void GaussianBlur(hls::stream<bit24_t> &src, hls::stream<bit24_t> &dst);

        // sobel filter
        template<uint32_t WIDTH, uint32_t HEIGHT>
        static void Sobel(hls::stream<bit24_t> &src, hls::stream<bit32_t> &dst);

        // non-maximum suppression
        template<uint32_t WIDTH, uint32_t HEIGHT>
        static void NonMaxSuppression(hls::stream<bit32_t> &src, hls::stream<bit24_t> &dst);

        // hysteresis threshold
        template<uint32_t WIDTH, uint32_t HEIGHT>
        static void HystThreshold(hls::stream<bit24_t> &src, hls::stream<bit24_t> &dst, uint8_t hthr, uint8_t lthr);

        // comparison operation at neighboring pixels after exe hysteresis threshold
        template<uint32_t WIDTH, uint32_t HEIGHT>
        static void HystThresholdComp(hls::stream<bit24_t> &src, hls::stream<uint8_t> &dst);

        // zero padding at boundary pixel
        template<uint32_t WIDTH, uint32_t HEIGHT>
        static void ZeroPadding(hls::stream<bit24_t> &src, hls::stream<bit24_t> &dst, uint32_t padding_size);
    };


    template<uint32_t WIDTH, uint32_t HEIGHT>
    inline void HlsImProc::GaussianBlur(hls::stream<bit24_t> &src, hls::stream<bit24_t> &dst) {
        HlsImProc_Pip_1:
        Stream_1:
        Stream_2:

        const int KERNEL_SIZE = 3;

        bit24_t in_stream = src.read();
        uint8_t new_pixel = in_stream(7, 0);
        uint8_t xi = in_stream(15, 8);
        uint8_t yi = in_stream(23, 16);

        static hls::LineBuffer<KERNEL_SIZE, WIDTH, uint8_t> line_buf;
        static hls::Window<KERNEL_SIZE, KERNEL_SIZE, uint8_t> window_buf;

        Reshape_1:
        Partition_1:

        //-- 5x5 Gaussian kernel (8bit left shift)
        // const int GAUSS_KERNEL[KERNEL_SIZE][KERNEL_SIZE] = { {1,  4,  6,  4, 1},
        //                                                      {4, 16, 24, 16, 4},
        //                                                      {6, 24, 36, 24, 6},
        //                                                      {4, 16, 24, 16, 4},
        //                                                      {1,  4,  6,  4, 1} };
        const int GAUSS_KERNEL[KERNEL_SIZE][KERNEL_SIZE] = { {1,  2,  1},
                                                             {2,  4,  2},
                                                             {1,  2,  1} };

        Partition_1_2:


        line_buf.shift_pixels_up(xi);

        // write to line buffer
        line_buf.insert_bottom_row(new_pixel, xi);


        window_buf.shift_pixels_left();


        // write to window buffer
        for(int yw = 0; yw < KERNEL_SIZE; yw++) {

            window_buf.insert_pixel(line_buf.getval(yw,xi), yw, KERNEL_SIZE - 1);
        }

        //-- convolution
        int pix_gauss = 0;
        for(int yw = 0; yw < KERNEL_SIZE; yw++) {
            for(int xw = 0; xw < KERNEL_SIZE; xw++) {
                pix_gauss += window_buf.getval(yw, xw) * GAUSS_KERNEL[yw][xw];
            }
        }

        // 8bit right shift
        pix_gauss >>= 4;

        bit24_t out_stream;
        out_stream(7, 0) = pix_gauss;
        out_stream(15, 8) = xi;
        out_stream(23, 16) = yi;

        // output
        dst.write(out_stream);
            
    }
    

    template<uint32_t WIDTH, uint32_t HEIGHT>
    inline void HlsImProc::Sobel(hls::stream<bit24_t> &src, hls::stream<bit32_t> &dst) {
        HlsImProc_Pip_3:
        Stream_3:
        Stream_4:
        
        const int KERNEL_SIZE = 3;

        bit24_t in_stream = src.read();
        uint8_t new_pixel = in_stream(7, 0);
        uint8_t xi = in_stream(15, 8);
        uint8_t yi = in_stream(23, 16);

        static hls::LineBuffer<KERNEL_SIZE, WIDTH, uint8_t> line_buf;
        static hls::Window<KERNEL_SIZE, KERNEL_SIZE, uint8_t> window_buf;

        Reshape_2:
        Partition_2:

        //-- 3x3 Horizontal Sobel kernel
        const int H_SOBEL_KERNEL[KERNEL_SIZE][KERNEL_SIZE] = {  { 1,  0, -1},
                                                                { 2,  0, -2},
                                                                { 1,  0, -1}   };
        //-- 3x3 vertical Sobel kernel
        const int V_SOBEL_KERNEL[KERNEL_SIZE][KERNEL_SIZE] = {  { 1,  2,  1},
                                                                { 0,  0,  0},
                                                                {-1, -2, -1}   };

        Partition_2_2:
        Partition_2_3:

        //--- sobel
        int pix_sobel;
        GradDir grad_sobel;

        //-- line buffer
        line_buf.shift_pixels_up(xi);


        // write to line buffer
        line_buf.insert_bottom_row(new_pixel, xi);

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
                HlsImProc_Pip_4:
                pix_h_sobel += window_buf.getval(yw, xw) * H_SOBEL_KERNEL[yw][xw];
            }
        }

        // convolution using by vertical kernel
        for(int yw = 0; yw < KERNEL_SIZE; yw++) {
            for(int xw = 0; xw < KERNEL_SIZE; xw++) {
                HlsImProc_Pip_5:
                pix_v_sobel += window_buf.getval(yw, xw) * V_SOBEL_KERNEL[yw][xw];
            }
        }

        pix_sobel = sqrt(float(pix_h_sobel * pix_h_sobel + pix_v_sobel * pix_v_sobel));

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

        bit32_t out_stream;
        
        out_stream(15, 8) = xi;
        out_stream(23, 16) = yi;

        // output
        if((KERNEL_SIZE < xi && xi < WIDTH - KERNEL_SIZE) &&
            (KERNEL_SIZE < yi && yi < HEIGHT - KERNEL_SIZE)) {
            out_stream(7, 0) = pix_sobel; //value
            out_stream(31, 24) = grad_sobel; // grad
        }
        else {
            out_stream(7, 0) = 0;
            out_stream(31, 24) = grad_sobel;
        }

        dst.write(out_stream);
        
    }

    template<uint32_t WIDTH, uint32_t HEIGHT>
    inline void HlsImProc::NonMaxSuppression(hls::stream<bit32_t> &src, hls::stream<bit24_t> &dst) {
        Stream_5:
        Stream_6:
        
        const int WINDOW_SIZE = 3;

        bit32_t in_stream = src.read();
        uint8_t xi = in_stream(15, 8);
        uint8_t yi = in_stream(23, 16);
        GradPix new_GradPix;
        new_GradPix.value = in_stream(7, 0);
        uint8_t new_grad = in_stream(31, 24);
        new_GradPix.grad = static_cast<GradDir>(new_grad);

        static hls::LineBuffer<WINDOW_SIZE,WIDTH, GradPix> line_buf;
        static hls::Window<WINDOW_SIZE, WINDOW_SIZE, GradPix> window_buf;

        Reshape_3:
        Partition_3:

        //--- non-maximum suppression
        uint8_t value_nms;
        GradDir grad_nms;

        //-- line buffer
        line_buf.shift_pixels_up(xi);


        // write to line buffer
        line_buf.insert_bottom_row(new_GradPix, xi);



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

        bit24_t out_stream;
        
        out_stream(15, 8) = xi;
        out_stream(23, 16) = yi;

        // output
        if((WINDOW_SIZE < xi && xi < WIDTH - WINDOW_SIZE) &&
            (WINDOW_SIZE < yi && yi < HEIGHT - WINDOW_SIZE)) {

            out_stream(7, 0) = value_nms;
        }
        else {
            out_stream(7, 0) = 0;
        }
            
        dst.write(out_stream);
    }

    template<uint32_t WIDTH, uint32_t HEIGHT>
    inline void HlsImProc::HystThreshold(hls::stream<bit24_t> &src, hls::stream<bit24_t> &dst, uint8_t hthr, uint8_t lthr) {
        Stream_7:
        Stream_8:


        bit24_t in_stream = src.read();
        uint8_t new_pixel = in_stream(7, 0);
        uint8_t xi = in_stream(15, 8);
        uint8_t yi = in_stream(23, 16);
        

        //--- hysteresis threshold
        int pix_hyst;

        if(new_pixel < lthr) {
            pix_hyst = 0;
        }
        else if(new_pixel > hthr) {
            pix_hyst = 255;
        }
        else {
            pix_hyst = 1;
        }

        // output
        bit24_t out_stream;
        out_stream(7, 0) = pix_hyst;
        out_stream(15, 8) = xi;
        out_stream(23, 16) = yi;

        dst.write(out_stream);
    }

    template<uint32_t WIDTH, uint32_t HEIGHT>
    inline void HlsImProc::HystThresholdComp(hls::stream<bit24_t> &src, hls::stream<uint8_t> &dst) {
        Stream_9:
        Stream_10:
        
        const int WINDOW_SIZE = 3;

        bit24_t in_stream = src.read();
        uint8_t new_pixel = in_stream(7, 0);
        uint8_t xi = in_stream(15, 8);
        uint8_t yi = in_stream(23, 16);

        static hls::LineBuffer<WINDOW_SIZE,WIDTH, uint8_t> line_buf;
        static hls::Window<WINDOW_SIZE, WINDOW_SIZE, uint8_t> window_buf;

        Reshape_4:
        Partition_4:

        //--- non-maximum suppression
        uint8_t pix_hyst = 0;

        //-- line buffer
        line_buf.shift_pixels_up(xi);


        // write to line buffer
        line_buf.insert_bottom_row(new_pixel, xi);


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
        dst.write(pix_hyst);
            
        
    }

    template<uint32_t WIDTH, uint32_t HEIGHT>
    inline void HlsImProc::ZeroPadding(hls::stream<bit24_t> &src, hls::stream<bit24_t> &dst, uint32_t padding_size) {

        Stream_11:
        Stream_12:
        
        bit24_t in_stream = src.read();
        uint8_t new_pixel = in_stream(7, 0);
        uint8_t xi = in_stream(15, 8);
        uint8_t yi = in_stream(23, 16);

        bit24_t out_stream;
        
        out_stream(15, 8) = xi;
        out_stream(23, 16) = yi;

        // output
        uint8_t pix = new_pixel;
        if((padding_size < xi && xi < WIDTH - padding_size) &&
            (padding_size < yi && yi < HEIGHT - padding_size)) {
            out_stream(7, 0) = pix;
        }
        else {
            out_stream(7, 0) = 0;
        }

        dst.write(out_stream);   
        
    }
}
