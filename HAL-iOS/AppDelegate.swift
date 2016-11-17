//
//  AppDelegate.swift
//  HAL-iOS
//
//  Created by Pranitha on 9/27/16.
//  Copyright © 2016 macys. All rights reserved.
//

import UIKit
import CoreData

//@UIApplicationMain
class AppDelegate: UIResponder,DTDeviceDelegate, UIApplicationDelegate {

    var window: UIWindow?
    var sled: DTDevices?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        CommonUtils.setUpUserDefaults()
        let app = application as! HALApplication;
        app.startTimer()
        detectDevice();
        NotificationCenter.default.addObserver( self,
                                                selector: #selector(readMDMValues),
                                                name: UserDefaults.didChangeNotification,
                                                object: nil);
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        detectDevice();
        NotificationCenter.default.addObserver( self,
                                                selector: #selector(readMDMValues),
                                                name: UserDefaults.didChangeNotification,
                                                object: nil);
    }
    
    func readMDMValues()
    {
        NotificationCenter.default.removeObserver(self, name: UserDefaults.didChangeNotification, object: nil);
        let userDefaults = UserDefaults.standard;
        if let answersSaved = userDefaults.dictionary(forKey: CommonUtils.landingPage)  {
            if let landingPage = answersSaved["landingPage"] {
                print("Current landing page: " + (landingPage as! String)); // value
                
            }
            if let timertime = answersSaved["autoLogout"] {
                CommonUtils.setAutoLogoutTimeinterval(value: timertime as! Int)
            }
        }
    };
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        if #available(iOS 10.0, *) {
            self.saveContext()
        } else {
            // Fallback on earlier versions
        }
    }

    // MARK: - Core Data stack

    @available(iOS 10.0, *)
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "HAL_iOS")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    @available(iOS 10.0, *)
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func getSled()-> Any?
    {
        if(isLineaConnected()) {
            return sled!
        }
        else {
            return nil
        }
    }
    
    func detectDevice()
    {
        sled = DTDevices.sharedDevice() as? DTDevices
        sled?.addDelegate(self)
        sled?.connect()
    }
    
    func isLineaConnected()->Bool
    {
        return (sled!.connstate==2)
    }
    
    func barcodeData(_ barcode: String!, type: Int32) {
        updateBarcodeData(barcode: barcode)
    }
    
    func barcodeData(_ barcode: String!, isotype: String!) {
        updateBarcodeData(barcode: barcode)
    }
    
    func barcodeNSData(_ barcode: Data!, type: Int32) {
        let strData = NSString(data: barcode, encoding: String.Encoding.utf8.rawValue)
        updateBarcodeData(barcode: strData as! String)
    }
    
    func barcodeNSData(_ barcode: Data!, isotype: String!) {
        let strData = NSString(data: barcode, encoding: String.Encoding.utf8.rawValue)
        updateBarcodeData(barcode: strData as! String)
    }
    
    func updateBarcodeData(barcode: String)
    {
        if(CommonUtils.isScanEnabled())
        {
            print(barcode);
            let viewController:ViewController = window!.rootViewController as! ViewController;
            viewController.updateBarcodeData(barcode: barcode)
        }
    }
    
    func connectionState(_ state: Int32) {
        let viewController:ViewController = window!.rootViewController as! ViewController;
        viewController.connectionState(state)
        
        if(state==2)
        {
        //viewController.showAlert(title: (sled?.firmwareRevision)!,message:String(describing: sled?.sdkVersion))
            print("sled firmware version: "+(sled?.firmwareRevision)!)
            print("sled SDK version: " + String(describing: sled?.sdkVersion))
            
            do {
                try sled?.setPassThroughSync(false);
            }
            catch {
                print(error)
            }
        }
    }
    
    func enableScanner()
    {
       do{
            try sled?.barcodeSetScanButtonMode(BUTTON_STATES.ENABLED.rawValue)
            CommonUtils.setScanEnabled(value: true)
            }
        catch {
            print(error)
        }
    }
    
    func disableScanner()
    {
        do{
            try sled?.barcodeSetScanButtonMode(BUTTON_STATES.DISABLED.rawValue)
            CommonUtils.setScanEnabled(value: false)
   
        }
        catch {
            print(error)
        }
    }
    
    func getSledBatteryLevel() -> Int32
    {
        if( isLineaConnected() )
        {
            do{
                let battery = try (sled?.getBatteryInfo().capacity)! as Int32
                return battery
            }
            catch {
                print(error)
            }
        }
        return 0;
    }
    
    func getIpodBatteryLevel() -> Float
    {
        UIDevice.current.isBatteryMonitoringEnabled = true
        print(UIDevice.current.batteryLevel)
        return UIDevice.current.batteryLevel;
    }
}
