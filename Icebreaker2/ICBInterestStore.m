//
//  ICBInterestStore.m
//  Icebreaker
//
//  Created by Andrew Cedotal on 6/29/14.
//  Copyright (c) 2014 Icebreaker. All rights reserved.
//

#import "ICBInterestStore.h"
#import "ICBInterest.h"
#import <Parse/Parse.h>

@interface ICBInterestStore()

@property (nonatomic) NSMutableArray *privateItems;

@end

@implementation ICBInterestStore

// we will attempt to get a new user to have at least this many interests before we try to show them any matches
const NSInteger minimumPreferences = 3;

// if a programmer calls [[BNRItemStore alloc] init], let him know the error of his ways
-(instancetype)init
{
    [NSException raise:@"Singleton" format:@"Use +[ICBInterestStore sharedStore"];
    return nil;
}

// here is the real (secret) initializer
-(instancetype)initPrivate
{
    self = [super init];
    _privateItems = [[NSMutableArray alloc] init];
    return self;
}

+(instancetype)sharedStore
{
    static ICBInterestStore *sharedStore;
    
    // do i need to create sharedStore?
    if (!sharedStore){
        sharedStore = [[self alloc] initPrivate];
    }
    
    return sharedStore;
}

-(void)fetchInterests
{
    PFQuery *query = [PFQuery queryWithClassName:@"Interest"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(error){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"nICBfetchInterestsDidFail"
                                                                object:nil];
        } else {
            for(PFObject *object in objects){
                ICBInterest *interest = [[ICBInterest alloc] initWithPFObject: object];
                [_privateItems addObject: interest];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:@"nICBfetchInterestsDidSucceed"
                                                                object:nil];

        }
    }];
}

-(ICBInterest*)retrieveRandomUnreviewedInterest
{
    NSIndexSet *unreviewedItemsIndexes = [_privateItems indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return !(((ICBInterest*)obj).reviewed);
    }];
    NSUInteger count = [unreviewedItemsIndexes count];
    if (count > 0){
        NSArray *unreviewedItems = [_privateItems objectsAtIndexes:unreviewedItemsIndexes];
        NSUInteger index = arc4random_uniform((unsigned int)count);
        ICBInterest *randomUnreviewedInterest = unreviewedItems[index];
        return randomUnreviewedInterest;
    } else {
        return nil;
    };
}

-(NSArray *)allPreferredInterests
{
    NSIndexSet *preferredInterestsIndexes = [_privateItems indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return (((ICBInterest*)obj).preference);
    }];
    NSArray *preferredInterests = [_privateItems objectsAtIndexes:preferredInterestsIndexes];
    return preferredInterests;
}

-(BOOL)userHasMinimumPreferredInterests
{
    NSIndexSet *preferredInterestsIndexes = [_privateItems indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return (((ICBInterest*)obj).preference);
    }];
    return ([preferredInterestsIndexes count] >= minimumPreferences);

}

@end
