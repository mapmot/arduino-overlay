Symlinking the local toolchain into /usr/share/${PN}/hardware/tools/avr/bin/ is retarded, because:

	* The location of the toolchain is defined in platform* which gets patched and installed with arduino-builder
	* If you are using arduino, you are using arduino-builder and you already have the correct location in platform*
	* If you are not using arduino-builder, you are using some other way (Makefile) to get to the toolchain, and don't care about what's in platform*

Before asking for help, make sure you read https://bugs.gentoo.org/348991

There is no longer a separation into arduino-[core,ide,blah]

* To get the IDE, use the java flag (enabled by default)
* To get the core, use the arduino-core-xxx flags (only arduino-core-avr available for now, enabled by default)

TODO:

* Add aditional cores, via flags, i.e. arduino-core-samd. Needs updated cross-arm-none-eabi-newlib with the nano flag. If anybody has gotten the gentoo newlib working with Arduino, let me know!

# arduino-overlay
Arduino IDE overlay for gentoo linux

Includes arduino overlay with many bundled dependancies removed:
 * dev-embedded/arduino-builder has a seperate ebuild and is built from go source
 * dev-embedded/avr-libc has been updated to 2.0.0 to work with gcc-5 (solves cannot find crtatmega328p.a link errors)
 * uses system libserialport and astyle
 * platform files havee ben patched to point to system avr-g++ and friends in /usr/bin
 * arduino-core is split from arduino-ide so users can use a different editor.  arduino-core does NOT require java.

The file package.keywords is included in the top level.  This is a first crack at the list of packages that should be ~arch keyworded.  Copy this file to /etc/portage/package.keywords/arduino

# layman

To use this overlay with layman, add the URL to the layman.xml file to
layman.cfg:

```
overlays  :
    https://api.gentoo.org/overlays/repositories.xml
    https://raw.github.com/sarnold/arduino-overlay/master-local/layman.xml
```

Run the following command as root:

```
 layman -f -a arduino -o https://raw.github.com/sarnold/arduino-overlay/master-local/layman.xml
```

and answer "y" at the prompt.  Then run "emerge arduino -vp" and check the
dependencies (if you are already set for ~arch keywords it should Just Work).
