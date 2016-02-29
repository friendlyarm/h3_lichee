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

#ifndef __EFUSE_H__
#define __EFUSE_H__

#include "asm/arch/cpu.h"

#define SID_PRCTL				(SUNXI_SID_BASE + 0x40)
#define SID_PRKEY				(SUNXI_SID_BASE + 0x50)
#define SID_RDKEY				(SUNXI_SID_BASE + 0x60)
#define SJTAG_AT0				(SUNXI_SID_BASE + 0x80)
#define SJTAG_AT1				(SUNXI_SID_BASE + 0x84)
#define SJTAG_S					(SUNXI_SID_BASE + 0x88)
#define SID_RF(n)               (SUNXI_SID_BASE + (n) * 4 + 0x80)

#define SID_EFUSE               (SUNXI_SID_BASE + 0x200)


#define EFUSE_CHIPID             (0x00)
#define EFUSE_OEM_PROGRAM       (0x10)
#define EFUSE_NV1               (0x14)
#define EFUSE_NV2               (0x18)
#define EFUSE_HDCP2X            (0x34)
#define EFUSE_THERMAL_SENSOR    (0x44)
#define EFUSE_HDCP              (0x4C)
#define EFUSE_RSSK              (0x94)

#define EFUSE_HDCP_HASH         (0xB4)

#define EFUSE_HUK               (0x174)
#define EFUSE_ROTPK             (0x184)
#define EFUSE_SSK               (0x1A4)

#define EFUSE_BKK1              (0x1B4)
#define EFUSE_BKK2              (0x1C4)
#define EFUSE_BKK3              (0x1D4)
#define EFUSE_BKK4              (0x1E4)

#define EFUSE_LCJS              (0x1F4)
#define EFUSE_DEBUG             (0x1F8)
#define EFUSE_CHIP_CONFIG        (0x1FC)


typedef struct
{
    //以下信息重复，表示每个key的信息
    char  name[64];    //key的名称
    u32 len;           //key数据段的总长度
	u8  *key_data;   //这是一个数组，存放key的全部信息，数据长度由len指定
}
sunxi_efuse_key_info_t;

extern void sid_program_key(uint key_index, uint key_value);
extern uint sid_read_key(uint key_index);
extern void sid_set_security_mode(void);
extern int sid_probe_security_mode(void);

#endif    /*  #ifndef __EFUSE_H__  */
