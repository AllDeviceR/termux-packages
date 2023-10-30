TERMUX_PKG_HOMEPAGE=https://github.com/termux/termux-packages
TERMUX_PKG_DESCRIPTION="Dummy test for Flang toolchain"
TERMUX_PKG_LICENSE="Public Domain"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=0.1
TERMUX_PKG_SKIP_SRC_EXTRACT=true
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_BLACKLISTED_ARCHES="arm, i686"

termux_step_pre_configure() {
	termux_setup_flang
}

termux_step_make() {
	$FC $FCFLAGS $TERMUX_PKG_BUILDER_DIR/main.f90 -o hello-flang
}

termux_step_make_install() {
	install -Dm700 hello-flang $TERMUX_PREFIX/bin/hello-flang
}
