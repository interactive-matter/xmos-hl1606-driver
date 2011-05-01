// Copyright (c) 2011, Interactive Matter, Marcus Nowotny., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/*
 * bit_density_modulation.xc
 *
 *  Created on: 18.03.2011
 *      Author: marcus
 */

#include "bit_density_modulation.h"

/*
 * returns 0 or -1 as bit output
 * TODO is there a bool - or anything more efficient
 * and the quantization error
 */
{int, int} bit_density_modulate(int value, int quantisation_error) {
	int result;
	int new_quantisation_error;
	if (value>=quantisation_error) {
		result=1;
		new_quantisation_error=255-value+quantisation_error;
	} else {
		result=0;
		new_quantisation_error=-value+quantisation_error;
	}
	return {result,new_quantisation_error};
}
