/*****************************************************************************************
 * Constants.swift
 *
 *
 *
 * Author   :  Gary Ash <gary.ash@icloud.com>
 * Created  :   7-Jul-2024  3:36pm
 * Modified :  13-Jul-2024 10:18pm
 * 
 * Copyright © 2024 By Gary Ash All rights reserved.
 ****************************************************************************************/

import Foundation

let SupportedContentUTIs = [
	"public.swift-source",
	"com.apple.dt.playground",
	"com.apple.dt.playgroundpage",
	"com.apple.dt.swiftpm-package-manifest",
	"com.apple.xcode.strings-text",
	"public.c-plus-plus-source",
	"public.objective-c-source",
	"public.objective-c-plus-plus-source",
	"public.c-header",
	"public.c-source",
	"public.precompiled-c-header"
]

enum CommandError: String, Error {
	case notSupported = "Unsupported file type"
	case notMine = "Not a Gee Dbl A source file"
}
