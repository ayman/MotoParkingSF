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

    let meteredMetadata: DatasetMetadata?
    let unmeteredMetadata: DatasetMetadata?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    let description = String(format: "%@ %@ %@",
                                             "Find motorcycle parking spots in San Francisco.",
                                             "Tap on any marker to view details and get directions. ",
                                             "Red markers indicate metered parking, orange markers show unmetered spots.")
                    Text(description)
                        .font(.body)

                    Text("Data from [data.sfgov.gov](data.sfgov.gov). SF is slow to update their data, so some locations may be wrong.")

                    // Display dataset last modified dates
                    VStack(alignment: .leading, spacing: 8) {
                        if let metered = meteredMetadata {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.metered)
                                    .frame(width: 10, height: 10)
                                Text("[Metered Parking](https://data.sfgov.org/Transportation/Metered-motorcycle-spaces/uf55-k7py/about_data)")
                                    .foregroundStyle(.secondary)
                            }
                            Text("Updated: \(metered.formattedLastModified)")
                                .font(.caption)
                        }
                        if let unmetered = unmeteredMetadata {
                            HStack(spacing: 4) {
                                Rectangle()
                                    .fill(Color.unmetered)
                                    .frame(width: 10, height: 10)
                                Text("[Unmetered Parking](https://data.sfgov.org/Transportation/Motorcycle-Parking-Unmetered/egmb-2zhs/about_data)")
                                    .foregroundStyle(.secondary)
                            }
                            Text("Updated: \(unmetered.formattedLastModified)")
                                .font(.caption)
                        }
                    }

                    Text("Free, open source, and no data collection!")
                    Text("[Shamur.ai](https://shamur.ai) • [MotoParkSF on GitHub](https://github.com/ShamurAI/MotoParkSF)")
                }
                .padding()
            }
            .navigationTitle(NameStrings.appName)
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
    CustomInfoAlert(meteredMetadata: nil, unmeteredMetadata: nil)
}
