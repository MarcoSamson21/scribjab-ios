//
//  ILoginViewControllerDelegate.h
//  Scribjab
//
//  Created by Oleg Titov on 12-09-12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LoginViewControllerDelegate <NSObject>

// Login view finished the login process and the user was logged in successfully.
@optional -(void) loginFinishedWithSuccess;

// Login view's cancel button was clicked. Login was unsuccessful
@optional -(void) loginCancelled;

// Login view will be dismissed (login unsuccessful), instead user opeden New Account Registration button
@optional -(void) loginReplacedWithRegistrationForm;

@end
