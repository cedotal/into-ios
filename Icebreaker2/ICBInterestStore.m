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
    // in order to know which interests are preferred, we're going to have to execute
    // multiple queries:
    // 1 a query to fill out the interests array on the current user
    // 2. a query to get all interests currently in existence
    
    // chain our queries so that the all but the last calls the next one if successful
    // and sends the failure notification otherwise. the last one executes our
    // model changes and sends the success notification if successful; it sends
    // the failure notification otherwise
    PFUser *user = [PFUser currentUser];
    PFQuery *userQuery = [PFUser query];
    [userQuery includeKey:@"interests"];
    NSString *username = [user objectForKey:@"username"];
    [userQuery whereKey:@"username" equalTo:username];
    [userQuery getFirstObjectInBackgroundWithBlock:^(PFObject *userObject, NSError *error) {
        if(error){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"nICBfetchInterestsDidFail"
                                                                object:nil];
        } else {
            NSArray *userPFInterests = [userObject objectForKey:@"interests"];
            PFQuery *allInterestsQuery = [PFQuery queryWithClassName:@"Interest"];
            [allInterestsQuery findObjectsInBackgroundWithBlock:^(NSArray *allPFInterests, NSError *error) {
                if(error){
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"nICBfetchInterestsDidFail"
                                                                        object:nil];
                } else {
                    [self populateInterestsWithUsersInterests:userPFInterests
                                              andAllInterests:allPFInterests];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"nICBfetchInterestsDidSucceed"
                                                                        object:nil];
                }
            }];
        }
    }];
}

-(void)populateInterestsWithUsersInterests:(NSArray *) userPFInterests
                           andAllInterests:(NSArray *) allPFInterests
{
    NSMutableArray *allInterests = [[NSMutableArray alloc] init];
    for(PFObject *allPFInterest in allPFInterests){
        ICBInterest *interest = [[ICBInterest alloc] initWithPFObject:allPFInterest];
        [allInterests addObject:interest];
    }
    NSMutableArray *userInterests = [[NSMutableArray alloc] init];
    for(PFObject *userPFInterest in userPFInterests){
        ICBInterest *interest = [[ICBInterest alloc] initWithPFObject:userPFInterest];
        [userInterests addObject:interest];
    }
    for(ICBInterest *allInterest in allInterests){
        if([userInterests containsObject:allInterest]){
            allInterest.preference = YES;
        }
        [_privateItems addObject: allInterest];
    }

}

-(ICBInterest*)retrieveRandomUnreviewedInterest
{
    // count unreviewed interests
    NSIndexSet *unreviewedItemsIndexes = [_privateItems indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return !(((ICBInterest *)obj).reviewed);
    }];
    NSUInteger count = [unreviewedItemsIndexes count];
    // if none are left, reset all non-preferred interests to be non-reviewed
    if (count == 0){
        for(ICBInterest *item in _privateItems){
            if(!item.preference){
                item.reviewed = NO;
            }
        }
        // reset these vars because their underlying data has changed
        unreviewedItemsIndexes = [_privateItems indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            return !(((ICBInterest *)obj).reviewed);
        }];
        count = [unreviewedItemsIndexes count];
    }
    ICBInterest *randomUnreviewedInterest;
    if(count > 0){
        NSArray *unreviewedItems = [_privateItems objectsAtIndexes:unreviewedItemsIndexes];
        NSUInteger index = arc4random_uniform((unsigned int)count);
        randomUnreviewedInterest = unreviewedItems[index];
    } else {
        randomUnreviewedInterest = nil;
    }
    
    return randomUnreviewedInterest;
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
