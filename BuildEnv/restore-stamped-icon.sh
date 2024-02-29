#!/usr/bin/env sh
if [ "${CONFIGURATION}" = "TestFlight" ]; then
	if [ -f "/opt/homebrew/bin/brew" ]; then
		export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
	fi
	if which magick >/dev/null; then
		iconDir="${SRCROOT}/${PROJECT_NAME}/Assets.xcassets/AppIcon.appiconset/"
		cp -rf "${TMPDIR}/${iconDir}" "${iconDir}"
	fi
fi
