//
//  ICBUsersViewController
//  Icebreaker
//
//  Created by Andrew Cedotal on 7/6/14.
//  Copyright (c) 2014 Icebreaker. All rights reserved.
//

#import "ICBUsersViewController.h"
#import "ICBInterestStore.h"
#import "ICBUserCell.h"
#import "ICBMessagesViewController.h"

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

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    // load the nib file
    UINib *nib = [UINib nibWithNibName:@"ICBUserCell" bundle:nil];
    
    // register the nib, which contains a cell
    [self.tableView registerNib:nib forCellReuseIdentifier:@"ICBUserCell"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
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
        // this is a hack around a parse limitation
        orQuery = [PFQuery queryWithClassName:@"_User"];
        [orQuery whereKeyExists: @"dummy"];
    }
    // the user shouldn't see themselves
    [orQuery whereKey:@"objectId" notEqualTo:[PFUser currentUser].objectId];
    // we need each user's full set of interest objects to display the cells properly
    [orQuery includeKey:@"interests"];
    return orQuery;
}

// UITableViewController methods
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)matchedUser
{
    ICBUserCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ICBUserCell" forIndexPath:indexPath];
    // main label is the user's username
    cell.usernameLabel.text = [matchedUser objectForKey:@"username"];
    // sublabel lists the user's interests, prioritizing those that are in common with the current user
    NSMutableString *interestsString = [[NSMutableString alloc] init];
    [interestsString appendString:@"Into:"];
    NSMutableArray *matchedUserInterestsMutable = [NSMutableArray arrayWithArray:[matchedUser objectForKey:@"interests"]];
    // convert all parse objects to our objects
    [matchedUserInterestsMutable enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        matchedUserInterestsMutable[idx] = [[ICBInterest alloc] initWithPFObject:obj];
    }];
    NSArray *currentUserInterests = [[ICBInterestStore sharedStore] allPreferredInterests];
    // preferentially show the interests of each matched user that are also interests
    // of the current user
    NSArray *matchedUserInterests = [matchedUserInterestsMutable sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2){
        BOOL currentUserHasInterest1 = [currentUserInterests containsObject:obj1];
        BOOL currentUserHasInterest2 = [currentUserInterests containsObject:obj2];
        if (!currentUserHasInterest1 && currentUserHasInterest2){
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        };
    }];
    // only display as many interest labels as we have room for, and don't attempt to
    // access array indexes in matched user's interests that don't exist
    unsigned long interestsToDisplay = MIN(3, [matchedUserInterests count]);
    for (unsigned long i = 0; i < interestsToDisplay; i++){
        ICBInterest *interest = matchedUserInterests[i];
        // don't attempt array access if nothing is in the array
        if(interest){
            NSString *interestName = interest.name;
            // just construct the attribute of the label instead of implementing an
            // array of IBOutlets in the cell object
            NSMutableString *interestLabelString = [[NSMutableString alloc] init];
            [interestLabelString appendString:@"interestLabel"];
            // note that the IBLabel names are 1-indexed, not 0-indexed
            [interestLabelString appendString:[NSString stringWithFormat:@"%lu", (i + 1)]];
            UILabel *interestLabel = [cell valueForKey:interestLabelString];
            interestLabel.text = interestName;
        }
    }
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 102;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UINavigationController *navController = self.navigationController;
    ICBMessagesViewController *mvc = [[ICBMessagesViewController alloc] init];
    [navController pushViewController:mvc animated:YES];
}

@end
