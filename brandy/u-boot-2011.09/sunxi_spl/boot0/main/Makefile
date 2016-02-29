
##
## Makefile for Sunxi Secure Boot
##



include $(TOPDIR)/config.mk

LIB	:= $(obj)libmain.o

HEAD    := boot0_head.o

DATA    := boot0_hash.o
DATA    += boot0_config.o

START	:= boot0_entry.o

COBJS   += boot0_main.o

SRCS	:= $(START:.o=.S) $(COBJS:.o=.c) $(HEAD:.o=.c)
OBJS	:= $(addprefix $(obj),$(COBJS) $(COBJS-y) $(SOBJS))
HEAD    := $(addprefix $(obj),$(HEAD))
START	:= $(addprefix $(obj),$(START))
DATA	:= $(addprefix $(obj),$(DATA))

all:	 $(obj).depend $(HEAD) $(START) $(LIB) $(DATA)

$(LIB):	$(OBJS)
	$(call cmd_link_o_target, $(OBJS))

#########################################################################

# defines $(obj).depend target
include $(SRCTREE)/rules.mk

sinclude $(obj).depend

#########################################################################
