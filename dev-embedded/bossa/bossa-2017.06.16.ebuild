# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit eutils git-r3

MY_PN=BOSSA

EGIT_REPO_URI="https://github.com/shumatech/${PN}.git"
EGIT_COMMIT=26154375695f345491bba158d57177aa231d6765

DESCRIPTION="BOSSA is a flash programming utility for Atmel's SAM family of flash-based ARM microcontrollers."
HOMEPAGE="https://github.com/shumatech/BOSSA"

LICENSE="BSD 3-clause "New" or "Revised" License"
SLOT="0"
IUSE=""
KEYWORDS="~amd64 ~arm ~x86"

RDEPEND="x11-libs/wxGTK
"
DEPEND="${RDEPEND}
"

PATCHES="${FILESDIR}/Fix_null_character_pointer_comparisson.patch"

src_install() {
	dobin bin/bossa*
}
