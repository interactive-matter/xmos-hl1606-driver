// Copyright (c) 2011, XMOS Ltd., All rights reserved
// Heavily reworked by Interactive MAtter, Marcus Nowotny
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/**
 * Module:  LedRefDesign
 * Version: 10.4.1
 * Build:   977cb8e0d3fefc67ac350c5f294ac65919b3ebdc
 * File:    ledbuffer.h
 *
 **/
#ifndef __LEDBUFFER_H__
#define __LEDBUFFER_H__

/*
 * all buffers interacting with the pixel buffer are supposed to read and write a
 * buffer structure of the following form:
 * The data is unsigned
 * The data is encoded as one big array
 * the position is calculated by CALCULATE_PIXEL_POINTER:
 *  - organized in columns
 *  - three values per column point: red, green, and blue
 *  you can read the different color values for by incrementing the pointer
 *  so buffer[n] is red
 *  buffer[n+1] is green
 *  buffer[n+2] is blue
 *  buffer[n+3] is red of the next row
 */
//a standardized way to calculate the pointer to the pixelbuffer
#define CALCULATE_PIXEL_POINTER(x,y) ((x*DISPLAY_HEIGHT+y)*3)

// ledbuffer
// Frame buffer for pixel data
// Uses "double-buffer" scheme with tearing prevention

#ifdef __XC__
void ledbuffer(chanend cLedBufferInput, streaming chanend cLedBufferOutput);
#else
void ledbuffer(unsigned cLedBufferInput, unsigned cLedBufferOutput);
#endif

#endif

