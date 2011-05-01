// Copyright (c) 2011, Interactive Matter, Marcus Nowotny., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/*
 * bit_density_modulation.h
 *
 *  Created on: 18.03.2011
 *      Author: marcus
 */

#ifndef BIT_DENSITY_MODULATION_H_
#define BIT_DENSITY_MODULATION_H_

/*
 * returns 0 or -1 as bit output
 * and the quantization error like
 * {result,quantisation_error}
 */
{int, int} inline bit_density_modulate(int value,int quantisation_error);

#endif /* BIT_WIDTH_MODULATION_H_ */
