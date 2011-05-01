// Copyright (c) 2011, Interactive Matter, Marcus Nowotny., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/*
 * testpattern.xc
 *
 *  Created on: 25.03.2011
 *      Author: marcus
 */
#include <xs1.h>

#include "testpattern.h"
#include "ledconfiguration.h"
#include "pixelbuffer/pixelbufferwriter.h"

void test_pattern(chanend communication_channel) {
	timer speed_timer;
	unsigned time;
#define TEST_WAIT_TIME 1000000
#define REDUCE 3
	int position = 0;
	int increment = 1;
	int values[DISPLAY_HEIGHT * 3];
	unsigned char output_values[DISPLAY_HEIGHT * 3];
	//empty the values
	for (int i = 0; i< DISPLAY_HEIGHT * 3; i++) {
		values[i]=0;
		output_values[i]=0;
	}
	//the test pattern goes forever
	speed_timer	:> time;
	while (1) {
		time+= TEST_WAIT_TIME;
		for (int i=0; i <DISPLAY_HEIGHT;i++) {
			int buffer_position = i*3;
			if (i==position) {
				values[buffer_position]=255;
				values[buffer_position+1]=255;
				values[buffer_position+2]=255;
			} else {
				values[buffer_position]-=REDUCE*4;
				values[buffer_position+1]-=REDUCE*8;
				values[buffer_position+2]-=REDUCE;
				//values[buffer_position]=0;
				//values[buffer_position+1]=0;
				//values[buffer_position+2]=0;
			}
			for (int j=0; j<3; j++) {
				if (values[buffer_position+j]<0) {
					values[buffer_position+j]=0;
				}
				output_values[buffer_position+j] = (char)values[buffer_position+j];
			}
		}
		for (int i=0; i<DISPLAY_WIDTH;i++) {
			sendLedData(communication_channel,i,0,DISPLAY_HEIGHT *3,output_values);
		}
		sendLedEndOfFrame(communication_channel);
		if (position==DISPLAY_HEIGHT-1) {
			increment=-1;
		} else if (position==0) {
			increment=1;
		}
		position += increment;
		position %= DISPLAY_HEIGHT;
		speed_timer when timerafter(time) :> void;
	}

}
