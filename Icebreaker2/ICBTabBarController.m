//
//  ICBTabBarController
//  Icebreaker
//
//  Created by Andrew Cedotal on 7/6/14.
//  Copyright (c) 2014 Icebreaker. All rights reserved.
//

#import "ICBTabBarController.h"
#import "ICBUsersViewController.h"
#import "ICBInterestsViewController.h"
#import "ICBInterestStore.h"
#import "ICBInterestReviewViewController.h"

@interface ICBTabBarController()

@property (nonatomic) ICBInterestsViewController *interestsViewController;

@property (nonatomic) NSMutableArray *presentedInterestReviewViewControllers;

// if an interest review view is chained, it's delegate knows to continue presenting
// more interest review view controllers on itself until the user has the minimum
// viable number of interests
// if it has successors, it will continue presenting interest review view controllers
// up to a minimum number as long as interests are available
-(void)presentInterestReviewViewControllerChainedUntilMinimumInterestsMet:(BOOL)isChained
                                                           withSuccessors:(long)successors;

@end

@implementation ICBTabBarController

-(instancetype)init{
    self = [super init];
    if (self){
        // set up tabbed views and their controllers
        ICBUsersViewController *uvc = [[ICBUsersViewController alloc] init];
        ICBInterestsViewController *ivc = [[ICBInterestsViewController alloc] init];
        self.interestsViewController = ivc;
        self.viewControllers = @[uvc, ivc];
        
        // set up item icons
        uvc.tabBarItem.title = @"Matches";
        UIImage *uvcImage = [[UIImage imageNamed:@"matches.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        uvc.tabBarItem.image = uvcImage;
        
        ivc.tabBarItem.title = @"Interests";
        UIImage *ivcImage = [[UIImage imageNamed:@"interests.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        ivc.tabBarItem.image = ivcImage;


    }
    return self;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    // init array of presented interest review view controllers
    self.presentedInterestReviewViewControllers = [[NSMutableArray alloc] init];
    
    if(![[ICBInterestStore sharedStore] userHasMinimumPreferredInterests]){
        [self presentInterestReviewViewControllerChainedUntilMinimumInterestsMet:true
                                                                   withSuccessors:0];
    }
}

#pragma mark Presenting and handling Interest Review modals

// the public version of the "present an interest review view controller" method
// hides the off-by-one complexity of tracking successors
-(void)presentInterestReviewViewControllerChainedUntilMinimumInterestMet:(BOOL)isChained
                                     withMinimumViewControllersPresented:(long)minimumViewControllers
{
    long successors = minimumViewControllers = (0 ? 0 : minimumViewControllers - 1);
    [self presentInterestReviewViewControllerChainedUntilMinimumInterestsMet:isChained
                                                              withSuccessors:successors];
}

// the private version of the "present an interest review view controller" method
// passes in the proper number of successors
-(void)presentInterestReviewViewControllerChainedUntilMinimumInterestsMet:(BOOL)isChained
                                                           withSuccessors:(long)successors
{
    // in getting our interest, we need to make sure that we're not using an interest
    // that already has an interest review view controller presented for it
    NSMutableArray *presentedInterests = [[NSMutableArray alloc] init];
    for (int i = 0; i < [self.presentedInterestReviewViewControllers count]; i++){
        ICBInterestReviewViewController *irvc = self.presentedInterestReviewViewControllers[i];
        ICBInterest *presentedInterest = irvc.interest;
        [presentedInterests addObject:presentedInterest];
    }
    
    // WARNING: this while will loop infinitely in the unlikely case where
    // the number of total interests available locally is lower than the permitted
    // number of interests
    ICBInterest *interest;
    while(interest == nil){
        ICBInterest *randomInterest = [[ICBInterestStore sharedStore] retrieveRandomUnreviewedInterest];
        if([presentedInterests indexOfObject:randomInterest] == NSNotFound){
            interest = randomInterest;
        }
    }
    
    if (interest != nil && ![[ICBInterestStore sharedStore] userHasMaximumPreferredInterests]){
        // create two interest review view controllers
        ICBInterestReviewViewController *irvc = [[ICBInterestReviewViewController alloc] initWithInterest:interest];
        irvc.delegate = self;
        
        // set the attributes that will allow this controller to determine if it needs
        // to create a successor
        irvc.chained = isChained;
        irvc.successors = successors;
        
        // put them in a property of this controller so we don't lose
        // reference to them
        [self.presentedInterestReviewViewControllers addObject:irvc];

        
        int screenWidth = self.view.frame.size.width;
        
        irvc.view.transform = CGAffineTransformMakeTranslation(screenWidth, 0.0);
        
        // always insert directly above the self's view, so we can "slide" new
        // interest review views under the topmost one without the user
        // noticing
        [self.view insertSubview:irvc.view aboveSubview:self.view];
        
        [UIView animateWithDuration:0.6
                         animations:^{
                             irvc.view.transform = CGAffineTransformIdentity;
                         }
                         completion:^(BOOL finished) {
                             [[NSNotificationCenter defaultCenter] postNotificationName:@"nICBinterestReviewViewAnimationDidFinish"
                                                                                 object:nil];
                         }];
    }
}

-(void)dismissInterestReviewViewController:(ICBInterestReviewViewController *)outgoingController
{
    // if the outgoing controller is chained or if it has successors, we need to conditionally (based on whether the user has the minimum number of interests) insert a
    // view controller under it so it appears to the user like the newly-uncovered view was there all along
    
    // however, if there is only one unreviewed interest left in the interest store
    BOOL needToChain = outgoingController.chained && ![[ICBInterestStore sharedStore] userHasMinimumPreferredInterests];
    BOOL hasSuccessors = outgoingController.successors > 0;
    if(needToChain || hasSuccessors){
        [self presentInterestReviewViewControllerChainedUntilMinimumInterestsMet:outgoingController.chained
                                                                  withSuccessors:(outgoingController.successors -1)];
    }
    
    // animate the view out
    int negativeWidth = -1*self.view.frame.size.width;
    
    [UIView animateWithDuration:0.6
        animations:^{
            outgoingController.view.transform = CGAffineTransformMakeTranslation(negativeWidth, 0.0);
    }];
    
    // remove the view from our array, which will cause it to be dealloc'd
    long indexOfPresentedViewToRemove = [self.presentedInterestReviewViewControllers indexOfObject:outgoingController];
    [self.presentedInterestReviewViewControllers removeObjectAtIndex:indexOfPresentedViewToRemove];
}

@end
