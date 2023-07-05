//
//  Lecture.swift
//  Srila Prabhupada
//
//  Created by IE03 on 13/09/22.
//

import Foundation
import CoreGraphics

struct Lecture: Hashable, Codable {

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
//        hasher.combine(creationTimestamp)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id &&
        lhs.titleDisplay == rhs.titleDisplay &&
        lhs.dateOfRecording == rhs.dateOfRecording &&
        lhs.creationTimestamp == rhs.creationTimestamp &&
        lhs.resources == rhs.resources &&
        lhs.downloadState == rhs.downloadState &&
        lhs.isFavorite == rhs.isFavorite &&
        lhs.lastPlayedPoint == rhs.lastPlayedPoint
    }

    let category: [String]
    let creationTimestamp: Date?
    let dateOfRecording: Day
    let description: [String]
    let id: Int
    let language: Language
    let lastModifiedTimestamp: Date?
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

    private(set) lazy var searchableTexts: [String] = {
        var searchableTexts: [String] = []
        searchableTexts.append(title.joined(separator: " "))
        searchableTexts.append(contentsOf: category)
        searchableTexts.append(contentsOf: description)
        searchableTexts.append(language.main)
        searchableTexts.append(contentsOf: language.translations)
        searchableTexts.append(legacyData.verse)
        searchableTexts.append(location.city)
        searchableTexts.append(location.state)
        searchableTexts.append(location.country)
        searchableTexts.append(contentsOf: search.simple)
        searchableTexts.append(contentsOf: search.advanced)
        searchableTexts.append(contentsOf: tags)
        searchableTexts.removeAll { $0.isEmpty }
        return searchableTexts
    }()

    var downloadState: DBLecture.DownloadState = .notDownloaded
    var downloadError: String?
    var isFavorite: Bool
    var lastPlayedPoint: Int = 0

    var isCompleted: Bool {
        lastPlayedPoint == length || lastPlayedPoint == -1
    }

    var playProgress: CGFloat {
        let progress: CGFloat

        if length != 0 {
            progress = CGFloat(lastPlayedPoint) / CGFloat(length)
        } else {
            progress = 0
        }

        return progress
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.category = (try? container.decode([String].self, forKey: .category)) ?? []
        self.dateOfRecording = try container.decode(Day.self, forKey: .dateOfRecording)
        self.description = try container.decode([String].self, forKey: .description)
        self.language = try container.decode(Language.self, forKey: .language)
        self.legacyData = try container.decode(LegacyData.self, forKey: .legacyData)
        self.length = try container.decodeIfPresent(Int.self, forKey: .length) ?? 0
        self.lengthType = try container.decode([String].self, forKey: .lengthType)
        self.location = try container.decode(Location.self, forKey: .location)
        self.place = (try? container.decode([String].self, forKey: .place)) ?? []
        self.resources = try container.decode(Resources.self, forKey: .resources)
        self.search = try container.decode(Search.self, forKey: .search)
        self.tags = try container.decode([String].self, forKey: .tags)
        self.thumbnail = (try? container.decode(String.self, forKey: .thumbnail)) ?? ""
        self.title = try container.decode([String].self, forKey: .title)

        let creationTimestamp = try container.decode(String.self, forKey: .creationTimestamp)
        self.creationTimestamp = DateFormatter.isoDateFormatter.date(from: creationTimestamp)

        let lastModifiedTimestamp = try container.decode(String.self, forKey: .lastModifiedTimestamp)
        self.lastModifiedTimestamp = DateFormatter.isoDateFormatter.date(from: lastModifiedTimestamp)

        isFavorite = (try? container.decodeIfPresent(Bool.self, forKey: .isFavorite)) ?? false
        lastPlayedPoint = (try? container.decodeIfPresent(Int.self, forKey: .lastPlayedPoint)) ?? 0
        downloadState = (try? container.decodeIfPresent(DBLecture.DownloadState.self, forKey: .downloadState)) ?? .notDownloaded
        downloadError = (try? container.decodeIfPresent(String.self, forKey: .downloadError)) ?? nil
    }

    static func createNewDBLecture(lecture: Lecture) -> DBLecture {

        let dbLecture = DBLecture.insertInContext(context: nil)
        dbLecture.id = lecture.id
        dbLecture.title = lecture.titleDisplay
        dbLecture.resources_audios_url = lecture.resources.audios.map({ $0.url ?? "" })
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
}
