//
//  CreateAccountAccoutTypeViewController.h
//  Scribjab
//
//  Created by Oleg Titov on 12-08-22.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WizardNavigationViewControllerDelegate.h"
#import "IWizardNavigationViewController.h"

@interface CreateAccountAccoutTypeViewController : UIViewController <IWizardNavigationViewController>

- (IBAction)childAccountTypeSelected:(id)sender;
- (IBAction)teacherAccountTypeSelected:(id)sender;
- (IBAction)adultAccountTypeSelected:(id)sender;

- (IBAction)cancelButtonPress:(id)sender;
@end
