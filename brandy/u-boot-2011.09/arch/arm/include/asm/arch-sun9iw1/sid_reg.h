#ifndef   _SID_REG_H
#define   _SID_REG_H


#include "platform.h"
#include "asm/io.h"


#define SID_SRAM				(SID_BASE + 0x200)


#define sid_read_w(n)   		readl(n)
#define sid_write_w(n,c) 		writel(c,n)




// size (bit)
#define SID_CHIPID_SIZE			(128)
#define SID_OEM_PROGRAM_SIZE	(32)
#define	SID_NV1_SIZE			(32)
#define	SID_NV2_SIZE			(224)
#define	SID_THERMAL_SIZE		(32)
#define	SID_RENEWABILITY_SIZE	(64)
#define	SID_HUK_SIZE			(256)
#define	SID_ROTPK_SIZE			(256)
#define	SID_SSK_SIZE			(128)
#define	SID_RSSK_SIZE			(256)
#define	SID_HDCP_HASH_SIZE		(128)
#define	SID_EK_HASH_SIZE		(128)

// chip config show flag
#define	SCC_USER_RESERVERD_AREA4_DONTSHOW_FLAG		(20)
#define	SCC_USER_RESERVERD_AREA3_DONTSHOW_FLAG		(19)
#define	SCC_USER_RESERVERD_AREA2_DONTSHOW_FLAG		(18)
#define	SCC_USER_RESERVERD_AREA1_DONTSHOW_FLAG		(17)
#define	SCC_SSK_DONTSHOW_FLAG						(15)
#define	SCC_ROTPK_DONTSHOW_FLAG						(14)
#define	SCC_HUK_DONTSHOW_FLAG						(13)

// chip config burned flag
#define	SCC_USER_RESERVERD_AREA4_BURNED_FLAG		(11)
#define	SCC_USER_RESERVERD_AREA3_BURNED_FLAG		(10)
#define	SCC_USER_RESERVERD_AREA2_BURNED_FLAG		(9)
#define	SCC_USER_RESERVERD_AREA1_BURNED_FLAG		(8)
#define	SCC_EK_HASH_BURNED_FLAG						(7)
#define	SCC_HDCP_HASH_BURNED_FLAG					(6)
#define	SCC_RSSK_BURNED_FLAG					    (5)
#define	SCC_SSK_BURNED_FLAG							(4)
#define	SCC_ROTPK_BURNED_FLAG						(3)
#define	SCC_HUK_BURNED_FLAG							(2)
#define	SCC_SECURE_ENABLE_BURNED_FLAG				(1)
#define	SCC_TEST_DISABLE							(0)



#endif  //_SID_REG_H
