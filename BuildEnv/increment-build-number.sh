#!/usr/bin/env sh
if [ "${CONFIGURATION}" = "Release" ] || [ "${CONFIGURATION}" = "TestFlight" ]; then
	cd "${PROJECT_DIR}"
	agvtool bump
fi
