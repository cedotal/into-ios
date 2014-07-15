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

@property (weak, nonatomic) IBOutlet UITextField *composeMessageField;

@end

@implementation ICBMessagesViewController

-(instancetype)init
{
    self = [super init];
    
    if (self){
        // attributes to handle getting data from Parse
        self.parseClassName = @"Message";
    }
    
    return self;
}

-(instancetype)initWithUser:(PFObject *) matchedUser
{
    self = [super init];
    
    if (self){
        _matchedUser = matchedUser;
    }
    
    return self;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    // register the nib, which contains a cell
    [self.tableView registerClass:[UITableViewCell class]
           forCellReuseIdentifier:@"UITableViewCell"];
    
    UIView *footerView = [self footerView];
    [self.tableView setTableFooterView:footerView];
}

-(UIView *)footerView
{
    if(!_footerView){
        NSArray *nibObjects = [[NSBundle mainBundle] loadNibNamed:@"ICBMessagesViewFooterView" owner:self options:nil];
        _footerView = [nibObjects firstObject];
    }
    return _footerView;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillAppear:animated];
}

// override the default no-op to get objects from Parse
-(PFQuery *)queryForTable
{
    PFQuery *messagesQuery = [PFQuery queryWithClassName:@"Message"];
    PFObject *fromUser = [PFUser currentUser];
    [messagesQuery whereKey:@"fromUser" equalTo: fromUser];
    PFObject *toUser = self.matchedUser;
    [messagesQuery whereKey:@"toUser" equalTo: toUser];
    return messagesQuery;
}

// UITableViewController methods
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)pfMessage
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"
                                                            forIndexPath:indexPath];
    cell.textLabel.text = [pfMessage objectForKey:@"content"];
    return cell;
}

- (IBAction)sendMessage:(id)sender {
    PFObject *message = [PFObject objectWithClassName:@"Message"];
    NSString *composedMessage = self.composeMessageField.text;
    [message setObject:composedMessage forKey:@"content"];
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
            // hit the server to get this message and any new messages
            [self loadObjects];
        }
    }];
}

@end
