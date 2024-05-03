//
//  ViewController.swift
//  TravelBook
//
//  Created by Mehmet Jiyan Atalay on 3.01.2024.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController , MKMapViewDelegate , CLLocationManagerDelegate{

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var nameTextF: UITextField!
    @IBOutlet weak var noteTextF: UITextField!
    @IBOutlet weak var saveButtonOutlet: UIButton!
    
    var chosenLatitude = Double()
    var chosenLongitude = Double()
    
    var selectedTitle = ""
    var selectedID : UUID?
    
    var annontationName = ""
    var annontationNote = ""
    var annontationLatitude = Double()
    var annontationLongitude = Double()
    
    var locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // konumun doğruluğunu ayarlama
        locationManager.requestWhenInUseAuthorization() // konumu ne zaman kullanıcağını seçme
        locationManager.startUpdatingLocation() // konumu güncellemeye başlama
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 3
        mapView.addGestureRecognizer(gestureRecognizer)
        
        if selectedTitle != "" {
            saveButtonOutlet.isHidden = true
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = selectedID!.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    for result in results as! [NSManagedObject] {
                        if let name = result.value(forKey: "name") as? String {
                            annontationName = name
                            if let note = result.value(forKey: "note") as? String {
                                annontationNote = note
                                if let latitude = result.value(forKey: "latitude") as? Double {
                                    annontationLatitude = latitude
                                    if let longitude = result.value(forKey: "longitude") as? Double {
                                        annontationLongitude = longitude
                                        
                                        let annontation = MKPointAnnotation()
                                        let coordinate = CLLocationCoordinate2D(latitude: annontationLatitude, longitude: annontationLongitude)
                                        annontation.title = name
                                        annontation.subtitle = note
                                        annontation.coordinate = coordinate
                                        
                                        mapView.addAnnotation(annontation)
                                        nameTextF.text = annontationName
                                        noteTextF.text = annontationNote
                                        
                                        locationManager.stopUpdatingLocation()
                                        
                                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        mapView.setRegion(region, animated: true)
                                        
                                    }
                                }
                            }
                        }
                    }
                }
            } catch {
                print("Error!!!")
            }
            
        } else {
            saveButtonOutlet.isEnabled = false
        }
        
    }
    
    @objc func chooseLocation(gestureRecognizer : UILongPressGestureRecognizer){
        if gestureRecognizer.state == .began { // tıklanmaya başlanıp başlanmadığını kontrol etme
            let touchedPoint = gestureRecognizer.location(in: self.mapView) // tıklanan noktayı alma
            let touchedCoordinat = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView)//noktayıkordinataçevirme
            
            chosenLatitude = touchedCoordinat.latitude
            chosenLongitude = touchedCoordinat.longitude
            
            let annotation = MKPointAnnotation() // pin sembolünü ekleme ve özellik verme
            annotation.coordinate = touchedCoordinat
            annotation.title = nameTextF.text
            annotation.subtitle = noteTextF.text
            self.mapView.addAnnotation(annotation)
            saveButtonOutlet.isEnabled = true
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if selectedTitle == "" {
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude) // koordinat alma
            let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1) // Zoom yapma oranı
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
        } else {
            //
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let reusID = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reusID) as? MKMarkerAnnotationView
        
        if pinView == nil {
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reusID)
            pinView?.canShowCallout = true // pinde ekstra bilgi gösterme
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        }
        else {
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedTitle != "" {
            let requestLocation = CLLocation(latitude: annontationLatitude, longitude: annontationLongitude)
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarks, error) in
                if let placemark = placemarks {
                    if placemark.count > 0 {
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annontationName
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                    }
                }
            }
        }
    }
    
    @IBAction func saveButton(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        
        if nameTextF.text != "" {
            newPlace.setValue(nameTextF.text, forKey: "name")
            if noteTextF.text != "" {
                newPlace.setValue(noteTextF.text, forKey: "note")
                newPlace.setValue(chosenLatitude, forKey: "latitude")
                newPlace.setValue(chosenLongitude, forKey: "longitude")
                newPlace.setValue(UUID(), forKey: "id")
            }
            else {
                makeAlert(title: "Error!", message: "Note is Empty!")
            }
        }
        else {
            makeAlert(title: "Error!", message: "Username is Empty!")
        }
        
        do {
            try context.save()
            print("Success")
        } catch {
            print("Kaydetme Hatasi!!!")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil)
        navigationController?.popViewController(animated: true)
    }
    
    func makeAlert(title : String , message : String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        let okButton = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
        alert.addAction(okButton)
        self.present(alert, animated: true, completion: nil)
    }
}

