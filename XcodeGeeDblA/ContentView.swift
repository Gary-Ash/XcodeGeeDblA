/*****************************************************************************************
 * ContentView.swift
 *
 * This file contains the implementation of the copyright's list editor.
 *
 * Author   :  Gary Ash <gary.ash@icloud.com>
 * Created  :  31-Jan-2026 10:52pm
 * Modified :   9-Jun-2026 10:05pm
 *
 * Copyright © 2026 By Gary Ash All rights reserved.
 ****************************************************************************************/

import SwiftUI

struct ContentView: View {
	@State private var selection: String?
	@State private var copyrightHolder = ""
	@State var copyrightHolders: [String]
	@FocusState private var copyrightHolderFocused: Bool

	var body: some View {
		VStack(spacing: 20) {
			VStack {
				Text("copyright.holders")
					.font(.title)
				HStack() {
					TextField("copyright holder", text: $copyrightHolder)
						.focused($copyrightHolderFocused)
						.clipShape(RoundedRectangle(cornerRadius: 8))
						.overlay(
							RoundedRectangle(cornerRadius: 8)
								.stroke(.separator, lineWidth: 1)
						)

					Button("add") {
						copyrightHolder = copyrightHolder.trimmingCharacters(in: .whitespacesAndNewlines)
						copyrightHolders.append(copyrightHolder)
						copyrightHolders.sort()
						UserDefaults(suiteName: appGroupSuiteName)?.set(copyrightHolders, forKey: "Copyright Holders")
						copyrightHolder = ""
					}
				}
			}
			ZStack {
				List(selection: $selection) {
					ForEach(copyrightHolders, id: \.self) { company in
						Text(company)
					}
					.onDelete {
						copyrightHolders.remove(atOffsets: $0)
						UserDefaults(suiteName: appGroupSuiteName)?.set(copyrightHolders, forKey: "Copyright Holders")
					}
				}
				.clipShape(RoundedRectangle(cornerRadius: 8))
				.overlay(
					RoundedRectangle(cornerRadius: 8)
						.stroke(.separator, lineWidth: 1)
				)
			}
		}
		.padding(20)
		.onAppear {
			DispatchQueue.main.async {
				copyrightHolderFocused = true
			}
		}
	}

	init() {
		var temp = UserDefaults(suiteName: appGroupSuiteName)?.array(forKey: "Copyright Holders") as? [String] ?? []
		temp.sort()
		copyrightHolders = temp
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}
