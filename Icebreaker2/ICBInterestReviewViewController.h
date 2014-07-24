//
//  ICBInterestReviewViewController.h
//  Icebreaker
//
//  Created by Andrew Cedotal on 6/29/14.
//  Copyright (c) 2014 Icebreaker. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ICBInterest;
@class ICBTabBarController;

@interface ICBInterestReviewViewController : UIViewController

@property (nonatomic) ICBInterest *interest;

@property (nonatomic, weak) ICBTabBarController *delegate;

// if an interest review view is chained, it's delegate knows to continue presenting
// more interest review view controllers on itself until the user has the minimum
// viable number of interests
@property (nonatomic) BOOL chained;

// if it has successors, it will continue presenting interest review view controllers
// up to a minimum number as long as interests are available
@property (nonatomic) long successors;

-(id)initWithInterest:(ICBInterest *)interest;

@end
