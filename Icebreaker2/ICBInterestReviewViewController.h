//
//  ICBInterestReviewViewController.h
//  Icebreaker
//
//  Created by Andrew Cedotal on 6/29/14.
//  Copyright (c) 2014 Icebreaker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ICBInterest.h"
#import "ICBTabBarController.h"

@interface ICBInterestReviewViewController : UIViewController

@property (nonatomic, weak) ICBTabBarController *delegate;

// designated initializer
-(id)initWithInterest:(ICBInterest *)interest andChainedStatus:(BOOL)chained;
-(id)initWithInterest:(ICBInterest *)interest;

@end
