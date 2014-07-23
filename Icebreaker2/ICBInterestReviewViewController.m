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
#import "ICBInterest.h"

@interface ICBInterestReviewViewController()

@property (nonatomic) ICBInterest *interest;
@property (nonatomic, weak) IBOutlet UILabel *interestNameLabel;

-(void)displayNewInterestReviewViewController;
-(void)userDidExpressPreference:(BOOL) preference;

@end

@implementation ICBInterestReviewViewController

-(id)initWithInterest:(ICBInterest *)interest;
{
    self = [super init];
    
    _interest = interest;
    
    return self;
}

-(void)viewDidLoad
{
    self.interestNameLabel.text = [NSString stringWithFormat:@"%@%@", self.interest.name, @"?"];
}

// handle user actions
-(IBAction)userTappedYes:(id)sender
{
    [self userDidExpressPreference:YES];
}

-(IBAction)userTappedNo:(id)sender
{
    [self userDidExpressPreference:NO];
}

-(void)userDidExpressPreference:(BOOL) preference
{
    // only need to go to network if the user set preference to YES
    if (preference){
        PFUser *user = [PFUser currentUser];
        PFObject *pfInterest = self.interest.pfObject;
        [user addObject:pfInterest forKey:@"interests"];
        [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if(!error){
                self.interest.preference = preference;
                NSDictionary *dict = [NSDictionary dictionaryWithObject:self.interest
                                                                 forKey:@"interest"];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"nICBuserDidSetPreferenceOnInterest"
                                                                    object:nil
                                                                  userInfo:dict];
            } else {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"You're not online!" message:@"You need to be online to edit your interests. Don't worry, you'll see this interest again later." delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
                [alertView show];
            }
            // either way, dismiss the controller
            [self.delegate dismissInterestReviewViewController:self];
        }];
    // if user set preference to NO, nothing needs to be created on server
    } else {
        self.interest.reviewed = YES;
        // either way, dismiss the controller
        [self.delegate dismissInterestReviewViewController:self];
    }
}

-(IBAction)userTappedOpenUrl:(id)sender
{
    [[UIApplication sharedApplication] openURL:self.interest.descriptionURL];
}

-(void)displayNewInterestReviewViewController
{
    
}

@end
