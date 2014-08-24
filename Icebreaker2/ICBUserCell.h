//
//  ICBUserCell.h
//  Icebreaker2
//
//  Created by Andrew Cedotal on 7/13/14.
//  Copyright (c) 2014 Icebreaker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

@interface ICBUserCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *interestLabel1;
@property (weak, nonatomic) IBOutlet UILabel *interestLabel2;
@property (weak, nonatomic) IBOutlet UILabel *interestLabel3;
@property (weak, nonatomic) IBOutlet UILabel *interestLabel4;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
@property (weak, nonatomic) IBOutlet PFImageView *profileImage;


@end
