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
#import "ICBInterestStore.h"
#import "ICBInterestReviewViewController.h"

@interface ICBTabBarController()

@property (nonatomic) ICBInterestsViewController *interestsViewController;

@property (nonatomic) NSMutableArray *presentedInterestReviewViewControllers;

-(void)presentInterestReviewViewController;

@end

@implementation ICBTabBarController

-(instancetype)init{
    self = [super init];
    if (self){
        // set up tabbed views and their controllers
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
    
    // init array of presented interest review view controllers
    self.presentedInterestReviewViewControllers = [[NSMutableArray alloc] init];
    
    [self presentThisManyInterestReviewViewControllers:3];
}

#pragma mark Presenting and handling Interest Review modals

-(void)presentThisManyInterestReviewViewControllers:(long)numberOfControllersToPresent
{
    for(int i = 0; i < numberOfControllersToPresent; i++){
        [self presentInterestReviewViewController];
    }
}

-(void)presentInterestReviewViewController
{
    ICBInterest *interest = [[ICBInterestStore sharedStore] retrieveRandomUnreviewedInterest];
    
    if (interest != nil){
        // create two interest review view controllers
        ICBInterestReviewViewController *irvc = [[ICBInterestReviewViewController alloc] initWithInterest:interest];
        irvc.delegate = self;
        
        // put them in a property of this controller so we don't lose
        // reference to them
        [self.presentedInterestReviewViewControllers addObject:irvc];

        
        int screenWidth = self.view.frame.size.width;
        
        irvc.view.transform = CGAffineTransformMakeTranslation(screenWidth, 0.0);
        
        [self.view insertSubview:irvc.view aboveSubview:self.view];
        
        [UIView animateWithDuration:0.8
                         animations:^{
            irvc.view.transform = CGAffineTransformIdentity;
        }];
    }
}

-(void)dismissInterestReviewViewController:(ICBInterestReviewViewController *)outgoingController
{
    // animate the view out
    int negativeWidth = -1*self.view.frame.size.width;
    
    [UIView animateWithDuration:0.6
        animations:^{
            outgoingController.view.transform = CGAffineTransformMakeTranslation(negativeWidth, 0.0);
    }];
    
    // remove the view from our array, which will cause it to be dealloc'd
    long indexOfPresentedViewToRemove = [self.presentedInterestReviewViewControllers indexOfObject:outgoingController];
    [self.presentedInterestReviewViewControllers removeObjectAtIndex:indexOfPresentedViewToRemove];
}

@end
