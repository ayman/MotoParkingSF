//
//  ParkingSpot.swift
//  MotoParkSF
//
//  Created by David A. Shamma on 1/12/26.
//
// Metered:
// https://data.sfgov.org/Transportation/Metered-motorcycle-spaces/uf55-k7py/about_data
// Data: https://data.sfgov.org/api/views/uf55-k7py/rows.json (12 should be 'black', 23 is space id, 24 is '[ null, "37.798279", "-122.426623", null, false ]')
// Unmetered:
// https://data.sfgov.org/Transportation/Motorcycle-Parking-Unmetered/egmb-2zhs/about_data
// Data: https://data.sfgov.org/api/views/egmb-2zhs/rows.json

import Foundation
import MapKit

struct ParkingSpot: Identifiable, Hashable {
    let id: String
    let street: String
    let location: String
    let numberOfSpaces: Int?
    let coordinate: CLLocationCoordinate2D
    let neighborhood: String?
    let isMetered: Bool
    let rateCode: String?

    var rateDescription: String? {
        guard let rateCode = rateCode else { return nil }

        switch rateCode {
        case "MC1":
            return "$0.70/hour"
        case "MC2":
            return "$0.60/hour"
        case "MC3":
            return "$0.40/hour"
        case "MC5":
            return "$0.25–$6.00/hour"
        default:
            return nil
        }
    }

    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ParkingSpot, rhs: ParkingSpot) -> Bool {
        lhs.id == rhs.id
    }
}

// Response structure for the JSON file
struct UnmeteredParkingResponse: Codable {
    let data: [[AnyCodable]]

    struct AnyCodable: Codable {
        let value: Any

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()

            if let string = try? container.decode(String.self) {
                value = string
            } else if let int = try? container.decode(Int.self) {
                value = int
            } else if let double = try? container.decode(Double.self) {
                value = double
            } else if let dict = try? container.decode([String: AnyCodable].self) {
                value = dict.mapValues { $0.value }
            } else if container.decodeNil() {
                value = NSNull()
            } else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode value")
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()

            if let string = value as? String {
                try container.encode(string)
            } else if let int = value as? Int {
                try container.encode(int)
            } else if let double = value as? Double {
                try container.encode(double)
            } else if value is NSNull {
                try container.encodeNil()
            }
        }
    }

    func toParkingSpots() -> [ParkingSpot] {
        print("🔄 Processing \(data.count) rows...")

        let spots = data.compactMap { row -> ParkingSpot? in
            guard row.count > 19 else { return nil }

            // Index 10 is the street name (e.g., "STEINER ST")
            // Index 12 is the location/full address (e.g., "1000 STEINER ST")
            guard let fullAddress = row[12].value as? String,
                  let streetName = row[10].value as? String else {
                return nil
            }

            // Use the full address from index 12 as the street display
            let street = fullAddress
            let location = streetName

            // Parse numberOfSpaces - it's a String in the JSON, need to convert
            let numberOfSpaces: Int?
            if let spacesString = row[13].value as? String {
                numberOfSpaces = Int(spacesString)
            } else {
                numberOfSpaces = row[13].value as? Int
            }

            let neighborhood = row[19].value as? String

            // Parse the WKT Point format: "POINT (longitude latitude)"
            guard let pointString = row[17].value as? String else {
                return nil
            }

            // Extract coordinates from "POINT (-122.433569267 37.77868774)"
            let pattern = #"POINT \(([+-]?\d+\.?\d*)\s+([+-]?\d+\.?\d*)\)"#
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: pointString, range: NSRange(pointString.startIndex..., in: pointString)),
                  match.numberOfRanges == 3 else {
                return nil
            }

            guard let lonRange = Range(match.range(at: 1), in: pointString),
                  let latRange = Range(match.range(at: 2), in: pointString),
                  let lon = Double(pointString[lonRange]),
                  let lat = Double(pointString[latRange]) else {
                return nil
            }

            let coordinate = CLLocationCoordinate2D(
                latitude: lat,
                longitude: lon
            )

            let id = "\(street)-\(location)"

            return ParkingSpot(
                id: id,
                street: street,
                location: location,
                numberOfSpaces: numberOfSpaces,
                coordinate: coordinate,
                neighborhood: neighborhood,
                isMetered: false,
                rateCode: nil
            )
        }
        print("✅ Successfully parsed \(spots.count) spots")
        return spots
    }
}

// Response structure for metered parking JSON
// Index 12 contains the street name (e.g., 'black')
// Index 24 contains an array: [ null, "37.798279", "-122.426623", null, false ]
struct MeteredParkingResponse: Codable {
    let data: [[AnyCodable]]

    struct AnyCodable: Codable {
        let value: Any

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()

            if let string = try? container.decode(String.self) {
                value = string
            } else if let int = try? container.decode(Int.self) {
                value = int
            } else if let double = try? container.decode(Double.self) {
                value = double
            } else if let bool = try? container.decode(Bool.self) {
                value = bool
            } else if let array = try? container.decode([AnyCodable].self) {
                value = array.map { $0.value }
            } else if let dict = try? container.decode([String: AnyCodable].self) {
                value = dict.mapValues { $0.value }
            } else if container.decodeNil() {
                value = NSNull()
            } else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode value")
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()

            if let string = value as? String {
                try container.encode(string)
            } else if let int = value as? Int {
                try container.encode(int)
            } else if let double = value as? Double {
                try container.encode(double)
            } else if let bool = value as? Bool {
                try container.encode(bool)
            } else if value is NSNull {
                try container.encodeNil()
            }
        }
    }

    func toParkingSpots() -> [ParkingSpot] {
        print("🔄 Processing \(data.count) metered parking rows...")

        // Helper struct to group parking space data
        struct SpaceGroup {
            let street: String
            let coordinate: CLLocationCoordinate2D
            let rateCode: String?
            let neighborhood: String?
            var count: Int
        }

        // First, collect all rows grouped by space ID
        var spaceGroups: [String: SpaceGroup] = [:]

        for row in data {
            guard row.count > 24 else { continue }

            // Index 23 contains the space ID
            guard let spaceID = row[23].value as? String else {
                continue
            }

            // Index 21 contains the street number, index 22 contains the street name
            let streetNumber = row[21].value as? String
            let streetName = row[22].value as? String

            // Combine street number and name
            let street: String
            if let number = streetNumber, let name = streetName, !number.isEmpty, !name.isEmpty {
                street = "\(number) \(name)"
            } else if let name = streetName, !name.isEmpty {
                street = name
            } else if let number = streetNumber, !number.isEmpty {
                street = number
            } else {
                // Fallback to index 12 if 21 and 22 are not available
                guard let fallbackStreet = row[12].value as? String else {
                    continue
                }
                street = fallbackStreet
            }

            // Index 19 contains the rate code (MC1, MC2, MC3, MC5)
            let rateCode = row[19].value as? String

            // Index 20 contains the neighborhood
            let neighborhood = row[20].value as? String

            // Index 24 contains an array with lat/long at indices 1 and 2
            guard let locationArray = row[24].value as? [Any],
                  locationArray.count > 2 else {
                continue
            }

            // Extract latitude and longitude from the array
            // Format: [ null, "37.798279", "-122.426623", null, false ]
            guard let latString = locationArray[1] as? String,
                  let lonString = locationArray[2] as? String,
                  let lat = Double(latString),
                  let lon = Double(lonString) else {
                continue
            }

            let coordinate = CLLocationCoordinate2D(
                latitude: lat,
                longitude: lon
            )

            // Group by space ID - if already exists, just increment count
            if var existing = spaceGroups[spaceID] {
                existing.count += 1
                spaceGroups[spaceID] = existing
            } else {
                spaceGroups[spaceID] = SpaceGroup(
                    street: street,
                    coordinate: coordinate,
                    rateCode: rateCode,
                    neighborhood: neighborhood,
                    count: 1
                )
            }
        }

        // Now create one ParkingSpot per space ID with the count
        let spots = spaceGroups.map { (spaceID, info) -> ParkingSpot in
            ParkingSpot(
                id: "metered-\(spaceID)",
                street: info.street,
                location: "Metered parking",
                numberOfSpaces: info.count,
                coordinate: info.coordinate,
                neighborhood: info.neighborhood,
                isMetered: true,
                rateCode: info.rateCode
            )
        }

        print("✅ Successfully parsed \(spots.count) metered spots from \(data.count) rows")
        return spots
    }
}
