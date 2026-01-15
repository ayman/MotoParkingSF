//
//  LinkButton.swift
//  MotoParkSF
//
//  Created by David A. Shamma on 1/13/26.
//

import SwiftUI

struct LinkButton: View {
    let title: String
    let url: URL
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            openURL(url)
        } label: {
            HStack {
                Image(systemName: "link.circle.fill")
                Text(title)
                Spacer()
                Image(systemName: "arrow.up.right.square")
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
        }
    }
}

#Preview {
    LinkButton(title: "Website",
               url: URL(string: "https://example.com")!)
}
