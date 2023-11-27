#include <stdio.h>

#define STB_IMAGE_WRITE_IMPLEMENTATION

// Image can be https://github.com/cnlohr/mini-rv32ima-images/blob/master/images/linux-5.18.0-rv32nommu-cnl-1.zip

#include "stb_image_write.h"

#define FRAMING 1024

int main()
{
	FILE * f = fopen( "Image", "rb" );
	if( !f ) { fprintf( stderr, "Error: Can't open image\n" ); return -9; }
	fseek( f, 0, SEEK_END );
	int imageLen = ftell( f );
	fseek( f, 0, SEEK_SET );
	uint8_t * buffer = calloc( imageLen + FRAMING, 1 );
	fread( buffer, imageLen, 1, f );
	fclose( f );
	
	int w, h;
	w = FRAMING;
	h = (imageLen + FRAMING-1) / FRAMING;
	int s = stbi_write_png( "sysimage.png", w, h, 1, buffer, FRAMING );
	printf( "ImageOut: %d %d\n", s, imageLen ) ;
	
	f = fopen( "sixtyfourmb.dtb", "rb" );
	if( !f ) { fprintf( stderr, "Error: Can't open sixtyfourmb.dtb\n" ); return -8; }
	fseek( f, 0, SEEK_END );
	int dtbLen = ftell( f );
	fseek( f, 0, SEEK_SET );
	uint8_t * dtb = calloc( dtbLen + FRAMING, 1 );
	// TRICKY: Override dtbSize
	uint32_t tSize = 1024*1023*16;
	fread( dtb, dtbLen, 1, f );
	dtb[0x13c+0] = tSize>>24;
	dtb[0x13c+1] = tSize>>16;
	dtb[0x13c+2] = tSize>>8;
	dtb[0x13c+0] = tSize>>0;

	w = FRAMING;
	h = (dtbLen + FRAMING-1) / FRAMING;
	s = stbi_write_png( "dtbimage.png", w, h, 1, dtb, FRAMING );
	printf( "dtbimage: %d %d\n", s, dtbLen ) ;
}
