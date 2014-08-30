//
//  ICBProfileView.m
//  Icebreaker2
//
//  Created by Andrew Cedotal on 8/27/14.
//  Copyright (c) 2014 Icebreaker. All rights reserved.
//

#import "ICBOtherUserProfileView.h"
#import <Parse/Parse.h>

@interface ICBOtherUserProfileView()

@property PFObject *user;

@property (nonatomic, strong) UILabel *interestsLabel;
@property (nonatomic, strong) PFImageView *profileImage;

@end

@implementation ICBOtherUserProfileView

-(instancetype)initWithFrame:(CGRect)frame
                     andUser:(PFObject *)user
{
    self = [super initWithFrame:frame];
    if(self){
        _user = user;
        [self updateSubviews];
        [self resizeSubviews];
    }
    return self;
}

-(void)updateSubviews
{
    self.backgroundColor = [UIColor whiteColor];
    // set up the label showing the user's username
    
    // set up the interest label
    self.interestsLabel = [[UILabel alloc] init];
    self.interestsLabel.numberOfLines = 0;
    self.interestsLabel.font = [self.interestsLabel.font fontWithSize:14];
    NSMutableString *hintString = [[NSMutableString alloc] init];
    [hintString appendString:@"They're into"];
    for(int i = 0; i < [[self.user objectForKey:@"interests"] count]; i++){
        PFObject *interest = [self.user objectForKey:@"interests"][i];
        if(i != [[self.user objectForKey:@"interests"] count] - 1){
            [hintString appendString:@" "];
            [hintString appendString:[interest objectForKey:@"name"]];
            [hintString appendString:@","];
        } else {
            [hintString appendString:@" and "];
            [hintString appendString:[interest objectForKey:@"name"]];
            [hintString appendString:@"."];
        }
        
    }
    self.interestsLabel.text = [hintString copy];
    
    // set up user's profile image
    self.profileImage = [[PFImageView alloc] init];
    if([self.user objectForKey:@"profileImage1"]){
        self.profileImage.file = [self.user objectForKey:@"profileImage1"];
        [self.profileImage loadInBackground];
    } else {
        self.profileImage.image = [UIImage imageNamed:@"noprofileimage"];
    }
}

-(void)resizeSubviews
{
    // position subviews
    int padding = 20;
    
    // we have two square, equally-sized elements, and we want to ensure that we use the maximum amount of the area of the frame to display them
    // we should orient the two squares along the longer axis of the frame to use the maximum area
    if(self.frame.size.height > self.frame.size.width){
        // calculate square edge from height, accounting for padding
        int squareEdge = (self.frame.size.height - 3*padding)/2;
        
        // position square 1
        int square1X = self.frame.size.width/2 - squareEdge/2;
        int square1Y = padding;
        CGRect square1Frame = CGRectMake(square1X, square1Y, squareEdge, squareEdge);
        
        // position square 2
        int square2X = self.frame.size.width/2 - squareEdge/2;
        int square2Y = squareEdge + 2*padding;
        CGRect square2Frame = CGRectMake(square2X, square2Y, squareEdge, squareEdge);

        // assign frames to views
        self.profileImage.frame = square1Frame;
        self.interestsLabel.frame = square2Frame;
    } else {
        // calculate square edge from height, accounting for padding
        int squareEdge = (self.frame.size.width - 3*padding)/2;
        
        // position square 1
        int square1X = padding;
        int square1Y = self.frame.size.height/2 - squareEdge/2;
        CGRect square1Frame = CGRectMake(square1X, square1Y, squareEdge, squareEdge);
        
        // position square 2
        int square2X = squareEdge + 2*padding;
        int square2Y = self.frame.size.height/2 - squareEdge/2;;
        CGRect square2Frame = CGRectMake(square2X, square2Y, squareEdge, squareEdge);
        
        // assign frames to views
        self.profileImage.frame = square1Frame;
        self.interestsLabel.frame = square2Frame;
    }
    
    // add subviews to view
    [self addSubview:self.interestsLabel];
    [self addSubview:self.profileImage];
}

@end
