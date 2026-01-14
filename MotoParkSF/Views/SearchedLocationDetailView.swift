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
        NavigationStack {
            List {
                Section("Location") {
                    // LabeledContent("Name", value: location.name)

                    LabeledContent("Address") {
                        Text(location.address)
                            .multilineTextAlignment(.trailing)
                    }

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

#Preview {
    let previewMapItem = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)))

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
