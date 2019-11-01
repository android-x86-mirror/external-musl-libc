#
# Copyright (C) 2019 The Android-x86 Open Source Project
#
# Licensed under the standard MIT license.
# See the COPYRIGHT in the same directory.
#

LOCAL_MODULE_CLASS := EXECUTABLES
include $(call my-dir)/binary.mk

$(LOCAL_PREBUILT_MODULE_FILE): $(all_objects)
	$(hide) $(MUSL_GCC) $^ -o $@ -Wl,-rpath=$(subst $(PRODUCT_OUT),,$(TARGET_OUT_VENDOR_SHARED_LIBRARIES))

include $(BUILD_PREBUILT)
