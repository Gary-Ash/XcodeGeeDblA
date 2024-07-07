#!/usr/bin/env sh
if [ "${CONFIGURATION}" = "TestFlight" ]; then
	if [ -f "/opt/homebrew/bin/brew" ]; then
		export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
	fi

	if which magick >/dev/null; then
		iconDir="$SRCROOT/$PROJECT_NAME/Assets.xcassets/AppIcon.appiconset"
		mkdir -p "${TMPDIR}/${iconDir}"
		echo "${TMPDIR}/${iconDir}"
		cp -rf "${iconDir}" "${TMPDIR}/${iconDir}"

		for file in $(find "$iconDir" -name "*.png" -type f); do
			width=$(magick identify -format %w "$file")
			if [ "$width" = 1024 ]; then
				largeIcon="$file"
				break
			fi
		done

		version="$MARKETING_VERSION"
		build="$CURRENT_PROJECT_VERSION"
		caption="v${version}\nBuild: ${build}"
		width=$(magick identify -format %w ${largeIcon})
		height=$(magick identify -format %h ${largeIcon})
		band_height=$(((height * 47) / 100))
		band_position=$((height - band_height))
		text_position=$((band_position - 3))
		point_size=$(((13 * width) / 100))

		magick convert "${largeIcon}" -blur 10x8 /tmp/blurred.png
		magick convert "${largeIcon}" -gamma 0 -fill white -draw "rectangle 0,$band_position,$width,$height" /tmp/mask.png
		magick convert -size ${width}x${band_height} xc:none -fill 'rgba(0,0,0,0.2)' -draw "rectangle 0,0,$width,$band_height" /tmp/labels-base.png
		magick convert -background none -size ${width}x${band_height} -pointsize $point_size -fill white -gravity center -gravity South caption:"$caption" /tmp/labels.png
		magick convert "$largeIcon" /tmp/blurred.png /tmp/mask.png -composite /tmp/temp.png
		magick convert /tmp/temp.png /tmp/labels-base.png -geometry +0+$band_position -composite /tmp/labels.png -geometry +0+$text_position -geometry +${w}-${h} -composite "$largeIcon"

		#rm -f /tmp/*.png
		for file in $(find "$iconDir" -name "*.png" -type f); do
			dim=$(magick identify -format "%wx%h" "$file")
			if [ "$dim" != "1024x1024" ]; then
				magick convert "$largeIcon" -resize "$dim!" "$file"
			fi
		done
	else
		echo "warning: Image Magick not installed,  brew install imagemagick"
	fi
fi
exit 0
