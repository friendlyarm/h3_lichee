// jpegdec.cpp : 定义控制台应用程序的入口点。
//

#include "tinyjpeg.h"
#include "bmp_head.h"
#include <common.h>

#include <stdlib.h>
#include <bat.h>
#include <malloc.h>

static void exitmessage(const char *message)
{
  printf("%s\n", message);
  return ;
}

static int add_bmp_head(char *dst_addr,int wight,int height)
{
	bmp_haedr bmp;
	int i;
	int len = 0;
	char *buffer_dst;
	char *buffer_src;
	buffer_dst = (char *)dst_addr;
	bmp.file.bfType = 0x4D42;
	bmp.file.bfSize = (wight*height*4+54);
	bmp.file.bfReserverd1 = 0;
	bmp.file.bfReserverd2 = 0;
	bmp.file.bfbfOffBits = 54;

	
	bmp.info.biSize = 40;
	bmp.info.biWidth = wight;
	bmp.info.biHeight = (-height);
	bmp.info.biPlanes = 1;
	bmp.info.biBitcount = 32;
	bmp.info.biCompression = 0;
	bmp.info.biSizeImage = 0;
	bmp.info.biClrUsed = 0;
	bmp.info.biXPelsPermeter = 0;
	bmp.info.biYPelsPermeter = 0;
	bmp.info.biClrImportant = 0;
	buffer_src = (char *)(&(bmp.file.bfType));
	for (i=0;i<54;i++)
	{
		*buffer_dst++ = *buffer_src++;	
		len++ ;
	}

	return len;
}


static void write_rgb(const unsigned long *dst_addr, int width, int height, unsigned char **components,sunxi_rgb_store_t *rgb_info)
{
  
  char *dst_buffer;
  char *src_buffer;

  int bufferlen =0;
  int len ;
  int i;
 // printf("#######debug by jason############\n");
  dst_buffer = (char *)rgb_info->buffer;  
  src_buffer = (char *)(components[0]);

  rgb_info->x = width;
  rgb_info->y = height;
  bufferlen = width*height;
  len = add_bmp_head(dst_buffer,width,height);
  dst_buffer = dst_buffer+len;

  for(i=0; i<bufferlen; i++) 
  {
  	*dst_buffer++ = *(src_buffer+2);
  	*dst_buffer++ = *(src_buffer+1);
  	*dst_buffer++ = *src_buffer;
	*dst_buffer++ = 0xff;
	 src_buffer = src_buffer +3;
  }	  
//  printf("rgb_info->x:%d,rgb_info->y:%d,rgb_info->buffer:0x%0x\n",rgb_info->x,rgb_info->y,rgb_info->buffer);
 
}


/**
 * Save a buffer in three files (.Y, .U, .V) useable by yuvsplittoppm
 */
static void write_yuv(const unsigned char *dst_addr, int width, int height, unsigned char **components,sunxi_rgb_store_t *rgb_info)
{

  char *dst_buffer;
  char *src_buffer;
  //int i;
  rgb_info->x = width;
  rgb_info->y = height;

  /*copy Y data*/
  dst_buffer = (char *)rgb_info->buffer;  
  src_buffer = (char *)(components[0]);
  memcpy(dst_buffer,src_buffer,width*height);
  /*copy U data*/
  dst_buffer = (char *)(rgb_info->buffer+width*height);  
  src_buffer = (char *)(components[1]);
  memcpy(dst_buffer,src_buffer,width*height/4);
  /*copy v data*/
  dst_buffer = (char *)(rgb_info->buffer+width*height*5/4);  
  src_buffer = (char *)(components[2]);
  memcpy(dst_buffer,src_buffer,width*height/4);

}

/**
 * Save a buffer in grey image (pgm format)

static void write_pgm(const char *filename, int width, int height, unsigned char **components)
{
  FILE *F;
  char temp[1024];

  sprintf(temp, "%s", filename);
  F = fopen(temp, "wb");
  fprintf(F, "P5\n%d %d\n255\n", width, height);
  fwrite(components[0], width, height, F);
  fclose(F);
}

*/


/**
 * Load one jpeg image, and decompress it, and save the result.
 */
int convert_one_image(const unsigned char *src_addr, const unsigned char *dst_addr,int output_format,sunxi_rgb_store_t *rgb_info)
{
  unsigned int length_of_file = 262144;		//max 256k
  unsigned int width, height;
  unsigned char *buf;
  struct jdec_private *jdec;
  unsigned char *components[3];
  //int i;

  buf = src_addr;

  /* Decompress it */
  jdec = tinyjpeg_init();
  if (jdec == NULL)
    exitmessage("Not enough memory to alloc the structure need for decompressing\n");

  if (tinyjpeg_parse_header(jdec, buf, length_of_file)<0) {
		printf("parse_header failed\n");
   		exitmessage(tinyjpeg_get_printfstring(jdec));
  }

  /* Get the size of the image */
  tinyjpeg_get_size(jdec, &width, &height);

//  printf("Decoding JPEG image...\n");
  if (tinyjpeg_decode(jdec, output_format) < 0)
		exitmessage(tinyjpeg_get_printfstring(jdec));

  /* 
   * Get address for each plane (not only max 3 planes is supported), and
   * depending of the output mode, only some components will be filled 
   * RGB: 1 plane, YUV420P: 3 planes, GREY: 1 plane
   */
  tinyjpeg_get_components(jdec, components);

  /* Save it */
  switch (output_format)
   {
    case TINYJPEG_FMT_RGB24:
    case TINYJPEG_FMT_BGR24:
      write_rgb(dst_addr, width, height, components,rgb_info);
      break;
    case TINYJPEG_FMT_YUV420P:
      write_yuv(dst_addr, width, height, components,rgb_info);
      break;
    case TINYJPEG_FMT_GREY:
     // write_pgm(outfilename, width, height, components);
      break;
   }

  /* Only called this if the buffers were allocated by tinyjpeg_decode() */
  tinyjpeg_free(jdec);

  return 0;
}

int jpegdec(const unsigned char *src_addr, const unsigned char *dst_addr,sunxi_rgb_store_t *rgb_info)
{
	int output_format = TINYJPEG_FMT_RGB24;
	
	if( (NULL == src_addr) || (NULL == dst_addr) )
		puts("Must specify input_pic and output_pic with full path!");
	convert_one_image(src_addr, dst_addr, output_format,rgb_info);
	return 0;                                                                                                                                                                                                                                        
}

