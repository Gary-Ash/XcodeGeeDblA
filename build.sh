#!/usr/bin/env bash
set -euo pipefail
#*****************************************************************************************
# build.sh
#
# Build, codesign, and notarize XcodeGeeDblA.app for distribution
#
# Author   :  Gary Ash <gary.ash@icloud.com>
# Created  :  13-Mar-2026  5:06pm
# Modified :  13-Mar-2026  6:30pm
#
# Copyright © 2026 By Gary Ash All rights reserved.
#*****************************************************************************************

readonly APP_NAME="XcodeGeeDblA"
readonly SCHEME="XcodeGeeDblA"
readonly PROJECT="${APP_NAME}.xcodeproj"
readonly NOTARY_PROFILE="notary-profile"
readonly BUILD_DIR="build"
readonly PROJECT_FILE="${PROJECT}/project.pbxproj"

TEAM_ID=""

cleanup() {
	local exit_code="${?}"
	if [[ -n "${TEAM_ID}" ]]; then
		sed -i '' "s/DEVELOPMENT_TEAM = ${TEAM_ID};/DEVELOPMENT_TEAM = \"\";/g" "${PROJECT_FILE}"
	fi
	rm -f AppGroup.swift
	rm -rf "${BUILD_DIR}"
	rm -f "${APP_NAME}.app.zip"
	exit "${exit_code}"
}

main() {
	trap cleanup EXIT

	SIGNING_IDENTITY=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | sed 's/.*"\(.*\)".*/\1/')

	if [[ -z "${SIGNING_IDENTITY}" ]]; then
		echo "Error: No Developer ID Application certificate found in keychain" >&2
		exit 1
	fi

	TEAM_ID=$(echo "${SIGNING_IDENTITY}" | sed 's/.*(\([A-Z0-9]*\))$/\1/')

	if [[ -z "${TEAM_ID}" ]]; then
		echo "Error: Could not extract team ID from signing identity" >&2
		exit 1
	fi

	echo "Using signing identity: [${SIGNING_IDENTITY}]"
	echo "Using team ID: [${TEAM_ID}]"

	sed -i '' "s/DEVELOPMENT_TEAM = \"\";/DEVELOPMENT_TEAM = ${TEAM_ID};/g" "${PROJECT_FILE}"

	rm -rf "${BUILD_DIR}"
	rm -rf "${APP_NAME}.app"

	xcodebuild -project "${PROJECT}" \
		-scheme "${SCHEME}" \
		-configuration Release \
		-arch arm64 \
		-derivedDataPath "${BUILD_DIR}" \
		ONLY_ACTIVE_ARCH=NO \
		CODE_SIGN_IDENTITY="${SIGNING_IDENTITY}" \
		DEVELOPMENT_TEAM="${TEAM_ID}" \
		CODE_SIGN_STYLE=Manual \
		clean build

	cp -R "${BUILD_DIR}/Build/Products/Release/${APP_NAME}.app" "${APP_NAME}.app"

	codesign --force --sign "${SIGNING_IDENTITY}" \
		--options runtime \
		--deep "${APP_NAME}.app"

	codesign --verify --verbose "${APP_NAME}.app"
	ditto -c -k --keepParent "${APP_NAME}.app" "${APP_NAME}.app.zip"

	xcrun notarytool submit "${APP_NAME}.app.zip" \
		--keychain-profile "${NOTARY_PROFILE}" \
		--wait

	xcrun stapler staple "${APP_NAME}.app"
}

main "${@}"
