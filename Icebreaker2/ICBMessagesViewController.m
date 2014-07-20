//
//  ICBMessagesViewController.m
//  Icebreaker2
//
//  Created by Andrew Cedotal on 7/13/14.
//  Copyright (c) 2014 Icebreaker. All rights reserved.
//

#import "ICBMessagesViewController.h"
#import "UIView+MWKeyboardAnimation.h"


@interface ICBMessagesViewController()

@property (nonatomic, strong) PFObject *matchedUser;

// pointers to important subviews
@property (nonatomic, strong) UITableView *messagesView;
@property (nonatomic, strong) UIView *sendMessageView;

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
    
    // in order to have all content scroll up when the keyboard appears, we
    // need to set up the following hierarchy of views:
    // * the controller's normal view, which has as subviews
    // ** a messagesView for the messages, and
    // ** a textEditView for the text editing textField and button
    
    // have to set frame manually or subview won't know to capture and pass
    // on touch events
    
    CGFloat textEditViewHeight = 80.0;
    
    // Initialize the UITableView
    CGRect messagesViewFrame = CGRectMake(CGRectGetMinX(self.view.bounds), CGRectGetMinY(self.view.bounds), CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - textEditViewHeight);
    self.messagesView = [[UITableView alloc] initWithFrame:messagesViewFrame style:UITableViewStylePlain];
    [self.messagesView setDataSource:self];
    [self.messagesView setDelegate:self];
    
    // register the nib, which contains a cell
    [self.messagesView registerClass:[UITableViewCell class]
           forCellReuseIdentifier:@"UITableViewCell"];
    
    [self.view addSubview:self.messagesView];
    
    // Initialize the sendMessageView
    CGRect sendMessageViewFrame = CGRectMake(CGRectGetMinX(self.view.bounds), CGRectGetMaxY(self.view.bounds) - textEditViewHeight, CGRectGetWidth(self.view.bounds), textEditViewHeight);
    self.sendMessageView = [self createSendMessageView];
    self.sendMessageView.frame = sendMessageViewFrame;
    [self.view addSubview:self.sendMessageView];
    
    // set up notifications for keyboard events
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    // get messages for the first time
    [self fetchMessages];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    self.fetchMessagesTimer = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self.navigationController navigationItem].title = [self.matchedUser objectForKey:@"username"];
    [super viewWillAppear:animated];
}

-(UIView *)createSendMessageView
{
    if(!_sendMessageView){
        NSArray *nibObjects = [[NSBundle mainBundle] loadNibNamed:@"ICBMessagesViewSendMessageView" owner:self options:nil];
        _sendMessageView = [nibObjects firstObject];
    }
    return _sendMessageView;
}

-(void)fetchMessages
{
    PFQuery *query = [self queryForTable];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error){
            // update local data for messages
            self.messages = [NSMutableArray arrayWithArray:objects];
            // reload table
            [self.messagesView reloadData];
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
    [messagesQuery orderByAscending:@"createdAt"];
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
            [self.messagesView reloadData];
        }
    }];
}


- (void)keyboardWillShow:(NSNotification *)notification {
    [UIView animateWithKeyboardNotification:notification animations:^(CGRect keyboardFrame) {
        // current keyboard attributes
        int keyboardHeight = CGRectGetHeight(keyboardFrame);
        
        // current controller.view attributes
        CGRect controllerViewFrame = self.view.frame;
        int controllerViewX = controllerViewFrame.origin.x;
        int controllerViewY = controllerViewFrame.origin.y;
        int controllerViewWidth = controllerViewFrame.size.width;
        int controllerViewHeight = controllerViewFrame.size.height;
        
        // current sendMessageView attributes
        CGRect sendMessageViewFrame = self.sendMessageView.frame;
        int sendMessageViewX = sendMessageViewFrame.origin.x;
        int sendMessageViewWidth = sendMessageViewFrame.size.width;
        int sendMessageViewHeight = sendMessageViewFrame.size.height;
        
        // resize the messagesView to allow the sendMessageView to show above
        // the keyboard
        int newMessagesViewHeight = controllerViewHeight - keyboardHeight - sendMessageViewHeight;
        CGRect newMessagesViewFrame = CGRectMake(controllerViewX, controllerViewY, controllerViewWidth, newMessagesViewHeight);
        self.messagesView.frame = newMessagesViewFrame;
        
        // move the sendMessagesView to immediately below the new messagesView
        int newSendMessageViewY = newMessagesViewHeight;
        CGRect newSendMessageViewFrame = CGRectMake(sendMessageViewX, newSendMessageViewY, sendMessageViewWidth, sendMessageViewHeight);
        self.sendMessageView.frame = newSendMessageViewFrame;
    }];
}

@end
