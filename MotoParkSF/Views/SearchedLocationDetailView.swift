//
//  SearchedLocationDetailView.swift
//  MotoParkSF
//
//  Created by David A. Shamma on 1/13/26.
//

import SwiftUI
import MapKit

struct SearchedLocationDetailView: View {
    let location: SearchedLocation
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let addressParts = location.address.components(separatedBy: ", ")
        NavigationStack {
            List {
                Section("Location") {
                    LabeledContent("Address") {
                        VStack {
                            ForEach(addressParts, id: \.self) { item in
                                Text(item)
                                    .frame(maxWidth: .infinity, alignment: .init(horizontal: .trailing, vertical: .top))
                            }
                        }
                    }
                    .labeledContentStyle(TopLabeledContentStyle())

                    if let phone = location.phoneNumber {
                        LabeledContent("Phone") {
                            Button(phone) {
                                if let url = URL(string: "tel://\(phone.filter { $0.isNumber })") {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                    }
                }

                Section {
                    Button {
                        location.mapItem.openInMaps()
                    } label: {
                        Label("Open in Maps", systemImage: "map.fill")
                    }
                } footer: {
                    Text(String(format: "(%.6f, %.6f)",
                                location.coordinate.latitude,
                                location.coordinate.longitude))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .navigationTitle("📍 \(location.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Source - https://stackoverflow.com/a/79751149
// Posted by Benzy Neez, modified by community. See post 'Timeline' for change history
// Retrieved 2026-01-13, License - CC BY-SA 4.0

struct TopLabeledContentStyle: LabeledContentStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextBaseline) {
            configuration.label
                .fontWeight(.semibold)
            configuration.content
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    let previewMapItem = MKMapItem(location: CLLocation(latitude: 37.7956,
                                             longitude: -122.3933),
                        address: MKAddress(fullAddress: "1 Ferry Building, San Francisco, CA 94111", shortAddress: "1 Ferry Building"))

    SearchedLocationDetailView(
        location: SearchedLocation(
            name: "Ferry Building",
            address: "1 Ferry Building, San Francisco, CA 94111",
            coordinate: CLLocationCoordinate2D(latitude: 37.7956, longitude: -122.3933),
            phoneNumber: "(415) 983-8000",
            mapItem: previewMapItem
        )
    )
}
