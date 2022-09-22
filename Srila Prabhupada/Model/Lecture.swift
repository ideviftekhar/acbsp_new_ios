//
//  Lecture.swift
//  Srila Prabhupada
//
//  Created by IE03 on 13/09/22.
//

import Foundation
import FirebaseFirestoreSwift

struct Lecture: Hashable, Codable {

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    var category: [String]
    var creationTimestamp: String
    var dateOfRecording: Day
    var description: [String]
    var id: Int
    var language: LectureLanguage
    var lastModifiedTimestamp: String
    var legacyData: LegacyData
    var length: Int
    var lengthType: [String]
    var location: Location
    var place: [String]
    var resources: Resources
    var search: Search
    var tags: [String]
    var thumbnail: String
    var title: [String]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            self.id = try container.decode(Int.self, forKey: .id)
            self.category = try container.decode([String].self, forKey: .category)
            self.creationTimestamp = try container.decode(String.self, forKey: .creationTimestamp)
            self.dateOfRecording = try container.decode(Day.self, forKey: .dateOfRecording)
            self.description = try container.decode([String].self, forKey: .description)
            self.language = try container.decode(LectureLanguage.self, forKey: .language)
            self.lastModifiedTimestamp = try container.decode(String.self, forKey: .lastModifiedTimestamp)
            self.legacyData = try container.decode(LegacyData.self, forKey: .legacyData)
            self.length = try container.decodeIfPresent(Int.self, forKey: .length) ?? 0
            self.lengthType = try container.decode([String].self, forKey: .lengthType)
            self.location = try container.decode(Location.self, forKey: .location)
            self.place = try container.decode([String].self, forKey: .place)
            self.resources = try container.decode(Resources.self, forKey: .resources)
            self.search = try container.decode(Search.self, forKey: .search)
            self.tags = try container.decode([String].self, forKey: .tags)
            self.thumbnail = try container.decode(String.self, forKey: .thumbnail)
            self.title = try container.decode([String].self, forKey: .title)
        } catch {
            print(error)
            fatalError(error.localizedDescription)
        }
    }

    var titleDisplay: String {
        title.joined(separator: " ")
    }

    var lengthTime: Time {
        return Time(totalSeconds: length)
    }

    var thumbnailURL: URL? {
        guard !thumbnail.isEmpty else {
            return nil
        }
        return URL(string: thumbnail)
    }
}

struct Day: Hashable, Codable {
    let day: String
    let month: String
    let year: String
}

struct LectureLanguage: Hashable, Codable {

    var main: String
    var translations: [String]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.main = try container.decode(String.self, forKey: .main)

        if let value = try? container.decode([String].self, forKey: .translations) {
            self.translations = value
        } else if let value = try? container.decode(String.self, forKey: .translations) {
            self.translations = [value]
        } else {
            self.translations = []
        }
    }
}

struct LegacyData: Hashable, Codable {

    var lectureCode: String
    var slug: String
    var verse: String
    var wpId: Int
}

struct Location: Hashable, Codable {

    var city: String
    var state: String
    var country: String

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

struct Resources: Hashable, Codable {
    var audios: [Audio]
}

struct Audio: Hashable, Codable {
    var creationTimestamp: String
    var downloads: Int
    var lastModifiedTimestamp: String
    var views: Int
    var url: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.creationTimestamp = try container.decode(String.self, forKey: .creationTimestamp)
        self.downloads = try container.decode(Int.self, forKey: .downloads)
        self.lastModifiedTimestamp = try container.decode(String.self, forKey: .lastModifiedTimestamp)
        self.views = try container.decode(Int.self, forKey: .views)
        self.url = try? container.decode(String.self, forKey: .url)
    }

    var audioURL: URL? {
        guard let url = url, !url.isEmpty else {
            return nil
        }
        return URL(string: url)
    }

}

struct Search: Hashable, Codable {
    var advanced: [String]
    var simple: [String]
}
