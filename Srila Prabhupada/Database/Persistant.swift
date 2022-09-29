//
//  Persistant.swift
//  
//
//  Created by IE06 on 21/09/22.
//

import Foundation
import CoreData

class Persistant: NSObject {

    static let downloadAddedNotification = Notification.Name(rawValue: "downloadAddedNotification")
    static let downloadUpdatedNotification = Notification.Name(rawValue: "downloadUpdatedNotification")
    static let downloadRemovedNotification = Notification.Name(rawValue: "downloadRemovedNotification")

    static let shared = Persistant()

    private(set) var dbLectures: [DBLecture] = []

    override init () {
        super.init()

        dbLectures = getDbLectures()
    }

    // MARK: - Core Data stack
    private let storeName: String = "SrilaDatabase"
    lazy var storeURL: URL = {
        let storePaths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        let storePath = storePaths[0] as NSString
        let fileManager = FileManager.default

        do {
            try fileManager.createDirectory(atPath: storePath as String, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Error creating storePath \(storePath): \(error)")
        }

        let sqliteFilePath = storePath.appendingPathComponent(storeName + ".sqlite")
        return URL(fileURLWithPath: sqliteFilePath)
    }()

    lazy var storeDescription: NSPersistentStoreDescription = {
        let description = NSPersistentStoreDescription(url: self.storeURL)
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true

        return description
    }()

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */

        let container = NSPersistentContainer(name: storeName)
        container.persistentStoreDescriptions = [self.storeDescription]

        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            } else {
                container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
                container.viewContext.name = "MainContext"
            }
        })

        return container
    }()

    var mainContext: NSManagedObjectContext {
        return self.persistentContainer.viewContext
    }

    // Save main context
    func saveMainContext(_ completionHandler: (() -> Void)?) {

        mainContext.perform {

            if self.mainContext.hasChanges {

                do {
                    try self.mainContext.save()
                } catch let error as NSError {
                    print("Could not save. \(error), \(error.userInfo)")
                }
            }

            if let finalCompletionHandler = completionHandler {
                OperationQueue.main.addOperation {
                    finalCompletionHandler()
                }
            }
        }
    }

    func performBlockAndSaveNewPrivateContext(_ newPrivateContextHandler: ((_ privateContext: NSManagedObjectContext) -> Void)?, saveCompletion completionHandler: (() -> Void)?) {

        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = mainContext
        context.name = "PrivateContext"
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        context.perform {

            if let privateContextHandler = newPrivateContextHandler {
                privateContextHandler(context)
            }

            // Save
            if context.hasChanges {

                do {
                    try context.save()
                } catch let error as NSError {
                    print("Could not save. \(error), \(error.userInfo)")
                }

                self.saveMainContext({
                    if let finalCompletionHandler = completionHandler {
                        finalCompletionHandler()
                    }
                })
            } else {
                DispatchQueue.main.async {
                    if let finalCompletionHandler = completionHandler {
                        finalCompletionHandler()
                    }
                }
            }
        }
    }

    func deleteObject(object: NSManagedObject?) {
        if let object = object {
            object.managedObjectContext?.delete(object)
        }
    }

    func clearCoreDataStore() {
        let context = mainContext

        for i in 0...persistentContainer.managedObjectModel.entities.count-1 {
            let entity = persistentContainer.managedObjectModel.entities[i]

            do {
                let query = NSFetchRequest<NSFetchRequestResult>(entityName: entity.name!)
                let deleterequest = NSBatchDeleteRequest(fetchRequest: query)
                try context.execute(deleterequest)
                try context.save()

            } catch let error as NSError {
                print("Error: \(error.localizedDescription)")
                abort()
            }
        }
    }
}

extension Persistant {

    func reschedulePendingDownloads() {

        let dbPendingDownloadedLectures: [DBLecture] = dbLectures.filter { $0.downloadStateEnum != .downloaded }

        for dbLecture in dbPendingDownloadedLectures {
            downloadStage1(dbLecture: dbLecture)
        }
    }

    func save(lecture: Lecture) {

        if let dbLecture = dbLectures.first(where: { $0.id == lecture.id }) {

            switch dbLecture.downloadStateEnum {
            case .notDownloaded, .error:
                downloadStage1(dbLecture: dbLecture)
            case .downloading, .downloaded:
                break
            }

        } else {
            let dbLecture = Lecture.createNewDBLecture(lecture: lecture)
            self.dbLectures.insert(dbLecture, at: 0)
            downloadStage1(dbLecture: dbLecture)
        }
    }

    func delete(lecture: Lecture) {

        guard let index = dbLectures.firstIndex(where: { $0.id == lecture.id }) else {
            return
        }

        do {
            let dbLecture = dbLectures[index]
            let documentDirectoryURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let destinationURL = documentDirectoryURL.appendingPathComponent(dbLecture.fileName)

            // Delete file in document directory
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }

            dbLectures.remove(at: index)
            dbLecture.downloadState = DBLecture.DownloadState.notDownloaded.rawValue
            NotificationCenter.default.post(name: Self.downloadRemovedNotification, object: dbLecture)
            deleteObject(object: dbLecture)
            saveMainContext(nil)
        } catch {

        }
    }

    private func getDbLectures() -> [DBLecture] {

        let finalContext = mainContext

        var objects = [DBLecture]()

        let fetchRequest = NSFetchRequest<DBLecture>(entityName: DBLecture.entityName)

        do {
            objects = try finalContext.fetch(fetchRequest)

        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }

        return objects
    }

    func lectureDownloadState(lecture: Lecture) -> DBLecture.DownloadState {
        if let object = dbLectures.first(where: { $0.id == lecture.id }) {
            return object.downloadStateEnum
        } else {
            return .notDownloaded
        }
    }
}

extension Persistant {

    private func downloadStage1(dbLecture: DBLecture) {

        do {
            let documentDirectoryURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

            let destinationURL = documentDirectoryURL.appendingPathComponent(dbLecture.fileName)

            // check if it exists before downloading it
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                dbLecture.downloadState = DBLecture.DownloadState.downloaded.rawValue
            } else {
                dbLecture.downloadState = DBLecture.DownloadState.downloading.rawValue
            }

            self.saveMainContext(nil)
            NotificationCenter.default.post(name: Self.downloadAddedNotification, object: dbLecture)

            if dbLecture.downloadStateEnum != .downloaded {
                downloadStage2(dbLecture: dbLecture)
            }
        } catch let error {
            dbLecture.downloadState = DBLecture.DownloadState.error.rawValue
            dbLecture.downloadError = error.localizedDescription
            self.saveMainContext(nil)
            NotificationCenter.default.post(name: Self.downloadUpdatedNotification, object: dbLecture)
        }
    }

    private func downloadStage2(dbLecture: DBLecture) {

        guard let audioURLString = dbLecture.resources_audios_url.first, let audioURL = URL(string: audioURLString) else {
            return
        }

        do {
            let documentDirectoryURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let destinationURL = documentDirectoryURL.appendingPathComponent(dbLecture.fileName)

            let downloadTask = URLSession.shared.downloadTask(with: audioURL, completionHandler: { (downloadedURL, response, error) in

                DispatchQueue.main.async {
                    if let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                       let mimeType = httpURLResponse.mimeType, mimeType.hasPrefix("audio"),
                       let downloadedURL = downloadedURL {

                        do {
                            try FileManager.default.moveItem(at: downloadedURL, to: destinationURL)
                            dbLecture.downloadState = DBLecture.DownloadState.downloaded.rawValue
                            self.saveMainContext(nil)
                            NotificationCenter.default.post(name: Self.downloadUpdatedNotification, object: dbLecture)
                        } catch let error {
                            dbLecture.downloadState = DBLecture.DownloadState.error.rawValue
                            dbLecture.downloadError = error.localizedDescription
                            self.saveMainContext(nil)
                            NotificationCenter.default.post(name: Self.downloadUpdatedNotification, object: dbLecture)
                        }
                    } else {
                        dbLecture.downloadState = DBLecture.DownloadState.error.rawValue
                        dbLecture.downloadError = error?.localizedDescription ?? "Unable to download the audio file"
                        self.saveMainContext(nil)
                        NotificationCenter.default.post(name: Self.downloadUpdatedNotification, object: dbLecture)
                    }
                }
            })

            downloadTask.resume()
        } catch let error {
            dbLecture.downloadState = DBLecture.DownloadState.error.rawValue
            dbLecture.downloadError = error.localizedDescription
            self.saveMainContext(nil)
            NotificationCenter.default.post(name: Self.downloadUpdatedNotification, object: dbLecture)
        }
    }
}
