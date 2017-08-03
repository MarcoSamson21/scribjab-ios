//
//  CreateAccountConfirmationViewControllerViewController.m
//  Scribjab
//
//  Created by Oleg Titov on 12-09-11.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CreateAccountConfirmationViewController.h"
#import "UserAccount.h"
#import "Globals.h"

// Google Analytics includes
#import "GAI.h"
#import "GAIFields.h"
#import "GAITracker.h"
#import "GAIDictionaryBuilder.h"

// **************************************************************************************************************************************
// **************************************************************************************************************************************

@interface CreateAccountConfirmationViewController ()

@end
 
// **************************************************************************************************************************************
// **************************************************************************************************************************************

@implementation CreateAccountConfirmationViewController

@synthesize delegate = _delegate;
@synthesize wizardDataObject = _wizardDataObject;

// ======================================================================================================================================
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    // --- Send Google Analytics Data ----------
    
    // This screen name value will remain set on the tracker and sent with hits until it is set to a new value or to nil.
    NSString * screenName = [NSString stringWithFormat:@"%@ (%@ class)", @"Create Account (Confirmation of Registration) Screen", [self class]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName value:screenName];
    
    // Send the screen view.
    [[GAI sharedInstance].defaultTracker send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

// ======================================================================================================================================
// Close the chain of navigation windows
- (IBAction)doneClicked:(id)sender 
{
    [self.delegate viewControllerInNavigation:self finishedNavigationAndRequestsModalDismissal:YES];
}
@end
