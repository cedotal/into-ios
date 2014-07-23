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

// if an interest review view is chained, it's delegate knows to continue presenting
// more interest review view controllers on itself until the user has the minimum
// viable number of interests
-(void)presentInterestReviewViewControllerChainedUntilMinimumInterestMet:(BOOL)isChained
                                     withMinimumViewControllersPresented:(long)minimumViewControllers;

-(void)dismissInterestReviewViewController:(ICBInterestReviewViewController *) outgoingController;

@end
