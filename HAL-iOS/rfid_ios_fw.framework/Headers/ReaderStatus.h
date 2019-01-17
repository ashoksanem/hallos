//
// Copyright (c) 2016 Johnson Controls. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TVEnums.h"


@interface ReaderStatus : NSObject

@property(nonatomic, readwrite) int readerPower, batteryLevel;
@property(nonatomic, readwrite) BOOL connected, barcodeScannerEnabled;
@property(nonatomic, readwrite) NSString *deviceId, *version;
@property(nonatomic, readwrite) TVReaderMode readerMode;
@property(nonatomic, readwrite) TVReaderSession readerSession;
@property(nonatomic, readwrite) TVReaderVolume readerVolume;

@end
