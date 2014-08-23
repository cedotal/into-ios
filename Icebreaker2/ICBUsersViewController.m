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
#import "ICBInterest.h"
#import "ICBTabBarController.h"
#import <CoreLocation/CoreLocation.h>

@interface ICBUsersViewController()

@property (nonatomic) CLLocationManager *locationManager;

@property (nonatomic) CLLocation *currentLocation;

@property (nonatomic, strong) NSMutableArray *userIdsWithUnreadMessages;

// timer for periodically attempting to look for new nearby users and update their
// messaged state
@property (nonatomic, strong) NSTimer *fetchUsersTimer;

@end

@implementation ICBUsersViewController

-(instancetype)init
{
    self = [super init];
    if(self){
        // init array of user ids with unread messages
        self.userIdsWithUnreadMessages = [[NSMutableArray alloc] init];
        
        // attributes to handle getting data from Parse
        self.parseClassName = @"_User";
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
    
    // set up listeners for events pertaining to interests, since updating the
    // set of preferred interests may change the users that we match the current
    // user with
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadNewUsers)
                                                 name: @"nICBuserDidSetPreferenceOnInterest"
                                               object:nil];
    
    // set this controller up as the delegate for location events
    CLLocationManager *locationManager = [[CLLocationManager alloc] init];
    self.locationManager = locationManager;
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    // set a movement threshold for new events
    locationManager.distanceFilter = kCLLocationAccuracyHundredMeters;
    
    [locationManager startUpdatingLocation];
    
    // set the initial location
    CLLocation *currentLocation = locationManager.location;
    if(currentLocation){
        self.currentLocation = currentLocation;
    }
    
    // set up table update timer
    self.fetchUsersTimer = [NSTimer scheduledTimerWithTimeInterval:8
                                                               target:self
                                                             selector:@selector(loadNewUsers)
                                                             userInfo:nil
                                                              repeats:YES];

}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
    [self loadNewUsers];
}

-(void)loadNewUsers
{
    // do not continue generating network calls if this controller is not on top of
    // the stack
    if(![self.navigationController.visibleViewController isKindOfClass:[ICBTabBarController class]]){
        return;
    }
    
    // NOTE: the implementation of this method has a flaw. since it calls the most
    // recent N messages (parse default is 100) sent to the current user, if a user recieves more than
    // N messages in between sessions, some new message indicators will not show up.
    // fixing this will require reversing the order of the calls, which will require
    // breaking out of the PFTableQueryView class.
    
    // first, perform a query that will allow us to distinguish users with
    // unread messages to the current user
    // get all messages...
    PFQuery *query = [PFQuery queryWithClassName:@"Message"];
    // ...sent to the current user...
    [query whereKey:@"toUser" equalTo:[PFUser currentUser]];
    // ...that are currently unread...
    [query whereKey:@"readByRecipient" equalTo:@NO];
    // ..ordered by time created...
    [query orderByAscending:@"createdAt"];
    // we don't need anything in the payload except for the id of the sending user
    [query selectKeys:@[@"fromUser"]];
    [query includeKey:@"fromUser"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
         if(!error){
             // store result
             [self.userIdsWithUnreadMessages removeAllObjects];
             for(id object in objects){
                 PFUser *user = [object objectForKey:@"fromUser"];
                 if(![self.userIdsWithUnreadMessages containsObject:user.objectId]){
                     [self.userIdsWithUnreadMessages addObject:user.objectId];
                 }
             }
             // then get nearby users
             [self loadObjects];
         } else {
             // fail silently
         }
     }];
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
        PFQuery *emptyQuery = [PFQuery queryWithClassName:@"_User"];
        [emptyQuery whereKey:@"interests" containedIn:[[NSArray alloc] init]];
        [interestQueries addObject:emptyQuery];
        orQuery = [PFQuery orQueryWithSubqueries: [interestQueries copy]];
    }
    // the user shouldn't see themselves
    [orQuery whereKey:@"objectId" notEqualTo:[PFUser currentUser].objectId];
    // we need each user's full set of interest objects to display the cells properly
    [orQuery includeKey:@"interests"];
    
    // sort the results by their distance from the current user
    PFGeoPoint *point = [PFGeoPoint geoPointWithLatitude:self.currentLocation.coordinate.latitude
                                               longitude:self.currentLocation.coordinate.longitude];
    // include everyone on the goddamn planet
    [orQuery whereKey:@"location" nearGeoPoint:point withinKilometers:30000];
    
    return orQuery;
}

#pragma mark - UITableViewController methods
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
    unsigned long interestsToDisplay = MIN(4, [matchedUserInterests count]);
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
    
    // calculate and display distance
    PFGeoPoint *matchedUserLocation = [matchedUser objectForKey:@"location"];
    int distanceToMatchedUser = floor([matchedUserLocation distanceInMilesTo:[PFGeoPoint geoPointWithLocation:self.currentLocation]]);
    NSMutableString *distanceLabelText = [[NSMutableString alloc] init];;
    if (distanceToMatchedUser < 1){
        [distanceLabelText appendString:@"Within a mile"];
    } else {
        [distanceLabelText appendString:[NSString stringWithFormat:@"%d", distanceToMatchedUser]];
        [distanceLabelText appendString:@" miles"];
    }
    cell.distanceLabel.text = distanceLabelText;
    
    // determine if the nearby user has any unread messages waiting for the current user
    if([self.userIdsWithUnreadMessages containsObject:matchedUser.objectId]){
        UIColor *lightBlue = [UIColor colorWithRed:(200.0f/255.0f)
                                             green:(247.0f/255.0f)
                                              blue:(247.0f/255.0f)
                                             alpha:1.0f];
        cell.backgroundColor = lightBlue;
    } else {
        cell.backgroundColor = [UIColor whiteColor];
    }
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 165;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PFObject *matchedUser = [self objectAtIndexPath:indexPath];
    UINavigationController *navController = self.navigationController;
    ICBMessagesViewController *mvc = [[ICBMessagesViewController alloc] initWithUser:matchedUser];
    [navController pushViewController:mvc animated:YES];
}

#pragma mark - CLLocationManagerDelegate methods

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *mostRecentLocation = [locations lastObject];
    self.currentLocation = mostRecentLocation;
    PFGeoPoint *point = [PFGeoPoint geoPointWithLatitude:self.currentLocation.coordinate.latitude
                                               longitude:self.currentLocation.coordinate.longitude];
    PFUser *currentUser = [PFUser currentUser];
    [currentUser setObject:point
                    forKey:@"location"];
    [currentUser saveEventually];
    
    [self loadNewUsers];
}


@end
