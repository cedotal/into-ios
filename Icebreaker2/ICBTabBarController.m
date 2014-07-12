//
//  ICBTabBarController
//  Icebreaker
//
//  Created by Andrew Cedotal on 7/6/14.
//  Copyright (c) 2014 Icebreaker. All rights reserved.
//

#import "ICBTabBarController.h"
#import "ICBUsersViewController.h"
#import "ICBInterestsViewController.h"
#import "ICBInterestReviewViewController.h"
#import "ICBInterestStore.h"

@interface ICBTabBarController()

@property (nonatomic) ICBInterestsViewController *interestsViewController;

-(void)presentInterestReviewViewControllerWithOptions:(NSDictionary *)options;

@end

@implementation ICBTabBarController

-(instancetype)init{
    self = [super init];
    if (self){
        ICBUsersViewController *uvc = [[ICBUsersViewController alloc] init];
        ICBInterestsViewController *ivc = [[ICBInterestsViewController alloc] init];
        self.interestsViewController = ivc;
        self.viewControllers = @[uvc, ivc];
    }
    return self;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    NSMutableDictionary *optionsMutable = [NSMutableDictionary dictionaryWithCapacity:2];
    [optionsMutable setValue:@YES forKey:@"checkMinimumPreferredInterests"];
    [optionsMutable setValue:@YES forKey:@"chained"];
    NSDictionary *options = [optionsMutable copy];
    
    [self presentThisManyInterestReviewViewControllers:1
                                           withOptions:options];
}

#pragma mark Presenting and handling Interest Review modals

-(void)presentThisManyInterestReviewViewControllers:(NSInteger)number
                                        withOptions:(NSDictionary *)options
{
    for (NSInteger i = 0; i < number; i++){
        [self presentInterestReviewViewControllerWithOptions: options];
    }
}

-(void)presentInterestReviewViewControllerWithOptions:(NSDictionary *)options
{
    // attempt to get an unreviewed interest
    ICBInterest *randomUnreviewedInterest = [[ICBInterestStore sharedStore] retrieveRandomUnreviewedInterest];
    // if we need to check whether the user has the minimum number of preferred
    // interests, check it
    BOOL minimumPreferredInterestsCheck;
    if ([[options objectForKey:@"checkMinimumPreferredInterests"] boolValue]){
        minimumPreferredInterestsCheck = ![[ICBInterestStore sharedStore] userHasMinimumPreferredInterests];
        
    } else {
        minimumPreferredInterestsCheck = YES;
    }
    // only present an interest view if there is an unreviewed interest left to present
    // and (if applicable) we passed the minimum preferred interests check
    if (randomUnreviewedInterest != nil && minimumPreferredInterestsCheck){
        ICBInterestReviewViewController *irvc = [[ICBInterestReviewViewController alloc] initWithInterest:randomUnreviewedInterest andChainedStatus:[[options objectForKey:@"chained"] boolValue]];
        // give presented model a pointer to self so modal can create more modals
        irvc.delegate = self;
        [self presentViewController:irvc
                           animated:YES
                         completion:^{}];
    }
}

@end
