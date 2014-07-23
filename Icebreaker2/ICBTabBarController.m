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
    
    [self presentTwoInterestReviewViewControllers];
}

#pragma mark Presenting and handling Interest Review modals

-(void)presentTwoInterestReviewViewControllers
{
    ICBInterest *interest1 = [[ICBInterestStore sharedStore] retrieveRandomUnreviewedInterest];
    ICBInterest *interest2 = [[ICBInterestStore sharedStore] retrieveRandomUnreviewedInterest];
    
    if (interest1 != nil && interest2 != nil){
        // create two interest review view controllers
        ICBInterestReviewViewController *irvc1 = [[ICBInterestReviewViewController alloc] initWithInterest:interest1];
        irvc1.delegate = self;
        ICBInterestReviewViewController *irvc2 = [[ICBInterestReviewViewController alloc] initWithInterest:interest2];
        irvc2.delegate = self;
        
        // put them in a property of this controller so we don't lose
        // reference to them
        [self.presentedInterestReviewViewControllers addObject:irvc1];
        [self.presentedInterestReviewViewControllers addObject:irvc2];

        
        int screenWidth = self.view.frame.size.width;
        
        irvc1.view.transform = CGAffineTransformMakeTranslation(screenWidth, 0.0);
        irvc2.view.transform = CGAffineTransformMakeTranslation(screenWidth, 0.0);
        
        [self.view insertSubview:irvc1.view aboveSubview:self.view];
        [self.view insertSubview:irvc2.view aboveSubview:self.view];
        
        [UIView animateWithDuration:0.8
                         animations:^{
            irvc1.view.transform = CGAffineTransformIdentity;
            irvc2.view.transform = CGAffineTransformIdentity;
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
