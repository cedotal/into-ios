//
//  ICBAppDelegate.m
//  Icebreaker
//
//  Created by Andrew Cedotal on 6/29/14.
//  Copyright (c) 2014 Icebreaker. All rights reserved.
//

#import "ICBAppDelegate.h"
#import "ICBWelcomeViewController.h"
#import "ICBMessagesViewController.h"
#import "ICBConnectingViewController.h"
#import <Parse/Parse.h>

@implementation ICBAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    // ****************************************************************************
    // Parse initialization
	[Parse setApplicationId:@"ZdJHjFNeFFfzj8DTzLl03wYGilzJ3coAPx9Ce6zn"
                  clientKey:@"Q2BIZMavY1iI1gZQHd4KYTJtZ1GFUNFm1A2YcRFS"];
	// ****************************************************************************
    // Parse analytics
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    // register for push notifications
    [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
    
    UIViewController *welcomeController = [[ICBWelcomeViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:welcomeController];
    navController.navigationBarHidden = YES;
    self.window.rootViewController = navController;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    // automatically log the user in if we have access to a valid PFUser object
    if([PFUser currentUser]){
        // push a connecting view controller onto the stack
        ICBConnectingViewController *cvc = [[ICBConnectingViewController alloc] init];
        [navController pushViewController:cvc
                                 animated:NO];
    }
    
    return YES;
}

-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    // store the device token in the current parse installation
    PFInstallation *installation = [PFInstallation currentInstallation];
    [installation setDeviceTokenFromData:deviceToken];
    installation.channels = @[@"global"];
    [installation saveInBackground];
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    // figure out if the user is not currently looking at the messagesView for the
    // sending user. if they are, there's no point in showing a notification, since
    // they're going to see the message anyway
    UINavigationController *navController = (UINavigationController *)self.window.rootViewController;
    UIViewController *topController = navController.topViewController;
    BOOL userIsLookingAtMessagesView = [topController isKindOfClass:[ICBMessagesViewController class]];
    if(!userIsLookingAtMessagesView){
        [self resetNotificationBadges];

    } else {
        // figure out if they're looking at the messages view of the user who
        // sent the message
        ICBMessagesViewController *messagesViewControllerCast = (ICBMessagesViewController *)topController;
        PFObject *userWhoseMessagesAreBeingViewed = messagesViewControllerCast.matchedUser;
        NSString *objectIdOfUserWhoseMessagesAreBeingViewed = userWhoseMessagesAreBeingViewed.objectId;
        NSString *objectIdOfUserWhoSentMessage = [userInfo objectForKey:@"u"];
        // check if the messages view we're looking at is actually that of a
        // different user
        if (![objectIdOfUserWhoseMessagesAreBeingViewed isEqualToString: objectIdOfUserWhoSentMessage]){
            [self resetNotificationBadges];
        }
    }
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    // reset badges to 0
    [self resetNotificationBadges];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

-(void)resetNotificationBadges
{
    PFInstallation *installation = [PFInstallation currentInstallation];
    if(installation.badge != 0){
        installation.badge = 0;
        [installation saveEventually];
    }
}

@end
