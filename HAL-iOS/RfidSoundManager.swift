//
//  RfidSoundManager.swift
//  HAL-iOS
//
//  Created by Minh Dang Le on 4/1/19.
//  Copyright © 2019 macys. All rights reserved.
///
//Required Files:
// 1-Ping-VerySlow.wav, 1-Ping-Slow.wav, 1-Ping-Medium.wav, 1-Ping-Fast.wav, 1-Ping-Insane"
//
// HOW TO SET PROXIMITY FOR EACH BUCKET
//  EXAMPLE
//  let RangeDefinition:[RfidSoundManager.bucketType: (Int,Int)] = [
//                      RfidSoundManager.bucketType.OutOfRange:(0, 0),
//                      RfidSoundManager.bucketType.BarelyInRange:(1, 10),
//                      RfidSoundManager.bucketType.Far :(11, 29),
//                      RfidSoundManager.bucketType.Near : (30, 59),
//                      RfidSoundManager.bucketType.VeryNear:(60, 79),
//                      RfidSoundManager.bucketType.RightOnTop:(80, 100]

//  RfidSoundManager.setProximitySetting(ProximityDef: RangeDefinition)
//


import UIKit
import AVFoundation


class RfidSoundManager: NSObject {
    //Create an audio player instance for each sound.
    //static var iPlayer : AVAudioPlayer!
    static var BarelyInRangePlayer : AVAudioPlayer!
    static var FarPlayer : AVAudioPlayer!
    static var NearPlayer: AVAudioPlayer!
    static var VeryNearPlayer: AVAudioPlayer!
    static var RightOnTopPlayer: AVAudioPlayer!
    
    //Define Soundtracks library
    static let sounds = SoundLibary(OutOfRangeFile: "", BarelyInRangeFile: "1-Ping-VerySlow", FarFile: "1-Ping-Slow", NearFile: "1-Ping-Medium", VeryNearFile: "1-Ping-Fast", RightOnTopFile: "1-Ping-Insane")
    
    static var isEnable = false
    
    static var isPlaying = false
    static var isProximityChanged = true;
    static var currentBucket:bucketType = bucketType.OutOfRange
    
    static var OutOfRange:(Int,Int)!
    static var BarelyInRange: (Int,Int)!
    static var Far : (Int,Int)!
    static var Near: (Int,Int)!
    static var VeryNear : (Int,Int)!
    static var RightOnTop : (Int,Int)!
    
    
    
    enum bucketType {
        case None
        case OutOfRange
        case BarelyInRange
        case Far
        case Near
        case VeryNear
        case RightOnTop
    }
    
    static private var RangeDefinition:[bucketType: (Int,Int)] = [
        bucketType.OutOfRange:(0, 0),
        bucketType.BarelyInRange:(1,9),
        bucketType.Far :(10,27),
        bucketType.Near : (28,48),
        bucketType.VeryNear:(49,79),
        bucketType.RightOnTop:(80,100)]
    
    
    override init(){
        super.init()
        
        do{
            
            let path = Bundle.main.path(forResource: RfidSoundManager.sounds.BarelyInRangeFile!, ofType: "wav")!
            let url = URL(fileURLWithPath: path)
            RfidSoundManager.BarelyInRangePlayer = try AVAudioPlayer(contentsOf: url)
            RfidSoundManager.BarelyInRangePlayer.numberOfLoops = -1;
            
            RfidSoundManager.FarPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: RfidSoundManager.sounds.FarFile!, ofType: "wav")!))
            RfidSoundManager.FarPlayer.numberOfLoops = -1;
            
            RfidSoundManager.NearPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: RfidSoundManager.sounds.NearFile!, ofType: "wav")!))
            RfidSoundManager.NearPlayer.numberOfLoops = -1;
            
            RfidSoundManager.VeryNearPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: RfidSoundManager.sounds.VeryNearFile!, ofType: "wav")!))
            RfidSoundManager.VeryNearPlayer.numberOfLoops = -1;
            
            RfidSoundManager.RightOnTopPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: RfidSoundManager.sounds.RightOnTopFile!, ofType: "wav")!))
            RfidSoundManager.RightOnTopPlayer.numberOfLoops = -1;
        }
        catch {
            print("ERROR: Could'nt load sound file")
            print("ERROR info: \(error)")
        }
        
        
    }
    
    
    
    class func setProximitySetting(ProximityDef:[bucketType: (Int,Int)]){
        
        self.RangeDefinition = ProximityDef
        isProximityChanged = true;
    }
    
    class func getProximitySetting() -> [RfidSoundManager.bucketType: (Int,Int)]{
        
        return self.RangeDefinition
        
    }
    /*
     Returns bucket type based on proximity percentage
     */
    private class func GetBucketType(p_rssi:Int ) -> bucketType{
        
        if(isProximityChanged){
            OutOfRange = RangeDefinition[bucketType.OutOfRange]
            BarelyInRange = RangeDefinition[bucketType.BarelyInRange]
            Far = RangeDefinition[bucketType.Far]
            Near = RangeDefinition[bucketType.Near]
            VeryNear = RangeDefinition[bucketType.VeryNear]
            RightOnTop = RangeDefinition[bucketType.RightOnTop]
            isProximityChanged = false
        }
        if(OutOfRange?.0)! <= p_rssi && p_rssi <= (OutOfRange?.1)!{
            return bucketType.OutOfRange
        }
        else if(BarelyInRange?.0)! <= p_rssi && p_rssi <= (BarelyInRange?.1)!{
            return bucketType.BarelyInRange
        }
        else if(Far?.0)! <= p_rssi && p_rssi <= (Far?.1)!{
            return bucketType.Far
        }
        else if(Near?.0)! <= p_rssi && p_rssi <= (Near?.1)!{
            return bucketType.Near
        }
        else if(VeryNear?.0)! <= p_rssi && p_rssi <= (VeryNear?.1)!{
            return bucketType.VeryNear
        }
        else if(RightOnTop?.0)! <= p_rssi && p_rssi <= (RightOnTop?.1)!{
            return bucketType.RightOnTop
        }
        
        return bucketType.OutOfRange
        
    }
    
    class func playSound(ProximityValue: Int){
        if(isEnable){
            
            switch(GetBucketType(p_rssi: ProximityValue)){
            case .OutOfRange:
                if(!(isPlaying && currentBucket == bucketType.OutOfRange)){
                    StopAllSounds()
                    isPlaying = true
                    currentBucket = bucketType.OutOfRange
                }
            case .BarelyInRange:
                if(!(isPlaying && currentBucket == bucketType.BarelyInRange)){
                    StopAllSounds()
                    BarelyInRangePlayer.play()
                    isPlaying = true
                    currentBucket = bucketType.BarelyInRange
                }
            case .Far:
                if(!(isPlaying && currentBucket == bucketType.Far)){
                    StopAllSounds()
                    FarPlayer.play()
                    isPlaying = true
                    currentBucket = bucketType.Far
                }
            case .Near:
                if(!(isPlaying && currentBucket == bucketType.Near)){
                    StopAllSounds()
                    NearPlayer.play()
                    isPlaying = true
                    currentBucket = bucketType.Near
                }
                
            case .VeryNear:
                if(!(isPlaying && currentBucket == bucketType.VeryNear)){
                    StopAllSounds()
                    VeryNearPlayer.play()
                    isPlaying = true
                    currentBucket = bucketType.VeryNear
                }
            case .RightOnTop:
                if(!(isPlaying && currentBucket == bucketType.RightOnTop)){
                    StopAllSounds()
                    RightOnTopPlayer.play()
                    isPlaying = true
                    currentBucket = bucketType.RightOnTop
                }
                
            default:
                StopAllSounds()
                
                
            }
        }
        
    }
    
    
    
    //    class func playSound(soundName: String)
    //    {
    //        if(isEnable){
    //            do {
    //                //soundName without extension
    //                let path = Bundle.main.path(forResource: soundName, ofType: "wav")!
    //                let url = URL(fileURLWithPath: path)
    //
    //                iPlayer = try AVAudioPlayer(contentsOf: url)
    //                iPlayer.numberOfLoops = -1;
    //                iPlayer.play()
    //                isPlaying = true
    //            } catch {
    //                print("ERROR: Could'nt load \(soundName) file")
    //            }
    //        }
    //    }
    
    
    class func StopAllSounds(){
        if(isEnable){
            do{
                
                // iPlayer.stop()
                BarelyInRangePlayer.stop()
                FarPlayer.stop()
                NearPlayer.stop()
                VeryNearPlayer.stop()
                RightOnTopPlayer.stop()
                currentBucket = bucketType.None
                isPlaying = false
            }
            catch{
                print("ERROR info: \(error)")
            }
        }
    }
    
    
    //You have to create your own queue or if you need the Default queue
    
    class func queueTEster() {
        let semaphore = DispatchSemaphore(value: 0)
        semaphore.signal()
        semaphore.wait(timeout: .distantFuture)
    }
    
}

class SoundLibary:NSObject{
    var OutOfRangeFile:String?
    var BarelyInRangeFile:String?
    var FarFile:String?
    var NearFile:String?
    var VeryNearFile:String?
    var RightOnTopFile:String?
    
    init(OutOfRangeFile:String, BarelyInRangeFile:String, FarFile:String, NearFile:String, VeryNearFile:String, RightOnTopFile:String){
        self.OutOfRangeFile = OutOfRangeFile
        self.BarelyInRangeFile = BarelyInRangeFile
        self.FarFile = FarFile
        self.NearFile = NearFile
        self.VeryNearFile = VeryNearFile
        self.RightOnTopFile = RightOnTopFile
    }
    
    override init(){
        super.init()
    }
    
    
    
}
