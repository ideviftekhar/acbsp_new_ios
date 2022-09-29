//
//  Lecture.swift
//  Srila Prabhupada
//
//  Created by IE03 on 13/09/22.
//

import Foundation

struct Lecture: Hashable, Codable {

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id &&
        lhs.creationTimestamp == rhs.creationTimestamp &&
        lhs.resources == rhs.resources &&
        lhs.downloadingState == rhs.downloadingState &&
        lhs.isFavourites == rhs.isFavourites &&
        lhs.playProgress == rhs.playProgress
    }

    let category: [String]
    let creationTimestamp: String
    let dateOfRecording: Day
    let description: [String]
    let id: Int
    let language: LectureLanguage
    let lastModifiedTimestamp: String
    let legacyData: LegacyData
    let length: Int
    let lengthType: [String]
    let location: Location
    let place: [String]
    let resources: Resources
    let search: Search
    let tags: [String]
    let thumbnail: String
    let title: [String]

    var downloadingState: DBLecture.DownloadState = .notDownloaded
    var isFavourites: Bool = false
    private(set) var playProgress: Int = 0

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
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

        downloadingState = Persistant.shared.lectureDownloadState(lecture: self)
        isFavourites = false
        playProgress = Int.random(in: 0...100)
    }

    init(from dbLecture: DBLecture) {

        self.id = dbLecture.id
        self.category = dbLecture.category
        self.creationTimestamp = dbLecture.creationTimestamp
        self.dateOfRecording = Day(day: dbLecture.dateOfRecording_day, month: dbLecture.dateOfRecording_month, year: dbLecture.dateOfRecording_year)
        self.description = dbLecture.aDescription
        self.language = LectureLanguage(main: dbLecture.language_main, translations: dbLecture.language_translations)
        self.lastModifiedTimestamp =  dbLecture.lastModifiedTimestamp
        self.legacyData = LegacyData(lectureCode: dbLecture.legacyData_lectureCode, slug: dbLecture.legacyData_slug, verse: dbLecture.legacyData_verse, wpId: dbLecture.legacyData_wpId)
        self.length = dbLecture.length
        self.lengthType = dbLecture.lengthType
        self.location = Location(city: dbLecture.location_city, state: dbLecture.location_state, country: dbLecture.location_country)
        self.place = dbLecture.place

        var audios: [Audio] = []
        for url in dbLecture.resources_audios_url {
            audios.append(Audio(creationTimestamp: "", downloads: 0, lastModifiedTimestamp: "", views: 0, url: url))
        }

        self.resources =  Resources(audios: audios)
        self.search = Search(advanced: dbLecture.search_advanced, simple: dbLecture.search_simple)
        self.tags = dbLecture.tags
        self.thumbnail = dbLecture.thumbnail
        self.title = dbLecture.title

        downloadingState = Persistant.shared.lectureDownloadState(lecture: self)
        isFavourites = false
        playProgress = Int.random(in: 0...100)
    }

    static func createNewDBLecture(lecture: Lecture) -> DBLecture {

        let dbLecture = DBLecture.insertInContext(context: nil)
        dbLecture.aDescription = lecture.description
        dbLecture.category = lecture.category
        dbLecture.creationTimestamp = lecture.creationTimestamp
        dbLecture.dateOfRecording_day = lecture.dateOfRecording.day
        dbLecture.dateOfRecording_month = lecture.dateOfRecording.month
        dbLecture.dateOfRecording_year = lecture.dateOfRecording.year
        dbLecture.id = lecture.id
        dbLecture.language_main = lecture.language.main
        dbLecture.language_translations = lecture.language.translations
        dbLecture.lastModifiedTimestamp = lecture.lastModifiedTimestamp
        dbLecture.legacyData_lectureCode = lecture.legacyData.lectureCode
        dbLecture.legacyData_slug = lecture.legacyData.slug
        dbLecture.legacyData_verse = lecture.legacyData.verse
        dbLecture.legacyData_wpId = lecture.legacyData.wpId
        dbLecture.length = lecture.length
        dbLecture.lengthType = lecture.lengthType
        dbLecture.location_city = lecture.location.city
        dbLecture.location_state = lecture.location.state
        dbLecture.location_country = lecture.location.country
        dbLecture.place = lecture.place
        dbLecture.resources_audios_url = lecture.resources.audios.map({ $0.url ?? "" })
        dbLecture.search_advanced = lecture.search.advanced
        dbLecture.search_simple = lecture.search.simple
        dbLecture.tags = lecture.tags
        dbLecture.thumbnail = lecture.thumbnail
        dbLecture.title = lecture.title
        dbLecture.downloadState = DBLecture.DownloadState.notDownloaded.rawValue

        if let audios = lecture.resources.audios.first, let audioURL = audios.audioURL {
            dbLecture.fileName = "\(lecture.id).\(audioURL.pathExtension)"
        } else {
            dbLecture.fileName = "\(lecture.id)"
        }

        return dbLecture
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

    var localFileURL: URL? {

        return DownloadManager.shared.localFileURL(for: self)
    }
}

struct Day: Hashable, Codable {
    let day: Int
    let month: Int
    let year: Int

    init(day: Int, month: Int, year: Int) {
        self.day = day
        self.month = month
        self.year = year
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let value = try? container.decode(String.self, forKey: .day), let valueInt = Int(value) {
            day = valueInt
        } else if let value = try? container.decode(Int.self, forKey: .day) {
            day = value
        } else {
            day = 0
        }

        if let value = try? container.decode(String.self, forKey: .month), let valueInt = Int(value) {
            month = valueInt
        } else if let value = try? container.decode(Int.self, forKey: .month) {
            month = value
        } else {
            month = 0
        }

        if let value = try? container.decode(String.self, forKey: .year), let valueInt = Int(value) {
            year = valueInt
        } else if let value = try? container.decode(Int.self, forKey: .year) {
            year = value
        } else {
            year = 0
        }
    }
}

struct LectureLanguage: Hashable, Codable {

    let main: String
    let translations: [String]

    init(main: String, translations: [String]) {
        self.main = main
        self.translations = translations
    }

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

    let lectureCode: String
    let slug: String
    let verse: String
    let wpId: Int

    init(lectureCode: String, slug: String, verse: String, wpId: Int) {
        self.lectureCode = lectureCode
        self.slug = slug
        self.verse = verse
        self.wpId = wpId
    }
}

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

struct Resources: Hashable, Codable {
    let audios: [Audio]

    init(audios: [Audio]) {
        self.audios = audios
    }
}

struct Audio: Hashable, Codable {
    let creationTimestamp: String
    let downloads: Int
    let lastModifiedTimestamp: String
    let views: Int
    let url: String?

    init(creationTimestamp: String, downloads: Int, lastModifiedTimestamp: String, views: Int, url: String?) {
        self.creationTimestamp = creationTimestamp
        self.downloads = downloads
        self.lastModifiedTimestamp = lastModifiedTimestamp
        self.views = views
        self.url = url
    }

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
    let advanced: [String]
    let simple: [String]
}
