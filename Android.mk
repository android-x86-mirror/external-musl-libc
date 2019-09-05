#
# Copyright (C) 2019 The Android-x86 Open Source Project
#
# Licensed under the standard MIT license.
# See the COPYRIGHT in the same directory.
#

LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE := libc-musl
LOCAL_MULTILIB := first
LOCAL_VENDOR_MODULE := true
LOCAL_MODULE_CLASS := SHARED_LIBRARIES

MUSL_ARCH := $(TARGET_ARCH)
MUSL_SRC_DIRS := $(addprefix $(LOCAL_PATH)/,src/* ldso)
MUSL_BASE_SRCS := $(sort $(wildcard $(addsuffix /*.c,$(MUSL_SRC_DIRS))))
MUSL_ARCH_SRCS := $(sort $(wildcard $(addsuffix /$(MUSL_ARCH)/*.[csS],$(MUSL_SRC_DIRS))))
MUSL_REPLACED_SRCS = $(addsuffix .c,$(subst $(MUSL_ARCH)/,,$(basename $(MUSL_ARCH_SRCS))))

LOCAL_SRC_FILES := $(subst $(LOCAL_PATH)/,,$(filter-out $(MUSL_REPLACED_SRCS),$(MUSL_BASE_SRCS)) $(MUSL_ARCH_SRCS))

LOCAL_C_INCLUDES := $(addprefix $(LOCAL_PATH)/, \
	arch/$(MUSL_ARCH) \
	arch/generic \
	src/include \
	src/internal \
	include) \

LOCAL_CFLAGS := -std=c99 -nostdinc \
	-ffreestanding -fexcess-precision=standard -frounding-math \
	-Wa,--noexecstack -D_XOPEN_SOURCE=700 -fomit-frame-pointer \
	-fno-unwind-tables -fno-asynchronous-unwind-tables \
	-ffunction-sections -fdata-sections \
	-Werror=implicit-function-declaration -Werror=implicit-int \
	-Werror=pointer-sign -Werror=pointer-arith \
	-Os -pipe \

intermediates := $(call local-generated-sources-dir)

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

LOCAL_CXX_STL := none
LOCAL_SANITIZE := never
LOCAL_SYSTEM_SHARED_LIBRARIES :=
LOCAL_NO_CRT := true
LOCAL_NO_DEFAULT_COMPILER_FLAGS := true
LOCAL_NO_LIBCOMPILER_RT := true
LOCAL_NO_STANDARD_LIBRARIES := true
LOCAL_LDFLAGS := \
	-Wl,--sort-common \
	-Wl,--gc-sections \
	-Wl,--hash-style=both \
	-Wl,--no-undefined \
	-Wl,--exclude-libs=ALL \
	-Wl,--dynamic-list=$(LOCAL_PATH)/dynamic.list \
	-Wl,-e,_dlstart -v

include $(BUILD_SHARED_LIBRARY)
