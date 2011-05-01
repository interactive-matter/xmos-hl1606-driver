// Copyright (c) 2011, Interactive Matter, Marcus Nowotny., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/*
 ============================================================================
 Name        : xc1a-flashing-led.xc
 Description : Driving H1606 LED Strings from one 16bit port of a
			   core
 ============================================================================
 */
#ifndef H1606_DRIVER
#define H1606_DRIVER
#include <platform.h>

/*
 * Process
 *
 * gets 8 colums from the pixelbuffer and uses bit density modulation to seend it to
 * the hl1606 strips.
 * Parameters:
 * pixel_buffer_reader_channel
 * 		- connected to the pixelbuffer, outputting 8 columns - so you probably want to use
 * 		  a splitter for more columns
 * communication_channel
 * 		- the channel to the hl1606 bitbanger, consider it as private channel you just have
 * 		  to provide
 * int start_column
 * 		- which column does the this process beginn - needed to request the correct data
 * 		  from the buffer
 */
void hl1606_strip_encoder(streaming chanend pixelbuffer_reader_channel,
		streaming chanend communication_channel, int start_column);

/*
 * Processs
 *
 * writes out the RGB value according to the current position in the PWM cycle.
 * If the value is bigger than pwm_count the corresponding LED is switched on.
 * no latching will occur to shift the data through to the end.
 *
 * data port is 32 bit wide, bit banged to 8 data ports - so we are writing two value at once
 * the stream is read as a 32 bit integer, containing 4 bits: Red, Green, Blue, Latch
 * Each value is expected to be high or low for the corresponding row
 * if latch!=0 it is interpreted as latch
 * If latch is send it is synchonized with a -1 as awnswer on the channel
 * Parameters:
 * 	data_port 	- 8 bit port to output the 8 SPI data values of the hl1606 chips (32 bit buffered for speed)
 *  clock_port 	- the port where the clk signal is connected
 *  led_port	- the port of one led of the core for debuggig purpose
 * 	pwm_output_channel
 *  			- reads data bytes as 32 bit int red, green, blue, latch
 * 				  color data ist bit value for output port
 * 				  latch is just a signal (255/0)
 * 	outputBitClock
 * 				- clock to output data
 *
 */
void hl1606_bitbanger(out port data_port, out port clock_port,
		out port latch_port, out port s_port, out port led_port,
		streaming chanend pwm_output_channel);

#endif
