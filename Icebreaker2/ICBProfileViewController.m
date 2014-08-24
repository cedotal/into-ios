//
//  ICBProfileViewController.m
//  Icebreaker2
//
//  Created by Andrew Cedotal on 8/23/14.
//  Copyright (c) 2014 Icebreaker. All rights reserved.
//

#import "ICBProfileViewController.h"
#include <Parse/Parse.h>

@interface ICBProfileViewController() <UIActionSheetDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet PFImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UIButton *changeProfileImageButton;

@end

@implementation ICBProfileViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    // set username label
    NSString *username = [[PFUser currentUser] objectForKey:@"username"];
    self.usernameLabel.text = username;
    
    self.changeProfileImageButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self updateChangeProfileImageButtonTitle];
    
    if([[PFUser currentUser] objectForKey:@"profileImage1"]){
        self.profileImageView.file = [[PFUser currentUser] objectForKey:@"profileImage1"];
        [self.profileImageView loadInBackground];
    }
}

- (IBAction)userTappedChangeUsernameButton:(id)sender {
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Change username"
                                                 message:@"Enter your new username."
                                                delegate:self
                                       cancelButtonTitle:@"Cancel"
                                       otherButtonTitles:@"Submit", nil];
    av.alertViewStyle = UIAlertViewStylePlainTextInput;
    [av show];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 1){
        NSString *oldUsername = [[[PFUser currentUser] objectForKey:@"username"] copy];
        NSString *newUsername = [alertView textFieldAtIndex:0].text;
        self.usernameLabel.text = newUsername;
        [[PFUser currentUser]setObject:newUsername
                                forKey:@"username"];
        [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if(error){
                self.usernameLabel.text = oldUsername;
                [[PFUser currentUser] setObject:oldUsername
                                         forKey:@"username"];
                UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error"
                                                             message:error.userInfo[@"error"]
                                                            delegate:self
                                                   cancelButtonTitle:@"Okay"
                                                   otherButtonTitles: nil];
                [av show];
            }
            // else do nothing
        }];
    }
}

- (IBAction)userTappedChangeProfileImageButton:(id)sender
{
    UIActionSheet *actionSheet;
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
        actionSheet = [[UIActionSheet alloc] initWithTitle:@"Profile Image"
                          delegate:self
                 cancelButtonTitle:@"Cancel"
            destructiveButtonTitle:nil
                 otherButtonTitles:@"Use Image from Phone", @"Take Photo", nil];
    } else {
        actionSheet = [[UIActionSheet alloc] initWithTitle:@"Profile Image"
                                                  delegate:self
                                         cancelButtonTitle:@"Cancel"
                                    destructiveButtonTitle:nil
                                         otherButtonTitles:@"Use Image from Phone", nil];
    }
    [actionSheet showInView:self.view];
}

-(void)updateChangeProfileImageButtonTitle
{
    NSMutableString *buttonTitle = [[NSMutableString alloc] init];
    // if the user doesn't have a photo already, change the button text
    // to prompt them to add one
    if(![[PFUser currentUser]objectForKey:@"profileImage1"]){
        [buttonTitle appendString:@"Add Profile Image"];
    } else {
        [buttonTitle appendString:@"Change Profile Image"];
    }
    [self.changeProfileImageButton setTitle:[buttonTitle copy]
                                   forState:UIControlStateNormal];
    [self.changeProfileImageButton setTitle:[buttonTitle copy]
                                   forState:UIControlStateHighlighted];
}

#pragma mark - UIActionSheetDelegate methods

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0){
        [self selectExistingImage];
    } else if (buttonIndex == 1) {
        [self takePicture];
    }
}


#pragma mark - UIImagePickerControllerDelegate methods

- (void)selectExistingImage
{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    imagePicker.delegate = self;
    
    imagePicker.allowsEditing = YES;
    
    // place image picker on the screen
    
    [self presentViewController:imagePicker
                       animated:YES
                     completion:NULL];
}

- (void)takePicture
{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    
    imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    imagePicker.delegate = self;
    
    imagePicker.allowsEditing = YES;
    
    // place image picker on the screen
    
    [self presentViewController:imagePicker
                       animated:YES
                     completion:NULL];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // get picked image from info dict
    UIImage *image = info[UIImagePickerControllerEditedImage];
    
    // create
    NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
    PFFile *imageFile = [PFFile fileWithName:@"profileImage1"
                                        data:imageData];
    
    // store the image
    PFUser *currentUser = [PFUser currentUser];
    [currentUser setObject:imageFile
                    forKey:@"profileImage1"];
    
    [currentUser saveInBackground];
    
    self.profileImageView.image = image;
    
    // take image picker off the screen - you must call this dismiss method
    
    [self updateChangeProfileImageButtonTitle];
    
    // dismiss the modal image picker
    [self dismissViewControllerAnimated:YES
                             completion:NULL];
    
}


@end
