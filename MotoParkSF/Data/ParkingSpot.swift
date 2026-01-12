//
//  ParkingSpot.swift
//  MotoParkSF
//
//  Created by David A. Shamma on 1/12/26.
//

import Foundation
import MapKit

struct ParkingSpot: Identifiable, Hashable {
    let id: String
    let street: String
    let location: String
    let numberOfSpaces: Int?
    let coordinate: CLLocationCoordinate2D
    let neighborhood: String?
    
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
            
            guard let street = row[10].value as? String,
                  let location = row[12].value as? String else {
                return nil
            }
            
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
                neighborhood: neighborhood
            )
        }
        print("✅ Successfully parsed \(spots.count) spots")
        return spots
    }
}


