LOCAL_CXX ?= $(HOST_OUT_EXECUTABLES)/musl-g++
LOCAL_CLANG := none
LOCAL_MULTILIB := first
LOCAL_VENDOR_MODULE := true
LOCAL_CXX_STL := none
LOCAL_SANITIZE := never
LOCAL_SYSTEM_SHARED_LIBRARIES :=
LOCAL_NO_CRT := true
LOCAL_NO_DEFAULT_COMPILER_FLAGS := true
LOCAL_NO_LIBCOMPILER_RT := true
LOCAL_NO_STANDARD_LIBRARIES := true
LOCAL_LDFLAGS += -v

$(if $(LOCAL_MODULE_CLASS),,$(eval LOCAL_MODULE_CLASS := SHARED_LIBRARIES))
