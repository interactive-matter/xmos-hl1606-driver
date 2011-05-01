// Copyright (c) 2011, Interactive Matter, Marcus Nowotny., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/*
 ============================================================================
 Name        : main.xc
 Description : The configuration & setup of the program
 core
 ============================================================================
 */
#include <xs1.h>
#include <platform.h>
#include "ledconfiguration.h"
#include "pixelbuffer/pixelbuffer.h"
#include "pixelbuffer/pixelbufferwriter.h"
#include "driversplitter.h"
#include "hl1606/hl1606-driver.h"
#include "testpattern.h"

//set up our ports for the first LED string
on stdcore[1]: port clock_port1 = XS1_PORT_1A;
on stdcore[1]: out port latch_port1 = XS1_PORT_1B;
on stdcore[1]: out port data_port1 = XS1_PORT_8A;
on stdcore[1]: out port s_port1 = XS1_PORT_1C;
on stdcore[1]: out port enable_port1 = XS1_PORT_1D;
on stdcore[1]: out port button_led_port1 = PORT_LED_1_0;
on stdcore[1]: port clock_port2 = XS1_PORT_1E;
on stdcore[1]: out port latch_port2 = XS1_PORT_1F;
on stdcore[1]: out port data_port2 = XS1_PORT_8B;
on stdcore[1]: out port s_port2 = XS1_PORT_1G;
on stdcore[1]: out port enable_port2 = XS1_PORT_1H;
on stdcore[1]: out port button_led_port2 = PORT_LED_1_1;

on stdcore[2]: port clock_port3 = XS1_PORT_1A;
on stdcore[2]: out port latch_port3 = XS1_PORT_1B;
on stdcore[2]: out port data_port3 = XS1_PORT_8A;
on stdcore[2]: out port s_port3 = XS1_PORT_1C;
on stdcore[2]: out port enable_port3 = XS1_PORT_1D;
on stdcore[2]: out port button_led_port3 = PORT_LED_2_0;
on stdcore[2]: port clock_port4 = XS1_PORT_1E;
on stdcore[2]: out port latch_port4 = XS1_PORT_1F;
on stdcore[2]: out port data_port4 = XS1_PORT_8B;
on stdcore[2]: out port s_port4 = XS1_PORT_1G;
on stdcore[2]: out port enable_port4 = XS1_PORT_1H;
on stdcore[2]: out port button_led_port4 = PORT_LED_2_1;

int main(void) {
	streaming chan pixelbuffer_output_cannel;
	chan testgenerator_channel;

	//that is our communication channels
	streaming chan bitbanger_channel1;
	streaming chan splitter_channel1;

	streaming chan bitbanger_channel2;
	streaming chan splitter_channel2;

	streaming chan bitbanger_channel3;
	streaming chan splitter_channel3;

	streaming chan bitbanger_channel4;
	streaming chan splitter_channel4;


	//processes start the engines
	par {
		//stdcore 0 is for the main apllication & pixel buffer
		on stdcore[0]:
		ledbuffer(testgenerator_channel, pixelbuffer_output_cannel);
		on stdcore[0]:
		test_pattern(testgenerator_channel);
		on stdcore[0]:
		driver_splitter(pixelbuffer_output_cannel,splitter_channel1,splitter_channel2,splitter_channel3, splitter_channel4);

		//stdcore 1 & 2 we drive the led arrays
		on stdcore[1]:
		hl1606_bitbanger(data_port1, clock_port1,
				latch_port1, s_port1, button_led_port1,
				bitbanger_channel1);
		on stdcore[1]:
		hl1606_strip_encoder(splitter_channel1, bitbanger_channel1, 0);

		on stdcore[1]:
		hl1606_bitbanger(data_port2, clock_port2,
				latch_port2, s_port2, button_led_port2,
				bitbanger_channel2);
		on stdcore[1]:
		hl1606_strip_encoder(splitter_channel2, bitbanger_channel2, 8);

		on stdcore[2]:
		hl1606_bitbanger(data_port3, clock_port3,
				latch_port3, s_port3, button_led_port3,
				bitbanger_channel3);
		on stdcore[2]:
		hl1606_strip_encoder(splitter_channel3, bitbanger_channel3, 16);

		on stdcore[2]:
		hl1606_bitbanger(data_port4, clock_port4,
				latch_port4, s_port4, button_led_port4,
				bitbanger_channel4);
		on stdcore[2]:
		hl1606_strip_encoder(splitter_channel4, bitbanger_channel4, 24);
		//on stdcore 3 we doe all the motor stuff
		}
	//this won't be reached either
	return 0;
}
