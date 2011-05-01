/**
 * Module:  LedRefDesign
 * Version: 10.4.1
 * Build:   977cb8e0d3fefc67ac350c5f294ac65919b3ebdc
 * File:    ledbufferclient.xc
 *
 * The copyrights, all other intellectual and industrial 
 * property rights are retained by XMOS and/or its licensors. 
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2010
 *
 * In the case where this code is a modification of existing code
 * under a separate license, the separate license terms are shown
 * below. The modifications to the code are still covered by the 
 * copyright notice above.
 *
 **/
#include "../ledconfiguration.h"
#include "pixelbuffer.h"

void sendLedData(chanend cLedBufferInput, int column, int row, unsigned len,
		unsigned char buf[]) {

	//TODO what sanity test should be done?
	//eg len<DISPLAY_HEIGHT, column<DISPLAY_WIDTH, row<DISPLAY_HEIGHT
	unsigned pixptr = CALCULATE_PIXEL_POINTER(column ,row);
	master
	{
		cLedBufferInput <: pixptr;
		cLedBufferInput <: len;
		for (int i=0; i<len; i+=3)
		{
			cLedBufferInput <: (char)buf[i];
			cLedBufferInput <: (char)buf[i+1];
			cLedBufferInput <: (char)buf[i+2];
		}
	}
}

void sendLedEndOfFrame(chanend cLedBufferInput) {
	master
	{
		cLedBufferInput <: -1;
	}
}

