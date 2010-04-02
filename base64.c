/*
 *  base64.c
 *  Created by tzeeniewheenie_ on 07.11.07.
 *
 *  Very simple functions to encode a single three char block or an whole
 *  array of chars of specified length to base64 encoding.
 *  tzeeniewheenie_: Re-used this code from an old C-project I did.
 */
#include <stdio.h>
#include <stdlib.h>

static const char cb64[]="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

void encodeblock( unsigned char in[3], unsigned char out[4], int len )
{
  out[0] = cb64[ in[0] >> 2 ];
  out[1] = cb64[ ((in[0] & 0x03) << 4) | ((in[1] & 0xf0) >> 4) ];
  out[2] = (unsigned char) (len > 1 ? cb64[ ((in[1] & 0x0f) << 2) | ((in[2] & 0xc0) >> 6) ] : '=');
  out[3] = (unsigned char) (len > 2 ? cb64[ in[2] & 0x3f ] : '=');
}

char decodeblock( unsigned char in[4], unsigned char out[3] )
{   
	char i = 0;
	while(in[i] != '=' && i < 4)
	{
		const char ind = in[i]; in[i] = 0;
		while(cb64[in[i]] != ind)
			in[i]++;
		i++;
	}
  
  out[ 0 ] = (unsigned char ) (in[0] << 2 | in[1] >> 4);
  out[ 1 ] = (unsigned char ) (in[1] << 4 | in[2] >> 2);
  out[ 2 ] = (unsigned char ) (((in[2] << 6) & 0xc0) | in[3]);
	return --i;
}

void encodeBase64( unsigned char * data, int len, unsigned char* retData, int* retLen )
{
	int i = *retLen = 0;
	unsigned char tmpBlock[3];
	unsigned char outBlock[4];
	while (i < len)
	{
		const char mod = i%3;
    char k = 0;
		tmpBlock[mod] = *data;
		if (mod == 2 || i + 1 == len)
		{
			/* encode a single block */
			encodeblock(tmpBlock, outBlock, mod + 1);
#ifdef DEBUG
			printf("%c%c%c%c", outBlock[0], outBlock[1], outBlock[2], outBlock[3]);
#endif
      for(; k < 4; k++)
      {
        retData[*retLen] = outBlock[k];
        (*retLen)++;
      }
		}
		i++;
		data++;
	}
}

void decodeBase64( unsigned char * data, int len, unsigned char* retData, int* retLen )
{
	int i = *retLen = 0;
	unsigned char tmpBlock[4];
	unsigned char outBlock[3];
	while (i < len)
	{
		const char mod = i%4;
		tmpBlock[mod] = *data;
    
		if (mod == 3)
		{
			char c = 0;
			/* encode a single block */
			const char cc = decodeblock(tmpBlock, outBlock);
      
			/*for(; c < cc; c++)
				printf("%c", outBlock[c]);*/
      
      for(; c < cc; c++)
      {
        retData[*retLen] = outBlock[c];
        (*retLen)++;
      }
		}
		i++;
		data++;
	}
}

