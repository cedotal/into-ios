//
//  ICBInterestsViewController.m
//  Icebreaker
//
//  Created by Andrew Cedotal on 6/30/14.
//  Copyright (c) 2014 Icebreaker. All rights reserved.
//

#import "ICBInterestsViewController.h"
#import "ICBInterestReviewViewController.h"
#import "ICBInterestStore.h"
#import "ICBTabBarController.h"

@interface ICBInterestsViewController()

@property (nonatomic, strong) IBOutlet UIView *headerView;

-(void)userDidAddInterestWithNotification:(NSNotification *) notification;

@end

@implementation ICBInterestsViewController

-(instancetype)init
{
    self = [super init];
    if(self){
        self.tabBarItem.title = @"Interests";
    }
    return self;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCell"];
    UIView *header = self.headerView;
    [self.tableView setTableHeaderView:header];
    
    // set up listeners for events pertaining to interests
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userDidAddInterestWithNotification:)
                                                 name: @"nICBuserDidSetPreferenceOnInterest"
                                               object:nil];
}

#pragma mark UITableViewController protocol methods

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[ICBInterestStore sharedStore] allPreferredInterests] count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell" forIndexPath:indexPath];
    NSArray *preferredInterests = [[ICBInterestStore sharedStore] allPreferredInterests];
    ICBInterest *interest = preferredInterests[indexPath.row];
    cell.textLabel.text = interest.name;
    return cell;
}

-(UIView *)headerView
{
    // if you have not loaded the header view yet
    if(!_headerView){
        [[NSBundle mainBundle]loadNibNamed:@"ICBInterestsViewHeaderView" owner:self options:nil];
    }
    return _headerView;
}

#pragma mark handling button presses

-(IBAction)toggleEditingMode:(id)sender
{
    // if you are currently in editing mode
    if (self.isEditing){
        // change text of button to inform user of state
        [sender setTitle:@"Edit" forState:UIControlStateNormal];
        // turn off editing mode
        [self setEditing:NO animated:YES];
    } else {
        // change text of button to inform user of state
        [sender setTitle:@"Done" forState:UIControlStateNormal];
        // turn on editing mode
        [self setEditing:YES animated:YES];
    }
}

-(IBAction)addNewInterests:(id)sender
{
    NSMutableDictionary *optionsMutable = [NSMutableDictionary dictionaryWithCapacity:2];
    [optionsMutable setValue:@NO forKey:@"checkMinimumPreferredInterests"];
    [optionsMutable setValue:@NO forKey:@"chained"];
    NSDictionary *options = [optionsMutable copy];
    [(ICBTabBarController *)self.tabBarController presentThisManyInterestReviewViewControllers:4
                                           withOptions:options];
}

#pragma mark adding and removing table rows

-(void)userDidAddInterestWithNotification:(NSNotification *) notification
{
    [self addRowForInterest:[notification.userInfo objectForKey:@"interest"]];
}

-(void)addRowForInterest:(ICBInterest *)interest
{
    // it's possible that the user marked interest.preference as NO, in which
    // case we don't need to add a new row to the table
    if(interest.preference){
    // make a new index path for the 0th section, last row
        NSInteger lastRow = [[[ICBInterestStore sharedStore] allPreferredInterests]indexOfObject:interest];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:lastRow inSection:0];
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
    }
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *interests = [[ICBInterestStore sharedStore] allPreferredInterests];
    ICBInterest *interest = interests[indexPath.row];
    PFUser *user = [PFUser currentUser];
    [user removeObject:interest.pfObject forKey:@"interests"];
    [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if(!error){
            // make local change
            interest.preference = NO;
            // also remove that row from the table view with an animation
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:YES];
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"You're not online!" message:@"You need to be online to edit your interests. Don't worry, you'll see this interest again later." delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
            [alertView show];
        }
    }];
    
    
}

@end
