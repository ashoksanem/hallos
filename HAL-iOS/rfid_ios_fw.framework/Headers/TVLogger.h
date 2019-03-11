//
//  TvLogger.h
//  TrueVueMobileSDK
//
//  Created by David m Gonzales on 1/23/19.
//  Copyright © 2019 Johnson Controls. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "TVEnums.h"

@interface TVLogger : NSObject

+ (void) setLogHandler:(void (^)(NSString * (^message)(void), TVLogLevel level, const char *file, const char *function, NSUInteger line))logHandler;

@end
