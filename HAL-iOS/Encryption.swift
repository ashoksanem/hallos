//
//  Encryption.swift
//  HAL-iOS
//
//  Created by Brian Dembinski on 7/24/17.
//  Copyright © 2017 macys. All rights reserved.
//

import Foundation

@objc(Encryption)
class Encryption: NSObject
{
    static var shared: Encryption = Encryption();
    
    private var dailyAesKeyVersion : Int32 = (-1);
    private var dailyAesKey : Data? = nil;
    
    private override init() {
        super.init();
    }
    
    func setDailyAesKeyVersion( version : Int32 )
    {
        //DLog( "Setting daily AES key version to " + String( version ) + "." );
        LoggingRequest.logData(name: LoggingRequest.metrics_info, value: "Setting daily AES key version to " + String( version ) + ".", type: "STRING", indexable: true);
        
        dailyAesKeyVersion = version;
    }
    
    func getDailyAesKeyVersion() -> Int32
    {
        return dailyAesKeyVersion;
    }
    
    func setDailyAesKey( key : String )
    {
        dailyAesKey = GenericEncryption.decrypt( key );
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.injectMsr();
            let start = dailyAesKey?.startIndex;
            let end = dailyAesKey?.endIndex;
            dailyAesKey?.resetBytes(in: start!..<end!);
            dailyAesKey = nil; //remove the aes key from memory once it's in the sled or if it fails to add it to the sled
        }
    }
    
    func getDailyAesKey() -> [UInt8]?
    {
        return dailyAesKey?.getBytes();
    }
}

func getKek() -> String
{
    //a4387054:imas b415570$ openssl enc -aes-256-ecb -k InfinitePeripherals -P -md sha1 -nosalt
    //key=4475C493C0AE0B2A112B40535DFE0A61A3FEB9BFB999404DCD8D650932D3F799
    return "4475C493C0AE0B2A112B40535DFE0A61";
}

func getKekVersion() -> Int32
{
    return 1;
}

func getDefaultAESKey() -> [UInt8]
{
    var array : [UInt8] = [UInt8](repeating: 0x00, count: 32 );
    array[0] = 0xFC;
    array[1] = 0xF3;
    array[2] = 0x80;
    array[3] = 0xD1;
    array[4] = 0xAC;
    array[5] = 0xC2;
    array[6] = 0x72;
    array[7] = 0xEB;
    array[8] = 0x40;
    array[9] = 0x53;
    array[10] = 0x40;
    array[11] = 0x48;
    array[12] = 0x40;
    array[13] = 0xC1;
    array[14] = 0xFC;
    array[15] = 0x6E;
    array[16] = 0x40;
    array[17] = 0xD6;
    array[18] = 0x64;
    array[19] = 0xC2;
    array[20] = 0x6E;
    array[21] = 0xC1;
    array[22] = 0xE2;
    array[23] = 0xCD;
    array[24] = 0x6D;
    array[25] = 0x52;
    array[26] = 0xC8;
    array[27] = 0x66;
    array[28] = 0xA0;
    array[29] = 0x48;
    array[30] = 0x50;
    array[31] = 0xB0;
    
    return array;
}

func AESOperation(data: NSData, operation:CCOperation, key:NSData) -> NSData?
{
    var keySize=kCCKeySizeAES256;
    if( key.length <= 16 )
    {
        keySize = kCCKeySizeAES128;
    }
    
    //See the doc: For block ciphers, the output size will always be less than or
    //equal to the input size plus the size of one block.
    //That's why we need to add the size of one block here
    let bufferSize = data.length + kCCBlockSizeAES128;
    
    //        let hash = UnsafeMutablePointer<UInt8>.alloc(Int(CC_SHA256_DIGEST_LENGTH))
    let buffer = malloc(bufferSize);
    var numBytes:size_t = 0;
    let cryptStatus = CCCrypt(operation, CCAlgorithm(kCCAlgorithmAES128), 0, key.bytes, keySize, nil, data.bytes, data.length, buffer, bufferSize, &numBytes);
    
    var d: NSData? = nil;
    if( cryptStatus == CCCryptorStatus(kCCSuccess) )
    {
        //the returned NSData takes ownership of the buffer and will free it on deallocation
        d=NSData(bytes: buffer, length: numBytes);
    }
    
    free(buffer); //free the buffer;
    return d;
}

func AESEncryptWithKey(data: NSData, key:NSData) -> NSData?
{
    return AESOperation(data: data, operation:CCAlgorithm(kCCEncrypt), key:key);
}

func AESDecryptWithKey(data: NSData, key:NSData) -> NSData?
{
    return AESOperation(data: data, operation:CCAlgorithm(kCCDecrypt), key:key);
}
