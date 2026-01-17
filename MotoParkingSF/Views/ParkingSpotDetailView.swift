//
//  ParkingSpotDetailView.swift
//  MotoParkSF
//
//  Created by David A. Shamma on 1/13/26.
//

import SwiftUI
import CoreLocation
import MapKit

struct ParkingSpotDetailView: View {
    let spot: ParkingSpot
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if !spot.isMetered {
                    Section("Location") {
                        LabeledContent("Cross Street", value: spot.location.capitalized)

                        if let neighborhood = spot.neighborhood {
                            LabeledContent("Neighborhood", value: neighborhood)
                        }
                    }
                } else {
                    if let neighborhood = spot.neighborhood {
                        if !neighborhood.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Section("Location") {
                                LabeledContent("Neighborhood", value: neighborhood)
                            }
                        }
                    }
                }
                Section("Parking Information") {
                    LabeledContent("Type") {
                        HStack {
                            Text(spot.isMetered ? "Metered" : "Unmetered")
                                .font(.headline)
                            Image(systemName: spot.isMetered ? "dollarsign.circle.fill" : "heart.fill")
                                .foregroundStyle(spot.isMetered ? Color.red : Color.green)
                        }
                    }

                    if spot.isMetered, let rateDescription = spot.rateDescription {
                        LabeledContent("Rate") {
                            HStack {
                                Text(rateDescription)
                                    .font(.headline)
                                Image(systemName: "dollarsign.circle")
                                    .foregroundStyle(Color.metered)
                            }
                        }
                    }

                    if let spaces = spot.numberOfSpaces {
                        LabeledContent("Number of Spaces") {
                            HStack {
                                Text("\(spaces)")
                                    .font(.headline)
                                Image(systemName: "parkingsign.circle.fill")
                                    .foregroundStyle(Color.green)
                            }
                        }
                    } else {
                        Text("Number of spaces not available")
                            .foregroundStyle(.secondary)
                    }
                }
                Section {
                    Button {
                        openInMaps()
                    } label: {
                        VStack {
                            Label("Open in Maps", systemImage: "map.fill")
                        }
                    }
                }
//                footer: {
//                    Text(String(format: "(%.6f, %.6f)",
//                                spot.coordinate.latitude,
//                                spot.coordinate.longitude))
//                    .frame(maxWidth: .infinity, alignment: .trailing)
//                }
            }
            .navigationTitle("📍 \(spot.street.capitalized)")
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

    private func openInMaps() {
        // let placemark = MKPlacemark(coordinate: spot.coordinate)
        // let mapItem = MKMapItem(placemark: placemark)
        let location = CLLocation(latitude: spot.coordinate.latitude,
                                  longitude: spot.coordinate.longitude)
        let address = MKAddress(fullAddress: spot.street, shortAddress: spot.street)
        let mapItem = MKMapItem(location: location, address: address)
        mapItem.name = spot.street.capitalized
        mapItem.openInMaps()
    }
}

#Preview("Unmetered") {
    ParkingSpotDetailView(spot: ParkingSpot(id: "1",
                                            street: "444 Castro St",
                                            location: "Market Street",
                                            numberOfSpaces: 2,
                                            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                                            neighborhood: "Castro",
                                            isMetered: false,
                                            rateCode: "0"))
}

#Preview("Metered") {
    ParkingSpotDetailView(spot: ParkingSpot(id: "1",
                                            street: "444 Castro St",
                                            location: "Market Street",
                                            numberOfSpaces: 2,
                                            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                                            neighborhood: "Castro",
                                            isMetered: true,
                                            rateCode: "0"))
}
