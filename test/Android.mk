LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE := hello

LOCAL_SRC_FILES := hello.cpp main.c

#include $(BUILD_MUSL_EXECUTABLE)
include $(LOCAL_PATH)/../executable.mk
