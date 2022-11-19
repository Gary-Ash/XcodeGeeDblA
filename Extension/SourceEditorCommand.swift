/*****************************************************************************************
 * SourceEditorCommand.swift
 *
 * This file contains the extension main command entry point
 *
 * Author   :  Gary Ash <gary.ash@icloud.com>
 * Created  :  17-Oct-2022  7:23pm
 * Modified :  18-Nov-2022  11:12pm
 *
 * Copyright © 2022 By Gee Dbl A All rights reserved.
 ****************************************************************************************/

import Foundation
import XcodeKit

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
	private var copyrightHolders: [String]
	private let dateFormatter = DateFormatter()

	override init() {
		self.copyrightHolders = UserDefaults(suiteName: "XcodeGeeDblA")?.array(forKey: "Copyright Holders") as? [String] ?? []
		super.init()
	}

	func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void) {
		guard SupportedContentUTIs.contains(invocation.buffer.contentUTI) else {
			return completionHandler(nil)
		}

		if invocation.commandIdentifier.hasSuffix(".UpdateHeader") {
			guard let copyrightRange = invocation.buffer.completeBuffer.range(of: "Copyright © [0-9]* By (.*) All rights reserved.", options: .regularExpression, range: nil, locale: nil) else {
				let error: CommandError = .notMine
				return completionHandler(error)
			}
			if let tightenRange = invocation.buffer.completeBuffer.range(of: "By (.*) All", options: .regularExpression, range: copyrightRange, locale: nil) {
				let s = String(invocation.buffer.completeBuffer[tightenRange.lowerBound ... tightenRange.upperBound])
				var company = s.replacingOccurrences(of: "By ", with: "")
				company = company.replacingOccurrences(of: " All", with: "")
				company = company.trimmingCharacters(in: .whitespacesAndNewlines)
	
				for c in copyrightHolders {
					if c == company {
						updateHeaderComment(&invocation.buffer.completeBuffer)
						break
					}
				}
				return completionHandler(nil)
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
				var numberOfDecorationCharacters = 88 - getColumnNumber(invocation, column: r.start.column)
				if numberOfDecorationCharacters < 1 {
					numberOfDecorationCharacters = 3
				}
				let comment1 = addSpaces(invocation, numberSpaces: r.start.column) + "/*" + String(repeating: decoratorChar, count: numberOfDecorationCharacters)
				let comment2 = addSpaces(invocation, numberSpaces: r.start.column) + " *"
				let comment3 = addSpaces(invocation, numberSpaces: r.start.column) + " *" + String(repeating: decoratorChar, count: numberOfDecorationCharacters - 2) + "*/"

				if r.start.column > 0 {
					invocation.buffer.lines.insert(comment1, at: r.start.line)
					invocation.buffer.lines.insert(comment2, at: r.start.line)
					invocation.buffer.lines.insert(comment3, at: r.start.line)
					setCursor(invocation, line: r.start.line - 2, column: r.start.column + 3)
				} else {
					invocation.buffer.lines.insert(comment1, at: r.start.line)
					invocation.buffer.lines.insert(comment2, at: r.start.line + 1)
					invocation.buffer.lines.insert(comment3, at: r.start.line + 2)
					setCursor(invocation, line: r.start.line + 1, column: r.start.column + 3)
				}
			}
		}
	}

	private func seperatorLine(_ invocation: XCSourceEditorCommandInvocation) {
		for range in invocation.buffer.selections {
			let r = range as! XCSourceTextRange
			if r.start.line == r.end.line, r.start.column == r.end.column {
				var numberDashes = 86 - getColumnNumber(invocation, column: r.start.column)
				if numberDashes < 1 {
					numberDashes = 1
				}
				let comment = addSpaces(invocation, numberSpaces: r.start.column) + "/*" + String(repeating: "-", count: numberDashes) + "*/\n"
				invocation.buffer.lines.insert(comment, at: r.start.line)
				setCursor(invocation, line: r.start.line + 1, column: r.start.column)
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

		if let range = buffer.range(of: "Copyright © [0-9]* By (.*) All rights reserved", options: .regularExpression, range: nil, locale: nil) {
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

	private func setCursor(_ invocation: XCSourceEditorCommandInvocation, line: Int, column: Int) {
		var col = column
		if invocation.buffer.usesTabsForIndentation {
			col = invocation.buffer.indentationWidth * column
		}
		let p = XCSourceTextPosition(line: line, column: col)
		invocation.buffer.selections.removeAllObjects()
		invocation.buffer.selections[0] = XCSourceTextRange(start: p, end: p)
	}

	private func getColumnNumber(_ invocation: XCSourceEditorCommandInvocation, column: Int) -> Int {
		if invocation.buffer.usesTabsForIndentation {
			return invocation.buffer.indentationWidth * column
		}
		return column + 1
	}

	private func addSpaces(_ invocation: XCSourceEditorCommandInvocation, numberSpaces: Int) -> String {
		return String(repeating: " ", count: getColumnNumber(invocation, column: numberSpaces))
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
