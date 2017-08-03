//
//  AccountManagementViewController.h
//  Scribjab
//
//  Created by Oleg Titov on 12-07-11.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"

@interface AccountManagementViewController : UIViewController

// returns absolute path for avatar or avatar thumbnail file, based on user ID
//+(NSString*) getAvatarAbsolutePathForUser:(User*) userId thumbnailSize:(BOOL) thumbnail;

@property (strong, nonatomic) IBOutlet UIButton *drawImageButton;
@property (strong, nonatomic) IBOutlet UITextField *passwordNew;
@property (strong, nonatomic) IBOutlet UITextField *emailNew;
@property (strong, nonatomic) IBOutlet UILabel *userNameLabel;
@property (strong, nonatomic) IBOutlet UITextField *confirmPassword;
@property (strong, nonatomic) IBOutlet UITextField *emailConfirm;
@property (strong, nonatomic) IBOutlet UIButton *saveButton;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIImageView *avatarThumBGView;
@property (strong, nonatomic) IBOutlet UIButton *deleteAccountButton;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *deleteAccountActivityIndicator;
- (IBAction)passwordChanged:(id)sender;
- (IBAction)emailChanged:(id)sender;
- (IBAction)closeAccountManagement:(id)sender;
- (IBAction)saveAccountInfo:(id)sender;
- (IBAction)passwordConfirmChanged:(id)sender;
- (IBAction)emailConfirmChanged:(id)sender;
- (IBAction)openAvatarDrawingPad:(id)sender;
- (IBAction)deleteAccount:(id)sender;
@end
