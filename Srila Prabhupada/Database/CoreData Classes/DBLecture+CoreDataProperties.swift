//
//  DownloadLecture+CoreDataProperties.swift
//  
//
//  Created by IE06 on 21/09/22.
//
//

import Foundation
import CoreData

extension DBLecture {

    enum DownloadState: Int, Codable, Hashable {
        case notDownloaded  = -1
        case downloading    = 0
        case downloaded     = 1
        case error          = 2
    }

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DBLecture> {
        return NSFetchRequest<DBLecture>(entityName: "DBLecture")
    }

    @NSManaged public var aDescription: [String]

    @NSManaged public var category: [String]
    @NSManaged public var creationTimestamp: String

    @NSManaged public var dateOfRecording_day: Int
    @NSManaged public var dateOfRecording_month: Int
    @NSManaged public var dateOfRecording_year: Int

    @NSManaged public var id: Int

    @NSManaged public var language_main: String
    @NSManaged public var language_translations: [String]

    @NSManaged public var lastModifiedTimestamp: String

    @NSManaged public var legacyData_lectureCode: String
    @NSManaged public var legacyData_slug: String
    @NSManaged public var legacyData_verse: String
    @NSManaged public var legacyData_wpId: Int

    @NSManaged public var length: Int
    @NSManaged public var lengthType: [String]

    @NSManaged public var location_city: String
    @NSManaged public var location_state: String
    @NSManaged public var location_country: String

    @NSManaged public var place: [String]

    @NSManaged public var resources_audios_url: [String]

    @NSManaged public var search_advanced: [String]
    @NSManaged public var search_simple: [String]

    @NSManaged public var tags: [String]
    @NSManaged public var thumbnail: String
    @NSManaged public var title: [String]

    // Local variables
    @NSManaged public var downloadState: Int
    @NSManaged public var downloadError: String?
    @NSManaged public var fileName: String

    var downloadStateEnum: DownloadState {
        guard let state = DownloadState(rawValue: downloadState) else { return .notDownloaded }
        return state
    }
}
