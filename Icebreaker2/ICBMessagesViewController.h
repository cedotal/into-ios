//
//  ICBMessagesViewController.h
//  Icebreaker2
//
//  Created by Andrew Cedotal on 7/13/14.
//  Copyright (c) 2014 Icebreaker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

@interface ICBMessagesViewController : PFQueryTableViewController

-(instancetype)initWithUser:(PFObject *) matchedUser;

@end
