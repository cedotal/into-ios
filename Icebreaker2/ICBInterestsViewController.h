//
//  ICBInterestsViewController.h
//  Icebreaker
//
//  Created by Andrew Cedotal on 6/30/14.
//  Copyright (c) 2014 Icebreaker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ICBInterest.h"

@interface ICBInterestsViewController : UITableViewController

-(void)addRowForInterest:(ICBInterest *)interest;

@end
