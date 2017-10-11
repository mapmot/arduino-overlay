# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5
JAVA_PKG_IUSE="doc"

inherit eutils java-pkg-2 java-ant-2

DESCRIPTION="An open-source AVR electronics prototyping platform"
HOMEPAGE="http://arduino.cc/"
SRC_URI="https://github.com/arduino/Arduino/archive/${PV}.tar.gz"

LICENSE="GPL-2 LGPL-2.1 CC-BY-SA-3.0"
SLOT="0"
KEYWORDS="~amd64 ~x86"

# Todo: Remaining bundled libs:
#   commons-exec
#   jackson-module-mrbean
#   java-semver
#   rsyntaxtextarea-arduino
#   xml-apis
#   xml-apis-ext

COMMONDEP="
dev-java/batik:1.8
dev-java/bcpg:1.52
dev-java/bcprov:1.52
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
dev-java/xmlgraphics-commons:2
dev-util/astyle[java]
dev-embedded/listserialportsc"

RDEPEND="${COMMONDEP}
dev-embedded/arduino-core
>=virtual/jre-1.8"

DEPEND="${COMMONDEP}
>=virtual/jdk-1.8"

EANT_GENTOO_CLASSPATH="batik-1.8,bcpg-1.52,bcprov-1.52,commons-codec,commons-compress,commons-httpclient-3,commons-lang-3.3,commons-logging,commons-net,jackson-2,jackson-annotations-2,jackson-databind-2,jackson-modules-base-2,jmdns,jna,jsch,jssc,xmlgraphics-commons-2"
EANT_EXTRA_ARGS="-Djava.net.preferIPv4Stack=true"
EANT_BUILD_TARGET="build"
JAVA_ANT_REWRITE_CLASSPATH="yes"

S="${WORKDIR}/Arduino-${PV}"
CORE="/usr/share/arduino-core"

java_prepare() {
	# Remove bundled libraries to ensure the system libraries are used
	rm -f {arduino-core,app}/lib/{apple*,batik*,bcpg*,bcprov*,commons-[^e]*,jackson*,jmdns*,jna*,jsch*,jssc*,xmlgraphics*} || die

	epatch "${FILESDIR}/${P}-build.xml.patch"
	if ! use doc; then
	    epatch "${FILESDIR}/${P}-no-doc.patch"
	fi
	sed -e 's/<download-library[^>]*>//g' -i build/build.xml

	epatch "${FILESDIR}/${P}-startup.patch"

	rm -rf {arduino-core,app}/src/processing/app/macosx
	rm -rf arduino-core/src/processing/app/linux/GTKLookAndFeelFixer.java
}

src_compile() {
	eant -f build/build.xml
}

src_install() {
	cd "${S}"/build/linux/work || die

	java-pkg_dojar lib/*.jar
	java-pkg_dolauncher ${PN} \
			    --pwd "${CORE}" \
			    --main "processing.app.Base" \
			    --java_args "-DAPP_DIR=/usr/share/${PN} -DCORE_DIR=${CORE} -splash:/usr/share/${PN}/lib/splash.png"

	# Install libraries
	insinto "/usr/share/${PN}"

	rm -fr lib/*.jar lib/*.so
	doins -r lib dist

	if use doc; then
		dodoc revisions.txt "${S}"/README.md
		dohtml -r reference
	fi

	# Install menu and icons
	domenu "${FILESDIR}/${PN}.desktop"
	for sz in `ls lib/icons | sed -e 's/\([0-9]*\)x[0-9]*/\1/'`; do
		newicon -s $sz \
			"lib/icons/${sz}x${sz}/apps/arduino.png" \
			"${PN}.png"
	done
}
