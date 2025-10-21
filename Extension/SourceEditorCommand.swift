/*****************************************************************************************
 * SourceEditorCommand.swift
 *
 * This file contains the extension main command entry point
 *
 * Author   :  Gary Ash <gary.ash@icloud.com>
 * Created  :  26-Mar-2025  7:24pm
 * Modified :  20-Oct-2025  9:51pm
 *
 * Copyright © 2024-2025 By Gary Ash All rights reserved.
 ****************************************************************************************/

import XcodeKit

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
	override init() {
		copyrightHolders = UserDefaults(suiteName: "XcodeGeeDblA")?.array(forKey: "Copyright Holders") as? [String] ?? []
		super.init()
	}

	func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void) {
		guard SupportedContentUTIs.contains(invocation.buffer.contentUTI) else {
			return completionHandler(nil)
		}

		if invocation.commandIdentifier.hasSuffix(".UpdateHeader") {
			guard let copyrightRange = invocation.buffer.completeBuffer.range(of: "Copyright © ([0-9 \\*-]*) By (.*) All rights reserved.", options: .regularExpression, range: nil, locale: nil) else {
				return completionHandler(nil)
			}
			if let tightenRange = invocation.buffer.completeBuffer.range(of: "By (.*) All", options: .regularExpression, range: copyrightRange, locale: nil) {
				let s = String(invocation.buffer.completeBuffer[tightenRange.lowerBound ... tightenRange.upperBound])
				var company = s.replacingOccurrences(of: "By ", with: "")
				company = company.replacingOccurrences(of: " All", with: "")
				company = company.trimmingCharacters(in: .whitespacesAndNewlines)

				for c in copyrightHolders {
					if c == company {
						updateHeaderComment(invocation)
						break
					}
				}
				return completionHandler(nil)
			}
			updateHeaderComment(invocation)
		} else if invocation.commandIdentifier.hasSuffix(".SeperatorLine") {
			seperatorLine(invocation)
		} else if invocation.commandIdentifier.hasSuffix(".AsteriskBox") {
			boxComment(invocation, decoratorChar: "*")
		} else if invocation.commandIdentifier.hasSuffix(".DashBox") {
			boxComment(invocation, decoratorChar: "-")
		} else if invocation.commandIdentifier.hasSuffix(".EqualsBox") {
			boxComment(invocation, decoratorChar: "=")
		} else if invocation.commandIdentifier.hasSuffix(".AddComment") {
			addComments(invocation)
		} else if invocation.commandIdentifier.hasSuffix(".RemoveComment") {
			removeComments(invocation)
		}
		completionHandler(nil)
	}

	private var copyrightHolders: [String]
	private let dateFormatter = DateFormatter()

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

	private func updateHeaderComment(_ invocation: XCSourceEditorCommandInvocation) {
		let createdRegEx = /Created\s*:\s*\d*-...-\d*\s*\d*:\d*.*(?=\n)|Created\s*:.*(?=\n)/
		let modifiedRegEx = /Modified\s*:\s*\d*-...-\d*\s*\d*:\d*.*(?=\n)|Modified\s*:.*(?=\n)/
		let copyrightRegEx = "Copyright © ([0-9 \\*-]*) By (.*) All rights reserved"
		/*********************************************************************************
		 * update the Created: date to ensure its in the proper form
		 ********************************************************************************/
		let createRanges = invocation.buffer.completeBuffer.ranges(of: createdRegEx)
		if !createRanges.isEmpty {
			if let dateRange = invocation.buffer.completeBuffer.range(of: "\\d+-.*", options: .regularExpression, range: createRanges[0], locale: nil) {
				let startIndex = dateRange.lowerBound
				let endIndex = dateRange.upperBound
				let dateSubstring = String(invocation.buffer.completeBuffer[startIndex ..< endIndex])

				dateFormatter.dateFormat = "d-MMM-yyyy h:mma"
				if let date = dateFormatter.date(from: dateSubstring) {
					invocation.buffer.completeBuffer.removeSubrange(createRanges[0])

					let cOn = stringFromDate(date)
					let creaatedOn = "Created  :  \(cOn)"
					invocation.buffer.completeBuffer.insert(contentsOf: creaatedOn, at: createRanges[0].lowerBound)
				}
			}
		}
		/*********************************************************************************
		 * update the Modified: date to ensure its in the proper form
		 ********************************************************************************/
		let modifiedRange = invocation.buffer.completeBuffer.ranges(of: modifiedRegEx)
		if !modifiedRange.isEmpty {
			invocation.buffer.completeBuffer.removeSubrange(modifiedRange[0])

			let modifiedDate = stringFromDate(Date())
			let modifiedOn = "Modified :  \(modifiedDate)"
			invocation.buffer.completeBuffer.insert(contentsOf: modifiedOn, at: modifiedRange[0].lowerBound)
		}
		/*********************************************************************************
		 * update the copyright notice as needed
		 ********************************************************************************/
		if let range = invocation.buffer.completeBuffer.range(of: copyrightRegEx,
		                                                      options: .regularExpression,
		                                                      range: nil,
		                                                      locale: nil)
		{
			if let yearRange = invocation.buffer.completeBuffer.range(of: "20[0-9]*",
			                                                          options: .regularExpression,
			                                                          range: range,
			                                                          locale: nil)
			{
				let startIndex = yearRange.lowerBound
				let endIndex = yearRange.upperBound
				let yearSubstring = String(invocation.buffer.completeBuffer[startIndex ..< endIndex])

				let year = Int(yearSubstring)
				let currentDate = Date()
				let components = Calendar.current.dateComponents([.year], from: currentDate)

				if year != components.year! {
					if let dateRange = invocation.buffer.completeBuffer.range(of: "20[0-9]*-20[0-9]*",
					                                                          options: .regularExpression,
					                                                          range: range,
					                                                          locale: nil)
					{
						invocation.buffer.completeBuffer.removeSubrange(dateRange)
					} else {
						invocation.buffer.completeBuffer.removeSubrange(yearRange)
					}
					let copyright = "\(year!)-\(components.year!)"
					invocation.buffer.completeBuffer.insert(contentsOf: copyright, at: yearRange.lowerBound)
				}
			}
		}
	}

	/*----------------------------------------------------------------------------------*/

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

		if let day = components.day {
			if day < 10 {
				output = " "
			}
		}
		output += dateFormatter.string(from: date)
		if let hour = components.hour {
			let h = (hour > 12) ? hour - 12 : hour
			if h > 9 {
				output += " "
			} else {
				output += "  "
			}

			dateFormatter.dateFormat = "h:mma"
			output += dateFormatter.string(from: date)
		}
		return output
	}

	private func addComments(_ invocation: XCSourceEditorCommandInvocation) {
		let extraIndent =
			if invocation.buffer.usesTabsForIndentation {
				"\t"
			} else {
				String(repeatElement(" ", count: invocation.buffer.indentationWidth))
			}

		guard let regex = try? NSRegularExpression(pattern: "([ \\t]*)(.*func )([^(]+)(.*?\n)", options: .caseInsensitive) else {
			return
		}
		invocation.buffer.completeBuffer = regex.stringByReplacingMatches(in: invocation.buffer.completeBuffer, options: [], range: NSRange(location: 0, length: invocation.buffer.completeBuffer.utf16.count), withTemplate: "$1$2$3$4$1\(extraIndent)print(\"# Gee Dbl A: Entering $3()\")\n")
	}

	private func removeComments(_ invocation: XCSourceEditorCommandInvocation) {
		guard let regex = try? NSRegularExpression(pattern: "(.*# Gee Dbl A: Entering.*\n)", options: .caseInsensitive) else {
			return
		}
		invocation.buffer.completeBuffer = regex.stringByReplacingMatches(in: invocation.buffer.completeBuffer, options: [], range: NSRange(location: 0, length: invocation.buffer.completeBuffer.utf16.count), withTemplate: "")
	}
}
