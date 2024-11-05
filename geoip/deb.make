#
# Generic Makefile for Debian packagess
#

#
# NO USER-SERVICEABLE PARTS BELOW THIS LINE
#

ifndef UNIBUILD_PACKAGE_MAKE
$(error Include unibuild-package.make, not an environment-specific template.)
endif

# Don't expect user interaction
RUN_AS_ROOT += DEBIAN_FRONTEND=noninteractive

# TODO: --build flag should be removed after we can get an original
# tarball for all build methods (tarball/source directory/none)


ifeq ($(shell id -u),0)
  ROOT_CMD :=
else
  ROOT_CMD := --root-cmd=sudo
endif


# This target is for internal use only.
_built:
	@if [ ! -d '$(PRODUCTS_DIR)' ] ; \
	then \
		printf "\nPackage is not built.\n\n" ; \
		false ; \
	fi

install:: _built
	@printf "\nInstall packages:\n"
	@find '$(PRODUCTS_DIR)' -name '*.deb' \
		| fgrep -v -- '-build-deps' \
		| sed -e 's|^.*/||; s/^/  /'
	@echo
	@find '$(PRODUCTS_DIR)' -name '*.deb' \
		| fgrep -v -- '-build-deps' \
		| sed -e 's|^|./|g' \
		| $(RUN_AS_ROOT) xargs apt-get -y --reinstall install


# Copy the products to a destination named by PRODUCTS_DEST and add
# additional info to the repo.

REPO_UNIBUILD := $(PRODUCTS_DEST)/unibuild
DEBIAN_PACKAGE_ORDER := $(REPO_UNIBUILD)/debian-package-order

install-products: $(PRODUCTS_DIR)
ifndef PRODUCTS_DEST
	@printf "\nERROR: No PRODUCTS_DEST defined for $@.\n\n"
	@false
endif
	@if [ ! -d "$(PRODUCTS_DEST)" ] ; then \
	    printf "\nERROR: $(PRODUCTS_DEST) is not a directory.\n\n" ; \
	    false ; \
	fi
	find "$(PRODUCTS_DIR)" \( \
		-name "*.deb" -o -name "*.dsc" -o -name "*.changes" -o -name "*.buildinfo" -o -name "*.build" -o -name "*.tar.*" -o -name "*.diff.gz" \
		\) -exec cp {} "$(PRODUCTS_DEST)" \;
	mkdir -p "$(REPO_UNIBUILD)"
	sed -e ':a;/\\\s*$$/{N;s/\\\s*\n//;ba}' "$(CONTROL)" \
		| awk '$$1 == "Source:" { print $$2; exit }' \
		>> "$(DEBIAN_PACKAGE_ORDER)"


# TODO: This doesn't work.
uninstall::
	@printf "\nUninstall packages:\n"
	@awk '$$1 == "Package:" { print $$2 }' ./unibuild/unibuild-packaging/deb/control \
	| ( while read PACKAGE ; do \
	    echo "    $${PACKAGE}" ; \
	    yes | $(RUN_AS_ROOT) apt remove -f $$PACKAGE ; \
	    done )


dump:: _built
	@find '$(PRODUCTS_DIR)' -name "*.deb" \
	| ( \
	    while read DEB ; \
	    do \
	        echo "$$DEB" | sed -e 's|^$(PRODUCTS_DIR)/||' | xargs -n 1 printf "\n%s:\n" ; \
	        dpkg --contents "$$DEB" ; \
	        echo ; \
	    done)

# Make this available so the primitive build process can tell if
# loading up was successful.
UNIBUILD_MAKE_FULLY_INCLUDED := 1