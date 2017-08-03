//
//  CreateAccountUserInformationViewController.h
//  Scribjab
//
//  Created by Oleg Titov on 12-08-23.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IWizardNavigationViewController.h"
#import "WizardNavigationViewControllerDelegate.h"

@interface CreateAccountUserInformationViewController : UIViewController <IWizardNavigationViewController>

@property (nonatomic, weak) id<WizardNavigationViewControllerDelegate> delegate;
@property (strong, nonatomic) IBOutlet UITextField *userNameTextBox;
@property (strong, nonatomic) IBOutlet UITextField *passwordTextBox;
@property (strong, nonatomic) IBOutlet UITextField *confirmPasswordTextBox;
@property (strong, nonatomic) IBOutlet UITextField *emailTextBox;
@property (strong, nonatomic) IBOutlet UITextField *confirmEmailTextBox;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) IBOutlet UIButton *submitButton;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *addUserSpinner;
@property (strong, nonatomic) IBOutlet UITextField *realName;
@property (strong, nonatomic) IBOutlet UITextField *location;
@property (strong, nonatomic) IBOutlet UILabel *errorMessageLabel;
- (IBAction)userNameIsChanging:(id)sender;
- (IBAction)userNameChanged:(id)sender;
- (IBAction)passwordChanged:(id)sender;
- (IBAction)confirmPasswordChanged:(id)sender;
- (IBAction)emailChanged:(id)sender;
- (IBAction)confirmEmailChanged:(id)sender;
- (IBAction)submitNewUserButtonPress:(id)sender;
- (IBAction)cancelRegistration:(id)sender;
- (IBAction)realNameChanged:(id)sender;
- (IBAction)locationChanged:(id)sender;
@end
