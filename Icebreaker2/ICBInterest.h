//
//  ICBInterest.h
//  Icebreaker
//
//  Created by Andrew Cedotal on 6/30/14.
//  Copyright (c) 2014 Icebreaker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

@interface ICBInterest : NSObject

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSURL *descriptionURL;
@property (nonatomic, readonly) PFObject *pfObject;

@property (nonatomic) BOOL preference;
@property (nonatomic) BOOL reviewed;

-(id)initWithPFObject:(PFObject *) object;

-(BOOL)isEqual:(id)object;

@end
