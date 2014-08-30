//
//  ICBMessagesViewController.m
//  Icebreaker2
//
//  Created by Andrew Cedotal on 7/13/14.
//  Copyright (c) 2014 Icebreaker. All rights reserved.
//

#import "ICBMessagesViewController.h"
#import "UIView+MWKeyboardAnimation.h"
#import "ICBOtherUserProfileView.h"

@interface ICBMessagesViewController()

// pointers to important subviews
@property (nonatomic, strong) ICBOtherUserProfileView *introductionView;
@property (nonatomic, strong) UITableView *messagesView;
@property (nonatomic, strong) UIView *sendMessageView;
@property (nonatomic, weak) IBOutlet UITextView *composeMessageView;
@property (weak, nonatomic) IBOutlet UIButton *sendMessageButton;

// store messages on the controller
@property (nonatomic, strong) NSMutableArray *messages;

// timer for periodically attempting to fetch new messages
@property (nonatomic, strong) NSTimer *fetchMessagesTimer;

@end

@implementation ICBMessagesViewController

#pragma mark - layout constants

const NSInteger cellMargin = 18;
const NSInteger textEditViewHeight = 44.0;

# pragma mark - initialization methods

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
        self.fetchMessagesTimer = [NSTimer scheduledTimerWithTimeInterval:2
                                                                   target:self
                                                                 selector:@selector(fetchMessages)
                                                                 userInfo:nil
                                                                  repeats:YES];
    }
    
    return self;
}

# pragma mark - methods for setting up the controller's views

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    // in order to have all content scroll up when the keyboard appears, we
    // need to set up the following hierarchy of views:
    // * the controller's normal view, which has as subviews
    // ** a messagesView for the messages, and
    // ** a textEditView for the text editing textField and button
    
    // initialize the messages table view
    CGRect messagesViewFrame = CGRectMake(CGRectGetMinX(self.view.bounds), CGRectGetMinY(self.view.bounds), CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - textEditViewHeight);
    self.messagesView = [[UITableView alloc] initWithFrame:messagesViewFrame
                                                     style:UITableViewStylePlain];
    
    [self.messagesView setDataSource:self];
    [self.messagesView setDelegate:self];
    
    // register the nib, which contains a cell
    [self.messagesView registerClass:[UITableViewCell class]
              forCellReuseIdentifier:@"UITableViewCell"];

    [self.view addSubview:self.messagesView];
    
    // Initialize the sendMessageView
    CGRect sendMessageViewFrame = CGRectMake(CGRectGetMinX(self.view.bounds), self.view.frame.size.height - textEditViewHeight, CGRectGetWidth(self.view.bounds), textEditViewHeight);
    NSArray *nibObjects = [[NSBundle mainBundle] loadNibNamed:@"ICBMessagesViewSendMessageView" owner:self options:nil];
    self.sendMessageView = [nibObjects firstObject];
    self.sendMessageView.frame = sendMessageViewFrame;
    self.composeMessageView.delegate = self;
    [self.view addSubview:self.sendMessageView];
    
    // set up notifications for keyboard events
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    self.navigationItem.title = [self.matchedUser objectForKey:@"username"];
    
    // get messages for the first time
    [self fetchMessagesWithFirstTimeBehavior:YES];
}

-(void)fetchMessages
{
    // do not continue generating network calls if this controller is not on top of
    // the stack
    if(self.navigationController.visibleViewController == self){
        [self fetchMessagesWithFirstTimeBehavior:NO];
    }
}

-(void)fetchMessagesWithFirstTimeBehavior:(BOOL)firstTime
{
    PFQuery *query = [self queryForTable];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error){
            NSMutableDictionary *paramDict = [[NSMutableDictionary alloc] init];
            [paramDict setObject:self.matchedUser.objectId
                          forKey:@"fromUser"];
            [paramDict setObject:[PFUser currentUser].objectId
                          forKey:@"toUser"];
            [PFCloud callFunctionInBackground:@"setReadReceipts"
                               withParameters:[paramDict copy]
                                        block:^(id object, NSError *error) {
                                            if(!error){
                                                // update local data for messages
                                                // custom setter method will handle the rest
                                                self.messages = [NSMutableArray arrayWithArray:objects];
                                                
                                                if([self.messages count] > 0){
                                                    [self.introductionView removeFromSuperview];
                                                    [self addUserProfileButton];
                                                    
                                                } else if (![self.view.subviews containsObject:self.introductionView]){
                                                    self.introductionView = self.createIntroductionView;
                                                    [self.view addSubview:self.introductionView];
                                                    [self removeUserProfileButton];
                                                }
                                                [self.tableView reloadData];
                                                
                                                // if it's the first time we put messages into the view, scroll down to
                                                // bottom (most recent) message
                                                if(firstTime){
                                                    [self scrollMessagesViewToBottom];
                                                }
                                            } else {
                                                // if error and we're doing this for the first time, kick back to previous view
                                                if(firstTime){
                                                    [self returnUserToPreviousViewController];
                                                }
                                                // else fail silently
                                            }
                                        }];
        } else {
            // if error and we're doing this for the first time, kick back to previous view
            if(firstTime){
                [self returnUserToPreviousViewController];
            }
            // else fail silently
        }
    }];
}
                                               
-(void)returnUserToPreviousViewController
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"You're not online!" message:@"You need to be online to send messages." delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
    [alertView show];
    [self.navigationController popViewControllerAnimated:YES];
}
                                               

- (void)viewWillAppear:(BOOL)animated
{
    // set border styling on compose message view so it resembles a UITextField
    self.composeMessageView.layer.borderColor = [[UIColor grayColor] CGColor];
    self.composeMessageView.layer.borderWidth = 0.7f;
    self.composeMessageView.layer.cornerRadius = 5.0f;

    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self.navigationController navigationItem].title = [self.matchedUser objectForKey:@"username"];
    
    // set up user profile button
    [self addUserProfileButton];
    [super viewWillAppear:animated];
}

-(void)addUserProfileButton
{
    if(self.navigationItem.rightBarButtonItem == nil){
        if([self.matchedUser objectForKey:@"profileImage1"]){
            PFImageView *buttonView = [[PFImageView alloc] init];
            int buttonMargin = 5;
            buttonView.frame = CGRectMake(buttonMargin, buttonMargin, (self.navigationController.toolbar.frame.size.height - buttonMargin*2), (self.navigationController.toolbar.frame.size.height - buttonMargin*2));
            buttonView.file = [self.matchedUser objectForKey:@"profileImage1"];
            UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                  action:@selector(userTappedProfileButton)];
            [buttonView addGestureRecognizer:tgr];
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:buttonView];
            [buttonView loadInBackground];
        } else {
            UIBarButtonItem *bi = [[UIBarButtonItem alloc] initWithTitle:@"Profile"
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(userTappedProfileButton)];
            self.navigationItem.rightBarButtonItem = bi;
        }
    }

}

-(void)removeUserProfileButton
{
    self.navigationItem.rightBarButtonItem = nil;
}

#pragma mark - methods for rendering the introduction view and messages view

-(CGRect)createIntroductionViewFrame
{
    CGRect introductionViewFrame = CGRectMake(CGRectGetMinX(self.view.bounds), CGRectGetMinY(self.view.bounds) + self.navigationController.toolbar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - textEditViewHeight - self.navigationController.toolbar.frame.size.height - [UIApplication sharedApplication].statusBarFrame.size.height);
    return introductionViewFrame;
}

-(ICBOtherUserProfileView *)createIntroductionView
{
    CGRect introductionViewFrame = [self createIntroductionViewFrame];
    ICBOtherUserProfileView *introductionView = [[ICBOtherUserProfileView alloc] initWithFrame:introductionViewFrame
                                                                                       andUser:self.matchedUser];
    
    return introductionView;
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
    // sending empty strings is disallowed
    NSString *content = self.composeMessageView.text;
    if ([content isEqualToString: @""]){
        return;
    }
    
    // disable UI while we attempt to send, to prevent multiple sendings
    [self disableSendMessageElements];
    
    // construct message object
    PFObject *message = [PFObject objectWithClassName:@"Message"];
    [message setObject:content forKey:@"content"];
    PFObject *fromUser = [PFUser currentUser];
    [message setObject:fromUser forKey:@"fromUser"];
    PFObject *toUser = self.matchedUser;
    [message setObject:toUser forKey:@"toUser"];
    [message saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if(error){
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"You're not online!" message:@"You need to be online to send messages." delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
            [alertView show];
            [self enableSendMessageElements];
        } else {
            // wipe the contents of the text field
            self.composeMessageView.text = @"";
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
            [self enableSendMessageElements];
        }
    }];
}

// functions to prevent tapping the add new interests button multiple times before
// the views animate in
-(void)disableSendMessageElements
{
    self.sendMessageButton.enabled = NO;

}

-(void)enableSendMessageElements
{
    self.sendMessageButton.enabled = YES;
}

// on editing in text view, change heights of application views
-(void)textViewDidChange:(UITextView *)textView
{
    // first, change the compose message view to fit its content
    
     // because iOS7's text view calculates content size lazily, we need to force this
     // calculation ourselves

    // note: the below method is brittle and obtuse. it works well enough on iOS7 to allow a two-line, scrollable editing field.
    
    [self.composeMessageView.layoutManager ensureLayoutForTextContainer:self.composeMessageView.textContainer];
    CGRect containerRect = [self.composeMessageView.layoutManager usedRectForTextContainer:self.composeMessageView.textContainer];
    
    // take insets into consideration
    float composeMessageViewHeight = ceilf(containerRect.size.height + textView.textContainerInset.top + textView.textContainerInset.bottom);
    
    // set the frame of the compose message view
    self.composeMessageView.frame = CGRectMake(self.composeMessageView.frame.origin.x, self.composeMessageView.frame.origin.y, self.composeMessageView.contentSize.width, composeMessageViewHeight);
    
    [self.composeMessageView sizeToFit];
    [self.composeMessageView layoutIfNeeded];
     
    // then, change the send message view to fit the compose message view
    CGFloat sendMessageViewY = self.view.frame.size.height - self.composeMessageView.frame.size.height - 14;
    CGFloat sendMessageViewWidth = self.sendMessageView.frame.size.width;
    CGFloat sendMessageViewHeight = self.composeMessageView.frame.size.height + 14;
    self.sendMessageView.frame = CGRectMake(self.sendMessageView.frame.origin.x, sendMessageViewY, sendMessageViewWidth, sendMessageViewHeight);
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
        
        // if introduction view is visible, resize it
        if(self.introductionView){
            self.introductionView.frame = newMessagesViewFrame;
            [self.introductionView resizeSubviews];
        }
        
        // move the sendMessagesView to immediately below the new messagesView
        int newSendMessageViewY = newMessagesViewHeight;
        CGRect newSendMessageViewFrame = CGRectMake(sendMessageViewX, newSendMessageViewY, sendMessageViewWidth, sendMessageViewHeight);
        self.sendMessageView.frame = newSendMessageViewFrame;
        
        // resize the main view, since we can't use any of the space under the keyboard
        CGFloat newControllerViewHeight = controllerViewHeight - keyboardHeight;
        self.view.frame = CGRectMake(controllerViewX, controllerViewY, controllerViewWidth, newControllerViewHeight);
    }];
    
    // if necessary, scroll messageView to bottom now that animations are done
    if(messagesViewIsScrolledToBottom){
        [self scrollMessagesViewToBottom];
    }
}

-(void)scrollMessagesViewToBottom
{
    [self.messagesView reloadData];
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

# pragma mark - methods for opening the profile view

-(void)userTappedProfileButton
{
    ICBOtherUserProfileView *oupv = [[ICBOtherUserProfileView alloc] initWithFrame:[self createIntroductionViewFrame]
                                                                           andUser:self.matchedUser];
    UIViewController *oupvController = [[UIViewController alloc] init];
    [oupvController.view addSubview:oupv];
    CGRect dummy = oupvController.view.frame;
    [self.navigationController pushViewController:oupvController
                                         animated:YES];
    // oupvController.view.frame = frame;
    dummy = oupvController.view.frame;
}


# pragma mark - methods for tearing down the controller

- (void)viewDidUnload {
    [super viewDidUnload];
    self.fetchMessagesTimer = nil;
}


@end
