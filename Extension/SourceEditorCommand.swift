/*****************************************************************************************
 * SourceEditorCommand.swift
 * 
 *
 *
 * Author   :  Gary Ash <gary.ash@icloud.com>
 * Created  :  17-Oct-2022  7:23pm
 * Modified :  17-Oct-2022  7:21pm
 * 
 * Copyright © 2022 By Gee Dbl A All rights reserved.
 ****************************************************************************************/

import Foundation
import XcodeKit

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
	func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) {
		guard SupportedContentUTIs.contains(invocation.buffer.contentUTI) else {
			let error: CommandError = .notSupported
			return completionHandler(error)
		}

		if invocation.commandIdentifier.hasSuffix(".UpdateModifiedDate") {
			if let range = invocation.buffer.completeBuffer.range(of: "Modified :", options: .literal, range: nil, locale: nil) {
				let currentDate = Date()
				let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: currentDate)
				let dateFormatter = DateFormatter()
				dateFormatter.amSymbol = "am"
				dateFormatter.pmSymbol = "pm"
				dateFormatter.dateFormat = "d-MMM-yyyy"
				invocation.buffer.completeBuffer.removeSubrange(range)
				var modifiedOn = "Modified : "
				if components.month != nil && components.month! > 9 {
					modifiedOn += " "
				}
				modifiedOn += dateFormatter.string(from: currentDate)
				if components.hour != nil && components.hour! > 9 {
					modifiedOn += " "
				} else {
					modifiedOn += "  "
				}
				dateFormatter.dateFormat = "h:mma"
				modifiedOn += dateFormatter.string(from: currentDate)

				invocation.buffer.completeBuffer.insert(contentsOf: modifiedOn, at: range.lowerBound)
			}
			completionHandler(nil)
		}
	}
}
