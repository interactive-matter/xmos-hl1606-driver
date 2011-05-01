// Copyright (c) 2011, XMOS Ltd., All rights reserved
// Heavily reworked by Interactive MAtter, Marcus Nowotny
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/**
 * Module:  LedRefDesign
 * Version: 10.4.1
 * Build:   977cb8e0d3fefc67ac350c5f294ac65919b3ebdc
 * File:    ledbuffer.xc
 *
 **/
#include <xs1.h>
#include <xclib.h>
// Gives us DISPLAY_HEIGHT and DISPLAY_WIDTH
#include "pixelbuffer.h"
#include "../ledconfiguration.h"

#define FRAME_SIZE     (DISPLAY_HEIGHT * DISPLAY_WIDTH)
#define BUFFER_SIZE    (3 * FRAME_SIZE)
#define SWAP(a,b)      {a -= b; b += a; a = b - a;}
#define BUFFER_TYPE    unsigned

#define SHIFT 0x01000000
#define DIV 1

// ------------------------------
#pragma unsafe arrays
void ledbuffer(chanend cLedBufferInput, streaming chanend cLedBufferOutput) {
	// Double buffer -- two frames
	// Frame is stored with in columns (original bitmap xy swapped)
	// This allows outputting one column at a time in a simple loop
	unsigned char buffer[BUFFER_SIZE * 3];

	unsigned bufswaptriggerN = 1, inbufptr = 0, outbufptr = FRAME_SIZE * 3;

	// Initialise the buffer to the specified test pattern
	// ---------------------------------------------------
	{
		unsigned ptr = 0;
		for (int buf = 0; buf < 3 * BUFFER_SIZE; buf++)
			buffer[buf] = 0;
	}

	// ---------------------------------------------------
	// Buffer init complete

	while (1) {
		// handle any writeout request
		//TODO when does buffer swap occur?
		unsigned pixelptr;
#pragma ordered
		select {
			// Sink request
		case cLedBufferOutput :> pixelptr:
			if (pixelptr == -1)
			{
				// End of frame signal from display driver
				// If the source wants us to swap, do so
				if (bufswaptriggerN == 0)
				{
					SWAP(inbufptr, outbufptr);
					bufswaptriggerN=1;
				}
			}
			else
			{
				// Request for data received by display driver
				//first we read our input values
				unsigned position = pixelptr;
				unsigned dimension;
				unsigned short row;
				unsigned short column;
				unsigned short width;
				unsigned short height;
				int end_row;
				int end_column;

				cLedBufferOutput :> dimension;
				row = (position,unsigned short[])[0];
				column = (position,unsigned short[])[1];
				width = (dimension,unsigned short[])[0];
				height = (dimension, unsigned short[])[1];
				end_row=row+width;
				end_column = column+height;
				//TODO sanity checks?
				for (int current_column = column; current_column<end_column;current_column++) {
					for (int current_row = row; current_row<end_row; current_row++) {
						//calculate the pixel pointer
						pixelptr = CALCULATE_PIXEL_POINTER(current_row,current_column)+outbufptr;
						cLedBufferOutput <: buffer[pixelptr];
						cLedBufferOutput <: buffer[pixelptr+1];
						cLedBufferOutput <: buffer[pixelptr+2];
					}
				}
			}
			break;

			// Source dump
			// Guard exists to prevent more data pushed in after frame switch
			case (bufswaptriggerN) => slave
			{
				cLedBufferInput :> pixelptr;
				if (pixelptr == -1)
				{
					// End of frame signal from source
					// Frame will not be swapped until sink completes also
					bufswaptriggerN = 0;
				}
				else
				{
					// New data from source
					int len;
					cLedBufferInput :> len;

					pixelptr += inbufptr;
					while (len > 0)
					{
						cLedBufferInput :> buffer[pixelptr];
						cLedBufferInput :> buffer[pixelptr+1];
						cLedBufferInput :> buffer[pixelptr+2];

						pixelptr+=3;
						len-=3;
					}
				}
			}:
			break;
		}
	}
	// Should never reach here
}
