//
//  ContentView.swift
//  MotoParkSF
//
//  Created by David A. Shamma on 1/12/26.
//

import SwiftUI
import SwiftData
import MapKit
import CoreLocation

@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    var userLocation: CLLocation?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.first
    }
}

struct ContentView: View {
    // @Environment(\.modelContext) private var modelContext
    @State private var locationManager: LocationManager
    @State private var parkingSpots: [ParkingSpot] = []
    @State private var cameraPosition: MapCameraPosition
    @State private var selectedSpotID: String?
    @State private var showingDetail = false
    
    private var selectedSpot: ParkingSpot? {
        guard let id = selectedSpotID else { return nil }
        return parkingSpots.first { $0.id == id }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $cameraPosition, selection: $selectedSpotID) {
                UserAnnotation()
                
                // Add parking spot markers
                ForEach(parkingSpots) { spot in
                    Annotation(spot.street, coordinate: spot.coordinate) {
                        ZStack {
                            Circle()
                                .fill(.orange)
                                .frame(width: 32, height: 32)
                            Circle()
                                .stroke(.white, lineWidth: 2)
                                .frame(width: 32, height: 32)
                            Text("\(spot.numberOfSpaces ?? 0)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .annotationTitles(.hidden)
                    .tag(spot.id)
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            
            // Debug overlay
            if !parkingSpots.isEmpty {
                Text("\(parkingSpots.count) spots loaded")
                    .font(.caption)
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    .padding()
            }
        }
        .onChange(of: selectedSpotID) { oldValue, newValue in
            if newValue != nil {
                showingDetail = true
            }
        }
        .sheet(isPresented: $showingDetail, onDismiss: {
            selectedSpotID = nil
        }) {
            if let spot = selectedSpot {
                ParkingSpotDetailView(spot: spot)
                    .presentationDetents([.medium, .large])
            }
        }
        .task {
            loadParkingSpots()
        }
        .onChange(of: locationManager.userLocation) { oldValue, newValue in
            if let location = newValue {
                cameraPosition = .region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))
            }
        }
    }
    
    init(locationManager: LocationManager = LocationManager()) {
        _locationManager = State(initialValue: locationManager)
        
        // Set initial camera position
        if let location = locationManager.userLocation {
            _cameraPosition = State(initialValue: .region(MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )))
        } else {
            // Default to San Francisco
            _cameraPosition = State(initialValue: .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )))
        }
    }
    
    private func loadParkingSpots() {
        print("📍 Attempting to load parking spots...")
        guard let url = Bundle.main.url(forResource: "unmetered", withExtension: "json") else {
            print("❌ Could not find unmetered.json in bundle")
            print("Bundle path: \(Bundle.main.bundlePath)")
            return
        }
        
        print("✅ Found JSON file at: \(url)")
        
        do {
            let data = try Data(contentsOf: url)
            print("✅ Loaded \(data.count) bytes of data")
            
            let response = try JSONDecoder().decode(UnmeteredParkingResponse.self, from: data)
            print("✅ Decoded JSON response with \(response.data.count) rows")
            
            parkingSpots = response.toParkingSpots()
            print("✅ Loaded \(parkingSpots.count) parking spots")
            
            if let first = parkingSpots.first {
                print("📌 First spot: \(first.street) at (\(first.coordinate.latitude), \(first.coordinate.longitude))")
            }
        } catch {
            print("❌ Error loading parking spots: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("Key '\(key)' not found:", context.debugDescription)
                case .valueNotFound(let value, let context):
                    print("Value '\(value)' not found:", context.debugDescription)
                case .typeMismatch(let type, let context):
                    print("Type '\(type)' mismatch:", context.debugDescription)
                case .dataCorrupted(let context):
                    print("Data corrupted:", context.debugDescription)
                @unknown default:
                    print("Unknown decoding error")
                }
            }
        }
    }
}

#Preview {
    let previewLocationManager = LocationManager()
    // Set preview location to San Francisco
    previewLocationManager.userLocation = CLLocation(
        latitude: 37.7749,
        longitude: -122.4194
    )
    
    return ContentView(locationManager: previewLocationManager)
}
// Detail view for parking spot information
struct ParkingSpotDetailView: View {
    let spot: ParkingSpot
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Location") {
                    LabeledContent("Street", value: spot.street)
                    LabeledContent("Details", value: spot.location)
                    
                    if let neighborhood = spot.neighborhood {
                        LabeledContent("Neighborhood", value: neighborhood)
                    }
                }
                
                Section("Parking Information") {
                    if let spaces = spot.numberOfSpaces {
                        LabeledContent("Number of Spaces") {
                            HStack {
                                Image(systemName: "parkingsign.circle.fill")
                                    .foregroundStyle(.red)
                                Text("\(spaces)")
                                    .font(.headline)
                            }
                        }
                    } else {
                        Text("Number of spaces not available")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Coordinates") {
                    LabeledContent("Latitude", value: String(format: "%.6f", spot.coordinate.latitude))
                    LabeledContent("Longitude", value: String(format: "%.6f", spot.coordinate.longitude))
                    
                    Button {
                        openInMaps()
                    } label: {
                        Label("Open in Maps", systemImage: "map.fill")
                    }
                }
            }
            .navigationTitle("Parking Spot")
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
        let placemark = MKPlacemark(coordinate: spot.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = spot.street
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

