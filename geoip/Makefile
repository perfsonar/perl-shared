#
# Include a package-building Makefile depending on the system's
# packaging model.
#

# unibuild-*.make will define this target.

default: build


# This is used to make sure the RPM and Debian templates aren't
# included directly.
UNIBUILD_PACKAGE_MAKE=1


# Figure out what needs to be run to get root.

ifeq ($(shell id -u),0)
  RUN_AS_ROOT :=
else
  RUN_AS_ROOT := sudo
endif



# Figure out what kind of packaging this system uses.  This uses the
# same method as Unibuild.

ifneq ($(wildcard /etc/redhat-release),)
  PACKAGE_FORMAT := rpm
else ifneq ($(wildcard /etc/debian_version),)
  PACKAGE_FORMAT := deb
else
  $(error Unable to determine the package format on this system.)
endif


# Standard directories and files

TOP := $(CURDIR)

UNIBUILD_DIR := unibuild-work
TO_CLEAN += $(UNIBUILD_DIR)

# Where patches live

# Where the build happens
BUILD_DIR := $(UNIBUILD_DIR)/build
$(BUILD_DIR)::
	mkdir -p $@
TO_BUILD += $(BUILD_DIR)

# Where the finished products go
PRODUCTS_DIR := $(UNIBUILD_DIR)/products
$(PRODUCTS_DIR):
	mkdir -p $@
TO_BUILD += $(PRODUCTS_DIR)

# Build log
BUILD_LOG := unibuild-log
TO_CLEAN += $(BUILD_LOG)

# A place to create temporary files
TMP_DIR := $(UNIBUILD_DIR)/tmp
$(TMP_DIR):
	mkdir -p $@



# Include the right version for this package format

ifdef BUILD_PATH
include $(BUILD_PATH)/$(PACKAGE_FORMAT).make
else
include ./$(PACKAGE_FORMAT).make
endif



# Standard targets

build:: $(PRODUCTS_DIR) $(BUILD_DIR)
	bash get_dependency.sh all $(PACKAGE_FORMAT)
	mv *.$(PACKAGE_FORMAT) $(PRODUCTS_DIR)

clean::
	@for FILE in $(TO_CLEAN) ; \
	do \
		if [ -d "$${FILE}" ] ; \
		then \
			chmod -R +w "$${FILE}" ; \
		fi \
	done
	rm -rf $(TO_CLEAN)
	find . -name '*~' | xargs rm -rf

ifdef AUTO_TARBALL
clean::
	find . -depth -name Makefile \
	    -exec /bin/sh -c \
	    '[ "{}" != "./Makefile" ] && make -C `dirname {}` clean' \;
endif



# Convenient shorthands for targets in the templates included above.

b: build
c: clean
i: install
d: dump

cb: c b
cbd: c b d
cbi: c b i

# CBI with forced clean afterward
cbic: cbi
	@$(MAKE) clean

# CBR with forced clean afterward
cbdc: cbd
	@$(MAKE) clean


# These are deprecated holdovers from the RPM-only days

r:
	@printf "\n\nThe '$@' target is deprecated, use 'd' instead.  Continuing shortly.\n\n"
	@sleep 3
	@$(MAKE) d

cbr:
	@printf "\n\nThe '$@' target is deprecated, use 'cbd' instead.  Continuing shortly.\n\n"
	@sleep 3
	@$(MAKE) cbd

rpmdump:
	@printf "\n\nThe '$@' target is deprecated, use 'dump' instead.  Continuing shortly.\n\n"
	@sleep 3
	@$(MAKE) dump

cbrc:
	@printf "\n\nThe '$@' target is deprecated, use 'cbdc' instead.  Continuing shortly.\n\n"
	@sleep 3
	@$(MAKE) cbdc


