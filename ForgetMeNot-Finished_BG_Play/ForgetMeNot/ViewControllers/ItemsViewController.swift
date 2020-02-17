/*
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import CoreLocation
import AVFoundation

let storedItemsKey = "storedItems"

class ItemsViewController: UIViewController,UNUserNotificationCenterDelegate {
    
    static let shared = ItemsViewController()
    var disconnectB1DateTime: Date?
    var disconnectB1DateTime1: Date = Date()
    var second:Int = 0
    
    
    @IBOutlet weak var tableView: UITableView!
    
    var items = [Item]()
    let locationManager = CLLocationManager()
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var objPlayer: AVAudioPlayer?
    var isDisconnect:Bool = false
    var isPlaySound:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.allowsBackgroundLocationUpdates = true

        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers

        
        UNUserNotificationCenter.current().delegate = self
        
        //Play Sound
        //==========
        playAudioFile()
        
    }
    
    func playAudioFile() {
        guard let url = Bundle.main.url(forResource: "beepPlus", withExtension: "mp3") else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)

            // For iOS 11
            objPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)


        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        loadItems()
    }
    
    func loadItems() {
//        guard let storedItems = UserDefaults.standard.array(forKey: storedItemsKey) as? [Data] else { return }
        for itemData in items {
//            guard let item = NSKeyedUnarchiver.unarchiveObject(with: itemData) as? Item else { continue }
//            items.append(item)
            startMonitoringItem(itemData)
        }
    }
    
    func persistItems() {
        var itemsData = [Data]()
        for item in items {
            let itemData = NSKeyedArchiver.archivedData(withRootObject: item)
            itemsData.append(itemData)
        }
        UserDefaults.standard.set(itemsData, forKey: storedItemsKey)
        UserDefaults.standard.synchronize()
    }
    
    func startMonitoringItem(_ item: Item) {
        let beaconRegion = item.asBeaconRegion()
        locationManager.startMonitoring(for: beaconRegion)
        locationManager.startUpdatingLocation()
        locationManager.startRangingBeacons(in: beaconRegion)
    }
    
    func stopMonitoringItem(_ item: Item) {
        let beaconRegion = item.asBeaconRegion()
        locationManager.stopMonitoring(for: beaconRegion)
        locationManager.stopRangingBeacons(in: beaconRegion)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueAdd", let viewController = segue.destination as? AddItemViewController {
            viewController.delegate = self
        }
    }
}

extension ItemsViewController: AddBeacon {
    func addBeacon(item: Item) {
        items.append(item)
        
        tableView.beginUpdates()
        let newIndexPath = IndexPath(row: items.count - 1, section: 0)
        tableView.insertRows(at: [newIndexPath], with: .automatic)
        tableView.endUpdates()
        
        startMonitoringItem(item)
        persistItems()
    }
}

// MARK: UITableViewDataSource
extension ItemsViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Item", for: indexPath) as! ItemCell
        cell.item = items[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            stopMonitoringItem(items[indexPath.row])
            
            tableView.beginUpdates()
            items.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
            
            persistItems()
        }
    }
    
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert,.sound])
    }
}

// MARK: UITableViewDelegate
extension ItemsViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    
    let item = items[indexPath.row]
    let detailMessage = "UUID: \(item.uuid.uuidString)\nMajor: \(item.majorValue)\nMinor: \(item.minorValue)"
    let detailAlert = UIAlertController(title: "Details", message: detailMessage, preferredStyle: .alert)
    detailAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
    self.present(detailAlert, animated: true, completion: nil)
  }
}

// MARK: CLLocationManagerDelegate
extension ItemsViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Failed monitoring region: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        
//        loadItems()
        print("Beacons : \(Date())" + " " + "\(beacons)")
        if(beacons.count == 0){
//            tableView.reloadData()
//            guard let aPlayer = objPlayer else { return }
//            aPlayer.play()
//            return;
        }
        
//        for beacon in beacons {
//            if #available(iOS 13.0, *) {
//                let uuid = beacon.uuid.uuidString
//                if(uuid == "B8949089-5A3F-499A-B718-AF2B741F8CF0" && beacon.rssi == 0){
//                    guard let aPlayer = objPlayer else { return }
//                    aPlayer.play()
//                }
//            } else {
//                // Fallback on earlier versions
//            }
//        }
        
        
//        var mess:String = ""
//        var index:Int = 10000
        // Find the same beacons in the table.
        
        var indexPaths = [IndexPath]()
        for beacon in beacons {
            for row in 0..<items.count {
                if items[row] == beacon {
                    items[row].beacon = beacon
                    indexPaths += [IndexPath(row: row, section: 0)]
                    if(items[row].name == "B1")
                    {
                        if(beacon.rssi == 0){
                            isDisconnect = true
                            if (disconnectB1DateTime == nil){
                                disconnectB1DateTime = Date()
                            }
                        }else{
                            isDisconnect = false
                            disconnectB1DateTime = nil
                        }
                    }
                    
                    if(isDisconnect == true){
                        if(items[row].name == "B2")
                        {
                            if(beacon.rssi != 0){
                                disconnectB1DateTime = nil
                            }
                        }
                    }
                }
            }
        }
        
        if(disconnectB1DateTime != nil){
            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents([Calendar.Component.second], from: disconnectB1DateTime!, to: Date())
            
            second = dateComponents.second!
            if(second>=5){
                isPlaySound = true
            }else{
                isPlaySound = false
            }
            
            if(isPlaySound){
                guard let aPlayer = objPlayer else { return }
                aPlayer.play()
            }
        }
        
        // Update beacon locations of visible rows.
        if let visibleRows = tableView.indexPathsForVisibleRows {
            let rowsToUpdate = visibleRows.filter { indexPaths.contains($0) }
            for row in rowsToUpdate {
                let cell = tableView.cellForRow(at: row) as! ItemCell
                cell.refreshLocation()
                let location = cell.lblLocation.text!
                if location.contains("Unknown") {
                    cell.lblState.text = "ABSENT"
                }else{
                    cell.lblState.text = "PRESENT"
                }
                
            }
        }
    }
    
}

//{
//  
//  var mess:String = ""
//  var index:Int = 0
//  // Find the same beacons in the table.
//  var indexPaths = [IndexPath]()
//  for beacon in beacons {
//    for row in 0..<items.count {
//      if items[row] == beacon {
//        items[row].beacon = beacon
//        indexPaths += [IndexPath(row: row, section: 0)]
//          if(items[row].name == "B1")
//          {
//              index = row
//          }
//      }
//    }
//  }
//  
//  // Update beacon locations of visible rows.
//  if let visibleRows = tableView.indexPathsForVisibleRows {
//    let rowsToUpdate = visibleRows.filter { indexPaths.contains($0) }
//    for row in rowsToUpdate {
//      let cell = tableView.cellForRow(at: row) as! ItemCell
//      cell.refreshLocation()
//      let location = cell.lblLocation.text!
//      if location.contains("Unknown") {
//          cell.lblState.text = "ABSENT"
//          if(row.row == index)
//          {
//              let message = "B1 " + (cell.lblState.text ?? "")
//              appDelegate.throwNotification(message: message)
//
//              items.removeAll()
//              viewWillAppear(true)
//          }
//      }else{
//          cell.lblState.text = "PRESENT"
//      }
//      
//      
//    }
//  }
//  
//}
