/*****************************************************************************************
 * SourceEditorCommand.swift
 *
 *
 *
 * Author   :  Gary Ash <gary.ash@icloud.com>
 * Created  :  17-Oct-2022  7:23pm
 * Modified :  22-Oct-2022  10:16pm
 *
 * Copyright © 2022 By Gee Dbl A All rights reserved.
 ****************************************************************************************/

import Foundation
import XcodeKit

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
	let dateFormatter = DateFormatter()

	func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void) {
		guard SupportedContentUTIs.contains(invocation.buffer.contentUTI) else {
			let error: CommandError = .notSupported
			return completionHandler(error)
		}

		if invocation.commandIdentifier.hasSuffix(".UpdateHeader") {
			guard let _ = invocation.buffer.completeBuffer.range(of: "Copyright © [0-9]* By Gee Dbl A All rights reserved.", options: .regularExpression, range: nil, locale: nil) else {
				let error: CommandError = .notMine
				return completionHandler(error)
			}
			updateHeaderComment(&invocation.buffer.completeBuffer)
		} else if invocation.commandIdentifier.hasSuffix(".SeperatorLine") {
			seperatorLine(invocation)
		} else if invocation.commandIdentifier.hasSuffix(".AsteriskBox") {
			boxComment(invocation, decoratorChar: "*")
		} else if invocation.commandIdentifier.hasSuffix(".DashBox") {
			boxComment(invocation, decoratorChar: "-")
		} else if invocation.commandIdentifier.hasSuffix(".EqualsBox") {
			boxComment(invocation, decoratorChar: "=")
		}
		completionHandler(nil)
	}

	private func boxComment(_ invocation: XCSourceEditorCommandInvocation, decoratorChar: String) {
		for range in invocation.buffer.selections {
			let r = range as! XCSourceTextRange
			if r.start.line == r.end.line, r.start.column == r.end.column {
				var numberOfDecorationCharacters = 88 - r.start.column
				if numberOfDecorationCharacters < 1 {
					numberOfDecorationCharacters = 3
				}
				let comment1 = addSpaces(r.start.column) + "/*" + String(repeating: decoratorChar, count: numberOfDecorationCharacters)
				let comment2 = addSpaces(r.start.column) + " *"
				let comment3 = addSpaces(r.start.column) + " *" + String(repeating: decoratorChar, count: numberOfDecorationCharacters - 2) + "*/"

				invocation.buffer.lines.insert(comment1, at: r.start.line)
				invocation.buffer.lines.insert(comment2, at: r.start.line + 1)
				invocation.buffer.lines.insert(comment3, at: r.start.line + 2)

				let p = XCSourceTextPosition(line: r.start.line + 1, column: r.start.column + 3)
				invocation.buffer.selections.removeAllObjects()
				invocation.buffer.selections[0] = XCSourceTextRange(start: p, end: p)
			}
		}
	}

	private func seperatorLine(_ invocation: XCSourceEditorCommandInvocation) {
		for range in invocation.buffer.selections {
			let r = range as! XCSourceTextRange
			if r.start.line == r.end.line, r.start.column == r.end.column {
				var numberDashes = 86 - r.start.column
				if numberDashes < 1 {
					numberDashes = 1
				}
				let comment = addSpaces(r.start.column) + "/*" + String(repeating: "-", count: numberDashes) + "*/\n"
				invocation.buffer.lines.insert(comment, at: r.start.line)
				let p = XCSourceTextPosition(line: r.start.line + 1, column: r.start.column)
				invocation.buffer.selections.removeAllObjects()
				invocation.buffer.selections[0] = XCSourceTextRange(start: p, end: p)
			}
		}
	}

	private func updateHeaderComment(_ buffer: inout String) {
		if let range = buffer.range(of: "Modified :.*", options: .regularExpression, range: nil, locale: nil) {
			let currentDate = Date()

			let modifiedOn = "Modified :  " + stringFromDate(currentDate)
			buffer.removeSubrange(range)
			buffer.insert(contentsOf: modifiedOn, at: range.lowerBound)
		}

		if let range = buffer.range(of: "Created  :.*", options: .regularExpression, range: nil, locale: nil) {
			if let dateRange = buffer.range(of: "\\d+-.*", options: .regularExpression, range: range, locale: nil) {
				let startIndex = dateRange.lowerBound
				let endIndex = dateRange.upperBound
				let dateSubstring = String(buffer[startIndex ..< endIndex])

				dateFormatter.dateFormat = "d-MMM-yyyy h:mma"
				if let date = dateFormatter.date(from: dateSubstring) {
					let creaatedOn = "Created  :  " + stringFromDate(date)
					buffer.removeSubrange(range)
					buffer.insert(contentsOf: creaatedOn, at: range.lowerBound)
				}
			}
		}

		if let range = buffer.range(of: "Copyright © [0-9]* By Gee Dbl A All rights reserved", options: .regularExpression, range: nil, locale: nil) {
			if let yearRange = buffer.range(of: "20[0-9]*", options: .regularExpression, range: range, locale: nil) {
				let startIndex = yearRange.lowerBound
				let endIndex = yearRange.upperBound
				let yearSubstring = String(buffer[startIndex ..< endIndex])

				let year = Int(yearSubstring)
				let currentDate = Date()
				let components = Calendar.current.dateComponents([.year], from: currentDate)

				if year != components.year! {
					if let dateRange = buffer.range(of: "20[0-9]* - 20[0-9]*", options: .regularExpression, range: range, locale: nil) {
						buffer.removeSubrange(dateRange)
					} else {
						buffer.removeSubrange(yearRange)
					}
					let copyright = "\(String(describing: year)) - \(components.year!)"
					buffer.insert(contentsOf: copyright, at: yearRange.lowerBound)
				}
			}
		}
	}

	private func addSpaces(_ numberSpaces: Int) -> String {
		return String(repeating: " ", count: numberSpaces)
	}
	private func stringFromDate(_ date: Date) -> String {
		var output = ""
		let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
		dateFormatter.amSymbol = "am"
		dateFormatter.pmSymbol = "pm"
		dateFormatter.dateFormat = "d-MMM-yyyy"

		if components.month != nil, components.month! < 10 {
			output = " "
		}
		output += dateFormatter.string(from: date)
		if components.hour != nil, components.hour! > 9 {
			output += "  "
		} else {
			output += "   "
		}
		dateFormatter.dateFormat = "h:mma"
		output += dateFormatter.string(from: date)

		return output
	}
}
