//
//  ListVC.swift
//  TravelBook
//
//  Created by Mehmet Jiyan Atalay on 3.01.2024.
//

import UIKit
import CoreData

class ListVC: UIViewController , UITableViewDelegate , UITableViewDataSource{

    @IBOutlet weak var tableView: UITableView!
    
    var nameArray = [String]()
    var noteArray = [String]()
    var idArray = [UUID]()
    
    var chosenTitle = ""
    var chosenID : UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addButtonClicked))

        tableView.delegate = self
        tableView.dataSource = self
        
        getData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name("newPlace"), object: nil)
    }
    
    @objc func addButtonClicked(){
        chosenTitle = ""
        performSegue(withIdentifier: "toVC", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nameArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        var content = cell.defaultContentConfiguration()
        content.text = nameArray[indexPath.row]
        //content.secondaryText = noteArray[indexPath.row]
        cell.contentConfiguration = content
        return cell
    }
    
    @objc func getData(){
        nameArray.removeAll(keepingCapacity: false)
        noteArray.removeAll(keepingCapacity: false)
        idArray.removeAll(keepingCapacity: false)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
        fetchRequest.returnsObjectsAsFaults = false
        
        do {
            let results = try context.fetch(fetchRequest)
            if results.count > 0 {
                for result in results as! [NSManagedObject]{
                    if let name = result.value(forKey: "name") as? String {
                        self.nameArray.append(name)
                    }
                    if let id = result.value(forKey: "id") as? UUID {
                        self.idArray.append(id)
                    }
                    if let note = result.value(forKey: "note") as? String{
                        self.noteArray.append(note)
                    }
                    tableView.reloadData()
                }
            }
        } catch {
            print("Error!!!")
        }
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        chosenTitle = nameArray[indexPath.row]
        chosenID = idArray[indexPath.row]
        
        performSegue(withIdentifier: "toVC", sender: nil)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toVC" {
            let destinationVC = segue.destination as! ViewController
            destinationVC.selectedID = chosenID
            destinationVC.selectedTitle = chosenTitle
        }
    }

}
