#
# Copyright 2023-2024 NXP
#
# SPDX-License-Identifier: BSD-3-Clause
#
MODULE_REPOSITORY_SETTINGS_FILE?=$(MODULE_REPOSITORY_SETTINGS_FILE_VAR)
ECLIPSE_HOME=$(ECLIPSE_HOME_VAR)

ifeq ($(OS),Windows_NT)
MICROEJ_SEC=cmd /c "echo jdk.jar.disabledAlgorithms=MD2, MD5, RSA keySize ^< 1024, \
      DSA keySize ^< 1024, include jdk.disabled.namedCurves > javasec.prop"
else
MICROEJ_SEC=echo "jdk.jar.disabledAlgorithms=MD2, MD5, RSA keySize < 1024, \
      DSA keySize < 1024, include jdk.disabled.namedCurves" > javasec.prop
endif

S2S_PORT=5555
S2S_TTY ?= /dev/ttyACM0

ifeq ($(OS),Windows_NT)
BASE_DIR=${CURDIR}
else
BASE_DIR=$(shell pwd)
endif

define del_file
	$(if $(filter $(OS),Windows_NT),$(if $(wildcard $(1)),cmd /c DEL /f /q $(subst /,\\,$(1)),),rm -f $(1))
endef

define del_dir
	$(if $(filter $(OS),Windows_NT),$(if $(wildcard $(1)),cmd /c RD /s /q $(subst /,\\,$(1)),),rm -fr $(1))
endef


BSP_DIR=$(BASE_DIR)/bsp
PLAT_DIR=$(BASE_DIR)/microej/MCXN947-frdm_platform-CM4hardfp_GCC48-1.0.0
APP_DIR=$(BASE_DIR)/microej/apps
MOCK_DIR=$(BASE_DIR)/microej/mock
FP_DIR=$(BASE_DIR)/microej/front-panel
CONF_DIR=$(BASE_DIR)/microej/vee-port-configuration
VAL_DIR=$(BASE_DIR)/microej/validation

TEST_DIR.java.test.core=$(VAL_DIR)/core/java-testsuite-runner-core
TEST_DIR.java.test.fs=$(VAL_DIR)/fs/java-testsuite-runner-fs
TEST_DIR.java.test.gpio=$(VAL_DIR)/gpio/java-testsuite-runner-gpio
TEST_DIR.java.test.net=$(VAL_DIR)/net/java-testsuite-runner-net
TEST_DIR.java.test.security=$(VAL_DIR)/security/java-testsuite-runner-security
TEST_DIR.java.test.ssl=$(VAL_DIR)/ssl/java-testsuite-runner-ssl

VALIDATIONS ?= core fs gpio net security ssl

ifeq ($(ECLIPSE_HOME_VAR),)
$(error Define ECLIPSE_HOME_VAR to e.g. ~/MicroEJ/MicroEJ-SDK-21.11/rcp/)
endif

ifeq ($(strip $(VERBOSE)),1)
	JAVA_VERBOSE=-v
endif

ifeq ($(strip $(QUIET)),1)
	JAVA_VERBOSE=-q
endif

ifeq ($(strip $(CMAKE_OPTS)),)
	OPT='CMAKE_OPTS=-DENABLE_NET=1 -DENABLE_SEC=1'
endif

ifeq ($(strip $(PUBLISH)),1)
	PUBLISH_ARTIFACTS=-Dskip.publish=false
	PUBLISH_MODE=release
	MODULE_REPOSITORY_SETTINGS=
else
	PUBLISH_ARTIFACTS=
	PUBLISH_MODE=
endif

USAGE?=eval
CMAKE_OPTS?=

ifneq ($(MODULE_REPOSITORY_SETTINGS_FILE),)
	MODULE_REPOSITORY_SETTINGS=--module-repository-settings-file=$(MODULE_REPOSITORY_SETTINGS_FILE)
endif

JAVAZIP ?=

MAIN ?=

nxpvee-ui.prj:
nxpvee-validation.prj:

MAIN.nxpvee-ui.java.app=com.nxp.simpleGFX.SimpleGFX

PROJS = nxpvee-ui

include Makefile.inc

help:
	@echo "npa-mcxn947-frdm build system:"
	@echo ""
	@echo "Valid targets are:"
	@echo "    nxpvee-ui.prj            build complete UI project"
	@echo "    nxpvee-ui-clean          clean UI project"
	@echo "    nxpvee-ui-flash          flash board using J-Link"
	@echo "    nxpvee-ui-flash_cmsisdap flash board using CMSIS"
	@echo "    nxpvee-ui-gdb            debug UI project using gdb and J-Link"
	@echo "    nxpvee-ui-gdb_cmsisdap   debug UI project using gdb and CMSIS"
	@echo "    nxpvee-ui-java_run       run java simulation"
	@echo "    nxpvee-ui-java_rebuild   rebuild java app"
	@echo "    nxpvee-validation.prj    compile and run validation"
	@echo ""
	@echo "Valid options are:"
	@echo "    S2S_TTY                  set validation serial port (e.g. /dev/ttyACM0)"
	@echo "    VALIDATIONS='[option]+'  overrides validation projects to be run {core, fs, net, security, ssl}"
	@echo "    VERBOSE=1                compile in verbose mode"
	@echo "    QUIET=1                  compile in quiet mode"
	@echo "    USAGE=[eval|prod]        compile in eval or prod"
	@echo "    MAIN=com.nxp...          overrides java MAIN [com.nxp.simpleGFX.SimpleGFX, com.nxp.aiSample.AiMain]"
