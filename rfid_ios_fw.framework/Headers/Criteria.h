//
//  Criteria.h
//  BlueBirdSDKiOS
//
//  Created by Codebrahma on 27/11/16.
//  Copyright © 2016 codebrahma. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SelectionCriteriasBT.h"
@interface Criteria : NSObject
-(instancetype)initWithRFMemType:(int)RFMemType selectMask:(NSString*)selectMask selectStartPosByte:(int)selectStartPosByte selectMaskLengthBit:(int)selectMaskLengthBit RFSelActionType:(int)RFSelActionType ;

/*!
* Get Criteria's MemType value
* @return		bank value
*/
-(int)getSelectMemType ;
/*!
* Get Criteria's mask value
* @return		mask value
*/
-(NSString *)getSelectMask;
/*!
* Get Criteria's start position value
* @return		start position value
*/
-(short)getSelectStartPosByte;
/*!
* Get Criteria's mask length bit value
* @return		mask length bit value
*/
-(int) getSelectMaskLengthBit;
/*!
* Get Criteria's action value
* @return		action value
*/
-(int) getSelectAction;
-(NSString*) getMask ;
-(int) getBitptr;
-(int) getAction;
-(int) getBank;
-(short) getSelEndbit;
@end
