//
//  Location.swift
//  Srila Prabhupada
//
//  Created by Iftekhar on 10/1/22.
//

import Foundation

struct Location: Hashable, Codable {

    let city: String
    let state: String
    let country: String

    var displayString: String {

        var locations: [String] = []

        if !city.isEmpty {
            locations.append(city)
        }

        if !state.isEmpty {
            locations.append(state)
        }

        if !country.isEmpty {
            locations.append(country)
        }

        return locations.joined(separator: ", ")
    }
}
