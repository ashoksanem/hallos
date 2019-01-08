//
//  SelectionCriteriasBT.h
//  BlueBirdSDKiOS
//
//  Created by Codebrahma on 27/11/16.
//  Copyright © 2016 codebrahma. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SelectionCriteriasBT : NSObject
@property (nonatomic) NSMutableArray *mCriteriaList;
-(int)makeCriteria:(int)scMemType mask:(NSString *)mask selectStartPosByte:(int)selectStartPosByte selectMaskLengthBit:(int)selectMaskLengthBit scActionType:(int) scActionType;
-(NSMutableArray*) getCriteria;
@end
