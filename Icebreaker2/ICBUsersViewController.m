//
//  ICBUsersViewController
//  Icebreaker
//
//  Created by Andrew Cedotal on 7/6/14.
//  Copyright (c) 2014 Icebreaker. All rights reserved.
//

#import "ICBUsersViewController.h"
#import "ICBInterestStore.h"

@implementation ICBUsersViewController

-(instancetype)init
{
    self = [super init];
    if(self){
        // attributes to handle getting data from Parse
        self.parseClassName = @"_User";
        
        // UI setup
        self.tabBarItem.title = @"Matches";
    }
    return self;
}

// override the default no-op to get objects from Parse
-(PFQuery *)queryForTable
{
    NSArray *interests = [[ICBInterestStore sharedStore] allPreferredInterests];
    NSMutableArray *interestQueries = [[NSMutableArray alloc] init];
    for (ICBInterest *interest in interests){
        PFQuery *query = [PFQuery queryWithClassName: @"_User"];
        [query whereKey: @"interests" equalTo: interest.pfObject];
        [interestQueries addObject: query];
    }
    PFQuery *orQuery;
    // creating an or query with an empty array crashes PFQueryTableViewController
    if([interestQueries count] > 0){
        orQuery = [PFQuery orQueryWithSubqueries: [interestQueries copy]];
    } else {
        // if you don't have any interests, you can't have any matches
        orQuery = [PFQuery queryWithClassName:@"_User"];
        [orQuery whereKeyExists: @"dummy"];
    }
    // the user shouldn't see themselves
    [orQuery whereKey:@"objectId" notEqualTo:[PFUser currentUser].objectId];
    return orQuery;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object
{
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    cell.textLabel.text = [object objectForKey:@"username"];
    return cell;
}

@end
