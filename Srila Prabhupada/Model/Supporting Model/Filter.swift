//
//  Filter.swift
//  Srila Prabhupada
//
//  Created by IE06 on 08/09/22.
//

import Foundation
import FirebaseFirestore

enum Filter: String, CaseIterable {
    case languages = "Languages"
    case countries = "Countries"
    case place = "Place"
    case years = "Years"
    case month = "Month"
    case categories = "Categories"
    case translation = "Translation"

    var firebaseKey: String {
        switch self {
        case .languages:    return "language.main"
        case .countries:    return "location.country"
        case .place:        return "place"
        case .years:        return "dateOfRecording.year"
        case .month:        return "dateOfRecording.month"
        case .categories:   return "category"
        case .translation:  return "language.translations"
        }
    }

    var subtypes: [String] {
        switch self {
        case .languages:
            return ["English", "Hindi", "Bangali"]
        case .countries:
            return ["Australia", "Canada", "China"]
        case .place:
            return ["Chhindwara, MP, India", "Boston, USA", "Delhi, India"]
        case .years:
            return [
                "1977",
                "1976",
                "1975",
                "1974",
                "1973",
                "1972",
                "1971",
                "1970",
                "1969",
                "1968",
                "1967",
                "1966"
            ]
        case .month:
            return Self.monthNames
        case .categories:
            return ["Addresses", "Darsana", "Lectures"]
        case .translation:
            return ["French", "Italian", "Hindi"]
        }
    }

    private static let monthNames: [String] = [
        "January",
        "February",
        "March",
        "April",
        "May",
        "June",
        "July",
        "August",
        "September",
        "October",
        "November",
        "December"
    ]

    func applyOn(query: Query, selectedSubtypes: [String]) -> Query {

        switch self {
        case .languages, .countries, .years, .translation:
            return query.whereField(firebaseKey, in: selectedSubtypes)
        case .month:

            let monthNumbers: [String] = selectedSubtypes.map { monthName in
                if let index = Self.monthNames.firstIndex(of: monthName) {
                    return "\(index+1)"
                } else {
                    return "0"
                }
            }

            return query.whereField(firebaseKey, in: monthNumbers)
        case .place, .categories:
            return query.whereField(firebaseKey, arrayContainsAny: selectedSubtypes)
        }
    }
}
