//
//  ICBInterest.m
//  Icebreaker
//
//  Created by Andrew Cedotal on 6/30/14.
//  Copyright (c) 2014 Icebreaker. All rights reserved.
//

#import "ICBInterest.h"

@implementation ICBInterest

-(id)initWithPFObject:(PFObject *) object
{
    NSString *name = [object objectForKey:@"name"];
    NSURL *descriptionURL = [NSURL URLWithString:[object objectForKey:@"descriptionUrl"]];
    return [self initWithName:name andDescriptionURL:descriptionURL];
}

-(id)initWithName:(NSString *)name andDescriptionURL:(NSURL *)descriptionURL
{
    // call the superclass' designated initializer
    self = [super init];
    if (self){
        _name = name;
        _descriptionURL = descriptionURL;
        _reviewed = NO;
        // default preference is NO; most people don't like most things
        _preference = NO;
    }
    
    // return address of new object
    return self;
}

-(void)setPreference:(BOOL)preference
{
    _preference = preference;
    // setting a preference is, by definition, reviewing
    _reviewed = YES;
}

-(void)setReviewed:(BOOL)reviewed
{
    _reviewed = reviewed;
    if(!reviewed){
        // back to default
        _preference = NO;
    }
}

@end
