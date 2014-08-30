//
//  ICBProfileView.h
//  Icebreaker2
//
//  Created by Andrew Cedotal on 8/27/14.
//  Copyright (c) 2014 Icebreaker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

@interface ICBOtherUserProfileView : UIView

-(instancetype)initWithFrame:(CGRect)frame
                     andUser:(PFObject *)user;

-(void)updateSubviews;
-(void)resizeSubviews;

@end
