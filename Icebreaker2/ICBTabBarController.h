//
//  ICBTabBarController
//  Icebreaker
//
//  Created by Andrew Cedotal on 7/6/14.
//  Copyright (c) 2014 Icebreaker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ICBInterestsViewController.h"

@interface ICBTabBarController : UITabBarController

@property (nonatomic, readonly) ICBInterestsViewController *interestsViewController;

// allows other view controllers to display new interest review modals
-(void)presentThisManyInterestReviewViewControllers:(NSInteger)numberOfInterestReviewViewControllers
                                        withOptions:(NSDictionary *)options;

@end
