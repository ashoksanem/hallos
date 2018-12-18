//
// Copyright (c) 2016 Johnson Controls. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TVEnums.h"


@interface ReaderConfig : NSObject

@property(nonatomic, readwrite) int readerPower;
@property(nonatomic, readwrite) TVReaderSession readerSession;
@property(nonatomic, readwrite) TVReaderVolume readerVolume;
@property(nonatomic, readwrite) BOOL enableBarcodeScanner;

@end
