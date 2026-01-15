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

struct ContentView: View {
    // @Environment(\.modelContext) private var modelContext
    @State private var locationManager: LocationManager
    @State private var parkingSpots: [ParkingSpot] = []
    @State private var cameraPosition: MapCameraPosition
    @State private var selectedSpotID: String?
    @State private var showingDetail = false
    @State private var showingInfo = false
    @State private var visibleRegion: MKCoordinateRegion?
    @State private var searchedLocation: SearchedLocation?
    @State private var showingSearchedLocationDetail = false
    @State private var meteredMetadata: DatasetMetadata?
    @State private var unmeteredMetadata: DatasetMetadata?

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

                // Add searched location marker
                if let searchLocation = searchedLocation {
                    Annotation("Searched Location", coordinate: searchLocation.coordinate) {
                        Button {
                            showingSearchedLocationDetail = true
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 40, height: 40)
                                Circle()
                                    .stroke(.white, lineWidth: 3)
                                    .frame(width: 40, height: 40)
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .annotationTitles(.hidden)
                }

                // Add parking spot markers
                ForEach(parkingSpots) { spot in
                    Annotation(spot.street, coordinate: spot.coordinate) {
                        ZStack {
                            if spot.isMetered {
                                Circle()
                                    .fill(Color.metered)
                                    .frame(width: 32, height: 32)
                                Circle()
                                    .stroke(.white, lineWidth: 2)
                                    .frame(width: 32, height: 32)
                                Text("\(spot.numberOfSpaces ?? 0)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                            } else {
                                Rectangle()
                                    .fill(Color.unmetered)
                                    .frame(width: 32, height: 32)
                                Rectangle()
                                    .stroke(.white, lineWidth: 2)
                                    .frame(width: 32, height: 32)
                                Text("\(spot.numberOfSpaces ?? 0)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .annotationTitles(.hidden)
                    .tag(spot.id)
                }
            }
            .mapStyle(.standard)
            .onMapCameraChange { context in
                visibleRegion = context.region
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }

            if !parkingSpots.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    let spots = visibleSpots.count != 1 ? "Locations" : "Location"
                    HStack {
                        Text("MotoParkSF")
                            .font(.title3.bold())
                        Button {
                            showingInfo = true
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.system(size: 24))
                                .foregroundStyle(.blue)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 32, height: 32)
                                )
                        }
                        .padding(.leading, 8)
                    }
                    Text("\(visibleSpots.count) \(spots)")
                        .font(.caption.bold())
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.metered)
                                .frame(width: 8, height: 8)
                            Text("\(visibleMeteredCount) metered")
                                .font(.caption2)
                        }
                        HStack(spacing: 4) {
                            Rectangle()
                                .fill(Color.unmetered)
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

            // Search field and Info button - positioned at bottom
            VStack {
                Spacer()

                HStack(alignment: .center, spacing: 16) {
                    // Search field
                    LocationSearchView(
                        cameraPosition: $cameraPosition,
                        visibleRegion: $visibleRegion,
                        searchedLocation: $searchedLocation
                    )
                }
                .padding()
                .padding(.bottom, 8) // Extra padding from bottom edge
            }
        }
        .onChange(of: selectedSpotID) { _, newValue in
            if newValue != nil {
                showingDetail = true
            }
        }
        .sheet(isPresented: $showingDetail, onDismiss: {
            selectedSpotID = nil
        }, content: {
            if let spot = selectedSpot {
                ParkingSpotDetailView(spot: spot)
                    .presentationDetents([.medium, .large])
            }
        })
        .sheet(isPresented: $showingSearchedLocationDetail) {
            if let location = searchedLocation {
                SearchedLocationDetailView(location: location)
                    .presentationDetents([.medium, .large])
            }
        }
        .sheet(isPresented: $showingInfo) {
            CustomInfoAlert(
                meteredMetadata: meteredMetadata,
                unmeteredMetadata: unmeteredMetadata
            )
        }
        .task {
            loadParkingSpots()
        }
        .onChange(of: locationManager.userLocation) { _, newValue in
            // Update camera position when location becomes available
            // Only move the camera if we don't already have a position set to user's location
            if let location = newValue {
                if Self.isInSanFrancisco(location.coordinate) {
                    // User is in SF, update to their location
                    cameraPosition = .region(MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    ))
                }
                // If user is not in SF, keep the default SF location (do nothing)
            }
        }
    }

    init(locationManager: LocationManager = LocationManager()) {
        _locationManager = State(initialValue: locationManager)

        // Set initial camera position based on user location
        let defaultSFCoordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)

        if let location = locationManager.userLocation, Self.isInSanFrancisco(location.coordinate) {
            // User is in San Francisco, use their location
            _cameraPosition = State(initialValue: .region(MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )))
        } else {
            // User is not in San Francisco or location not available, default to SF
            _cameraPosition = State(initialValue: .region(MKCoordinateRegion(
                center: defaultSFCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )))
        }
    }

    /// Check if a coordinate is within San Francisco's approximate boundaries
    private static func isInSanFrancisco(_ coordinate: CLLocationCoordinate2D) -> Bool {
        // San Francisco approximate bounds
        let minLat = 37.70
        let maxLat = 37.84
        let minLon = -122.52
        let maxLon = -122.35

        return coordinate.latitude >= minLat &&
               coordinate.latitude <= maxLat &&
               coordinate.longitude >= minLon &&
               coordinate.longitude <= maxLon
    }

    private func loadParkingSpots() {
        // print("📍 Attempting to load parking spots...")
        var allSpots: [ParkingSpot] = []

        // Load unmetered parking spots
        if let url = Bundle.main.url(forResource: "unmetered", withExtension: "json") {
            // print("✅ Found unmetered.json file at: \(url)")

            do {
                let data = try Data(contentsOf: url)
                // print("✅ Loaded \(data.count) bytes of unmetered data")

                let response = try JSONDecoder().decode(UnmeteredParkingResponse.self, from: data)
                // print("✅ Decoded unmetered JSON response with \(response.data.count) rows")

                // Store metadata
                if let meta = response.meta {
                    unmeteredMetadata = DatasetMetadata(meta: meta)
                    // print("✅ Loaded unmetered metadata: last modified \(unmeteredMetadata?.formattedLastModified ?? "unknown")")
                }

                let unmeteredSpots = response.toParkingSpots()
                allSpots.append(contentsOf: unmeteredSpots)
                // print("✅ Loaded \(unmeteredSpots.count) unmetered parking spots")
            } catch {
                // print("❌ Error loading unmetered parking spots: \(error)")
            }
        } else {
            // print("⚠️ Could not find unmetered.json in bundle")
        }

        // Load metered parking spots
        if let url = Bundle.main.url(forResource: "metered", withExtension: "json") {
            // print("✅ Found metered.json file at: \(url)")

            do {
                let data = try Data(contentsOf: url)
                // print("✅ Loaded \(data.count) bytes of metered data")

                let response = try JSONDecoder().decode(MeteredParkingResponse.self, from: data)
                // print("✅ Decoded metered JSON response with \(response.data.count) rows")

                // Store metadata
                if let meta = response.meta {
                    meteredMetadata = DatasetMetadata(meta: meta)
                    // print("✅ Loaded metered metadata: last modified \(meteredMetadata?.formattedLastModified ?? "unknown")")
                }

                let meteredSpots = response.toParkingSpots()
                allSpots.append(contentsOf: meteredSpots)
                // print("✅ Loaded \(meteredSpots.count) metered parking spots")
            } catch {
                // print("❌ Error loading metered parking spots: \(error)")
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
            // print("⚠️ Could not find metered.json in bundle")
        }

        parkingSpots = allSpots
        // print("✅ Total loaded: \(parkingSpots.count) parking spots (\(parkingSpots.filter(\.isMetered).count) metered, \(parkingSpots.filter { !$0.isMetered }.count) unmetered)")

        if let first = parkingSpots.first {
            print("📌 First spot: \(first.street) at (\(first.coordinate.latitude), \(first.coordinate.longitude))")
        }
    }
}

#Preview("App") {
    let previewLocationManager = LocationManager()
    // Set preview location to San Francisco
    previewLocationManager.userLocation = CLLocation(
        latitude: 37.7749,
        longitude: -122.4194
    )

    return ContentView(locationManager: previewLocationManager)
}
