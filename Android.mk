#
# Copyright (C) 2019 The Android-x86 Open Source Project
#
# Licensed under the standard MIT license.
# See the COPYRIGHT in the same directory.
#

LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE := libc-musl
LOCAL_CC := $(TARGET_CC)

include $(LOCAL_PATH)/common.mk

MUSL_ARCH := $(TARGET_ARCH)
MUSL_SRC_DIRS := $(addprefix $(LOCAL_PATH)/,src/* crt ldso)
MUSL_BASE_SRCS := $(sort $(wildcard $(addsuffix /*.c,$(MUSL_SRC_DIRS))))
MUSL_ARCH_SRCS := $(sort $(wildcard $(addsuffix /$(MUSL_ARCH)/*.[csS],$(MUSL_SRC_DIRS))))
MUSL_REPLACED_SRCS := $(addsuffix .c,$(subst $(MUSL_ARCH)/,,$(basename $(MUSL_ARCH_SRCS))))
MUSL_LDSO_PATHNAME := $(TARGET_OUT_VENDOR_SHARED_LIBRARIES)/$(LOCAL_MODULE).so
MUSL_EMPTY_LIB_NAMES := m rt pthread crypt util xnet resolv dl

MUSL_SRC_FILES := $(subst $(LOCAL_PATH)/,,$(filter-out $(MUSL_REPLACED_SRCS),$(MUSL_BASE_SRCS)) $(MUSL_ARCH_SRCS))
MUSL_CRT_SRCS := $(filter crt/%,$(MUSL_SRC_FILES))
LOCAL_SRC_FILES := $(filter-out $(MUSL_CRT_SRCS),$(MUSL_SRC_FILES))

LOCAL_C_INCLUDES := $(addprefix $(LOCAL_PATH)/, \
	arch/$(MUSL_ARCH) \
	arch/generic \
	src/include \
	src/internal \
	include)

LOCAL_CFLAGS := -std=c99 -nostdinc \
	-ffreestanding -fexcess-precision=standard -frounding-math \
	-Wa,--noexecstack -D_XOPEN_SOURCE=700 -fomit-frame-pointer \
	-fno-unwind-tables -fno-asynchronous-unwind-tables \
	-ffunction-sections -fdata-sections \
	-Werror=implicit-function-declaration -Werror=implicit-int \
	-Werror=pointer-sign -Werror=pointer-arith -fno-stack-protector \
	-Os -pipe

intermediates := $(call local-intermediates-dir)
MUSL_LIBC_SYS := $(intermediates)

LOCAL_EXPORT_C_INCLUDE_DIRS := $(LOCAL_C_INCLUDES)

LOCAL_GENERATED_SOURCES := \
	$(intermediates)/bits/alltypes.h \
	$(intermediates)/bits/syscall.h \
	$(intermediates)/version.h

$(intermediates)/bits/alltypes.h: $(LOCAL_PATH)/tools/mkalltypes.sed $(LOCAL_PATH)/arch/$(MUSL_ARCH)/bits/alltypes.h.in $(LOCAL_PATH)/include/alltypes.h.in
	sed -f $^ > $@

$(intermediates)/bits/syscall.h: $(LOCAL_PATH)/arch/$(MUSL_ARCH)/bits/syscall.h.in | $(ACP)
	$(ACP) $< $@
	sed -n -e s/__NR_/SYS_/p < $< >> $@

$(intermediates)/version.h: $(wildcard $(LOCAL_PATH)/VERSION $(LOCAL_PATH)/.git)
	echo "#define VERSION \"$$(cd $(<D); sh tools/version.sh)\"" > $@

MUSL_CRT_OBJS := $(addsuffix .o,$(basename $(MUSL_CRT_SRCS:%=$(intermediates)/%)))
$(MUSL_CRT_OBJS): PRIVATE_CFLAGS := $(LOCAL_CFLAGS) $(addprefix -I,$(intermediates) $(LOCAL_C_INCLUDES)) -DCRT
$(filter $(intermediates)/crt/$(MUSL_ARCH)/%.o,$(MUSL_CRT_OBJS)): $(intermediates)/%.o: $(LOCAL_PATH)/%.s
	$(TARGET_CC) $(PRIVATE_CFLAGS) -o $@ -c $< && ln -sf crt/$(MUSL_ARCH)/$(@F) $(@D)/../..
$(filter-out $(intermediates)/crt/$(MUSL_ARCH)/%.o,$(MUSL_CRT_OBJS)): $(intermediates)/%.o: $(LOCAL_PATH)/%.c
	$(TARGET_CC) $(PRIVATE_CFLAGS) $(if $(filter %/crt1.c,$<),,-fPIC) -o $@ -c $< && ln -sf crt/$(@F) $(@D)/..

LOCAL_ADDITIONAL_DEPENDENCIES := $(MUSL_CRT_OBJS)

LOCAL_LDFLAGS := \
	-Wl,--sort-common \
	-Wl,--gc-sections \
	-Wl,--hash-style=both \
	-Wl,--no-undefined \
	-Wl,--exclude-libs=ALL \
	-Wl,--dynamic-list=$(LOCAL_PATH)/dynamic.list \
	-Wl,-e,_dlstart

LOCAL_POST_INSTALL_CMD := ln -sf $(LOCAL_MODULE).so $(MUSL_LIBC_SYS)/libc.so

include $(BUILD_SHARED_LIBRARY)

include $(CLEAR_VARS)

LOCAL_MODULE := musl-gcc
LOCAL_MODULE_CLASS := EXECUTABLES
LOCAL_IS_HOST_MODULE := true

intermediates := $(call local-generated-sources-dir)
MUSL_GCC_SPECS := $(intermediates)/$(LOCAL_MODULE).specs
LOCAL_PREBUILT_MODULE_FILE := $(basename $(MUSL_GCC_SPECS))
LOCAL_GENERATED_SOURCES := $(LOCAL_PREBUILT_MODULE_FILE)

$(MUSL_GCC_SPECS): $(LOCAL_PATH)/tools/musl-gcc.specs.sh
	sh $< "$(MUSL_LIBC_SYS)" "$(MUSL_LIBC_SYS)" "$(subst $(PRODUCT_OUT),,$(MUSL_LDSO_PATHNAME))" > $@

$(LOCAL_PREBUILT_MODULE_FILE): $(MUSL_GCC_SPECS)
	echo -e "#!/bin/sh\ncd \$$(dirname \$$0)/../../../..\nexec $(TARGET_CC) \$$(cat $(MUSL_LIBC_SYS)/export_includes) -specs $(MUSL_GCC_SPECS) \"\$$@\"\n" > $@

MUSL_EMPTY_LIBS := $(MUSL_EMPTY_LIB_NAMES:%=$(MUSL_LIBC_SYS)/lib%.a)
$(MUSL_EMPTY_LIBS):
	$(hide) rm -f $@; $(LLVM_PREBUILTS_PATH)/llvm-ar rc $@

LOCAL_ADDITIONAL_DEPENDENCIES := $(MUSL_EMPTY_LIBS)

include $(BUILD_PREBUILT)

MUSL_GCC := $(LOCAL_INSTALLED_MODULE)

include $(call all-makefiles-under,$(LOCAL_PATH))
