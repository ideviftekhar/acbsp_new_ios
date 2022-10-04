//
//  NSManagedObject+Extensions.swift
//  Flight
//
//  Created by IftekharSSD on 25/04/22.
//

import CoreData

extension NSManagedObject {

    public class var entityName: String {
        return NSStringFromClass(self)
    }

    public class func insertInContext(context: NSManagedObjectContext?) -> Self {

        let finalContext: NSManagedObjectContext = context ?? Persistant.shared.mainContext

        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: finalContext) else {
            fatalError("Could not found NSEntityDescription")
        }

        guard let object = NSManagedObject(entity: entity, insertInto: finalContext) as? Self else {
            fatalError("Could not create an object of type \(Self.self)")
        }
        return object
    }
}
