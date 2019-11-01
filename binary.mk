#
# Copyright (C) 2019 The Android-x86 Open Source Project
#
# Licensed under the standard MIT license.
# See the COPYRIGHT in the same directory.
#

LOCAL_CC := $(MUSL_GCC)
LOCAL_SHARED_LIBRARIES += libc-musl
LOCAL_VENDOR_MODULE := true

intermediates := $(call local-intermediates-dir)

LOCAL_PREBUILT_MODULE_FILE := $(intermediates)/$(LOCAL_MODULE)-musl
LOCAL_GENERATED_SOURCES := $(LOCAL_PREBUILT_MODULE_FILE)

c_normal_sources := $(filter-out ../%,$(filter %.c,$(LOCAL_SRC_FILES)))
c_normal_objects := $(addprefix $(intermediates)/,$(c_normal_sources:.c=.o))
$(c_normal_objects): PRIVATE_CC := $(MUSL_GCC)
$(c_normal_objects): PRIVATE_CFLAGS := $(LOCAL_CFLAGS)
$(c_normal_objects): $(intermediates)/%.o: $(LOCAL_PATH)/%.c | $(MUSL_GCC)
	$(transform-c-to-o)

LOCAL_CPP_EXTENSION := $(if $(LOCAL_CPP_EXTENSION),$(LOCAL_CPP_EXTENSION),.cpp)
cpp_normal_sources := $(filter-out ../%,$(filter %$(LOCAL_CPP_EXTENSION),$(LOCAL_SRC_FILES)))
cpp_normal_objects := $(addprefix $(intermediates)/,$(cpp_normal_sources:$(LOCAL_CPP_EXTENSION)=.o))
$(cpp_normal_objects): PRIVATE_CXX := $(MUSL_GCC)
$(cpp_normal_objects): PRIVATE_CPPFLAGS := $(LOCAL_CPPFLAGS)
$(cpp_normal_objects): $(intermediates)/%.o: $(LOCAL_PATH)/%$(LOCAL_CPP_EXTENSION) | $(MUSL_GCC)
	$(transform-cpp-to-o)

all_objects := $(c_normal_objects) $(cpp_normal_objects)
