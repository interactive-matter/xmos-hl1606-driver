// Copyright (c) 2011, Interactive Matter, Marcus Nowotny., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/*
 * driversplitter.xc
 *
 *  Created on: 18.03.2011
 *      Author: marcus
 */
#include <xs1.h>
#include "driversplitter.h"

//our latch bits for managing the latches of all drivers
#define DRIVER_0_LATCHES (1<<0)
#define DRIVER_1_LATCHES (1<<1)
#define DRIVER_2_LATCHES (1<<2)
#define DRIVER_3_LATCHES (1<<3)

//internal functions
void splitter_copy_data(unsigned position_data, streaming chanend driver,
		streaming chanend buffer_output_channel);

/*
 * Process
 *
 * splits the pixel buffer communication to 4 hl1606 led drivers.
 * The latching is coordinated between all hl1606 drivers so that it is waited until all
 * drivers have latched.
 *
 * Parameters
 * buffer_output_channel
 * 		- the output channel of the pixelbuffer
 * driver_0, ..1, ..2, ..3
 * 		- the input channels of the drivers, they think it is the pixel buffer output channel
 */
//TODO this is dodgy
void driver_splitter(streaming chanend buffer_output_channel,
		streaming chanend driver_0, streaming chanend driver_1,
		streaming chanend driver_2, streaming chanend driver_3) {
	unsigned latch_information=0;
	//this is a process
	while (1) {
		unsigned position_data;
		//who is sending data?
#pragma ordered
		if ((latch_information & DRIVER_0_LATCHES) == 0) {
			select {
				case driver_0 :> position_data:
				//read only if the driver does not want to latch
				if (position_data==-1) {
					latch_information |= DRIVER_0_LATCHES;
				} else {
					splitter_copy_data(position_data, driver_0, buffer_output_channel);
				}
				break;
				default:
					//do nothing
				break;
			}
		}
		if ((latch_information & DRIVER_1_LATCHES) ==0 ) {
			select {
				case driver_1 :> position_data:
				//read only if the driver does not want to latch
				if (position_data==-1) {
					latch_information |= DRIVER_1_LATCHES;
				} else {
					splitter_copy_data(position_data, driver_1, buffer_output_channel);
				}
				break;
				default:
					//do nothing
				break;
			}
		}
		if ((latch_information & DRIVER_2_LATCHES) ==0 ) {
			select {
				case driver_2 :> position_data:
				//read only if the driver does not want to latch
				if (position_data==-1) {
					latch_information |= DRIVER_2_LATCHES;
				} else {
					splitter_copy_data(position_data, driver_2, buffer_output_channel);
				}
				break;
				default:
					//do nothing
				break;
			}
		}
		if ((latch_information & DRIVER_3_LATCHES) ==0 ) {
			select {
				case driver_3 :> position_data:
				//read only if the driver does not want to latch
				if (position_data==-1) {
					latch_information |= DRIVER_3_LATCHES;
				} else {
					splitter_copy_data(position_data, driver_3, buffer_output_channel);
				}
				break;
				default:
					//do nothing
				break;
			}
		}
		//ok all driver latched?
		if (latch_information == (DRIVER_0_LATCHES | DRIVER_1_LATCHES | DRIVER_2_LATCHES | DRIVER_3_LATCHES)) {
			//latch all
			buffer_output_channel <: -1;
			//reset latch information
			latch_information = 0;
		}
	}
}

void splitter_copy_data(unsigned position_data, streaming chanend driver,
		streaming chanend buffer_output_channel) {
	unsigned amount_of_data;
	unsigned char comm_buffer;
	unsigned dimension;
	//output the position data
	buffer_output_channel	<: position_data;
	//read out the dimension data to see how much we gonna read
	driver :> dimension;
	//output the position data
	buffer_output_channel <: dimension;
	//we do not care how much columns & rows we have - we just need to know how much data to transmit
	amount_of_data = (dimension,unsigned short[])[0] * (dimension, unsigned short[])[1]*3;
	for (int i=0; i< amount_of_data; i++) {
		//read the data from the buffer
		buffer_output_channel :> comm_buffer;
		//output the data to the driver
		driver <: comm_buffer;
	}
}
