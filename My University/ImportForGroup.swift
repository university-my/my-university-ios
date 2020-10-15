//
//  ImportForGroup.swift
//  My University
//
//  Created by Yura Voevodin on 12/9/18.
//  Copyright © 2018 Yura Voevodin. All rights reserved.
//

import CoreData

extension Record {
    
    #warning("Try to make single class")
    
    final class ImportForGroup: BaseRecordImportController<ModelKinds.GroupModel> {
        
        /// Delete previous records and insert new records
        override func sync(_ records: [Record.CodingData], taskContext: NSManagedObjectContext) {
            
            taskContext.performAndWait {
                
                guard let groupInContext = Group.fetch(id: modelID, context: taskContext) else {
                    self.completionHandler?(nil)
                    return
                }
                
                // Records to update
                let toUpdate = RecordEntity.fetch(records, group: groupInContext, context: taskContext)
                
                // IDs to update
                let idsToUpdate = toUpdate.map({ record in
                    return record.id
                })
                
                // Find records to insert
                let toInsert = records.filter({ record in
                    return (idsToUpdate.contains(record.id) == false)
                })
                
                // Update
                for record in toUpdate {
                    if let recordFromServer = records.first(where: { parsedRecord in
                        return parsedRecord.id == record.id
                    }) {
                        record.date = recordFromServer.date
                        record.dateString = recordFromServer.dateString
                        record.pairName = recordFromServer.pairName
                        record.name = recordFromServer.name
                        record.reason = recordFromServer.reason
                        record.time = recordFromServer.time
                        record.type = recordFromServer.type
                    }
                }
                
                // Insert
                for record in toInsert {
                    self.insert(record, group: groupInContext, context: taskContext)
                }
                
                // Finishing import. Save context.
                if taskContext.hasChanges {
                    do {
                        try taskContext.save()
                    } catch {
                        self.completionHandler?(error)
                    }
                }
                
                // Reset the context to clean up the cache and low the memory footprint.
                taskContext.reset()
                
                // Finish.
                self.completionHandler?(nil)
            }
        }
        
        /// Insert new record with related group
        private func insert(_ parsedRecord: Record.CodingData, group: GroupEntity, context: NSManagedObjectContext) {
            let recordEntity = RecordEntity(context: context)
            
            recordEntity.id = NSNumber(value: parsedRecord.id).int64Value
            recordEntity.date = parsedRecord.date
            recordEntity.dateString = parsedRecord.dateString
            recordEntity.pairName = parsedRecord.pairName
            recordEntity.name = parsedRecord.name
            recordEntity.reason = parsedRecord.reason
            recordEntity.time = parsedRecord.time
            recordEntity.type = parsedRecord.type
            
            // Fetch classroom entity for set relation with record
            if let object = parsedRecord.classroom {
                recordEntity.classroom = Classroom.fetch(id: object.id, context: context)
            }
            
            // Groups
            if let university = group.university {
                let groups = Group.fetch(parsedRecord.groups, for: university, in: context)
                let set = NSSet(array: groups)
                recordEntity.addToGroups(set)
            }
            
            // Fetch teacher entity for set relation with record
            if let object = parsedRecord.teacher {
                recordEntity.teacher = Teacher.fetch(id: object.id, context: context)
            }
        }
    }
}
