
# RPM package build for Octez
#
# (c) Chris Pinnock 2023, Supplied under a MIT license.
# see ../pkg-common/utils.sh for more detail

set -eu

# Setup
#
myhome=scripts/rpm
common=scripts/pkg-common

#shellcheck disable=SC1091
. ${common}/utils.sh
protocols=${protocols:?protocols not specified}

warnings
pkg_vers=getOctezVersion

### RPM specifc

# Checking prerequisites
#
if ! which rpmbuild >/dev/null 2>&1; then
	echo "Needs to run on a system with rpmbuild in path" >&2
	echo "yum install rpmdevtools"
	exit 2
fi

rpmdev-setuptree
rpmbuild_root=$HOME/rpmbuild	# Seems to be standard
spec_dir="${rpmbuild_root}/SPECS"
rpm_dir="${rpmbuild_root}/RPMS"
src_dir="${rpmbuild_root}/SOURCES"

# Get the local architecture
#
rpm_arch=$(uname -m)

# For each spec file in the directory, build a package
#
for specfile in "$myhome"/*spec.in; do
	pg=$(basename "$specfile" | sed -e 's/-spec.in$//g')
	echo "===> Building package $pg v$pkg_vers rev $OCTEZ_PKGREV"

	if [ -f "${common}/${pg}-binaries.in" ]; then
	  expand_PROTOCOL "${common}/${pg}-binaries.in" > "${common}/${pg}-binaries"
	fi

	# Derivative variables
	#
	rpm_name=${OCTEZ_PKGNAME}-${pg}
	init_name=${OCTEZ_REALNAME}-${pg}
	rpm_fullname="${rpm_name}-${pkg_vers}-${OCTEZ_PKGREV}.${rpm_arch}.rpm"
  if [ -f "${common}/${pg}-binaries" ]; then
    binaries=$(cat "${common}/${pg}-binaries" 2>/dev/null)
  fi
  zcashstuff=
  if [ -f "${common}/${pg}-zcash" ]; then
    zcashstuff=$(cat "${common}/${pg}-zcash" 2>/dev/null)
  fi

	if [ -f "$rpm_fullname" ]; then
		echo "built already - skipping"
    continue
	fi

	tar_name=${rpm_name}-${pkg_vers}
	# Populate the staging directory with control scripts
	# binaries and configuration as appropriate
	#
	staging_dir="_rpmbuild"
	build_dir="${staging_dir}/${tar_name}"

	rm -rf "${staging_dir}"
	mkdir -p "${build_dir}"

	if [ -n "$binaries" ]; then
		echo "=> Populating directory with binaries"
		mkdir -p "${build_dir}/usr/bin"
		for bin in ${binaries}; do
			echo "${bin}"
			install -s -t "${build_dir}/usr/bin" "${bin}"
		done
	fi


	# init.d scripts
	#
	initdScripts "${common}/${pg}.initd.in" ${init_name} ${build_dir}
  	if [ "$pg" = "baker" ]; then
		initdScripts "${common}/vdf.initd.in" octez-vdf \
			${build_dir}
	fi


	# Configuration files
	#
	if [ -f "${common}/${pg}.conf" ]; then
		echo "=> Config files"
		mkdir -p "${build_dir}/etc/octez"
		expand_PROTOCOL "${common}/${pg}.conf" > "${build_dir}/etc/octez/${pg}.conf"
	fi

	# Zcash parameters must ship with the node
	#
	if [ -n "${zcashstuff}" ]; then
		echo "=> Zcash"
		mkdir -p "${build_dir}/usr/share/zcash-params"
		for shr in ${zcashstuff}; do
			cp "_opam/share/zcash-params/${shr}" "${build_dir}/usr/share/zcash-params"
		done
	fi

	# Edit the spec file to contain real values
	#
	spec_file="${pg}.spec"
	sed -e "s/@ARCH@/${rpm_arch}/g" -e "s/@VERSION@/$pkg_vers/g" \
		-e "s/@REVISION@/${OCTEZ_PKGREV}/g" \
		-e "s/@MAINT@/${OCTEZ_PKGMAINTAINER}/g" \
		-e "s/@PKG@/${rpm_name}/g" \
		-e "s/@DPKG@/${OCTEZ_PKGNAME}/g" \
		-e "s/@FAKESRC@/${tar_name}.tar.gz/g" < "$specfile" \
		> "${spec_dir}/${spec_file}"

	# Stage the package
	#
	echo "=> Staging ${pg}"
	(cd ${staging_dir} && tar zcf "${src_dir}/${tar_name}.tar.gz" "${tar_name}" )

	# Build the package
	#
	echo "=> Constructing RPM package ${rpm_fullname}"
	_flags="--quiet"
	rpmbuild -bb ${_flags} "${spec_dir}/${spec_file}"
	if [ -f "${rpm_dir}/${rpm_arch}/${rpm_fullname}" ]; then
    mv "${rpm_dir}/${rpm_arch}/${rpm_fullname}" .
  fi
done
