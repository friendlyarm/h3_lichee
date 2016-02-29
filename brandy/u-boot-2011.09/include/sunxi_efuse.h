/*
**********************************************************************************************************************
*
*						           the Embedded Secure Bootloader System
*
*
*						       Copyright(C), 2006-2014, Allwinnertech Co., Ltd.
*                                           All Rights Reserved
*
* File    :
*
* By      :
*
* Version : V2.00
*
* Date	  :
*
* Descript:
**********************************************************************************************************************
*/

#ifndef __SUNXI_EFUSE_H__
#define __SUNXI_EFUSE_H__

extern int sunxi_efuse_read(void *key_name,void *read_buf);
extern int sunxi_efuse_write(void *key_buf);

#endif    /*  #ifndef __SUNXI_EFUSE_H__  */
