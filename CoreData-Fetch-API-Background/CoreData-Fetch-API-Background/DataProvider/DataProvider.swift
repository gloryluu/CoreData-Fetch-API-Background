//
//  DataProvider.swift
//  CoreData-Fetch-API-Background
//
//  Created by Quang V. Luu on 12/19/19.
//  Copyright © 2019 Officience SARL. All rights reserved.
//

import CoreData

class DataProvider {
    private let persistentContainer: NSPersistentContainer
    private let repository: ApiRepository
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    init(persistentContainer: NSPersistentContainer, repository: ApiRepository) {
        self.persistentContainer = persistentContainer
        self.repository = repository
    }
    
    func fetchFilms(completion: @escaping(Error?) -> Void) {
        self.repository.getFilms {[weak self] response in
            guard let self = self else { return }
            switch response {
            case .success(let result):
                let taskContext = self.taskManagedObjectContextBuilder(persistentContainer: self.persistentContainer)
                _ = self.syncFilms(jsonDictionary: result, taskContext: taskContext)
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }
    
    func taskManagedObjectContextBuilder(persistentContainer: NSPersistentContainer) -> NSManagedObjectContext {
        let taskContext = persistentContainer.newBackgroundContext()
        taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        taskContext.undoManager = nil
        return taskContext
    }
    
    private func syncFilms(jsonDictionary: [[String: Any]], taskContext: NSManagedObjectContext) -> Bool {
        var successfull = false
        taskContext.performAndWait {
            let matchingEpisodeRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Film")
            let episodeIds = jsonDictionary.map { $0["episode_id"] as? Int }.compactMap { $0 }
            matchingEpisodeRequest.predicate = NSPredicate(format: "episodeId in %@", argumentArray: [episodeIds])
            
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: matchingEpisodeRequest)
            batchDeleteRequest.resultType = .resultTypeObjectIDs
            
            // Execute the request to de batch delete and merge the changes to viewContext, which triggers the UI update
            do {
                let batchDeleteResult = try taskContext.execute(batchDeleteRequest) as? NSBatchDeleteResult
                
                if let deletedObjectIDs = batchDeleteResult?.result as? [NSManagedObjectID] {
                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSDeletedObjectsKey: deletedObjectIDs],
                                                        into: [self.persistentContainer.viewContext])
                }
            } catch {
                print("Error: \(error)\nCould not batch delete existing records.")
                return
            }
            
            // Create new records.
            for filmDictionary in jsonDictionary {
                
                guard let film = NSEntityDescription.insertNewObject(forEntityName: "Film", into: taskContext) as? FilmModel else {
                    print("Error: Failed to create a new Film object!")
                    return
                }
                
                do {
                    try film.update(with: filmDictionary)
                } catch {
                    print("Error: \(error)\nThe film object will be deleted.")
                    taskContext.delete(film)
                }
            }
            
            // Save all the changes just made and reset the taskContext to free the cache.
            if taskContext.hasChanges {
                do {
                    try taskContext.save()
                } catch {
                    print("Error: \(error)\nCould not save Core Data context.")
                }
                taskContext.reset() // Reset the context to clean up the cache and low the memory footprint.
            }
            successfull = true
        }
        return successfull
    }
}
