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
#include <xs1.h>
#include <platform.h>
#include "hl1606-driver.h"
#include "../ledconfiguration.h"
#include "../bit_density_modulation/bit_density_modulation.h"

//these are HL1606 specific timing values
#define CLOCK_ON_WAIT 60 // we can work in theory with 300 ns whi is 30 in 10ns units but that is safe enough
#define CLOCK_OFF_WAIT 60 //We have to see if we cannot use smaller clock cycles
#define HL1606_LATCH_TIME 100

//TODO calculate this!
//how much led strips do we support per 16 bit port
#define MAX_NUMBER_STRIPS 8
//the bit value to light up the status led to indicate thread activity
#define STATUS_LED_BIT 1

//we can either work on the A or B portion of the so we have to define everything as a or b
//to support all 6 headers we will only be able to use the 8 bit ports
#define HL1606_PORT_A XS1_PORT_8A //expansion pins 2-9
#define HL1606_PORT_B XS1_PORT_8B //expansion pins 14-21
//first three bits are always the control bits
//the clock ports
#define CLOCK_PORT_A XS1_PORT_1A //expansion pin 0
#define CLOCK_PORT_B XS1_PORT_1E //expansion pin 12
//the ports for the latch ports
#define LATCH_PORT_A XS1_PORT_1B //expansion pin 1
#define LATCH_PORT_B XS1_PORT_1F //expansion pin 2
//the ports for the (completely ununderstandable) sPin
#define S_PIN_PORT_A XS1_PORT_1C //expansion pin 10
#define S_PIN_PORT_B XS1_PORT_1G //expansion pin 22
//this leaves port 1d - 11 && 1h - 23 unused - enable pins?
//the activity leds as ports - for activity status
#define LED_PORT_A XS1_PORT_1I
#define LED_PORT_B XS1_PORT_1J

//HL1606 specific define
#define RED_ON_BIT 2
#define GREEN_ON_BIT 4
#define BLUE_ON_BIT 0
#define LATCH_OK_BIT 7

#define CALCULATE_ERROR_POINTER(x,y) ((x*DISPLAY_HEIGHT+y)*3)

/*
 * TODO the process tructur has to be reworked:
 * is it usefull to put the writing in an own process to increase speed?
 */

//some internal functions
//send the pwm values over a streaming channel
static inline void hl1606_send_pwm_values(streaming chanend communication_channel, unsigned char red,
		unsigned char green, unsigned char blue, unsigned char latch);
//writeout a value respecting the clock cycles
static inline void hl1606_write_out_value(unsigned char value, out port data_port, out port clock_port);

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
		streaming chanend communication_channel, int start_column) {
	//the quantization error for 8 columns & all rows & all colors
	short quantization_error[DISPLAY_HEIGHT*MAX_NUMBER_STRIPS*3];
	//initialze the quantization erro with 0
	for (int i = 0; i < DISPLAY_HEIGHT*MAX_NUMBER_STRIPS*3; i++) {
		quantization_error[i] = 0;
	}
	//this is a process
	while (1) {
		//go through the rows
		for (int current_row = 0; current_row < DISPLAY_HEIGHT; current_row++) {
			//request the row from the reader
			unsigned position_request;
			unsigned size_request;
			//our output data
			unsigned char red_output = 0;
			unsigned char green_output = 0;
			unsigned char blue_output = 0;
			unsigned char latch_output = 0;

			//TODO this should go into the reader routine
			( position_request,unsigned short[])[0] = start_column;
			( position_request,unsigned short[])[1] = current_row;
			//we always request 8 columsn & 1 row
			( size_request,unsigned short[])[0] = MAX_NUMBER_STRIPS;
			( size_request,unsigned short[])[1] = 1;
			//request the current row data
			pixelbuffer_reader_channel <: position_request;
			pixelbuffer_reader_channel <: size_request;
#pragma loop unroll
			for (int current_column = 0; current_column<MAX_NUMBER_STRIPS; current_column++) {
				//the color information for the current row;
				unsigned char red_value;
				unsigned char green_value;
				unsigned char blue_value;
				//to store is the bit has to be set by the bit width modulation
				int is_bit;
				int quantisation_error_ptr = CALCULATE_ERROR_POINTER(current_column,current_row);
				unsigned char current_bit = (1<<current_column);

				//TODO why don't we encode it in one int
				pixelbuffer_reader_channel :> red_value;
				pixelbuffer_reader_channel :> green_value;
				pixelbuffer_reader_channel :> blue_value;

				{	is_bit,quantization_error[quantisation_error_ptr]}= bit_density_modulate(red_value,quantization_error[quantisation_error_ptr]);
				if (is_bit) {
					red_output |= current_bit;
				}
				{	is_bit,quantization_error[quantisation_error_ptr+1]}= bit_density_modulate(green_value,quantization_error[quantisation_error_ptr+1]);
				if (is_bit) {
					green_output |= current_bit;
				}
				{	is_bit,quantization_error[quantisation_error_ptr+2]}= bit_density_modulate(blue_value,quantization_error[quantisation_error_ptr+2]);
				if (is_bit) {
					blue_output |= current_bit;
				}
			}
			//if it is the last row we latch
			if (current_row==DISPLAY_HEIGHT-1) {
				latch_output=1;
			}
			hl1606_send_pwm_values(communication_channel, red_output, green_output, blue_output, latch_output);
			if (latch_output) {
				//signal the latch to the pixelbuffer
				pixelbuffer_reader_channel <: -1;
			}
		}
	}

}

/*
 * sends pwm data to the bitbanger
 * Parameters:
 * communication_channel
 * 			- output channel to the bitbanger process
 * red, gree, blue, latch
 * 			- bytes to encode on the channel
 */
static inline void hl1606_send_pwm_values(streaming chanend communication_channel,
		unsigned char red,
		unsigned char green, unsigned char blue, unsigned char latch) {
	unsigned value;

	//encode the data
	( value,unsigned char[])[0]=red;
	( value,unsigned char[])[1]=green;
	( value,unsigned char[])[2]=blue;
	( value,unsigned char[])[3]=latch;

	communication_channel	<: value;
	if (latch) {
		//Wait until we get the latch information
		communication_channel :> value; //value0 is discarded anyway
	}
}

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
		streaming chanend pwm_output_channel) {

	//we do not want to use the s port
	s_port <:0;
	//the clock is low
	clock_port <: 0;

	// and now we start our thread to output the values
	while (1) {
		//read a 32 bit value from the channel
		unsigned pwm_input;
		//we separate it later to those values
		unsigned char red;
		unsigned char green;
		unsigned char blue;
		unsigned char latch;
		//what we put out to the port
		unsigned outputvalue;


		/*
		 * This decodes the input value as 32 bit word:
		 * byte 0: red bytes for all 8
		 */
		pwm_output_channel	:> pwm_input;

		//signal that we are outputing data
		led_port <: 1;

		//TODO enabling disabling the timer around this

		red = (pwm_input,unsigned char[])[0];
		green = (pwm_input,unsigned char[])[1];
		blue = (pwm_input,unsigned char[])[2];
		latch = (pwm_input,unsigned char[])[3];

		/* The HL1606 drives 2 RGB LED's.  Each 3-color LED is controlled with a command
		 * word consisting of 8 bits.  Command word is clocked out MSB first (i.e. D8
		 * is first bit sent)
		 *
		 * Format of command word (using conventions in datasheet):
		 *   ________________________________________________________________________
		 *  |   D8   |   D7   |   D6   |   D5   |   D4   |   D3   |   D2   |    D1   |
		 *   ------------------------------------------------------------------------
		 *   ________________________________________________________________________
		 *  | LatchOK|    2x  |    LED1 CMD     |   LED 2 CMD     |     LED3 CMD     |
		 *   ------------------------------------------------------------------------
		 *
		 *   LED{1,2,3} CMD -
		 *       00 - LED off
		 *       01 - LED on (max bright)
		 *       10 - LED fade up   (start at min bright)
		 *       11 - LED fade down (start at max bright)
		 *
		 *   2X - Double fade speed
		 *       0 - 1X fade speed, each pulse on SI line steps brightness by 1/128th.
		 *       1 - 2X fade speed, each pulse on SI line steps brightness by 1/64th.
		 *
		 *   LatchOK - Enable latch.  Set to 0 to insert 'white space' in the serial
		 *             chain.  If set to 0, the entire CMD is ignored.
		 *       0 - Do not latch this CMD when Latch is thrown.
		 *       1 - Latch CMD as normal when Latch is thrown.
		 *
		 */
		//latch
		hl1606_write_out_value(0xff,data_port,clock_port);
		//don't care about speed
		hl1606_write_out_value(0x00,data_port,clock_port);
		//led1 0
		hl1606_write_out_value(0x00,data_port,clock_port);
		//led1 value
		hl1606_write_out_value(green,data_port,clock_port);
		//led2 0
		hl1606_write_out_value(0x00,data_port,clock_port);
		//led2 value
		hl1606_write_out_value(red,data_port,clock_port);
		//led3 0
		hl1606_write_out_value(0x00,data_port,clock_port);
		//led3 value
		hl1606_write_out_value(blue,data_port,clock_port);

		if (latch) {
			timer latch_timer;
			unsigned latch_time;
			//signal latching
			pwm_output_channel <: -1;
			//after the signal is handled we just latch
			latch_port <: 1;
			//and wait the specifiec latch time
			latch_timer :> latch_time;
			latch_time += HL1606_LATCH_TIME;
			latch_timer when timerafter(latch_time) :> void;
			latch_port <: 0;
		}
		//signal that we have finished outputing data
		led_port <: 0;
	}
}

static inline void hl1606_write_out_value(unsigned char value, out port data_port, out port clock_port) {
	//this is our timer to pulse out the output
	timer hl1606_timer;
	//some values to store time
	unsigned hl1606_clock_time;
	//writeout the latch bit
	data_port <: value;
	//set the clock port high
	clock_port <: 1;
	//read the timer and set the clock wait
	hl1606_timer :> hl1606_clock_time;
	hl1606_clock_time += CLOCK_ON_WAIT;
	//wait for the clock cycle
	hl1606_timer when timerafter(hl1606_clock_time) :> void;
	//set the clock port low
	clock_port <: 0;
	hl1606_clock_time += CLOCK_OFF_WAIT;
	//wait for the clock cycle
	hl1606_timer when timerafter(hl1606_clock_time) :> void;
}

