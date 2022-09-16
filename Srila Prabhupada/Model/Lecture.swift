//
//  Lecture.swift
//  Srila Prabhupada
//
//  Created by IE03 on 13/09/22.
//

import Foundation

struct Lecture: Hashable, Equatable {

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)

    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.length == rhs.length
    }

    var category: [String]
    var creationTimestamp: String
    var dateOfRecording: Day
    var descriptions: [String]
    var id: Int
    var language: [String: Any]
    var lastModifiedTimestamp: String
    var legacyData: [String: Any]
    var length: Time
    var lengthType: [String]
    var location: [String: Any]
    var place: [String]
    var resources: [String: Any]
    var search: [String: Any]
    var tags: [String]
    var thumbnail: URL?
    var title: [String]

    init(_ attributes: [String: Any]) {

        self.category = attributes["category"] as? [String] ?? []
        self.creationTimestamp = attributes["creationTimestamp"] as? String ?? ""
        let dateOfRecording = attributes["dateOfRecording"] as? [String: String] ?? [:]
        self.dateOfRecording = Day(day: dateOfRecording["day"] ?? "", month: dateOfRecording["month"] ?? "", year: dateOfRecording["year"] ?? "")
        self.descriptions = attributes["description"] as? [String] ?? []
        self.id = attributes["id"] as? Int ?? 0
        self.language = attributes["language"] as? [String: Any] ?? [:]
        self.lastModifiedTimestamp = attributes["lastModifiedTimestamp"] as? String ?? ""
        self.legacyData = attributes["legacyData"] as? [String: Any] ?? [:]
        let length = attributes["length"] as? Int ?? 0
        self.length = Time(totalSeconds: length)
        self.lengthType = attributes["lengthType"] as? [String] ?? []
        self.location = attributes["location"] as? [String: Any] ?? [:]
        self.place = attributes["place"] as? [String] ?? []
        self.resources = attributes["resources"] as? [String: Any] ?? [:]
        self.search = attributes["resources"] as? [String: Any] ?? [:]
        self.tags = attributes["tags"] as? [String] ?? []
        let thumbnailString = attributes["thumbnail"] as? String ?? ""

        if !thumbnailString.isEmpty {
            thumbnail = URL(string: thumbnailString)
        } else {
            thumbnail = nil
        }

        self.title = attributes["title"] as? [String] ?? []
    }

    var titleDisplay: String {
        title.joined(separator: " ")
    }

    var locationDisplay: String {

        var locations: [String] = []

        if let value = self.location["city"] as? String, !value.isEmpty {
            locations.append(value)
        }

        if let value = self.location["state"] as? String, !value.isEmpty {
            locations.append(value)
        }

        if let value = self.location["country"] as? String, !value.isEmpty {
            locations.append(value)
        }

        return locations.joined(separator: ", ")
    }
}
