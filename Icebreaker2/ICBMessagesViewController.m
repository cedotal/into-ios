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
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillAppear:animated];
}

// UITableViewController methods
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)pfMessage
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"
                                                            forIndexPath:indexPath];
    cell.textLabel.text = [pfMessage objectForKey:@"content"];
    return cell;
}

@end
