//
//  Persistant.swift
//  
//
//  Created by IE06 on 21/09/22.
//

import Foundation
import CoreData
import Reachability

class Persistant: NSObject {

    struct Notification {
        static let downloadsAdded = Foundation.Notification.Name(rawValue: "downloadsAddedNotification")
        static let downloadUpdated = Foundation.Notification.Name(rawValue: "downloadUpdatedNotification")
        static let downloadsRemoved = Foundation.Notification.Name(rawValue: "downloadsRemovedNotification")
    }

    private let storeName: String = "SrilaDatabase"

    static let shared = Persistant()

    private let reachability: Reachability?

    var dbLectures: [DBLecture] = []

    override init () {

        reachability = try? Reachability()

        super.init()

        dbLectures = getDbLectures()

        addReachabilityObserver()
    }

    private func addReachabilityObserver() {
        guard let reachability = reachability else {
            return
        }
        reachability.whenReachable = { reachability in
            if reachability.connection == .wifi {
                print("Reachable via WiFi")
            } else {
                print("Reachable via Cellular")
            }

            self.reschedulePendingDownloads()
        }
        reachability.whenUnreachable = { _ in
            print("Not reachable")
        }

        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }

    // MARK: - Core Data stack
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

    func fetch<T: NSManagedObject>(in context: NSManagedObjectContext) -> [T] {

        let fetchRequest = NSFetchRequest<T>(entityName: T.entityName)

        do {
            let objects: [T] = try context.fetch(fetchRequest)
            return objects
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }

        return []
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
