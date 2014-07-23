//
//  ICBInterestStore.h
//  Icebreaker
//
//  Created by Andrew Cedotal on 6/29/14.
//  Copyright (c) 2014 Icebreaker. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ICBInterest;

@interface ICBInterestStore : NSObject

// get the singleton object
+(instancetype)sharedStore;

// get interests from Parse
-(void)fetchInterests;

// ways to get interests
-(ICBInterest *)retrieveRandomUnreviewedInterest;
-(NSArray *)allPreferredInterests;

// user status
-(BOOL)userHasMinimumPreferredInterests;

@end
