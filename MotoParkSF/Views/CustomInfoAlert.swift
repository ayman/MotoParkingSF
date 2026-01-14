//
//  CustomInfoAlert.swift
//  MotoParkSF
//
//  Created by David A. Shamma on 1/13/26.
//

import SwiftUI

struct CustomInfoAlert: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Find motorcycle parking spots in San Francisco. Tap on any marker to view details and get directions.")
                    Text("Red markers indicate metered parking, orange markers show unmetered spots.")
                        .font(.body)

                    Text("Data from data.sfgov.gov:\n[Unmetered Parking](https://data.sfgov.org/Transportation/Motorcycle-Parking-Unmetered/egmb-2zhs/about_data) • [Metered Parking](https://data.sfgov.org/Transportation/Metered-motorcycle-spaces/uf55-k7py/about_data)")
                        .font(.body)
                    Text("The data isn't updated by the city very often so some locations may be decommissioned.")
                        .font(.footnote)

                    Text("[https://shamur.ai](https://shamur.ai)")
                }
                .padding()
            }
            .navigationTitle("MotoParkSF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    CustomInfoAlert()
}
