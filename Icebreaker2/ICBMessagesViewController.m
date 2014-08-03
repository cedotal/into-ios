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

// pointers to important subviews
@property (nonatomic, strong) UITableView *messagesView;
@property (nonatomic, strong) UIView *sendMessageView;

@property (nonatomic, weak) IBOutlet UITextField *composeMessageField;

@property (nonatomic, strong) NSMutableArray *messages;

@property (nonatomic, strong) NSTimer *fetchMessagesTimer;

@end

@implementation ICBMessagesViewController

// margin of text labels in cells
const NSInteger cellMargin = 18;

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
    
    CGFloat textEditViewHeight = 75.0;
    
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
    // only need to scroll to bottom the first time we fetch messages
    static BOOL firstFetch = TRUE;
    
    PFQuery *query = [self queryForTable];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error){
            // update local data for messages
            self.messages = [NSMutableArray arrayWithArray:objects];
            // reload table
            [self.messagesView reloadData];
            if(firstFetch){
                [self scrollMessagesViewToBottom];
                firstFetch = !firstFetch;
            }
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
    // we need the sending user to properly display the message
    [messagesQuery includeKey:@"fromUser"];
    return messagesQuery;
}

#pragma mark - UITableView protocol

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"
                                                            forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    NSString *messageText = [self messageForIndexPath:indexPath];
    UILabel *labelView = [[UILabel alloc] initWithFrame:CGRectMake(cellMargin, cellMargin, (self.view.frame.size.width - (cellMargin*2)), MAXFLOAT)];
    // have to remove our subviews, since we may be reusing a previously-used cell
    [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [cell.contentView addSubview:labelView];
    labelView.numberOfLines = 0;
    labelView.text = messageText;
    labelView.lineBreakMode = NSLineBreakByCharWrapping;
    [labelView sizeToFit];
    labelView.frame = CGRectMake(labelView.frame.origin.x, cellMargin, labelView.frame.size.width, labelView.frame.size.height);
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellText = [self messageForIndexPath: indexPath];
    // use a dummy message view and sizeToFit to get the proper size
    UILabel *dummyMessageView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, (self.view.frame.size.width - (cellMargin*2)), self.view.frame.size.height)];
    dummyMessageView.numberOfLines = 0;
    dummyMessageView.text = cellText;
    dummyMessageView.lineBreakMode = NSLineBreakByCharWrapping;
    [dummyMessageView sizeToFit];
    CGFloat height = dummyMessageView.frame.size.height + (cellMargin*2);
    return height;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.messages count];
}

-(NSString *)messageForIndexPath:(NSIndexPath *)indexPath
{
    PFObject *message = self.messages[indexPath.row];
    NSMutableString *messageText = [[NSMutableString alloc] init];
    // add sending user
    PFObject *fromUser = [message objectForKey:@"fromUser"];
    NSString *fromUserUsername = [fromUser objectForKey:@"username"];
    [messageText appendString:fromUserUsername];
    // add separator
    [messageText appendString:@": "];
    // add message content
    [messageText appendString:[message objectForKey:@"content"]];
    return messageText;
}

#pragma mark - handling user input

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
            // scroll table to bottom to show inputted message
            [self scrollMessagesViewToBottom];
            // create supporting objects for push notification to send to messaged user
            NSMutableString *pushMessage = [[NSMutableString alloc] init];
            [pushMessage appendString:[fromUser objectForKey:@"username"]];
            [pushMessage appendString:@" has sent you a message!"];
            PFQuery *toUserQuery = [PFInstallation query];
            [toUserQuery whereKey:@"user" equalTo:toUser];
            NSString *fromUserObjectId = fromUser.objectId;
            NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:pushMessage, @"alert",
                                  @"Increment", @"badge",
                                  fromUserObjectId, @"u",
                                  nil];
            // send the push
            PFPush *push = [[PFPush alloc] init];
            [push setQuery:toUserQuery];
            [push setData:data];
            [push sendPushInBackground];
        }
    }];
}

#pragma mark - resizing views on keyboard appearance

- (void)keyboardWillShow:(NSNotification *)notification {
    // determine if user is scrolled to bottom
    NSArray *visiblePaths = [self.messagesView indexPathsForVisibleRows];
    NSIndexPath *lastIndex = [visiblePaths lastObject];
    BOOL messagesViewIsScrolledToBottom = (lastIndex.row == ([self.messages count] - 1));
    
    // (since we changed the frame)
    // handle necessary animations to accomodate keyboard on screen
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
    
    // if necessary, scroll messageView to bottom now that animations are done
    if(messagesViewIsScrolledToBottom){
        [self scrollMessagesViewToBottom];
    }
}

-(void)scrollMessagesViewToBottom
{
    // handle the case where we have no messages, since we can't tell the table to scroll
    // to a negatively-indexed cell
    long targetRow = ([self.messages count] - 1);
    if (targetRow > 0){
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:targetRow
                                                    inSection:0];
        [self.messagesView scrollToRowAtIndexPath:indexPath
                                 atScrollPosition:UITableViewScrollPositionBottom
                                         animated:YES];
    }
}

@end
