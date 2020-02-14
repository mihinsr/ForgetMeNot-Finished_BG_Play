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
import UserNotifications
import CoreLocation


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate,UNUserNotificationCenterDelegate {

  var window: UIWindow?
//    var initialViewController = ItemsViewController()
  let locationManager = CLLocationManager()
  var aObjNavi = UINavigationController()
    
    var items = [Item]()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        locationManager.delegate = self
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.allowsBackgroundLocationUpdates = true
        
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        
        
        addItem()
        
        
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        let initialViewController = storyboard.instantiateViewController(withIdentifier: "ItemsViewController") as! ItemsViewController
        initialViewController.items = self.items
        aObjNavi = UINavigationController(rootViewController: initialViewController)
        aObjNavi.navigationBar.isHidden = true
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = aObjNavi
        self.window?.makeKeyAndVisible()
        
        // Request permission to send notifications
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options:[.alert, .sound]) { (granted, error) in }
        
        //    if launchOptions?[UIApplicationLaunchOptionsKey.location] != nil {
        //        //You have a location when app is in killed/ not running state
        //    }
        
        
        return true
    }
    func addItem()
    {
        var uuidString = "b8949089-5a3f-499a-b718-af2b741f8cf0".trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard let uuid1 = UUID(uuidString: uuidString) else { return }

        let newItem1 = Item(name: "B1", icon: Icons.bag.rawValue, uuid: uuid1, majorValue: 0, minorValue: 0)
        items.append(newItem1)
        uuidString = "69844c68-a4c9-4cf1-ac3f-798ac7aa32ad".trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard let uuid2 = UUID(uuidString: uuidString) else { return }

        let newItem2 = Item(name: "B2", icon: Icons.bag.rawValue, uuid: uuid2, majorValue: 0, minorValue: 0)
        items.append(newItem2)
    }
    func applicationDidEnterBackground(_ application: UIApplication) {

//        self.locationManager.stopUpdatingLocation()
//        self.locationManager.startMonitoringSignificantLocationChanges()

        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        
//        ItemsViewController.shared.loadItems()
    }
    
//    func applicationWillTerminate(_ application: UIApplication) {
//        self.locationManager.stopUpdatingLocation()
//        self.locationManager.startMonitoringSignificantLocationChanges()
//    }
	
    
    func throwNotification(message :String)
    {
        let content = UNMutableNotificationContent()
        content.title = "Forget Me Not"
        content.body = message
            content.sound = .default()
//        content.sound = UNNotificationSound(named: UNNotificationSoundName(string: "AlarmSound.wav") as String)
        
        
        let request = UNNotificationRequest(identifier: "ForgetMeNot", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
//    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
//        completionHandler([.alert,.sound])
//    }
    
}

// MARK: CLLocationManagerDelegate
extension AppDelegate: CLLocationManagerDelegate {
  func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
    guard region is CLBeaconRegion else { return }
        
    let content = UNMutableNotificationContent()
    content.title = "Forget Me Not"
    content.body = "Are you forgetting something?"
    content.sound = .default()
//    content.sound = UNNotificationSound(named: UNNotificationSoundName(string: "AlarmSound.wav") as String)


    let request = UNNotificationRequest(identifier: "ForgetMeNot", content: content, trigger: nil)
    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
  }
}

