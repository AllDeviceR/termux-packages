termux_setup_flang() {
    if [ "$TERMUX_ON_DEVICE_BUILD" = true ]; then
		if [[ "$TERMUX_APP_PACKAGE_MANAGER" = "apt" && "$(dpkg-query -W -f '${db:Status-Status}\n' flang 2>/dev/null)" != "installed" ]] ||
			[[ "$TERMUX_APP_PACKAGE_MANAGER" = "pacman" && ! "$(pacman -Q flang 2>/dev/null)" ]]; then
			echo "Package 'flang' is not installed."
			echo "You can install it with"
			echo
			echo "  pkg install flang"
			echo
			echo "  pacman -S flang"
			echo
			exit 1
		fi
        export FC="flang"
        export FCFLAGS=""
		return
	fi

	local _version="dev%2Fr26b"
	local _clang_toolchain_url="https://github.com/licy183/ndk-toolchain-clang-with-flang/releases/download/$_version/package-install.tar.bz2"
	local _flang_toolchain_url="https://github.com/licy183/ndk-toolchain-clang-with-flang/releases/download/$_version/package-flang-host.tar.bz2"
	local _flang_aarch64_libs_url="https://github.com/licy183/ndk-toolchain-clang-with-flang/releases/download/$_version/package-flang-aarch64.tar.bz2"
	local _flang_x86_64_libs_url="https://github.com/licy183/ndk-toolchain-clang-with-flang/releases/download/$_version/package-flang-x86_64.tar.bz2"

	local _clang_toolchain_checksum="f0e447846e336093a7d175fa3e6d8874ed276c6cc1cbbf0b1e19533dbca56a28"
	local _flang_toolchain_checksum="aca0b6155a6c0ff68ff65fc1e134de5b8c06461bb388acc1191dfebc1e93cf0c"
	local _flang_aarch64_libs_checksum="2963b30e1b1b41f55357fb8f14fecb2218e5b876bd647e043d517fff30e90e94"
	local _flang_x86_64_libs_checksum="5787bfbaf5675f0d6a3bd4d319dcb0e1ac9a90b7797b3a46e9888c3b4ad33142"

	local _flang_toolchain_cache_dir="$TERMUX_COMMON_CACHEDIR/flang-toolchain-cache"
	mkdir -p $_flang_toolchain_cache_dir

	local _clang_toolchain_file="$_flang_toolchain_cache_dir/$(basename "$_clang_toolchain_url")"
	local _flang_toolchain_file="$_flang_toolchain_cache_dir/$(basename "$_flang_toolchain_url")"
	local _flang_aarch64_libs_file="$_flang_toolchain_cache_dir/$(basename "$_flang_aarch64_libs_url")"
	local _flang_x86_64_libs_file="$_flang_toolchain_cache_dir/$(basename "$_flang_x86_64_libs_url")"

	termux_download $_clang_toolchain_url $_clang_toolchain_file $_clang_toolchain_checksum
	termux_download $_flang_toolchain_url $_flang_toolchain_file $_flang_toolchain_checksum
	termux_download $_flang_aarch64_libs_url $_flang_aarch64_libs_file $_flang_aarch64_libs_checksum
	termux_download $_flang_x86_64_libs_url $_flang_x86_64_libs_file $_flang_x86_64_libs_checksum

	local _flang_toolchain_version=0

	local _termux_toolchain_name="$(basename "$TERMUX_STANDALONE_TOOLCHAIN")"

	local FLANG_FOLDER=
	if [ "${TERMUX_PACKAGES_OFFLINE-false}" = "true" ]; then
		FLANG_FOLDER="$TERMUX_SCRIPTDIR/build-tools/$_termux_toolchain_name-flang-v$_flang_toolchain_version"
	else
		FLANG_FOLDER="$TERMUX_COMMON_CACHEDIR/$_termux_toolchain_name-flang-v$_flang_toolchain_version"
	fi

	if [ ! -d "$FLANG_FOLDER" ]; then
		local FLANG_FOLDER_TMP="$FLANG_FOLDER"-tmp
		rm -rf "$FLANG_FOLDER_TMP"
		mkdir -p "$FLANG_FOLDER_TMP"
		cd "$FLANG_FOLDER_TMP"
		tar xf $_clang_toolchain_file -C $FLANG_FOLDER_TMP --strip-components=4
		tar xf $_flang_toolchain_file -C $FLANG_FOLDER_TMP --strip-components=1
		cp -Rf $TERMUX_STANDALONE_TOOLCHAIN/sysroot $FLANG_FOLDER_TMP/

		tar xf $_flang_aarch64_libs_file -C $FLANG_FOLDER_TMP/sysroot/usr/lib/aarch64-linux-android --strip-components=1
		tar xf $_flang_x86_64_libs_file -C $FLANG_FOLDER_TMP/sysroot/usr/lib/x86_64-linux-android --strip-components=1

		local host_plat
		local tool
		for host_plat in aarch64-linux-android armv7a-linux-androideabi i686-linux-android x86_64-linux-android; do
			cat <<- EOF > $FLANG_FOLDER_TMP/bin/${host_plat}-flang-new
			#!/usr/bin/env bash
			if [ "\$1" != "-cpp" ] && [ "\$1" != "-fc1" ]; then
				\`dirname \$0\`/flang-new --target=${host_plat}${TERMUX_PKG_API_LEVEL} -D__ANDROID_API__=$TERMUX_PKG_API_LEVEL "\$@"
			else
				# Target is already an argument.
				\`dirname \$0\`/flang-new "\$@"
			fi
			EOF
			chmod u+x $FLANG_FOLDER_TMP/bin/${host_plat}-flang-new
			cp $FLANG_FOLDER_TMP/bin/${host_plat}-flang-new \
				$FLANG_FOLDER_TMP/bin/${host_plat}${TERMUX_PKG_API_LEVEL}-flang-new
		done

		cp $FLANG_FOLDER_TMP/bin/armv7a-linux-androideabi-flang-new \
			$FLANG_FOLDER_TMP/bin/arm-linux-androideabi-flang-new
		cp $FLANG_FOLDER_TMP/bin/armv7a-linux-androideabi-flang-new \
			$FLANG_FOLDER_TMP/bin/arm-linux-androideabi${TERMUX_PKG_API_LEVEL}-flang-new

		mv "$FLANG_FOLDER_TMP" "$FLANG_FOLDER"
	fi

	export PATH="$FLANG_FOLDER/bin:$PATH"

	export FC=$TERMUX_HOST_PLATFORM-flang-new
	export FCFLAGS="--target=$CCTERMUX_HOST_PLATFORM -D__ANDROID_API__=$TERMUX_PKG_API_LEVEL"
}
