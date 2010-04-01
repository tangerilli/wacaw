/*
 *  base64.h
 *  Created by tzeeniewheenie_ on 07.11.07.
 *
 *  Very simple functions to encode a single three char block or an whole
 *  array of chars of specified length to base64 encoding.
 *  tzeeniewheenie_: Re-used this code from an old C-project I did.
 */

void encodeBase64( unsigned char * data, int len, unsigned char * retData, int* retLen );
void encodeblock( unsigned char in[3], unsigned char out[4], int len );
