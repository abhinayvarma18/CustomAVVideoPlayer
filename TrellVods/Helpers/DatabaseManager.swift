//
//  DatabaseManager.swift
//  TrellVods
//
//  Created by abhinay varma on 28/09/20.
//  Copyright © 2020 abhinay varma. All rights reserved.
//

import UIKit
import CoreData

class DatabaseManager:NSObject {
    
    static let instance = DatabaseManager()
    
    var context:NSManagedObjectContext!
    
    override init() {
        super.init()
        let appDel: AppDelegate = (UIApplication.shared.delegate as! AppDelegate)
        context = appDel.persistentContainer.viewContext
    }
    
    func saveBookmark(_ model:VideoItem) {
        if(!checkIfModelIsBookmark(model)) {
            guard let fullRes = NSEntityDescription.insertNewObject(forEntityName: "Video", into: context) as? Video else {
                // handle failed new object in moc
                print("moc error")
                return
            }
            let data = model.image?.toData
            fullRes.image = data
            fullRes.path = model.path?.absoluteString
            
            do {
                try context.save()
            }catch {
            
            }
        }
    }
    
    func fetchBookmarks(_ completion:@escaping(([VideoItem]?)->())) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Video")
        do {
            let results = try context.fetch(fetchRequest)
            let imageData = results as? [Video]
            var modelToReturn:[VideoItem] = []
            for model in imageData ?? [] {
                if let data = model.image, let urlString = model.path {
                    let image = UIImage(data: data)
                    let url = NSURL(string: urlString)
                    let localmodel = VideoItem(path: url, image: image, name: nil, data: nil, currentProgress: nil, isBookmarked: true)
                    modelToReturn.append(localmodel)
                }
            }
            completion(modelToReturn)
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
            return
        }
    }
    
    func deleteBookmark(_ model:VideoItem) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Video")
        let predicate = NSPredicate(format: "path == %@", model.path ?? "")
        fetchRequest.predicate = predicate
        do {
            let results = try context.fetch(fetchRequest)
            if results.isEmpty {
                return
            }
            let object = results.first
            context.delete(object as! NSManagedObject)
            try context.save()
        }catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
            return
        }
    }
    
    func checkIfModelIsBookmark(_ model:VideoItem) -> Bool {
       let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Video")
       let predicate = NSPredicate(format: "path == %@", model.path ?? "")
       fetchRequest.predicate = predicate
        do {
            let results = try context.fetch(fetchRequest)
            if results.isEmpty {
                return false
            }
            return true
        }catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
            return false
        }
    }
}
