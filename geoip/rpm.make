#
# Generic Makefile for RPMs
#


#
# NO USER-SERVICEABLE PARTS BELOW THIS LINE
#

ifndef UNIBUILD_PACKAGE_MAKE
$(error Include unibuild-package.make, not an environment-specific template.)
endif


# RPM Directory

# We don't care about rpm directories in anything we built
RPM_DIR := $(shell find . -type d -name "rpm" | egrep -ve '^./$(UNIBUILD_DIR)/')
ifeq "$(RPM_DIR)" ""
$(error Unable to find rpm directory.)
endif
ifneq "$(words $(RPM_DIR))" "1"
$(error Found more than one rpm directory.  There can be only one.)
endif

#
# RPM Build Directory
#

BUILD_RPMS=$(BUILD_DIR)/RPMS
BUILD_SOURCES=$(BUILD_DIR)/SOURCES
BUILD_SPECS=$(BUILD_DIR)/SPECS
BUILD_SRPMS=$(BUILD_DIR)/SRPMS

BUILD_SUBS=\
	$(BUILD_RPMS) \
	$(BUILD_SOURCES) \
	$(BUILD_SPECS) \
	$(BUILD_SRPMS)


TO_BUILD += $(BUILD_SUBS)

# Source files installed in the build directory
INSTALLED_SOURCE_FILES := $(SOURCE_FILES:%=$(BUILD_SOURCES)/%)

$(BUILD_SUBS):
	mkdir -p '$@'


#
# Patches
#

# Patch files will either be in the same directory with the RPM spec
# or the unibuild-packaging directory above it.

# Enable this to force an error.
#PATCH_FILES += INTENTIONALLY-BAD.patch


# Find the patch files and weed out duplicates.
LOCATED_PATCH_FILES := $(shell echo \
	$(wildcard $(PATCH_FILES:%=$(RPM_DIR)/%)) \
	$(wildcard $(PATCH_FILES:%=$(dir $(RPM_DIR))/%)) \
	| sed -e 's/\s\+/\n/g' \
	| sort \
	| uniq)

LOCATED_PATCH_FILE_NAMES := $(notdir $(LOCATED_PATCH_FILES))

INSTALLED_PATCH_FILES := $(LOCATED_PATCH_FILE_NAMES:%=$(BUILD_SOURCES)/%)

MISSING_PATCH_FILES := $(filter-out $(LOCATED_PATCH_FILE_NAMES),$(PATCH_FILES))

ifneq "$(words $(MISSING_PATCH_FILES))" "0"
$(INSTALLED_PATCH_FILES):
	@echo
	@printf "ERROR: Unable to locate one or more of the following patch files:\n"
	@printf " $(MISSING_PATCH_FILES:%=    %\n)"
	@echo
	@printf "Each should exist in one of these directories:\n"
	@printf "    $(RPM_DIR)\n    $(dir $(RPM_DIR))\n"
	@echo
	@false
endif
ifneq "$(words $(LOCATED_PATCH_FILES))" "0"
$(INSTALLED_PATCH_FILES): $(BUILD_SOURCES)
	cp $(LOCATED_PATCH_FILES) $(BUILD_SOURCES)
endif


# Spec file in the build directory

BUILD_SPEC_FILE := $(BUILD_SPECS)/$(SPEC_BASE)
$(BUILD_SPEC_FILE): $(SPEC)
	mkdir -p $(dir $@)
	cp '$<' '$@'
ifdef UNIBUILD_TIMESTAMP
	sed -i -e 's/^\(Release:\s\+\).*$$/\10.$(UNIBUILD_TIMESTAMP)%{?dist}/' $@
endif

$(BUILD_DIR):: $(SPEC) $(BUILD_SPECS) $(BUILD_SPEC_FILE) $(INSTALLED_SOURCE_FILES) $(INSTALLED_PATCH_FILES)


#
# Source files
#

ifeq "$(words $(SOURCE_FILES))" "1"
  TARBALL_EXISTS := $(shell [ -e '$(SOURCE_FILES)' ] && echo 1 || true)
else
  # Go with whatever's in the source file.
  TARBALL_EXISTS=1
endif


ifeq "$(TARBALL_EXISTS)" "1"

# Have tarball(s), just need to copy into $(BUILD_SOURCES)

TO_BUILD += $(SOURCE_FILES:%=$(BUILD_SOURCES)/%)

$(BUILD_SOURCES)/%: % $(BUILD_SOURCES)
	cp '$(notdir $@)' '$@'

else

# Have a tarball, need to generate it in $(BUILD_SOURCES)

TARBALL_SOURCE := $(shell echo $(SOURCE_FILES) | sed -e 's/-[^-]*\.tar\.gz$$//')
TARBALL_NAME := $(TARBALL_SOURCE)-$(VERSION)
TARBALL_FULL := $(TARBALL_NAME).tar.gz

TARBALL_BUILD := $(BUILD_SOURCES)/$(TARBALL_NAME)
BUILD_SOURCE_TARBALL := $(BUILD_SOURCES)/$(TARBALL_FULL)

$(BUILD_SOURCE_TARBALL): $(BUILD_SOURCES)
	cp -r '$(TARBALL_SOURCE)' '$(TARBALL_BUILD)'
	cd '$(BUILD_SOURCES)' && tar czf '$(TARBALL_FULL)' '$(TARBALL_NAME)'
	rm -rf '$(TARBALL_BUILD)'

TO_BUILD += $(BUILD_SOURCE_TARBALL)

endif





#
# Useful Targets
#

ifdef NO_DEPS
  RPM=rpm
  RPMBUILD=rpmbuild
else
  RPM=rpm-with-deps
  RPMBUILD=rpmbuild-with-deps
endif

dump::
	@if [ -d "$(BUILD_RPMS)" ] ; then \
	    for RPM in `find $(BUILD_RPMS) -name '*.rpm'` ; do \
	    	echo `basename $${RPM}`: ; \
	     	rpm -qpl $$RPM 2>&1 | sed -e 's/^/\t/' ; \
	     	echo ; \
	    done ; \
        else \
	    echo "RPMs are not built." ; \
	    false ; \
	fi



# Install the built packages.  This is done in two phases so it can be
# done with YUM (or DNF): Reinstall anything that's already installed,
# then install anything that isn't.  This is the YUMmy equivalent of
# rpm -Uvh.

# Figure out which YUM-like installer to use, preferring DNF.
PATH_WORDS := $(subst :, ,$(PATH))
PATH_SEARCH := \
	$(addsuffix /dnf,$(PATH_WORDS)) \
	$(addsuffix /yum,$(PATH_WORDS))
INSTALL_PACKAGE := $(firstword $(wildcard $(PATH_SEARCH)))
ifndef INSTALL_PACKAGE
$(error Unable to find YUM or DNF on this system.)
endif


INSTALL_INSTALLED=$(TMP_DIR)/install-installed
INSTALL_NOT_INSTALLED=$(TMP_DIR)/install-not-installed
install:: $(TMP_DIR)
	rm -f "$(INSTALL_INSTALLED)" "$(INSTALL_NOT_INSTALLED)"
	@for PACKAGE in `find $(PRODUCTS_DIR) -name '*.rpm'`; do \
	    SHORT=`basename "$${PACKAGE}" | sed -e 's/.rpm$$//'` ; \
	    rpm --quiet -q "$${SHORT}" && LIST_OUT="$(INSTALL_INSTALLED)" || LIST_OUT="$(INSTALL_NOT_INSTALLED)" ; \
	    echo "$${PACKAGE}" >> "$${LIST_OUT}" ; \
	done
	@if [ -s "$(INSTALL_INSTALLED)" ]  ; then \
		xargs $(RUN_AS_ROOT) $(INSTALL_PACKAGE) -y reinstall < "$(INSTALL_INSTALLED)" ; \
	fi
	@if [ -s "$(INSTALL_NOT_INSTALLED)" ] ; then \
		xargs $(RUN_AS_ROOT) $(INSTALL_PACKAGE) -y install < "$(INSTALL_NOT_INSTALLED)" ; \
	fi



uninstall::
	rpm -q --specfile "$(SPEC)" | xargs $(RUN_AS_ROOT) $(INSTALL_PACKAGE) -y erase


# Copy the products to a destination named by PRODUCTS_DEST
install-products: $(PRODUCTS_DIR)
ifndef PRODUCTS_DEST
	@printf "\nERROR: No PRODUCTS_DEST defined for $@.\n\n"
	@false
endif
	@if [ ! -d "$(PRODUCTS_DEST)" ] ; then \
	    printf "\nERROR: $(PRODUCTS_DEST) is not a directory.\n\n" ; \
	    false ; \
	fi
	find "$(PRODUCTS_DIR)" -name '*.rpm' -exec cp {} "$(PRODUCTS_DEST)" \;


# Placeholder for running unit tests.
test::
	@true


# Make this available so the primitive build process can tell if
# loading up was successful.
UNIBUILD_MAKE_FULLY_INCLUDED := 1