/*****************************************************************************************
 * ContentView.swift
 *
 *
 *
 * Author   :  Gary Ash <gary.ash@icloud.com>
 * Created  :  14-Oct-2022  4:02pm
 * Modified :  18-Nov-2022  4:53pm
 *
 * Copyright © 2022 By Gee Dbl A All rights reserved.
 ****************************************************************************************/

import SwiftUI

struct ContentView: View {
	@State var copyrightHolder = ""
	@State var copyrightHolders: [String]

	var body: some View {
		VStack {
			VStack {
				Text("copyright.holders")
					.font(.title)
				HStack(spacing: 10) {
					TextField("copyright holder", text: $copyrightHolder)
						.overlay(RoundedRectangle(cornerRadius: 1)
							.stroke(Color.gray, lineWidth: 1))

					Button("add") {
						copyrightHolder = copyrightHolder.trimmingCharacters(in: .whitespacesAndNewlines)
						self.copyrightHolders.append(copyrightHolder)
						UserDefaults(suiteName: "XcodeGeeDblA")?.set(copyrightHolders, forKey: "Copyright Holders")
						copyrightHolder = ""
					}
				}
				Spacer()
			}
			List {
				ForEach($copyrightHolders, id: \.self) { $company in
					Text(company)
				}
				.onDelete {
					self.copyrightHolders.remove(atOffsets: $0)
					UserDefaults(suiteName: "XcodeGeeDblA")?.set(copyrightHolders, forKey: "Copyright Holders")
				}
			}
		}
		.padding(20)
	}

	init() {
		self.copyrightHolders = UserDefaults(suiteName: "XcodeGeeDblA")?.array(forKey: "Copyright Holders") as? [String] ?? []
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}
