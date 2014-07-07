//
//  ICBInterestReviewViewController.m
//  Icebreaker
//
//  Created by Andrew Cedotal on 6/29/14.
//  Copyright (c) 2014 Icebreaker. All rights reserved.
//

#import "ICBInterestReviewViewController.h"
#import "ICBInterestsViewController.h"
#import "ICBTabBarController.h"

@interface ICBInterestReviewViewController()

@property (nonatomic) ICBInterest *interest;
@property (nonatomic, weak) IBOutlet UILabel *interestNameLabel;

// determines whether the view attempts to push another controller of its class
// underneath when it's dismissed
@property (nonatomic) BOOL chained;

-(void)displayNewInterestReviewViewController;

@end

@implementation ICBInterestReviewViewController

-(id)initWithInterest:(ICBInterest *)interest andChainedStatus:(BOOL)chained;
{
    self = [super init];
    
    _interest = interest;
    _chained = chained;
    
    return self;
}

-(id)initWithInterest:(ICBInterest *)interest
{
    return [self initWithInterest:interest
                 andChainedStatus:NO];
}

-(void)viewDidLoad
{
    self.interestNameLabel.text = [NSString stringWithFormat:@"%@%@", self.interest.name, @"?"];
}

// handle user actions
-(IBAction)userTappedYes:(id)sender
{
    self.interest.preference = YES;
    NSDictionary *dict = [NSDictionary dictionaryWithObject:self.interest
                                                     forKey:@"interest"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"nICBuserDidSetPreferenceOnInterest"
                                                        object:nil
                                                      userInfo:dict];
    [self.presentingViewController dismissViewControllerAnimated:YES
                                                      completion:^{
                                                          [self displayNewInterestReviewViewController];
                                                      }];
}

-(IBAction)userTappedNo:(id)sender
{
    self.interest.preference = NO;
    [self.presentingViewController dismissViewControllerAnimated:YES
                                                      completion:^{
                                                          [self displayNewInterestReviewViewController];
                                                      }];
}
     
-(IBAction)userTappedOpenUrl:(id)sender
{
    [[UIApplication sharedApplication] openURL:self.interest.descriptionURL];
}

-(void)displayNewInterestReviewViewController
{
    NSDictionary *options = [NSDictionary dictionaryWithObjects:@[@(self.chained), @(self.chained)]
                                                        forKeys:@[@"checkMinimumPreferredInterests", @"chained"]];
    if (self.chained){
        [self.delegate presentThisManyInterestReviewViewControllers:1
                                                        withOptions:options];
    }
}

@end
