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
        case .month:
            return Self.monthNames
        default:
            return UserDefaults.standard.array(forKey: firebaseKey) as? [String] ?? []
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

    static func updateFilterSubtypes(lectures: [Lecture]) {
        DispatchQueue.global().async {

            do {
                var languages: Set<String> = []

                for lecture in lectures where !lecture.language.main.isEmpty {
                    languages.insert(lecture.language.main)
                }
                UserDefaults.standard.set(languages.sorted(), forKey: Filter.languages.firebaseKey)
            }

            do {
                var countries: Set<String> = []

                for lecture in lectures where !lecture.location.country.isEmpty {
                    countries.insert(lecture.location.country)
                }

                UserDefaults.standard.set(countries.sorted(), forKey: Filter.countries.firebaseKey)
            }

            do {
                var place: Set<String> = []

                for lecture in lectures where !lecture.place.isEmpty {
                    place.formUnion(lecture.place)
                }
                UserDefaults.standard.set(place.sorted(), forKey: Filter.place.firebaseKey)
            }

            do {
                var years: Set<String> = []

                for lecture in lectures where !lecture.dateOfRecording.year.isEmpty {
                    years.insert(lecture.dateOfRecording.year)
                }
                UserDefaults.standard.set(years.sorted(), forKey: Filter.years.firebaseKey)
            }

            do {
                var categories: Set<String> = []

                for lecture in lectures where !lecture.category.isEmpty {
                    categories.formUnion(lecture.category)
                }
                UserDefaults.standard.set(categories.sorted(), forKey: Filter.categories.firebaseKey)
            }

            do {
                var translation: Set<String> = []

                for lecture in lectures where !lecture.language.translations.isEmpty {
                    translation.formUnion(lecture.language.translations)
                }
                UserDefaults.standard.set(translation.sorted(), forKey: Filter.translation.firebaseKey)
            }
            UserDefaults.standard.synchronize()
        }
    }
}
