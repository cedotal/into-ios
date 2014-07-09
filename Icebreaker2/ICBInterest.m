//
//  ICBInterest.m
//  Icebreaker
//
//  Created by Andrew Cedotal on 6/30/14.
//  Copyright (c) 2014 Icebreaker. All rights reserved.
//

#import "ICBInterest.h"

@implementation ICBInterest

-(id)initWithPFObject:(PFObject *) pfObject
{
    NSString *name = [pfObject objectForKey:@"name"];
    NSURL *descriptionURL = [NSURL URLWithString:[pfObject objectForKey:@"descriptionUrl"]];
    return [self initWithName:name andDescriptionURL:descriptionURL andPFObject:pfObject];
}

-(id)initWithName:(NSString *)name
andDescriptionURL:(NSURL *)descriptionURL
      andPFObject:(PFObject *)pfObject
{
    // call the superclass' designated initializer
    self = [super init];
    if (self){
        _name = name;
        _descriptionURL = descriptionURL;
        _pfObject = pfObject;
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

-(BOOL)isEqual:(id)object
{
    // first check if object is this class or a subclass to avoid breaking when
    // we send a message to objectId
    if(![object isKindOfClass:[ICBInterest class]]){
        return false;
    };
    // use contained Parse object to determine equality
    NSString *ownObjectId = self.pfObject.objectId;
    NSString *otherObjectId = [[(ICBInterest *)object valueForKey:@"pfObject"] valueForKey:@"objectId"];
    BOOL equals = [ownObjectId isEqualToString: otherObjectId];
    return (equals);
}


@end
