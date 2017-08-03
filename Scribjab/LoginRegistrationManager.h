//
//  LoginRegistrationManager.h
//  Scribjab
//
//  Created by Oleg Titov on 12-09-13.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LoginViewControllerDelegate.h"
#import "User.h"

@protocol LoginRegistrationManagerDelegate <NSObject>

-(void) userDeleteRequestStarted;
-(void) userDeleteRequestFinishedWithSuccess:(BOOL)success;

@end


@interface LoginRegistrationManager : NSObject

// Shows login dialog and attach it to the specified parent controller. Specified delegate s used to notify of user requests.
// Show registration parameter indicates if a user can register from the login screen.
+ (void) showLoginWithParent:(UIViewController* )parent delegate:(id<LoginViewControllerDelegate>)delegate registrationButton:(BOOL)showRegistration;

// Shows user registration dialog and attach it to the specified parent controller. 
+ (void) showAccountRegistrationFormWithParent:(UIViewController* )parent;

// Logs a user in to the system and performs any necessary cleanups/initializations.
+ (void) login;

// Logs out a user (if logged-in) from the system and performs any necessary cleanups.
+ (void) logout;

// Get a logged-in user form core data. If no user logged-in, return nil.
+ (User *) getLoginUser;



// ======================================================================================================================================
// -- MEMBER METHODS
@property (nonatomic, weak) id<LoginRegistrationManagerDelegate> delegate;

// Permanently delete user from the server and from iPad. This method will delete all of the data created by this user:
// books, comment, flags, groups, etc. Password - current password of the user.
-(void)deleteUserAccountPermanently:(User *)user password:(NSString*)currentPassword;

@end
