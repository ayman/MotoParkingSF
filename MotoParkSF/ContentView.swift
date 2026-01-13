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
    @State private var showingInfo = false
    @State private var visibleRegion: MKCoordinateRegion?
    
    private var selectedSpot: ParkingSpot? {
        guard let id = selectedSpotID else { return nil }
        return parkingSpots.first { $0.id == id }
    }
    
    private var visibleSpots: [ParkingSpot] {
        guard let region = visibleRegion else { return parkingSpots }
        
        return parkingSpots.filter { spot in
            let latInRange = abs(spot.coordinate.latitude - region.center.latitude) <= region.span.latitudeDelta / 2
            let lonInRange = abs(spot.coordinate.longitude - region.center.longitude) <= region.span.longitudeDelta / 2
            return latInRange && lonInRange
        }
    }
    
    private var visibleMeteredCount: Int {
        visibleSpots.filter(\.isMetered).count
    }
    
    private var visibleUnmeteredCount: Int {
        visibleSpots.filter { !$0.isMetered }.count
    }

    var body: some View {
        ZStack {
            Map(position: $cameraPosition, selection: $selectedSpotID) {
                UserAnnotation()
                
                // Add parking spot markers
                ForEach(parkingSpots) { spot in
                    Annotation(spot.street, coordinate: spot.coordinate) {
                        ZStack {
                            Circle()
                                .fill(spot.isMetered ? .red : .orange)
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
            .onMapCameraChange { context in
                visibleRegion = context.region
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            
            // Visible spots overlay
            if !parkingSpots.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    let spots = visibleSpots.count != 1 ? "Locations" : "Location"
                    Text("MotoParkSF")
                        .font(.title3.bold())
                    Text("\(visibleSpots.count) \(spots)")
                        .font(.caption.bold())
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.red)
                                .frame(width: 8, height: 8)
                            Text("\(visibleMeteredCount) metered")
                                .font(.caption2)
                        }
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.orange)
                                .frame(width: 8, height: 8)
                            Text("\(visibleUnmeteredCount) unmetered")
                                .font(.caption2)
                        }
                    }
                }
                .padding(8)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding()
            }
            
            // Info button
            Button {
                showingInfo = true
            } label: {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.blue)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 40, height: 40)
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding()
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
        .alert("MotoPark SF", isPresented: $showingInfo) {
            Button("OK") {
                showingInfo = false
            }
        } message: {
            Text("Find motorcycle parking spots in San Francisco. Tap on any marker to view details and get directions. Red markers indicate metered parking, orange markers show unmetered spots.")
        }
        .task {
            loadParkingSpots()
        }
//        .onChange(of: locationManager.userLocation) { oldValue, newValue in
//            if let location = newValue {
//                cameraPosition = .region(MKCoordinateRegion(
//                    center: location.coordinate,
//                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
//                ))
//            }
//        }
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
        var allSpots: [ParkingSpot] = []
        
        // Load unmetered parking spots
        if let url = Bundle.main.url(forResource: "unmetered", withExtension: "json") {
            print("✅ Found unmetered.json file at: \(url)")
            
            do {
                let data = try Data(contentsOf: url)
                print("✅ Loaded \(data.count) bytes of unmetered data")
                
                let response = try JSONDecoder().decode(UnmeteredParkingResponse.self, from: data)
                print("✅ Decoded unmetered JSON response with \(response.data.count) rows")
                
                let unmeteredSpots = response.toParkingSpots()
                allSpots.append(contentsOf: unmeteredSpots)
                print("✅ Loaded \(unmeteredSpots.count) unmetered parking spots")
            } catch {
                print("❌ Error loading unmetered parking spots: \(error)")
            }
        } else {
            print("⚠️ Could not find unmetered.json in bundle")
        }
        
        // Load metered parking spots
        if let url = Bundle.main.url(forResource: "metered", withExtension: "json") {
            print("✅ Found metered.json file at: \(url)")
            
            do {
                let data = try Data(contentsOf: url)
                print("✅ Loaded \(data.count) bytes of metered data")
                
                let response = try JSONDecoder().decode(MeteredParkingResponse.self, from: data)
                print("✅ Decoded metered JSON response with \(response.data.count) rows")
                
                let meteredSpots = response.toParkingSpots()
                allSpots.append(contentsOf: meteredSpots)
                print("✅ Loaded \(meteredSpots.count) metered parking spots")
            } catch {
                print("❌ Error loading metered parking spots: \(error)")
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
        } else {
            print("⚠️ Could not find metered.json in bundle")
        }
        
        parkingSpots = allSpots
        print("✅ Total loaded: \(parkingSpots.count) parking spots (\(parkingSpots.filter(\.isMetered).count) metered, \(parkingSpots.filter { !$0.isMetered }.count) unmetered)")
        
        if let first = parkingSpots.first {
            print("📌 First spot: \(first.street) at (\(first.coordinate.latitude), \(first.coordinate.longitude))")
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

