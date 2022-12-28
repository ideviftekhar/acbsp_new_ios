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
        case pause          = 3
    }

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DBLecture> {
        return NSFetchRequest<DBLecture>(entityName: "DBLecture")
    }

    @NSManaged public var id: Int
    @NSManaged public var title: String
    @NSManaged public var resources_audios_url: [String]

    // Local variables
    @NSManaged public var downloadState: Int
    @NSManaged public var downloadError: String?
    @NSManaged public var fileName: String
    @NSManaged public var resumeData: Data?

    var downloadStateEnum: DownloadState {
        guard let state = DownloadState(rawValue: downloadState) else { return .notDownloaded }
        return state
    }
}
