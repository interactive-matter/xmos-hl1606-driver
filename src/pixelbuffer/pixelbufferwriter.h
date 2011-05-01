/**
 * Module:  LedRefDesign
 * Version: 10.4.1
 * Build:   977cb8e0d3fefc67ac350c5f294ac65919b3ebdc
 * File:    ledbufferclient.h
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
#ifndef LEDBUFFERCLIENT_H_
#define LEDBUFFERCLIENT_H_

void sendLedData(chanend cLedBufferInput, int column, int row, unsigned len,
		unsigned char buf[]);
void sendLedEndOfFrame(chanend cLedBufferInput);

#endif /*LEDBUFFERCLIENT_H_*/
