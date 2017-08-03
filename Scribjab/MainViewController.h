//
//  MainViewController.h
//  Scribjab
//
//  Created by Oleg Titov on 12-07-11.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainViewController : UIViewController
@property (strong, nonatomic) IBOutlet UIView *overlayView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) IBOutlet UIButton *loginButton;
@property (strong, nonatomic) IBOutlet UIButton *logoutButton;

- (IBAction)takeTourButtonTouched:(id)sender;
- (IBAction)showCreateBook:(id)sender;
- (IBAction)showMyLibrary:(id)sender;
- (IBAction)showBookNavigationAndSearch:(id)sender;
- (IBAction)logout:(id)sender;

- (void) refreshLanguages;

@end
