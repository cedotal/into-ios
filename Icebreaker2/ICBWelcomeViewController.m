//
//  ICBWelcomeViewController.m
//  Icebreaker
//
//  Created by Andrew Cedotal on 6/29/14.
//  Copyright (c) 2014 Icebreaker. All rights reserved.
//

#import "ICBWelcomeViewController.h"
#import "ICBLoginViewController.h"
#import "ICBSignupViewController.h"

@interface ICBWelcomeViewController()

@property (nonatomic, weak) IBOutlet UIButton *loginButton;
@property (nonatomic, weak) IBOutlet UIButton *signupButton;

@end

@implementation ICBWelcomeViewController

-(IBAction)userSelectedLoginButton:(id)sender
{
    ICBLoginViewController *lvc = [[ICBLoginViewController alloc] init];
    [self.navigationController presentViewController:lvc animated:YES completion:^{}];
}

-(IBAction)userSelectedSignupButton:(id)sender
{
    ICBSignupViewController *svc = [[ICBSignupViewController alloc] init];
    [self.navigationController presentViewController:svc animated:YES completion:^{}];
}

@end
