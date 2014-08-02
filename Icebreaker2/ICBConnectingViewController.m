//
//  ICBConnectingViewController.m
//  Icebreaker
//
//  Created by Andrew Cedotal on 7/5/14.
//  Copyright (c) 2014 Icebreaker. All rights reserved.
//

#import "ICBConnectingViewController.h"
#import "ICBInterestStore.h"
#import "ICBTabBarController.h"
#import <Parse/Parse.h>

@interface ICBConnectingViewController()

-(void)fetchInterestsDidSucceedWithNotification:(NSNotification *)notification;
-(void)fetchInterestsDidFailWithNotification:(NSNotification *)notification;

@end

@implementation ICBConnectingViewController

-(void)viewDidLoad
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:NSSelectorFromString(@"fetchInterestsDidSucceedWithNotification:")
                                                 name:@"nICBfetchInterestsDidSucceed"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:NSSelectorFromString(@"fetchInterestsDidFailWithNotification:")
                                                 name:@"nICBfetchInterestsDidFail"
                                               object:nil];
    [[ICBInterestStore sharedStore] fetchInterests];
}

-(void)fetchInterestsDidSucceedWithNotification:(NSNotification *)notification
{
    // if we successfully connected, associate this logged-in user with the
    // current Parse installation
    [[PFInstallation currentInstallation] setObject:[PFUser currentUser] forKey:@"user"];
    [[PFInstallation currentInstallation] saveEventually];
    // push the core application view controller
    ICBTabBarController *tbc = [[ICBTabBarController alloc] init];
    [self.navigationController pushViewController:tbc
                                         animated:YES];
}

-(void)fetchInterestsDidFailWithNotification:(NSNotification *)notification
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
