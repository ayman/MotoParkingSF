//
//  LocationSearchView.swift
//  MotoParkSF
//
//  Created by David A. Shamma on 1/13/26.
//

import SwiftUI
import MapKit

@Observable
class LocationSearchViewModel: NSObject, MKLocalSearchCompleterDelegate {
    var searchQuery = ""
    var searchResults: [MKLocalSearchCompletion] = []
    var isSearching = false

    private let completer: MKLocalSearchCompleter
    private let region: MKCoordinateRegion

    init(region: MKCoordinateRegion) {
        self.region = region
        self.completer = MKLocalSearchCompleter()
        super.init()
        self.completer.delegate = self
        self.completer.region = region
        self.completer.resultTypes = [.address, .pointOfInterest]
    }

    func updateSearchQuery(_ query: String) {
        searchQuery = query
        if query.isEmpty {
            searchResults = []
            isSearching = false
        } else {
            isSearching = true
            completer.queryFragment = query
        }
    }

    func updateRegion(_ region: MKCoordinateRegion) {
        completer.region = region
    }

    // MARK: - MKLocalSearchCompleterDelegate

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("❌ Search completer error: \(error.localizedDescription)")
    }

    func performSearch(for completion: MKLocalSearchCompletion) async -> (region: MKCoordinateRegion, location: SearchedLocation)? {
        let searchRequest = MKLocalSearch.Request(completion: completion)
        searchRequest.resultTypes = [.address, .pointOfInterest]

        let search = MKLocalSearch(request: searchRequest)

        do {
            let response = try await search.start()
            if let item = response.mapItems.first {
                let region = MKCoordinateRegion(
                    center: item.placemark.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                )

                // Build address string
                var addressComponents: [String] = []
                if let thoroughfare = item.placemark.thoroughfare {
                    addressComponents.append(thoroughfare)
                }
                if let subThoroughfare = item.placemark.subThoroughfare {
                    addressComponents.insert(subThoroughfare, at: 0)
                }
                if let locality = item.placemark.locality {
                    addressComponents.append(locality)
                }
                if let administrativeArea = item.placemark.administrativeArea {
                    addressComponents.append(administrativeArea)
                }
                if let postalCode = item.placemark.postalCode {
                    addressComponents.append(postalCode)
                }

                let address = addressComponents.isEmpty ? "Address not available" : addressComponents.joined(separator: ", ")

                let searchedLocation = SearchedLocation(
                    name: item.name ?? completion.title,
                    address: address,
                    coordinate: item.placemark.coordinate,
                    phoneNumber: item.phoneNumber,
                    mapItem: item
                )

                return (region, searchedLocation)
            }
        } catch {
            print("❌ Search error: \(error.localizedDescription)")
        }

        return nil
    }
}

struct LocationSearchView: View {
    @Binding var cameraPosition: MapCameraPosition
    @Binding var visibleRegion: MKCoordinateRegion?
    @Binding var searchedLocation: SearchedLocation?
    @State private var viewModel: LocationSearchViewModel
    @FocusState private var isSearchFieldFocused: Bool

    init(cameraPosition: Binding<MapCameraPosition>, visibleRegion: Binding<MKCoordinateRegion?>, searchedLocation: Binding<SearchedLocation?>) {
        _cameraPosition = cameraPosition
        _visibleRegion = visibleRegion
        _searchedLocation = searchedLocation

        // Initialize with a default region (San Francisco)
        let defaultRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        _viewModel = State(initialValue: LocationSearchViewModel(region: visibleRegion.wrappedValue ?? defaultRegion))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search for a location or address", text: $viewModel.searchQuery)
                    .textFieldStyle(.plain)
                    .focused($isSearchFieldFocused)
                    .onChange(of: viewModel.searchQuery) { _, newValue in
                        viewModel.updateSearchQuery(newValue)
                    }

                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.searchQuery = ""
                        viewModel.searchResults = []
                        isSearchFieldFocused = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .cornerRadius(10)

            // Search results
            if !viewModel.searchResults.isEmpty && isSearchFieldFocused {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(viewModel.searchResults, id: \.self) { result in
                            Button {
                                Task {
                                    if let searchResult = await viewModel.performSearch(for: result) {
                                        // Set the searched location marker with full details
                                        searchedLocation = searchResult.location

                                        withAnimation {
                                            cameraPosition = .region(searchResult.region)
                                        }
                                    }
                                    viewModel.searchQuery = result.title
                                    viewModel.searchResults = []
                                    isSearchFieldFocused = false
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(result.title)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    if !result.subtitle.isEmpty {
                                        Text(result.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            }

                            if result != viewModel.searchResults.last {
                                Divider()
                                    .padding(.leading, 12)
                            }
                        }
                    }
                }
                .frame(maxHeight: 300)
                .background(.ultraThinMaterial)
                .cornerRadius(10)
                .padding(.top, 4)
            }
        }
        .onChange(of: visibleRegion?.center.latitude) { _, _ in
            if let region = visibleRegion {
                viewModel.updateRegion(region)
            }
        }
        .onChange(of: visibleRegion?.center.longitude) { _, _ in
            if let region = visibleRegion {
                viewModel.updateRegion(region)
            }
        }
    }
}
