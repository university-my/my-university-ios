//
//  Group+ImportController.swift
//  My University
//
//  Created by Yura Voevodin on 12/19/18.
//  Copyright © 2018 Yura Voevodin. All rights reserved.
//

import CoreData

extension Group {
    
    final class ImportController: BaseModelImportController<ModelKinds.GroupModel> {
        
        /// Delete previous groups and insert new
        override func sync(from data: Data, taskContext: NSManagedObjectContext) {
            
            var groups: [Group.CodingData] = []
            do {
                let decoder = JSONDecoder()
                groups = try decoder.decode([Group.CodingData].self, from: data)
            } catch {
                completionHandler?(error)
            }
            
            taskContext.performAndWait {
                
                // University in current context
                guard let universityObjectID = university?.objectID else {
                    self.completionHandler?(nil)
                    return
                }
                guard let universityInContext = taskContext.object(with: universityObjectID) as? UniversityEntity else {
                    self.completionHandler?(nil)
                    return
                }
                
                // Groups to update
                let toUpdate = GroupEntity.fetch(groups, university: universityInContext, context: taskContext)
                
                // IDs to update
                let idsToUpdate = toUpdate.compactMap({ group in
                    return group.slug
                })
                
                // Find groups to insert
                let toInsert = groups.filter({ group in
                    return (idsToUpdate.contains(group.slug) == false)
                })
                
                // IDs
                let slugs = groups.map({ group in
                    return group.slug
                })
                
                // Now find groups to delete
                let allGroups = GroupEntity.fetchAll(university: universityInContext, context: taskContext)
                let toDelete = allGroups.filter({ group in
                  if let slug = group.slug {
                    return (slugs.contains(slug) == false)
                  } else {
                    return true
                  }
                })
                
                // 1. Delete
                for group in toDelete {
                    taskContext.delete(group)
                }
                
                // 2. Update
                for group in toUpdate {
                    if let groupFromServer = groups.first(where: { (parsedGroup) -> Bool in
                        return parsedGroup.slug == group.slug
                    }) {
                        // Update name if changed
                        if groupFromServer.name != group.name {
                            group.name = groupFromServer.name
                            if let firstCharacter = groupFromServer.name.first {
                                group.firstSymbol = String(firstCharacter).uppercased()
                            } else {
                                group.firstSymbol = ""
                            }
                        }
                        
                        if (group.records?.count ?? 0) > 0 {
                            // Delete all related records
                            // Because Group can be changed to another one.
                            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = RecordEntity.fetchRequest()
                            
                            fetchRequest.predicate = NSPredicate(format: "ANY groups = %@", group)
                            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                            deleteRequest.resultType = .resultTypeObjectIDs
                            do {
                                let result = try taskContext.execute(deleteRequest) as? NSBatchDeleteResult
                                if let objectIDArray = result?.result as? [NSManagedObjectID] {
                                    let changes = [NSDeletedObjectsKey: objectIDArray]
                                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self.persistentContainer.viewContext])
                                }
                            } catch {
                                completionHandler?(error)
                            }
                        }
                    }
                }
                
                // 3. Insert
                for group in toInsert {
                    self.insert(group, university: universityInContext, context: taskContext)
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
        
        private func insert(_ parsedGroup: Group.CodingData, university: UniversityEntity, context: NSManagedObjectContext) {
            let groupEntity = GroupEntity(context: context)
            
            if let firstCharacter = parsedGroup.name.first {
                groupEntity.firstSymbol = String(firstCharacter).uppercased()
            } else {
                groupEntity.firstSymbol = ""
            }
            groupEntity.id = parsedGroup.id
            groupEntity.name = parsedGroup.name
            groupEntity.university = university
            groupEntity.slug = parsedGroup.slug
        }
    }
}