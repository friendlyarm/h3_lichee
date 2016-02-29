/*
 * (C) Copyright 2014
 * jaon_Yin(yinxinliang),  Software Engineering, yinxinliang@allwinnertech.com
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston,
 * MA 02111-1307 USA
 */
 
#ifndef __SUNXI_BMP_HEAD_H__
#define __SUNXI_BMP_HEAD_H__
typedef  struct  tagBITMAPFILEHEADER
{ 
unsigned short int  bfType;       //位图文件的类型，必须为BM 
unsigned long       bfSize;       //文件大小，以字节为单位
unsigned short int  bfReserverd1; //位图文件保留字，必须为0 
unsigned short int  bfReserverd2; //位图文件保留字，必须为0 
unsigned long       bfbfOffBits;  //位图文件头到数据的偏移量，以字节为单位
}__attribute__ ((packed))BITMAPFILEHEADER;

typedef  struct  tagBITMAPINFOHEADER 
{ 
long biSize;                        //该结构大小，字节为单位
long  biWidth;                     //图形宽度以象素为单位
long  biHeight;                     //图形高度以象素为单位
short int  biPlanes;               //目标设备的级别，必须为1 
short int  biBitcount;             //颜色深度，每个象素所需要的位数
long  biCompression;        //位图的压缩类型
long  biSizeImage;              //位图的大小，以字节为单位
long  biXPelsPermeter;       //位图水平分辨率，每米像素数
long  biYPelsPermeter;       //位图垂直分辨率，每米像素数
long  biClrUsed;            //位图实际使用的颜色表中的颜色数
long  biClrImportant;       //位图显示过程中重要的颜色数
}__attribute__ ((packed))BITMAPINFOHEADER;

typedef struct 
{
	BITMAPFILEHEADER file;
	BITMAPINFOHEADER info;
}bmp_haedr;

#endif