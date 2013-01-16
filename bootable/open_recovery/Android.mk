ifneq ($(TARGET_SIMULATOR),true)
ifeq ($(TARGET_ARCH),arm)

LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)

commands_recovery_local_path := $(LOCAL_PATH)

include $(CLEAR_VARS)

LOCAL_SRC_FILES := \
	recovery.c \
	bootloader.c \
	firmware.c \
	install.c \
	roots.c \
	ui.c

LOCAL_SRC_FILES += test_roots.c

#FFS -> gcc 4.4.0 and a nice bug when exiting the console when used more heavily
LOCAL_CFLAGS := -Os -fno-stack-protector

LOCAL_MODULE := open_recovery_STCU
LOCAL_MODULE_STEM := open_rcvr.STCU
LOCAL_MODULE_PATH := $(LOCAL_PATH)/../../OpenRecovery/sbin
LOCAL_UNSTRIPPED_PATH := $(TARGET_OUT_UNSTRIPPED)/recovery/

LOCAL_FORCE_STATIC_EXECUTABLE := true

RECOVERY_API_VERSION := 2
LOCAL_CFLAGS += -DRECOVERY_API_VERSION=$(RECOVERY_API_VERSION) -DOPEN_RCVR_STCU

LOCAL_MODULE_TAGS := eng

LOCAL_STATIC_LIBRARIES :=
ifeq ($(TARGET_RECOVERY_UI_LIB),)
  LOCAL_SRC_FILES += default_recovery_ui.c
else
  LOCAL_STATIC_LIBRARIES += $(TARGET_RECOVERY_UI_LIB)
endif
LOCAL_STATIC_LIBRARIES += libminzip_orcvr libunz libmtdutils_orcvr libmincrypt
LOCAL_STATIC_LIBRARIES += libminui_orcvr libpixelflinger_static libpng libcutils
LOCAL_STATIC_LIBRARIES += libstdc++ libc

include $(BUILD_EXECUTABLE)

include $(CLEAR_VARS)

LOCAL_SHARED_LIBRARIES := \
        libcutils \
        libutils \
        libbinder

LOCAL_SRC_FILES:= ss.cpp

LOCAL_MODULE:= sshot
LOCAL_MODULE_PATH := $(LOCAL_PATH)/../../OpenRecovery/sbin
LOCAL_MODULE_TAGS := optional

include $(BUILD_EXECUTABLE)

include $(commands_recovery_local_path)/minui/Android.mk
include $(commands_recovery_local_path)/minzip/Android.mk
include $(commands_recovery_local_path)/mtdutils/Android.mk
include $(commands_recovery_local_path)/edify/Android.mk
include $(commands_recovery_local_path)/updater/Android.mk
include $(commands_recovery_local_path)/applypatch/Android.mk

commands_recovery_local_path :=

endif   # TARGET_ARCH == arm
endif	# !TARGET_SIMULATOR
