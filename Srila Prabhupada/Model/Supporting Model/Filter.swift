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

    func filter(_ lectures: [Lecture], selectedSubtypes: [String]) -> [Lecture] {

        switch self {
        case .languages:
            return lectures.filter { selectedSubtypes.contains($0.language.main) }
        case .countries:
            return lectures.filter { selectedSubtypes.contains($0.location.country) }
        case .place:
            let subTypesSet = Set(selectedSubtypes)
            return lectures.filter { !subTypesSet.intersection($0.place).isEmpty }
        case .years:
            return lectures.filter { selectedSubtypes.contains("\($0.dateOfRecording.year)") }
        case .month:

            let selectedMonthNumbers: [Int] = selectedSubtypes.map { monthName in
                if let index = Self.monthNames.firstIndex(of: monthName) {
                    return index+1
                } else {
                    return 0
                }
            }

            return lectures.filter { selectedMonthNumbers.contains($0.dateOfRecording.month) }
        case .categories:
            let subTypesSet = Set(selectedSubtypes)
            return lectures.filter { !subTypesSet.intersection($0.category).isEmpty }
        case .translation:
            let subTypesSet = Set(selectedSubtypes)
            return lectures.filter { !subTypesSet.intersection($0.language.translations).isEmpty }
        }
    }

    static func get(userDefaultKey: String) -> [Filter: [String]] {

        guard let filterDict: [String: [String]] = UserDefaults.standard.dictionary(forKey: userDefaultKey) as? [String: [String]] else {
            return [:]
        }

        var filters: [Filter: [String]] = [:]

        for aFilter in filterDict {
            if let filter = Filter(rawValue: aFilter.key) {
                filters[filter] = aFilter.value
            }
        }

        return filters
    }

    static func set(filters: [Filter: [String]], userDefaultKey: String) {

        var filterDict: [String: [String]] = [:]

        for filter in filters {
            filterDict[filter.key.rawValue] = filter.value
        }

        UserDefaults.standard.set(filterDict, forKey: userDefaultKey)
        UserDefaults.standard.synchronize()
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

                for lecture in lectures where lecture.dateOfRecording.year != 0 {
                    years.insert("\(lecture.dateOfRecording.year)")
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
