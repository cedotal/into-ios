//
//  ICBTabBarController
//  Icebreaker
//
//  Created by Andrew Cedotal on 7/6/14.
//  Copyright (c) 2014 Icebreaker. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ICBInterestsViewController;
@class ICBInterestReviewViewController;

@interface ICBTabBarController : UITabBarController

@property (nonatomic, readonly) ICBInterestsViewController *interestsViewController;

-(void)presentThisManyInterestReviewViewControllers:(long)numberOfControllersToPresent;

-(void)dismissInterestReviewViewController:(ICBInterestReviewViewController *) outgoingController;

@end
