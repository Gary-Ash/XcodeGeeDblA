/*****************************************************************************************
 * ContentView.swift
 *
 * This file contains the implementation of the copyright's list editor.
 *
 * Author   :  Gary Ash <gary.ash@icloud.com>
 * Created  :  26-Mar-2025  7:24pm
 * Modified :
 *
 * Copyright © 2024 By Gary Ash All rights reserved.
 ****************************************************************************************/

import SwiftUI

struct ContentView: View {
	@State private var selection: String?
	@State private var copyrightHolder = ""
	@State var copyrightHolders: [String]

	var body: some View {
		VStack {
			VStack {
				Text("copyright.holders")
					.font(.title)
				HStack(spacing: 10) {
					TextField("copyright holder", text: $copyrightHolder)
						.overlay(RoundedRectangle(cornerRadius: 3.0).strokeBorder(Color.blue, style: StrokeStyle(lineWidth: 1.0)))
						.padding()

					Button("add") {
						copyrightHolder = copyrightHolder.trimmingCharacters(in: .whitespacesAndNewlines)
						copyrightHolders.append(copyrightHolder)
						copyrightHolders.sort()
						UserDefaults(suiteName: "XcodeGeeDblA")?.set(copyrightHolders, forKey: "Copyright Holders")
						copyrightHolder = ""
					}
				}
				Spacer()
			}
			List(selection: $selection) {
				ForEach(copyrightHolders, id: \.self) { company in
					Text(company)
				}
				.onDelete {
					copyrightHolders.remove(atOffsets: $0)
					UserDefaults(suiteName: "XcodeGeeDblA")?.set(copyrightHolders, forKey: "Copyright Holders")
				}
			}
		}
		.padding(20)
	}

	init() {
		var temp = UserDefaults(suiteName: "XcodeGeeDblA")?.array(forKey: "Copyright Holders") as? [String] ?? []
		temp.sort()
		copyrightHolders = temp
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}
