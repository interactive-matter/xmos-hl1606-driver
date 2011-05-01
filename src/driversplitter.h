/*
 * driversplitter.h
 *
 *  Created on: 21.03.2011
 *      Author: marcus
 */

#ifndef DRIVERSPLITTER_H_
#define DRIVERSPLITTER_H_

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
void driver_splitter(streaming chanend buffer_output_channel, streaming chanend driver_0, streaming chanend driver_1, streaming chanend driver_2, streaming chanend driver_3);

#endif /* DRIVERSPLITTER_H_ */
