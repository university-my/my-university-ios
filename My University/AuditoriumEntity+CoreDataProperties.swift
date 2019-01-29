//
//  AuditoriumEntity+CoreDataProperties.swift
//  My University
//
//  Created by Yura Voevodin on 1/29/19.
//  Copyright © 2019 Yura Voevodin. All rights reserved.
//
//

import Foundation
import CoreData


extension AuditoriumEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AuditoriumEntity> {
        return NSFetchRequest<AuditoriumEntity>(entityName: "AuditoriumEntity")
    }

    @NSManaged public var firstSymbol: String?
    @NSManaged public var id: Int64
    @NSManaged public var name: String?
    @NSManaged public var isVisited: Bool
    @NSManaged public var records: NSSet?

}

// MARK: Generated accessors for records
extension AuditoriumEntity {

    @objc(addRecordsObject:)
    @NSManaged public func addToRecords(_ value: RecordEntity)

    @objc(removeRecordsObject:)
    @NSManaged public func removeFromRecords(_ value: RecordEntity)

    @objc(addRecords:)
    @NSManaged public func addToRecords(_ values: NSSet)

    @objc(removeRecords:)
    @NSManaged public func removeFromRecords(_ values: NSSet)

}
