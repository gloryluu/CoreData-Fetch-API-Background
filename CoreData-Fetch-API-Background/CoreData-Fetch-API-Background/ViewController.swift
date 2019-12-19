//
//  ViewController.swift
//  CoreData-Fetch-API-Background
//
//  Created by Quang V. Luu on 12/19/19.
//  Copyright © 2019 Officience SARL. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    @IBOutlet var tableView: UITableView!
    
    var dataProvider: DataProvider!
    
    lazy var fetchedResultsController: NSFetchedResultsController<FilmModel> = {
        let fetchRequest = NSFetchRequest<FilmModel>(entityName:"Film")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "episodeId", ascending:true)]
        
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                    managedObjectContext: dataProvider.viewContext,
                                                    sectionNameKeyPath: nil, cacheName: nil)
        controller.delegate = self
        
        do {
            try controller.performFetch()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        
        return controller
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.tableView.dataSource = self
        
        dataProvider.fetchFilms { (error) in
            // Handle Error by displaying it in UI
        }
    }
}

extension ViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CELL", for: indexPath)
        let film = fetchedResultsController.object(at: indexPath)
        cell.textLabel?.text = film.title
        cell.detailTextLabel?.text = film.director
        return cell
    }
}


extension ViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
         tableView.reloadData()
     }
}
