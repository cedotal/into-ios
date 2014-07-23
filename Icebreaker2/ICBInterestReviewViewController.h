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

@property (nonatomic, weak) ICBTabBarController *delegate;

-(id)initWithInterest:(ICBInterest *)interest;

@end
