TERMUX_PKG_HOMEPAGE="https://p11-glue.github.io/p11-glue/p11-kit.html"
TERMUX_PKG_DESCRIPTION="Provides a way to load and enumerate PKCS#11 modules"
TERMUX_PKG_LICENSE="BSD 3-Clause"
TERMUX_PKG_MAINTAINER="@leapofazzam123"
TERMUX_PKG_VERSION="0.25.1"
TERMUX_PKG_SRCURL="https://github.com/p11-glue/p11-kit/releases/download/$TERMUX_PKG_VERSION/p11-kit-$TERMUX_PKG_VERSION.tar.xz"
TERMUX_PKG_SHA256=b6f326925725c8c45484e6daf78cdc73428a86296b6b99078255017f1bacdafc
TERMUX_PKG_DEPENDS="libffi, libtasn1"
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="--without-trust-paths --disable-static"
TERMUX_PKG_AUTO_UPDATE=true

termux_step_post_get_source() {
	# Do not forget to bump revision of reverse dependencies and rebuild them
	# after SOVERSION is changed.
	local _SOVERSION=0

	local a
	for a in CURRENT AGE; do
		local _LT_${a}=$(sed -En 's/^P11KIT_'"${a}"'=([0-9]+).*/\1/p' \
				configure.ac)
	done
	local v=$(( _LT_CURRENT - _LT_AGE ))
	if [ ! "${_LT_CURRENT}" ] || [ "${v}" != "${_SOVERSION}" ]; then
		termux_error_exit "SOVERSION guard check failed."
	fi
}

termux_step_pre_configure() {
	autoreconf -fi
}
