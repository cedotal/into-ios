//
//  ICBMessagesViewController.h
//  Icebreaker2
//
//  Created by Andrew Cedotal on 7/13/14.
//  Copyright (c) 2014 Icebreaker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

@interface ICBMessagesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate>

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UIView *fixedTableFooterView;
@property (nonatomic, strong) PFObject *matchedUser;

-(instancetype)initWithUser:(PFObject *) matchedUser;

@end
