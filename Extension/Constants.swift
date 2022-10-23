/*****************************************************************************************
 * Constants.swift
 *
 *
 *
 * Author   :  Gary Ash <gary.ash@icloud.com>
 * Created  :  18-Oct-2022 11:31am
 * Modified :  18-Oct-2022 11:30am
 *
 * Copyright © 2022 By Gee Dbl A All rights reserved.
 ****************************************************************************************/

import Foundation

let SupportedContentUTIs = [
	"public.swift-source",
	"com.apple.dt.playground",
	"com.apple.dt.playgroundpage",
	"com.apple.dt.swiftpm-package-manifest"
]

enum CommandError: String, Error {
	case notSupported = "Unsupported file type"
	case notMine      = "Not a Gee Dbl A source file"
}
