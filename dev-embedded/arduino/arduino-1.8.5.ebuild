# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6
JAVA_PKG_IUSE="doc"
IUSE='+java +arduino-core-avr arduino-core-samd udooqdl'

inherit java-pkg-opt-2 java-ant-2 user

DESCRIPTION="An open-source AVR electronics prototyping platform"
HOMEPAGE="http://arduino.cc/"
SRC_URI="https://github.com/arduino/Arduino/archive/${PV}.tar.gz
	udooqdl? ( https://github.com/UDOOboard/arduino-board-package/archive/boardmanager.tar.gz )"

LICENSE="GPL-2 LGPL-2.1 CC-BY-SA-3.0"
SLOT="0"
KEYWORDS="~amd64 ~arm ~x86"

# note this does not work with current QA_* vars, not even with
# QA_PREBUILT and exact file names/paths...
# The offending files are all .elf firmware and prebuilt embedded static
# libs (about 10 files in total) required for specific hardware.
RESTRICT="strip binchecks"

#HTML_DOCS=(  )

# Todo: Remaining bundled libs:
#   commons-exec
#   jackson-module-mrbean
#   java-semver
#   rsyntaxtextarea-arduino

JDEPEND="
	dev-java/batik:1.9
	dev-java/bcpg:1.58
	dev-java/bcprov:1.58
	dev-java/commons-codec:0
	dev-java/commons-compress:0
	dev-java/commons-httpclient:3
	dev-java/commons-lang:3.3
	dev-java/commons-logging:0
	>=dev-java/commons-net-3.2:0
	dev-java/jackson:2
	dev-java/jackson-annotations:2
	dev-java/jackson-databind:2
	dev-java/jackson-modules-base:2
	dev-java/jmdns:0
	dev-java/jna:0
	dev-java/jsch:0
	>=dev-java/jssc-2.8.0-r1:0
	dev-java/slf4j-simple
	dev-java/xml-commons-external:1.3
	dev-java/xmlgraphics-commons:2
	<dev-util/astyle-3[java]
	dev-embedded/listserialportsc"

RDEPEND="
	java? ( ${JDEPEND}
		>=virtual/jre-1.8
		dev-embedded/arduino-builder
		dev-embedded/avrdude
		dev-embedded/uisp )
	|| (
		arduino-core-samd? ( >=dev-embedded/bossa-1.8 )
		udooqdl? ( dev-embedded/bossa[udooqdl=] )
	)"

DEPEND="
	java? ( ${JDEPEND}
		>=virtual/jdk-1.8 )
	virtual/udev"

PATCHES=(
	"${FILESDIR}/${P}"-startup.patch
	"${FILESDIR}/${P}"-platform.patch
	"${FILESDIR}"/${P}-remove-avr-gcc-tools-dependency.patch
)

EANT_GENTOO_CLASSPATH="batik-1.9,bcpg-1.58,bcprov-1.58,commons-codec,commons-compress,commons-httpclient-3,commons-lang-3.3,commons-logging,commons-net,jackson-2,jackson-annotations-2,jackson-databind-2,jackson-modules-base-2,jmdns,jna,jsch,jssc,xml-commons-external-1.3,xmlgraphics-commons-2"
EANT_EXTRA_ARGS="-Djava.net.preferIPv4Stack=true"
EANT_BUILD_TARGET="build"
JAVA_ANT_REWRITE_CLASSPATH="yes"

S="${WORKDIR}/Arduino-${PV}"
CORE="/usr/share/arduino"
SHARE="/usr/share/${PN}"
BOARDS="${WORKDIR}/arduino-board-package-boardmanager"

pkg_setup() {
	# group may not exist yet
	enewgroup uucp

	java-pkg-opt-2_pkg_setup
}

src_prepare() {
	# Remove bundled libraries to ensure the system libraries are used
	# Elegant, but breaks the build :(
	#rm -f {arduino-core,app}/lib/{apple*,batik*,bcpg*,bcprov*,commons-[^e]*,jackson-*,jmdns*,jna*,jsch*,jssc*,xmlgraphics*} || die

	if use udooqdl ; then
		mkdir -p "${S}"/hardware/UDOO
		cp -R "${BOARDS}"/udoo/sam "${S}"/hardware/UDOO/ || die
	fi

	default

	use udooqdl && eapply "${FILESDIR}"/${PN}-fix-utoa-to-match-name.patch \
		"${FILESDIR}"/${PN}-sam-platform-toolchain.patch
}

src_compile() {
	if use java; then
		EANT_EXTRA_ARGS+=" -Dlight_bundle=1 -Dno_arduino_builder=1"
		use arm && EANT_EXTRA_ARGS+=" -Dplatform=linux32"
		use x86 && EANT_EXTRA_ARGS+=" -Dplatform=linux32"
		use amd64 && EANT_EXTRA_ARGS+=" -Dplatform=linux64"
		use doc || EANT_EXTRA_ARGS+=" -Dno_docs=1"
		echo "eant -f build/build.xml "${EANT_EXTRA_ARGS}""
		eant -f build/build.xml "${EANT_EXTRA_ARGS}"
	fi
}

src_install() {
	insinto "${SHARE}"
	doins -r hardware

	# Use system arduino-builder
	dosym /usr/bin/arduino-builder "${SHARE}/arduino-builder"
	dosym /usr/share/arduino-builder/platform.keys.rewrite.txt "${SHARE}/hardware/platform.keys.rewrite.txt"
	dosym /usr/share/arduino-builder/platform.txt "${SHARE}/hardware/platform.txt"

	# hardware/tools/avr needs to exist or arduino-builder will
	# complain about missing required -tools arg
	dodir "${SHARE}/hardware/tools/avr"

	#Install IDE
	if use java; then
		cd "${S}"/build/linux/work || die
		rm -v lib/{apple*,batik*,bcpg*,bcprov*,commons-[^e]*,jackson*,jmdns*,jna*,jsch*,jssc*,slf4j*,xml*}
		rm -v lib/*.so
		doins -r lib examples

		java-pkg_dojar lib/*.jar
		java-pkg_dolauncher ${PN} \
			    --pwd "${CORE}" \
			    --main "processing.app.Base" \
			    --java_args "-DAPP_DIR=/usr/share/${PN} -DCORE_DIR=${CORE} -splash:/usr/share/${PN}/lib/splash.png"

		if use doc; then
			dodoc revisions.txt "${S}"/README.md
			insinto /usr/share/doc/"${P}"
			doins -r reference
			insinto /usr/share/doc/"${P}"/cli
			doins -r "${FILESDIR}"/BlinkWithoutDelay
			docompress -x /usr/share/doc/${PF}/cli /usr/share/doc/${PF}/reference
		fi

		# set permissions for group write, allows compiling Makefile example
		fowners -R root:uucp /usr/share/arduino/hardware
		fperms -R g+w /usr/share/arduino/hardware

		# Install menu and icons
		domenu "${FILESDIR}/${PN}.desktop"
		local sz
		for sz in `ls lib/icons | sed -e 's/\([0-9]*\)x[0-9]*/\1/'`; do
			newicon -s $sz \
				"lib/icons/${sz}x${sz}/apps/arduino.png" \
				"${PN}.png"
		done
	fi

	# adjust rules for board-specific devices
	use udooqdl && udev_dorules "${FILESDIR}"/80-udoo-${PN}.rules
}

pkg_postinst() {
	elog
	elog "To be able to use the Arduino IDE you need to aquire the avr toolchain,"
	elog "i.e., install crossdev-99999999 and run: "
	elog " "
	elog "   USE="-nls -openmp -pch -sanitize -vtv" "
	elog "     crossdev -t avr -s4 --without-headers "
	elog " "
	elog " and set the kernel options: "
	elog "   Device Drivers -> USB support -> USB Serial Converter support -> USB FTDI Single Port Serial Driver "
	elog "   Device Drivers -> USB support -> USB Modem \(CDC ACM\) support "
	elog " "
	elog "Note with the latest crossdev you may need to specify an output overlay."
	elog "You should also be in the uucp group; this ebuild provides uucp"
	elog "group write access to $SHARE/hardware"
	elog " "
	elog "To remove this access, run 'sudo chown root:root -R $SHARE/hardware'"
	elog " "
	elog " Some resources:"
	elog "   http://playground.arduino.cc/linux/gentoo "
	elog "   https://bugs.gentoo.org/show_bug.cgi?id=525882 "
	elog "   http://forums.gentoo.org/viewtopic-t-907860.html "
	elog " "
	elog "Copy the example BlinkWithoutDelay folder from the docs/cli"
	elog "folder for a command line example with Makefile."
	elog
}
