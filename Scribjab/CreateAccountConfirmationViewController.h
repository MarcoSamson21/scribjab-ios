//
//  CreateAccountConfirmationViewControllerViewController.h
//  Scribjab
//
//  Created by Oleg Titov on 12-09-11.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IWizardNavigationViewController.h"
#import "WizardNavigationViewControllerDelegate.h"

@interface CreateAccountConfirmationViewController : UIViewController <IWizardNavigationViewController>
@property (nonatomic, weak) id<WizardNavigationViewControllerDelegate> delegate;
- (IBAction)doneClicked:(id)sender;
@end
