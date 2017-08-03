//
//  ResetPasswordViewControllerViewController.h
//  Scribjab
//
//  Created by Oleg Titov on 12-09-14.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ResetPasswordViewController : UIViewController
- (IBAction)closeDialog:(id)sender;
@property (strong, nonatomic) IBOutlet UITextField *userNameEmailText;
- (IBAction)sendRequest:(id)sender;
@property (strong, nonatomic) IBOutlet UIButton *sendRequestButton;
@property (strong, nonatomic) IBOutlet UIView *submitView;
@property (strong, nonatomic) IBOutlet UIView *successView;
@property (strong, nonatomic) IBOutlet UILabel *errorMessageLabel;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (strong, nonatomic) IBOutlet UITextView *successMessage;

@end
