//
//  Lecture.swift
//  Srila Prabhupada
//
//  Created by IE03 on 13/09/22.
//

import Foundation
import CoreGraphics
import FirebaseFirestoreSwift

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

    // Local Variables
    var playedCount: Int?
    var playedText: String?

    private(set) lazy var searchableTexts: [String] = {
        var searchableTexts: [String] = []
        searchableTexts.append(title.joined(separator: " "))
        searchableTexts.append(contentsOf: category)
        searchableTexts.append(contentsOf: description)
        searchableTexts.append("\(id)")
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

    var downloadState: DBLecture.DownloadState
    var downloadError: String?
    var isFavorite: Bool
    var lastPlayedPoint: Int

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

        if let value = try? container.decode(Date.self, forKey: .creationTimestamp) {
            self.creationTimestamp = value
        } else if let creationTimestamp = try? container.decode(String.self, forKey: .creationTimestamp) {
            self.creationTimestamp = DateFormatter.isoDateFormatter.date(from: creationTimestamp)
        } else {
            self.creationTimestamp = nil
        }

        if let value = try? container.decode(Date.self, forKey: .lastModifiedTimestamp) {
            self.lastModifiedTimestamp = value
        } else if let lastModifiedTimestamp = try? container.decode(String.self, forKey: .lastModifiedTimestamp) {
            self.lastModifiedTimestamp = DateFormatter.isoDateFormatter.date(from: lastModifiedTimestamp)
        } else {
            self.lastModifiedTimestamp = nil
        }

        if let value = try? container.decodeIfPresent(Bool.self, forKey: .isFavorite) {
            self.isFavorite = value
        } else {
            self.isFavorite = false
        }

        if let value = try? container.decodeIfPresent(Int.self, forKey: .lastPlayedPoint) {
            self.lastPlayedPoint = value
        } else {
            self.lastPlayedPoint = 0
        }

        if let value = try? container.decodeIfPresent(DBLecture.DownloadState.self, forKey: .downloadState) {
            self.downloadState = value
        } else {
            self.downloadState = .notDownloaded
        }

        if let value = try? container.decodeIfPresent(String.self, forKey: .downloadError) {
            self.downloadError = value
        } else {
            self.downloadError = nil
        }
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
}

extension Lecture {

    var isCompleted: Bool {
        lastPlayedPoint >= length || lastPlayedPoint == -1
    }

    var isPartiallyPlayed: Bool {
        let playProgress = playProgress
        return playProgress > 0.0 && playProgress < 1.0
    }

    var playProgress: CGFloat {
        let progress: CGFloat

        if lastPlayedPoint == -1 {
            progress = 1.0
        } else if length != 0 {
            progress = CGFloat(lastPlayedPoint) / CGFloat(length)
        } else {
            progress = 0
        }

        return progress
    }

    var titleDisplay: String {
        title.joined(separator: " ")
    }

    var playedTime: Time {

        let playedTime: Int
        if length != 0 {
            if lastPlayedPoint < 0 {
                playedTime = length
            } else {
                playedTime = lastPlayedPoint
            }
        } else {
            playedTime = 0
        }

        return Time(totalSeconds: playedTime)
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


import FirebaseDynamicLinks

extension Lecture {
    func generateShareLink(completion: @escaping (Swift.Result<URL, Error>) -> Void) {
        let deepLinkBaseURL = "https://bvks.com?lectureId=\(id)"
        let domainURIPrefix = Constants.domainURIPrefix

        guard let link = URL(string: deepLinkBaseURL),
              let linkBuilder = DynamicLinkComponents(link: link, domainURIPrefix: domainURIPrefix) else {
            return
        }

        do {
            let iOSParameters = DynamicLinkIOSParameters(bundleID: Constants.iOSBundleIdentifier)
            iOSParameters.appStoreID = "\(Constants.appStoreIdentifier)"
            linkBuilder.iOSParameters = iOSParameters
        }

        do {
            let androidParameters = DynamicLinkAndroidParameters(packageName: Constants.androidBundleIdentifier)
             linkBuilder.androidParameters = androidParameters
        }

        var descriptions: [String] = []
        do {
            let durationString = "• Duration: " + lengthTime.displayString
            descriptions.append(durationString)

            if !legacyData.verse.isEmpty {
                let verseString = "• " + legacyData.verse
                descriptions.append(verseString)
            }

            let recordingDateString = "• Date of Recording: " + dateOfRecording.display_dd_MM_yyyy
            descriptions.append(recordingDateString)

            if !location.displayString.isEmpty {
                let locationString = "• Location: " + location.displayString
                descriptions.append(locationString)
            }
        }

        do {
            let socialMediaParameters = DynamicLinkSocialMetaTagParameters()
            socialMediaParameters.title = titleDisplay
            socialMediaParameters.descriptionText = descriptions.joined(separator: "\n")
            if let thumbnailURL = thumbnailURL {
                socialMediaParameters.imageURL = thumbnailURL
            }
            linkBuilder.socialMetaTagParameters = socialMediaParameters
        }

        linkBuilder.options = DynamicLinkComponentsOptions()
        linkBuilder.options?.pathLength = .short
        linkBuilder.shorten(completion: { url, _, error in
            if let url = url {
                completion(.success(url))
            } else if let url = linkBuilder.url {
                completion(.success(url))
            } else if let error = error {
                completion(.failure(error))
            }
        })
    }
}
