//
//  ParkingSpotDetailView.swift
//  MotoParkSF
//
//  Created by David A. Shamma on 1/13/26.
//

import SwiftUI
import CoreLocation
import MapKit

// Detail view for parking spot information
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
                        if neighborhood.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                            Section("Location") {
                                LabeledContent("Neighborhood", value: neighborhood)
                            }
                        }
                    }
                }
                Section("Parking Information") {
                    LabeledContent("Type") {
                        HStack {
                            Image(systemName: spot.isMetered ? "dollarsign.circle.fill" : "parkingsign.circle.fill")
                                .foregroundStyle(spot.isMetered ? .red : .orange)
                            Text(spot.isMetered ? "Metered" : "Unmetered")
                                .font(.headline)
                        }
                    }
                    
                    if spot.isMetered, let rateDescription = spot.rateDescription {
                        LabeledContent("Rate") {
                            HStack {
                                Image(systemName: "dollarsign.circle")
                                    .foregroundStyle(.red)
                                Text(rateDescription)
                                    .font(.headline)
                            }
                        }
                    }
                    
                    if let spaces = spot.numberOfSpaces {
                        LabeledContent("Number of Spaces") {
                            HStack {
                                Image(systemName: "parkingsign.circle.fill")
                                    // .foregroundStyle(spot.isMetered ? .red : .orange)
                                    .foregroundStyle(.green)
                                Text("\(spaces)")
                                    .font(.headline)
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
                } footer: {
                    Text(String(format: "(%.6f, %.6f)",
                                spot.coordinate.latitude,
                                spot.coordinate.longitude))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
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


#Preview {
    ParkingSpotDetailView(spot: ParkingSpot(id: "1",
                                      street: "444 Castro St",
                                      location: "Market Street",
                                      numberOfSpaces: 2,
                                      coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                                      neighborhood: "Castro",
                                      isMetered: false,
                                      rateCode: "0"))
}
