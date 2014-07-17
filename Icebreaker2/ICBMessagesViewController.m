//
//  ICBMessagesViewController.m
//  Icebreaker2
//
//  Created by Andrew Cedotal on 7/13/14.
//  Copyright (c) 2014 Icebreaker. All rights reserved.
//

#import "ICBMessagesViewController.h"

@interface ICBMessagesViewController()

@property (nonatomic, strong) PFObject *matchedUser;

@property (nonatomic, strong) UIView *footerView;

@property (nonatomic, weak) IBOutlet UITextField *composeMessageField;

@property (nonatomic, strong) NSMutableArray *messages;

@property (nonatomic, strong) NSTimer *fetchMessagesTimer;

@end

@implementation ICBMessagesViewController

-(instancetype)init{
    self = [super init];
    
    if (self){
        self.messages = [[NSMutableArray alloc] init];
    }
    
    return self;
}

-(instancetype)initWithUser:(PFObject *) matchedUser
{
    self = [super init];
    
    if (self){
        _matchedUser = matchedUser;
        self.fetchMessagesTimer = [NSTimer scheduledTimerWithTimeInterval:3
                                                                   target: self
                                                                 selector:@selector(fetchMessages)
                                                                 userInfo:nil
                                                                  repeats:YES];
    }
    
    return self;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    CGFloat fixedFooterHeight = 200.0;
    
    // Initialize the UITableView
    CGRect tableViewFrame = CGRectMake(CGRectGetMinX(self.view.bounds), CGRectGetMinY(self.view.bounds), CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - fixedFooterHeight);
    self.tableView = [[UITableView alloc] initWithFrame:tableViewFrame style:UITableViewStylePlain];
    [self.tableView setDataSource:self];
    [self.tableView setDelegate:self];
    
    // register the nib, which contains a cell
    [self.tableView registerClass:[UITableViewCell class]
           forCellReuseIdentifier:@"UITableViewCell"];
    
    [self.view addSubview:self.tableView];
    
    // Initialize your Footer
    CGRect footerFrame = CGRectMake(CGRectGetMinX(self.view.bounds), CGRectGetMaxY(self.view.bounds) - fixedFooterHeight, CGRectGetWidth(self.view.bounds), fixedFooterHeight);
    self.fixedTableFooterView = [self footerView];
    self.fixedTableFooterView.frame = footerFrame;
    [self.view addSubview:self.fixedTableFooterView];
    
    // get messages for the first time
    [self fetchMessages];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    [self setTableView:nil];
    [self setFixedTableFooterView:nil];
    self.fetchMessagesTimer = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self.navigationController navigationItem].title = [self.matchedUser objectForKey:@"username"];
    [super viewWillAppear:animated];
}

-(UIView *)footerView
{
    if(!_footerView){
        NSArray *nibObjects = [[NSBundle mainBundle] loadNibNamed:@"ICBMessagesViewFooterView" owner:self options:nil];
        _footerView = [nibObjects firstObject];
    }
    return _footerView;
}

-(void)fetchMessages
{
    PFQuery *query = [self queryForTable];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error){
            // update local data for messages
            self.messages = [NSMutableArray arrayWithArray:objects];
            // reload table
            [self.tableView reloadData];
        }
        // if error, do nothing
    }];
}

// query to get objects from Parse
-(PFQuery *)queryForTable
{
    // we need to get both the messages sent to the user and messages
    // sent from the user
    PFObject *fromUser = [PFUser currentUser];
    PFObject *toUser = self.matchedUser;
    PFQuery *fromUserMessagesQuery = [PFQuery queryWithClassName:@"Message"];
    [fromUserMessagesQuery whereKey:@"fromUser" equalTo: fromUser];
    [fromUserMessagesQuery whereKey:@"toUser" equalTo: toUser];
    PFQuery *toUserMessagesQuery = [PFQuery queryWithClassName:@"Message"];
    [toUserMessagesQuery whereKey:@"toUser" equalTo: fromUser];
    [toUserMessagesQuery whereKey:@"fromUser" equalTo: toUser];
    NSMutableArray *subQueries = [[NSMutableArray alloc] init];
    [subQueries addObject:fromUserMessagesQuery];
    [subQueries addObject:toUserMessagesQuery];
    PFQuery *messagesQuery = [PFQuery orQueryWithSubqueries:[subQueries copy]];
    // need them ordered
    [messagesQuery orderByDescending:@"createdAt"];
    // cap number returned
    messagesQuery.limit = 100;
    return messagesQuery;
}

// UITableViewDelegate methods
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"
                                                            forIndexPath:indexPath];
    PFObject *message = self.messages[indexPath.row];
    cell.textLabel.text = [message objectForKey:@"content"];
    return cell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.messages count];
}

-(IBAction)sendMessage:(id)sender {
    PFObject *message = [PFObject objectWithClassName:@"Message"];
    NSString *content = self.composeMessageField.text;
    [message setObject:content forKey:@"content"];
    PFObject *fromUser = [PFUser currentUser];
    [message setObject:fromUser forKey:@"fromUser"];
    PFObject *toUser = self.matchedUser;
    [message setObject:toUser forKey:@"toUser"];
    [message saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if(error){
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"You're not online!" message:@"You need to be online to send messages." delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
            [alertView show];
        } else {
            // wipe the contents of the text field
            self.composeMessageField.text = @"";
            // add to messages property
            [self.messages addObject:message];
            // re-render table
            [self.tableView reloadData];
        }
    }];
}

@end
