# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit eutils

MY_PN="bossac"
MY_PV="1.3a-1.0"
MY_P="${MY_PN}-${MY_PV}"

if [[ ${PV} == "9999" ]] ; then
	EGIT_REPO_URI="https://github.com/UDOOboard/${MY_PN}.git"
	inherit git-r3
	KEYWORDS=""
else
	SRC_URI="https://github.com/UDOOboard/${MY_PN}/archive/v${MY_PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~arm"
fi

DESCRIPTION="Udoo fork of bossa flash programming utility for Atmel's SAM family of flash-based ARM microcontrollers (only useful on Udoo quad/dual board)."
HOMEPAGE="https://github.com/UDOOboard/bossac"

LICENSE="BSD 3-clause "New" or "Revised" License"
SLOT="0"
IUSE="+udooqdl"

RDEPEND="
"
DEPEND="${RDEPEND}
"

PATCHES=( "${FILESDIR}"/${P}-fix-flags.patch
	"${FILESDIR}"/${P}-fix_null_character_pointer_comparisson.patch )

S="${WORKDIR}"/${MY_P}

src_compile() {
	emake -C udoo
}

src_install() {
	dobin udoo/bin/bossa*
}
