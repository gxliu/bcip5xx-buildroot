#############################################################
#
# python3
#
#############################################################
PYTHON3_VERSION_MAJOR = 3.3
PYTHON3_VERSION       = $(PYTHON3_VERSION_MAJOR).0
PYTHON3_SOURCE        = Python-$(PYTHON3_VERSION).tar.bz2
PYTHON3_SITE          = http://python.org/ftp/python/$(PYTHON3_VERSION)

# Python needs itself and a "pgen" program to build itself, both being
# provided in the Python sources. So in order to cross-compile Python,
# we need to build a host Python first. This host Python is also
# installed in $(HOST_DIR), as it is needed when cross-compiling
# third-party Python modules.

HOST_PYTHON3_CONF_OPT += 	\
	--without-cxx-main 	\
	--disable-sqlite3	\
	--disable-tk		\
	--with-expat=system	\
	--disable-curses	\
	--disable-codecs-cjk	\
	--disable-nis		\
	--disable-unicodedata	\
	--disable-dbm		\
	--disable-gdbm		\
	--disable-bsddb		\
	--disable-test-modules	\
	--disable-bz2		\
	--disable-ssl

HOST_PYTHON3_MAKE_ENV = \
	PYTHON_MODULES_INCLUDE=$(HOST_DIR)/usr/include \
	PYTHON_MODULES_LIB="$(HOST_DIR)/lib $(HOST_DIR)/usr/lib"

HOST_PYTHON3_AUTORECONF = YES

define HOST_PYTHON3_CONFIGURE_CMDS
	(cd $(@D) && rm -rf config.cache; \
	        $(HOST_CONFIGURE_OPTS) \
		CFLAGS="$(HOST_CFLAGS)" \
		LDFLAGS="$(HOST_LDFLAGS)" \
                $(HOST_PYTHON3_CONF_ENV) \
		./configure \
		--prefix="$(HOST_DIR)/usr" \
		--sysconfdir="$(HOST_DIR)/etc" \
		$(HOST_PYTHON3_CONF_OPT) \
	)
endef

PYTHON3_DEPENDENCIES  = host-python3 libffi

HOST_PYTHON3_DEPENDENCIES = host-expat host-zlib

PYTHON3_INSTALL_STAGING = YES

ifeq ($(BR2_PACKAGE_PYTHON3_READLINE),y)
PYTHON3_DEPENDENCIES += readline
endif

ifeq ($(BR2_PACKAGE_PYTHON3_CURSES),y)
PYTHON3_DEPENDENCIES += ncurses
endif

ifeq ($(BR2_PACKAGE_PYTHON3_PYEXPAT),y)
PYTHON3_DEPENDENCIES += expat
PYTHON3_CONF_OPT += --with-expat=system
else
PYTHON3_CONF_OPT += --with-expat=none
endif

ifeq ($(BR2_PACKAGE_PYTHON3_SQLITE),y)
PYTHON3_DEPENDENCIES += sqlite
endif

ifeq ($(BR2_PACKAGE_PYTHON3_SSL),y)
PYTHON_DEPENDENCIES += openssl
endif

ifeq ($(BR2_PACKAGE_PYTHON3_BZIP2),y)
PYTHON_DEPENDENCIES += bzip2
endif

ifeq ($(BR2_PACKAGE_PYTHON3_ZLIB),y)
PYTHON3_DEPENDENCIES += zlib
endif

PYTHON3_CONF_ENV += \
	_PROJECT_BASE=$(PYTHON3_DIR) \
	_PYTHON_HOST_PLATFORM=$(BR2_HOSTARCH) \
	PYTHON_FOR_BUILD=$(HOST_PYTHON3_DIR)/python \
	PGEN_FOR_BUILD=$(HOST_PYTHON3_DIR)/Parser/pgen \
	ac_cv_have_long_long_format=yes \
	ac_cv_file__dev_ptmx=yes \
	ac_cv_file__dev_ptc=yes \

PYTHON3_CONF_OPT += \
	--without-cxx-main 	\
	--with-system-ffi	\
	--disable-pydoc		\
	--disable-test-modules	\
	--disable-lib2to3	\
	--disable-gdbm		\
	--disable-tk		\
	--disable-nis		\
	--disable-dbm

PYTHON3_MAKE_ENV = \
	_PROJECT_BASE=$(PYTHON3_DIR) \
	_PYTHON_HOST_PLATFORM=$(BR2_HOSTARCH) \
	PYTHON_MODULES_INCLUDE=$(STAGING_DIR)/usr/include \
	PYTHON_MODULES_LIB="$(STAGING_DIR)/lib $(STAGING_DIR)/usr/lib"

# python distutils adds -L$LIBDIR when linking binary extensions, causing
# trouble for cross compilation
define PYTHON3_FIXUP_LIBDIR
	$(SED) 's|^LIBDIR=.*|LIBDIR= $(STAGING_DIR)/usr/lib|' \
	   $(STAGING_DIR)/usr/lib/python$(PYTHON3_VERSION_MAJOR)/config-3.3m/Makefile
endef

PYTHON3_POST_INSTALL_STAGING_HOOKS += PYTHON3_FIXUP_LIBDIR

#
# Development files removal
#
define PYTHON3_REMOVE_DEVFILES
	rm -f $(TARGET_DIR)/usr/bin/python$(PYTHON3_VERSION_MAJOR)-config
	rm -f $(TARGET_DIR)/usr/bin/python3-config
endef

ifneq ($(BR2_HAVE_DEVFILES),y)
PYTHON3_POST_INSTALL_TARGET_HOOKS += PYTHON3_REMOVE_DEVFILES
endif

#
# Remove useless files. In the config/ directory, only the Makefile
# and the pyconfig.h files are needed at runtime.
#
define PYTHON3_REMOVE_USELESS_FILES
	for i in `find $(TARGET_DIR)/usr/lib/python$(PYTHON3_VERSION_MAJOR)/config-3.3m/ \
		-type f -not -name pyconfig.h -a -not -name Makefile` ; do \
		rm -f $$i ; \
	done
endef

PYTHON3_POST_INSTALL_TARGET_HOOKS += PYTHON3_REMOVE_USELESS_FILES

PYTHON3_AUTORECONF = YES

$(eval $(autotools-package))
$(eval $(host-autotools-package))
