//
//  AppDelegate.swift
//  HAL-iOS
//
//  Created by Pranitha on 9/27/16.
//  Copyright © 2016 macys. All rights reserved.
//

import UIKit
import CoreData
import SystemConfiguration.CaptiveNetwork

//@UIApplicationMain
class AppDelegate: UIResponder, DTDeviceDelegate, UIApplicationDelegate {

    var window: UIWindow?;
    var sled: DTDevices?;
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        CommonUtils.setUpUserDefaults();
        
        let defaults = UserDefaults.standard;
        defaults.set(Assembly.halVersion(), forKey: "application_version");
        defaults.synchronize();
        
        //since the sumulator isn't in AW let's force some values
        if( CommonUtils.isSimulator() ) {
            setSimulatorValues();
        }
        
        if let app = application as? HALApplication {
            app.startTimer();
        }
        
        //app.startNetworkTimer()
        //detectDevice(); commenting out per IPC
        
        NotificationCenter.default.addObserver( self,
                                                selector: #selector(readConfigurationParams),
                                                name: UserDefaults.didChangeNotification,
                                                object: nil);
        if(!ConfigurationManager.existsInMDM("ssp"))
        {
            CommonUtils.getDNS(_value: "ssp");
        }
        if(!ConfigurationManager.existsInMDM("isp"))
        {
            CommonUtils.getDNS(_value: "isp01");
        }
        NSSetUncaughtExceptionHandler { exception in
            DLog( "error details : " + exception.reason! );
            LoggingRequest.logData( name: LoggingRequest.metrics_app_crash, value: exception.reason!, type: "STRING", indexable: true );
        }
        
        let crashReporter = PLCrashReporter.shared();
        
        if( crashReporter?.hasPendingCrashReport() )! {
            DLog("Previous Error!");
            do {
                let crashData = try crashReporter?.loadPendingCrashReportDataAndReturnError();
                
                do {
                    let report = try PLCrashReport.init(data: crashData);
                    
                    if var humanReadableReport = PLCrashReportTextFormatter.stringValue(for: report, with: PLCrashReportTextFormatiOS)
                    {
                        //max char count will be 15k, leading to a 20k max base64 encoded message after we truncate
                        if(humanReadableReport.count > 15000)
                        {
                            humanReadableReport = humanReadableReport.substring(to: humanReadableReport.index(humanReadableReport.startIndex, offsetBy: 15000));
                        }
                        
                        //convert to NSData type
                        let crashReport = humanReadableReport.data(using: String.Encoding.utf8);
                        
                        //log the base64 encoded stack trace
                        LoggingRequest.logError(name: LoggingRequest.metrics_app_crash, value: (crashReport?.base64EncodedString())!, type: "STRING", indexable: false);
                    }
                }
                catch {
                    DLog("Could not parse crash report.");
                    LoggingRequest.logData(name: LoggingRequest.metrics_warning, value: "Could not parse crash report.", type: "STRING", indexable: true);
                }
                
                crashReporter?.purgePendingCrashReport();
            }
            catch {
                DLog("Could not load crash report.");
                LoggingRequest.logData(name: LoggingRequest.metrics_warning, value: "Could not load crash report.", type: "STRING", indexable: true);
                crashReporter?.purgePendingCrashReport();
            }
        }
        
        // Enable the Crash Reporter
        do {
            try crashReporter?.enableAndReturnError();
            DLog("Crash reporter enabled.");
            LoggingRequest.logData(name: LoggingRequest.metrics_info, value: "Crash reporter enabled.", type: "STRING", indexable: true);
        }
        catch
        {
            DLog("Could not enable crash reporter.");
            LoggingRequest.logData(name: LoggingRequest.metrics_warning, value: "Could not enable crash reporter.", type: "STRING", indexable: true);
        }
        
        //_ = [][0]; force an app crash to test the crash reporter/crash logger

        return true;
    }
    
    func checkSSID() -> Bool
    {
        if( CommonUtils.isSimulator() )
        {
            return true;
        }

        let ssids = currentSSIDs();
        
        for ssid in ssids {
            if( ssid == "FDS030A" ) ||
              ( ssid == "FDS030B" ) ||
              ( ssid == "FDS030C" ) ||
              ( ssid == "MST030B" ) ||
              ( ssid == "MST030A" ) ||
              ( ssid == "MST030C" ) ||
              ( ssid == "FDS030AZ" ) ||
              ( ssid == "LAB030A" ) ||
//              ( ssid == "FDS010" ) ||  // uncomment for local development testing
              ( ssid == "FDS010" && CommonUtils.getisBYOD() ) ||  // used for QE testing on a dev build. Works in Production in BYOD
              ( ssid == "MB030A" )
            {
                return true;
            }
        }
        
        if( ssids.count > 0 ) {
            LoggingRequest.logData(name: "IncorrectSSID", value: ssids[0], type: "STRING", indexable: true);
        }
        else {
            LoggingRequest.logData(name: "IncorrectSSID", value: "No SSID found", type: "STRING", indexable: true);
        }
        
        return false;
    }
    
    func readConfigurationParams() {
        ConfigurationManager.readMDMValues();
    }

    func currentSSIDs() -> [String] {
        guard let interfaceNames = CNCopySupportedInterfaces() as? [String] else {
            return []
        }
        return interfaceNames.flatMap { name in
            guard let info = CNCopyCurrentNetworkInfo(name as CFString) as? [String:AnyObject] else {
                return nil
            }
            guard let ssid = info[kCNNetworkInfoKeySSID as String] as? String else {
                return nil
            }
            return ssid
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        attachBackgroundSplash();
        CommonUtils.setInactivityStartTime();
        if !CommonUtils.isSSOPage(ViewController.webView?.url) {
            CommonUtils.setCurrentPage(value: (ViewController.webView?.url)!);
        }
        URLCache.shared.removeAllCachedResponses();
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

        //CommonUtils.setIsSSOAuthenticated( value: false );
        //LoggingRequest.logData(name: LoggingRequest.metrics_info, value: "Associate logout by applicationDidEnterBackground.", type: "STRING", indexable: true);
        if let app = application as? HALApplication
        {
            app.stopNetworkTimer();
            app.stopMetricTimer();
            app.stopBatteryTimer();
            app.stopJSTimer();
            app.stopChargingTimer();
        }
        self.setLineaCharging(val: false);
        
        LoggingRequest.logData(name: LoggingRequest.metrics_app_shutdown, value: "", type: "STRING", indexable: true);
        LoggingRequest.logStoredData();
        LogAnalyticsRequest.logStoredData();
        DataForwarder.forwardStoredData();
        
        //The following lines are suggestions of IPC
        sled = DTDevices.sharedDevice() as? DTDevices;
        sled?.disconnect();
        
        URLCache.shared.removeAllCachedResponses();
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        let splashView = UIApplication.shared.keyWindow?.subviews.last?.viewWithTag(CommonUtils.bgSplashTag);
        splashView?.removeFromSuperview();
        verifyOSVersion(UIDevice.current.systemVersion); //kills app if iOS is between 11 & 11.2.4
        
        if( !checkSSID() )
        {
            if let viewController:ViewController = window!.rootViewController as? ViewController
            {
                let blank = CommonUtils.getBlankPage();
                CommonUtils.setLandingPage(blank);
                CommonUtils.setCurrentPage(value: blank);
                viewController.loadWebView(url: blank);
                var jail = "";
                var failedSSIDLaunches = CommonUtils.getFailedSSIDLaunchAttempts();
                failedSSIDLaunches += 1;
                if(failedSSIDLaunches < 3)
                {
                    jail = "This application cannot run on this network. Connect to a valid selling network and try again.";
                    CommonUtils.setFailedSSIDLaunchAttempts(failedSSIDLaunches);
                }
                else
                {
                    jail = "This application cannot run on this network. Remove this device from the selling floor immediately and open a ticket.";
                }
            
                // create the alert
                let alertController = UIAlertController(title: "Network Error", message: jail, preferredStyle: UIAlertControllerStyle.alert);
            
                // add an action (button)
                alertController.addAction(UIAlertAction(title: "Settings", style: .default, handler: { action in
                    UIApplication.shared.openURL(URL(string:"App-Prefs:root=WIFI")!); //open settings app on WIFI screen
                }));
            
                // show the alert
                viewController.present(alertController, animated: true, completion: nil);
            }
        }
        else
        {
            CommonUtils.setFailedSSIDLaunchAttempts(0);
            
            // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
            let esp = ESPRequest();
            esp.getParms( ["L4P", "MST"] ) {
                (result: String) in
                
                if(result == "error")
                {
                    let defaultLandingPage = CommonUtils.getDefaultLandingPage();
                    CommonUtils.setLandingPage(defaultLandingPage);
                    CommonUtils.setCurrentPage(value: defaultLandingPage);
                    if let viewController:ViewController = self.window!.rootViewController as? ViewController
                    {
                        viewController.loadWebView(url: CommonUtils.getLandingPage() );
                    }
                }
                else if( !CommonUtils.isSSOAuthenticated() ) // check if they need pin re-entry
                {
                    _ = Locn();
                    CommonUtils.setCommonLogMetrics();
                    if( Date().timeIntervalSince( CommonUtils.getInactivityStartTime() ) > TimeInterval( CommonUtils.getInactivityTimeInterval() ) ) // see if they've been inactive for too long
                    {
                        if let viewController:ViewController = self.window!.rootViewController as? ViewController
                        {
                            viewController.loadWebView(url: CommonUtils.getLandingPage() );
                        }
                    }
                    else
                    {
                        //if this code is hit, we're attempting to load the last page in memory
                        let currentPage = CommonUtils.getCurrentPage();
                        if(CommonUtils.isDefaultLandingPage(currentPage) || CommonUtils.isBlankPage(currentPage))
                        {
                            //if we're on one of the default pages, we want to try to load landing page
                            if let viewController:ViewController = self.window!.rootViewController as? ViewController
                            {
                                viewController.loadWebView(url: CommonUtils.getLandingPage() );
                            }
                        }
                    }
                }
                else
                {
                    let timeSinceLastActivity = Date().timeIntervalSince( CommonUtils.getInactivityStartTime() );
                    let allowedInactivityTime = TimeInterval( CommonUtils.getAuthenticatedInactivityTimeInterval() );
                    
                    _ = Locn();
                    CommonUtils.setCommonLogMetrics();
                    if( Date().timeIntervalSince( CommonUtils.getAutoLogoutStartTime() ) > TimeInterval( CommonUtils.getAutoLogoutTimeinterval() ) )
                    {
                        self.autoLogout();
                    }
                    else if ( timeSinceLastActivity < allowedInactivityTime )
                    {
                        //user is authenticated, but came back before they needed to re-enter pin, do nothing
                    }
                    else if let viewController:ViewController = self.window!.rootViewController as? ViewController
                    {
                        let currentUrl = ViewController.webView?.url
                        if (!CommonUtils.isSSOPage(currentUrl))
                        {
                            CommonUtils.setCurrentPage(value: (ViewController.webView?.url)!);
                            let url = Bundle.main.url(forResource: "sso/index", withExtension:"html")
                            viewController.loadWebView(url: url!)
                        }
                    }
                }
                
                //occurs even if parms returns an error, but won't run until after parms function has returned
                if( Encryption.shared.getDailyAesKeyVersion() == -1 ) //if we have a default AES key, call EES to get a real one, should only run on initial launch
                {
                    let concurrentQueue = DispatchQueue(label: "encryptionQueue", attributes: .concurrent)
                    concurrentQueue.async {
                        GenericEncryption.rsaInit();
                        EESRequest().getDailyAESKey();
                    }
                }
                
            };
            
            LoggingRequest.logData(name: LoggingRequest.metrics_app_startup, value: "", type: "STRING", indexable: true);
            LoggingRequest.logStoredData();
            LogAnalyticsRequest.logStoredData();
            DataForwarder.forwardStoredData()
            detectDevice();
            
            NotificationCenter.default.addObserver( self,
                                                    selector: #selector(readConfigurationParams),
                                                    name: UserDefaults.didChangeNotification,
                                                    object: nil);
            
            if let app = application as? HALApplication
            {
                app.startNetworkTimer();
                app.startMetricTimer();
                app.startBatteryTimer();
                app.startJSTimer();
                app.startChargingTimer();
            }
        }
        
    }
    
    func verifyAppVersion(version: String)
    {
        let currentStringList = Assembly.halVersion().components(separatedBy: ".");
        let appStringList = version.components(separatedBy: ".");

        if( appStringList.count == 3 )
        {
            let currentMajor = atoi( currentStringList[0] );
            let currentMinor = atoi( currentStringList[1] );
            let currentBuild = atoi( currentStringList[2] );
            let appMajor = atoi( appStringList[0] );
            let appMinor = atoi( appStringList[1] );
            let appBuild = atoi( appStringList[2] );

            if(( currentMajor > appMajor ) ||
               ( currentMajor == appMajor && currentMinor > appMinor ) ||
               ( currentMajor == appMajor && currentMinor == appMinor && currentBuild >= appBuild ) )
            {
                DLog("I'm newer? NICE.\n");
            }
            else
            {
                if let viewController:ViewController = window!.rootViewController as? ViewController
                {
                    let message = "The application is out of date. Tap Update to install the latest version.";
                    DLog(message);

                    // create the alert
                    let alert = UIAlertController(title: "Update Required", message: message, preferredStyle: UIAlertControllerStyle.alert)

                    // add an action (button)
                    alert.addAction(UIAlertAction(title: "Update", style: .default, handler: { action in
                        self.openMstAppStore();
                    }))

                    // show the alert
                    viewController.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    func verifyOSVersion(_ v: String)
    {
        var version = v;
        let versionArr = version.components(separatedBy: ".");

        //verify we're comparing a version in the correct format
        switch versionArr.count {
        case 1:
            version += ".0.0";
        case 2:
            version += ".0";
        case 3:
            _ = "";
        default:
            DLog("Failed to read iOS version. Apple what have you messed up this time??");
            return;
        }
        
        if(version >= "11.0.0" && version <= "11.2.4")
        {
            if let viewController:ViewController = window!.rootViewController as? ViewController
            {
                let message = "The version of iOS running on this device is not compatible with this app. Please go to settings and update the software.";
                let alert = UIAlertController(title: "iOS Incompatible", message: message, preferredStyle: UIAlertControllerStyle.alert);
                
                alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { action in
                    UIApplication.shared.openURL(URL(string:"App-Prefs:root")!); //can't go to "General" page in iOS 10+ SCREW YOU APPLE
                }));
                viewController.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func openMstAppStore()
    {
        let url = URL(string: "MacysAppStore://")!;
    
        if #available(iOS 10.0, *)
        {
            UIApplication.shared.open(url, options: [:], completionHandler: nil);
        }
        else
        {
            UIApplication.shared.openURL(url);
        }
    }
    
    
    func setSimulatorValues()
    {
        CommonUtils.setLandingPage(URL(string: "http://mstore.devops.fds.com/")!);
        CommonUtils.setAutoLogoutTimeinterval(1200);
        CommonUtils.setAuthenticatedInactivityTimeInterval(60); // tells how long sso will wait before forcing pin re-entry
        CommonUtils.setInactivityTimeInterval(3600);            // tells how long before the app will return to the landing page on open
        CommonUtils.setDivNum(value: 71);
        CommonUtils.setStoreNum(value: 572);
        SharedContainer.setIsp(value: "fs572asisp01");
        SharedContainer.setSsp(value: "fs024asssp01");
        SharedContainer.setCloud(value: "junk");
        CommonUtils.setLogRetryCount(10);
        CommonUtils.setLogCountLimit(5);
        CommonUtils.setLogRetryFrequency(120);
        CommonUtils.setLogTimeLimit(120);
        CommonUtils.setCertificatePinningEnabled(value: false);
        let esp = ESPRequest();
        esp.getParms( ["MST"] ) {
            (result: String) in
            if(result == "error")
            {
                DLog("ERROR returning parms: " + result);
            }
            else
            {
                _ = Locn();
                CommonUtils.setCommonLogMetrics();
            }
        };
        //lvl4 isn't yet needed for the simulator but I'll leave this here just in case
//        might need to add LP4 to the above array
    
        CommonUtils.isPreProd() ? Heap.setAppId("282132961") : Heap.setAppId("1675328291");   //282132961 = development  1675328291 = production
        //Heap.enableVisualizer();  // let's keep this here for future research but don't want it turned on now.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        URLCache.shared.removeAllCachedResponses();
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        if #available(iOS 10.0, *) {
            self.saveContext();
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
        let container = NSPersistentContainer(name: "HAL_iOS");
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the
                 device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)");
            }
        })
        return container;
    }()

    // MARK: - Core Data Saving support

    @available(iOS 10.0, *)
    func saveContext () {
        let context = persistentContainer.viewContext;
        if context.hasChanges {
            do {
                try context.save();
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError;
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)");
            }
        }
    }
    
    func getSled()-> Any?
    {
        if(isLineaConnected()) {
            return sled!;
        }
        else {
            return nil;
        }
    }
    
    func detectDevice()
    {
        sled = DTDevices.sharedDevice() as? DTDevices;
        
        DLog("sled SDK version: " + String(describing: sled?.sdkVersion));
        sled?.addDelegate(self);
        sled?.connect();
    }
    
    func isLineaConnected()->Bool
    {
        return ( sled?.connstate == 2 );
    }

    func isLineaCharging() -> Bool
    {
        if( isLineaConnected() )
        {
            var youSuckIP = ObjCBool(false)
            
            do {
                try sled?.getCharging(&youSuckIP);
            }
            catch {
                youSuckIP = false;
            }
            return youSuckIP.boolValue;
        }
        
        return false;
    }
    
    func setLineaCharging(val : Bool) -> Void
    {
        if( isLineaConnected() )
        {
            //DLog( @"Charging switched to %s with rc of %s\n", chargeFlag ? "true":"false", [sled setCharging:chargeFlag error:nil] ? "true":"false" );

            do {
                try sled?.setCharging( val );
            }
            catch {
                DLog("Failed to charge");
            }
        }
    }
    
    func setLineaIdleTimeout() -> Void
    {
        if( isLineaConnected() )
        {
            //Set linea idle timeout of lightning port when app is running to 12 hours and disconnect timeout while app is in background to 12 hours.
            do {
                try sled?.setAutoOffWhenIdle(43200, whenDisconnected: 43200)
            }
            catch {
                DLog("Failed to change idle timeout")
            }
        }
    }
    
    func barcodeData(_ barcode: String!, type: Int32) {
        updateBarcodeData(barcode: barcode);
    }
    
    func barcodeData(_ barcode: String!, isotype: String!) {
        updateBarcodeData(barcode: barcode);
    }
    
    func barcodeNSData(_ barcode: Data!, type: Int32) {
        var translatedBarcode : String = "";
        if( barcode[0] < 0x20 )
        {
            translatedBarcode = String(format:"0x%02X", barcode[0]);
            //yes, this technically exceeds the bounds of the array but it's an open range so it should be okay
            let tempBarcode = barcode.subdata( in: 1..<barcode.count );
            translatedBarcode += NSString(data: tempBarcode, encoding: String.Encoding.utf8.rawValue)! as String;
        }
        else
        {
            translatedBarcode = NSString(data: barcode, encoding: String.Encoding.utf8.rawValue)! as String;
        }
        updateBarcodeData(barcode: translatedBarcode);
    }
    
    func barcodeNSData(_ barcode: Data!, isotype: String!) {
        let strData = NSString(data: barcode, encoding: String.Encoding.utf8.rawValue);
        updateBarcodeData(barcode: strData! as String);
    }
    
    func updateBarcodeData(barcode: String)
    {
        /*if(CommonUtils.isScanEnabled())
        {
            if let viewController:ViewController = window!.rootViewController as? ViewController
            {
                viewController.updateBarcodeData(barcode: barcode);
            }
        }*/
        
        if let printerViewController:PrinterViewController = window!.rootViewController?.presentedViewController as? PrinterViewController
        {
            printerViewController.updateMacAddress(barcode: barcode)
            
            if( !CommonUtils.isScannerModeEnabledFromWeb() )
            {
                disableScanner();
            }
        }
        else if let viewController:ViewController = window!.rootViewController as? ViewController        {
            viewController.updateBarcodeData(barcode: barcode)
        }

    }
    
    func connectionState(_ state: Int32) {
        //let viewController:ViewController = window!.rootViewController as! ViewController;
        //viewController.connectionState(state)
        
        DLog("Sled state [" + String(state) + "]");
        updateBattery();
        
        if(state==2)
        {
            //viewController.showAlert(title: (sled?.firmwareRevision)!,message:String(describing: sled?.sdkVersion))
            let val = "Sled firmware version: " + (sled?.firmwareRevision)!;
            let eMSRversion = "Sled eMSR firmware version: " + getSledEmsrFirmwareVersion();
            DLog(val);
            
            LoggingRequest.logData(name: LoggingRequest.metrics_info, value: val, type: "STRING", indexable: true);
            LoggingRequest.logData(name: LoggingRequest.metrics_info, value: eMSRversion, type: "STRING", indexable: true);

            LoggingRequest.logData(name: "Sled_Firmware_Version", value: (sled?.firmwareRevision)!, type: "STRING", indexable: true);
            LoggingRequest.logData(name: "eMSR_Version", value: getSledEmsrFirmwareVersion(), type: "STRING", indexable: true);
            
            do
            {
                try sled?.setPassThroughSync( false );
                //disableScanner();
            }
            catch
            {
                DLog("Sled pass through error: " + String(describing:error));
            }
            
            if( CommonUtils.isScannerModeEnabledFromWeb() )
            {
                enableScanner();
            }
            else
            {
                disableScanner();
            }
            
            injectMsr();
            
            if( CommonUtils.isMSRModeEnabledFromWeb() )
            {
                enableMsr();
            }
            else
            {
                disableMsr();
            }

            //disableMsr();
        }
        else {
            LoggingRequest.logData(name: LoggingRequest.metrics_lost_peripheral_connection, value: "sled", type: "STRING", indexable: true);
        }
    }
    
    //prepares and loads a key
    //NOTE!!!! There can't be a key with duplicate value, this is PCI requirement!
    func loadKeyId(keyID: Int32, keyData:[UInt8], keyVersion:Int32, kekData:[UInt8]?) -> Bool
    {
        //DLog( "Loading key version: " + String( keyVersion ) );
        
        //format the key to load it, optionally encrypt with KEK
        let generatedKeyData = emsrGenerateKeyData(keyID: keyID, keyVersion: Int32(keyVersion), keyData: keyData, kekData: kekData);
        
        do {
            let lib: DTDevices = DTDevices.sharedDevice() as! DTDevices;
            
            //try to load the key in the slot
            try lib.emsrLoadKey(generatedKeyData.getNSData());
            return true;
        }
        catch let error as NSError
        {
            DLog("ERROR: Danger Will Robinson! [" + error.localizedDescription + "]");
        }
        return false;
    }
    
    /**
     Loads initial key in plain text or changes existing key. Keys in plain text can be loaded only once,
     on every subsequent key change, they needs to be encrypted with KEY_EH_AES256_LOADING.
     
     KEY_EH_AES256_LOADING can be used to change all the keys in the head except for the TMK, and KEY_AES256_LOADING
     can be loaded in plain text the first time too.
     */
    func emsrGenerateKeyData(keyID: Int32, keyVersion: Int32, keyData: [UInt8], kekData: [UInt8]?) -> [UInt8]
    {
//        //pull it out in hex
//        let string = NSMutableString(capacity: keyData.count * 2);
//        var byteArray = keyData.map { $0 as! UInt8 };
//        for i in 0 ..< keyData.count {
//            string.appendFormat("%02X", byteArray[i]);
//        }
//        NSLog("keyId %d  keyVersion %d: %@", keyID, keyVersion, string);
        
        var data: [UInt8] = [];
        var junk : Int32 = keyVersion;
        let versionBytes = NSData(bytes: &junk, length: MemoryLayout.size(ofValue: junk) ).getBytes();        
        
        data.append(0x2b);
        //key to encrypt with, either KEY_AES256_LOADING or 0xff to use plain text
        data.append((kekData != nil) ? UInt8(KEY_EH_AES256_LOADING) : 0xff);
        data.append(UInt8(keyID)); //key to set
        data.append(UInt8((versionBytes?[3])!)); //key version
        data.append(UInt8((versionBytes?[2])!)); //key version
        data.append(UInt8((versionBytes?[1])!)); //key version
        data.append(UInt8((versionBytes?[0])!)); //key version
        
        let keyStart = data.count;
        
        var hashed: [UInt8] = [];
        hashed.append(contentsOf: data);
        hashed.append(contentsOf: keyData); //key data
        let hash = SHA256(data: NSData(bytes: hashed, length: hashed.count));
        
        hashed.append(contentsOf: hash.getBytes());
        
        //encrypt the data if using the encryption key
        if kekData != nil
        {
            let toEncrypt = Array( hashed[keyStart..<hashed.count] );
            let encrypted = AESEncryptWithKey(data: toEncrypt.getNSData() as NSData, key: kekData!.getNSData() as NSData);
            
            //store the encryptd data back into the packet
            data.append(contentsOf: encrypted!.getBytes());
        }
        else
        {
            //we only get here when he KEK is first being injected
            data = hashed;
        }
        
//        let string2 = NSMutableString(capacity: data.count * 2);
//        for i in 0 ..< data.count {
//            string2.appendFormat("%02X", data[i]);
//        }
//        NSLog("data: %@", string2);

        return data;
    }
    
    func SHA256(data: NSData) -> NSData
    {
        let hash = UnsafeMutablePointer<UInt8>.allocate( capacity: Int( CC_SHA256_DIGEST_LENGTH ) );
        
        CC_SHA256( data.bytes,UInt32( data.length ),hash );
        
        let r = NSData( bytes: hash, length: Int( CC_SHA256_DIGEST_LENGTH ) );
        free( hash );
        
        return r;
    }
    
    func attachBackgroundSplash()
    {
        let splashView = Bundle.main.loadNibNamed("SplashView", owner: self, options: nil)?.first as! UIView;
        splashView.tag = CommonUtils.bgSplashTag;
         UIApplication.shared.keyWindow?.subviews.last?.addSubview(splashView);
    }
    
    func enableScanner()
    {
        do {
            try sled?.barcodeSetScanButtonMode(BUTTON_STATES.ENABLED.rawValue)
            CommonUtils.setScanEnabled(value: true);
        }
        catch {
            DLog("Enable scanner error: " + String(describing:error));
        }
    }
    
    func disableScanner()
    {
        CommonUtils.setScannerModeFromWeb(value: false);
        do {
            try sled?.barcodeSetScanButtonMode(BUTTON_STATES.DISABLED.rawValue)
            CommonUtils.setScanEnabled(value: false);
        }
        catch {
            DLog("Disable scanner error: " + String(describing:error));
        }
    }
    
    func getSledBatteryLevel() -> Int32
    {
        if( isLineaConnected() )
        {
            do {
                let battery = try (sled?.getBatteryInfo().capacity)! as Int32
                return battery
            }
            catch {
                DLog("Get sled battery level error: " + String(describing:error));
            }
        }
        return 0;
    }
    func getSledEmsrFirmwareVersion() -> String
    {
        if( isLineaConnected() )
        {
            do {
                let firmwareVersion = try (sled?.emsrGetDeviceInfo().firmwareVersionString)! as String;
                return firmwareVersion;
            }
            catch {
                DLog("Get sled eMSR firmware version error: " + String(describing:error));
            }
        }
        return "";
    }
    
    func getDeviceBatteryLevel() -> Float
    {
        UIDevice.current.isBatteryMonitoringEnabled = true;
        
        DLog("Sled battery: " + String(describing:UIDevice.current.batteryLevel));
        return UIDevice.current.batteryLevel;
    }
    
    func updateBattery() {
        if let viewController:ViewController = window!.rootViewController as? ViewController
        {
            viewController.updateBattery();
        }
    }
    
    func autoLogout() {
        LoggingRequest.logData(name: LoggingRequest.metrics_info, value: "Associate logout due to inactivity.", type: "STRING", indexable: true);
        Heap.track("AssociateLogout", withProperties:[AnyHashable("reason"):"inactivity",
                                                      AnyHashable("associateNumber"):CommonUtils.getCurrentAssociateNum(),
                                                      AnyHashable("duration"):CommonUtils.getSSODuration(),
                                                      AnyHashable("divNum"):CommonUtils.getDivNum(),
                                                      AnyHashable("storeNum"):CommonUtils.getStoreNum()]);
        
        CommonUtils.setIsSSOAuthenticated( value: false );
        
        if let viewController:ViewController = window!.rootViewController as? ViewController
        {
            viewController.loadWebView(url: CommonUtils.getLandingPage() );
        }
    }
    
    func enableMsr()
    {
        CommonUtils.setMSRModeFromWeb(value: true)
        do {
            try sled?.msEnable();
            try sled?.msSetCardDataMode(0);
            CommonUtils.setEnableMsr(value: true);
            let val = "Timestamp : " + CommonUtils.getDateformatter().string(from: Date());
            LoggingRequest.logData(name: LoggingRequest.metrics_msr_startup, value: val , type: "STRING", indexable: true);
        }
        catch {
            CommonUtils.setEnableMsr(value: false);
            let val = "Error in activating MSR at timestamp : " + CommonUtils.getDateformatter().string(from: Date()) + " with error : "+String(describing:error);
            LoggingRequest.logData(name: LoggingRequest.metrics_msr_connectionError, value: val , type: "STRING", indexable: true);
            DLog("Enable MSR error : " + String(describing:error));
        }
    }
    
    func disableMsr()
    {
        CommonUtils.setMSRModeFromWeb(value: false)
        do {
            try sled?.msDisable();
            CommonUtils.setEnableMsr(value: false);
            let val = "Timestamp : " + CommonUtils.getDateformatter().string(from: Date());
            LoggingRequest.logData(name: LoggingRequest.metrics_msr_shutdown, value: val , type: "STRING", indexable: true);
        }
        catch {
            let val = "Error in deactivating MSR at timestamp : " + CommonUtils.getDateformatter().string(from: Date()) + " with error : "+String(describing:error);
            LoggingRequest.logData(name: LoggingRequest.metrics_msr_connectionError, value: val , type: "STRING", indexable: true);
            DLog("Disable MSR error: " + String(describing:error));
        }
    }
    
    func updateMsrData(msrData: String)
    {
        if(CommonUtils.isMsrEnabled())
        {
            if let viewController:ViewController = window!.rootViewController as? ViewController
            {
                viewController.updateMsrData(msrData: msrData);
            }
        }
    }
    
    func injectMsr()
    {
        if( getSled() == nil )
        {
            //no reason to inject if there's no sled
            return;
        }
        
        //inject the default key into the MSR head
        let info = sled?.emsrGetDeviceInfo;
        
        if( info != nil )
        {
            if( sled?.emsrGetKeysInfo != nil )
            {
                var retries = 4;
                let newKekData = [UInt8](getKek().utf8);

                repeat
                {
                    // Brian note: I just realized we don't handle changing the KEK, which is probably fine. We also don't need to inject the KEK every single 
                    // time if it hasn't changed. When that day comes that we do change the KEK we'll have to save the old KEK to encrypt the new KEK before
                    // injecting it. Since we haven't done that in the last 8 years I'm not going to worry about it yet.
                    
                    var msrKekVer:Int32 = 0;
                    var msrAesVer:Int32 = 0;
                    do
                    {
                        try sled?.emsrGetKeyVersion(KEY_EH_AES256_LOADING, keyVersion: &msrKekVer);
                        try sled?.emsrGetKeyVersion(KEY_EH_AES256_ENCRYPTION1, keyVersion: &msrAesVer);
                        
                        if( msrKekVer <= 0 )
                        {
                            if( loadKeyId(keyID: KEY_EH_AES256_LOADING, keyData: newKekData, keyVersion: getKekVersion(), kekData: nil) )
                            {
                                try sled?.emsrGetKeyVersion(KEY_EH_AES256_LOADING, keyVersion: &msrKekVer);
                            }
                        }
                    }
                    catch
                    {
                        LoggingRequest.logData(name: LoggingRequest.metrics_error, value: "Unable to get MSR KEK key version.", type: "STRING", indexable: true);
                    }

                    //DLog("MSR KEK key version: " + String( msrKekVer ) );
                    //DLog("MSR AES key version: " + String( msrAesVer ) );

                    if( msrKekVer == getKekVersion() )
                    {
                        //We loaded the KEK, and there was much rejoicing
                        
                        var key : [UInt8] = getDefaultAESKey();
                        //use version 1 for default key because we can't use version 0
                        var keyVersion : Int32 = 1;
                        
                        if( Encryption.shared.getDailyAesKeyVersion() > 0 && Encryption.shared.getDailyAesKey() != nil )
                        {
                            key = Encryption.shared.getDailyAesKey()!;
                            keyVersion = Encryption.shared.getDailyAesKeyVersion();
                        }

                        //DLog("AES key version: " + String( keyVersion ) );

                        //still overwrite with default key, in case switched stores
                        /*//don't overwrite previous daily key with default key
                        if( keyVersion == 1 && msrAesVer > 1 )
                        {
                            //DLog("AES key version loaded on MSR is " + String( msrAesVer ) + ", skipping overwriting with default key.");
                            LoggingRequest.logData(name: LoggingRequest.metrics_info, value: "AES key version loaded on MSR is " + String( msrAesVer ) + ", skipping overwriting with default key.", type: "STRING", indexable: true);
                            break;
                        }*/

                        //DLog("Injected key version: " + String( CommonUtils.getInjectedKeyVersion() ) );
                        //DLog("Daily AES key version: " + String( Encryption.shared.getDailyAesKeyVersion() ) );

                        if( CommonUtils.getInjectedKeyVersion() == 0 ||
                            CommonUtils.getInjectedKeyVersion() != Encryption.shared.getDailyAesKeyVersion() )  //set injected key version idiot
                        {
                            if( /*keyVersion == msrAesVer ||*/ loadKeyId(keyID: KEY_EH_AES256_ENCRYPTION1, keyData: key, keyVersion: keyVersion, kekData: newKekData ) )
                            {
                                //still load the key even if the version is the same, in case switched stores
                                /*if( keyVersion == msrAesVer )
                                {
                                    //DLog("AES key version loaded on MSR is already " + String( msrAesVer ) + ", skipping load.");
                                    LoggingRequest.logData(name: LoggingRequest.metrics_info, value: "AES key version loaded on MSR is already " + String( msrAesVer ) + ", skipping load.", type: "STRING", indexable: true);
                                }*/

                                //DLog("Setting injected key version to " + String( keyVersion ) );
                                CommonUtils.setInjectedKeyVersion( value: keyVersion );
                                break;
                            }
                        }
                        else if( CommonUtils.getInjectedKeyVersion() == Encryption.shared.getDailyAesKeyVersion() )
                        {
                            // Ran in to a bug where if the daily key was injected, the app was pushed to the backgroud, then restarted, when the sled reconnected we tried to inject the daily key again but the daily key
                            // was already injected, so we looped through our retries then killed the app. Putting this break here should stop that from happening, but will still allow us to switch devices between stores
                            // even with the same daily key number because this logic is triggered off of what key did the current running instance of the application inject. Therefore if we switched between stores the
                            // injected key version is cleared and the app will try to inject it again. This only works, I think, if the app is restarted (or reinstalled) when switching stores. If you change stores then just
                            // repush the managed application configuration through AirWatch I think we'll still have this issue, but most people don't do that so this will cover almost all common use cases.
                            
                            break;
                        }
                    }
                    
                    retries -= 1;
                    sleep(1);
                }
                    while( retries > 0 );
                
                if( retries == 0 )
                {
                    //we tried too many times, bail out
                    if let viewController:ViewController = window!.rootViewController as? ViewController
                    {
                        let message = "This device does not have the required security key. Please remove device from sales floor immediately and open a ticket.";
                        
                        // create the alert
                        let alert = UIAlertController(title: "No Security Key", message: message, preferredStyle: UIAlertControllerStyle.alert);
                        
                        // add an action (button)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                            exit(0);
                        }));
                        
                        // show the alert
                        viewController.present(alert, animated: true, completion: nil);
                    }
                }
            }
        }
    }

    func magneticCardEncryptedData(_ encryption: Int32, tracks: Int32, data: Data!, track1masked: String!, track2masked: String!, track3: String!, source: Int32) {
        let cardData = data ?? Data.init();
        
//        let decrypted = AESDecryptWithKey(data: data as NSData, key: getDefaultAESKey().getNSData() as NSData );
//        let decryptedBytes = decrypted?.getBytes();
//        let encryptedBytes = data.getBytes();
        
        var keyVersion : Int32? = (-1);
        do {
            let keyInfo = try sled?.emsrGetKeysInfo();
            if( keyInfo != nil )
            {
                keyVersion = keyInfo?.getKeyVersion(KEY_EH_AES256_ENCRYPTION1 );
                if( keyVersion == 1 )
                {
                    // Version 1 is the default key. Whoops!
                    LoggingRequest.logData(name: LoggingRequest.metrics_warning, value: "MSR swipe using default key.", type: "STRING", indexable: true);
                    //Since Macy's knows the default key as 0 and not 1 change the version over to 0
                    keyVersion = 0;
                }
            }
            else
            {
                LoggingRequest.logData(name: LoggingRequest.metrics_error, value: "Unable to get MSR keyInfo.", type: "STRING", indexable: true);
            }
        }
        catch
        {
            LoggingRequest.logData(name: LoggingRequest.metrics_error, value: "Unable to get MSR key version.", type: "STRING", indexable: true);
        }
        
        let msrData = [
            "data": cardData.base64EncodedString(),
            "encryptionType": "AES",
            "encryptionAlgorithm": "CBC",
            "keyVersion": keyVersion as Any
            ] as [String : Any];
        
        let msrJsonData = try! JSONSerialization.data(withJSONObject: msrData, options: []);
        var msrJsonString = String(data: msrJsonData, encoding: String.Encoding.utf8)!;
        msrJsonString = msrJsonString.replacingOccurrences(of: "\\", with: ""); //strip the backslashes since that's not valid base64
        updateMsrData(msrData: msrJsonString);
    }
}
