//
//  CreateAccountAccoutTypeViewController.m
//  Scribjab
//
//  Created by Oleg Titov on 12-08-22.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CreateAccountAccoutTypeViewController.h"
#import "CreateAccountUserInformationViewController.h"
#import "UserAccount.h"
#import "ModelConstants.h"

// Google Analytics includes
#import "GAI.h"
#import "GAIFields.h"
#import "GAITracker.h"
#import "GAIDictionaryBuilder.h"

@interface CreateAccountAccoutTypeViewController () <WizardNavigationViewControllerDelegate>

@end

// **************************************************************************************************************************************
// **************************************************************************************************************************************

@implementation CreateAccountAccoutTypeViewController

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
    
    // Create A New User Account
    UserAccount* account = [[UserAccount alloc] init];
    account.databaseID = 0;
    account.userType = [NSNumber numberWithInt:-1];
    account.avatarBgColor = @"ffffff";
    self.wizardDataObject = account;

    // --- Send Google Analytics Data ----------
    
    // This screen name value will remain set on the tracker and sent with hits until it is set to a new value or to nil.
    NSString * screenName = [NSString stringWithFormat:@"%@ (%@ class)", @"Create Account (Choose Account Type) Screen", [self class]];
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
// Child/Parent user account is selected
- (IBAction)childAccountTypeSelected:(id)sender 
{
    ((UserAccount*)self.wizardDataObject).userType = [NSNumber numberWithInt:ACCOUNT_TYPE_CHILD];
    [self performSegueWithIdentifier:@"Create Account - Proceed to User Information Section" sender:self];
}

// ======================================================================================================================================
// Teacher user account is selected
- (IBAction)teacherAccountTypeSelected:(id)sender 
{
    ((UserAccount*)self.wizardDataObject).userType = [NSNumber numberWithInt:ACCOUNT_TYPE_TEACHER];
    [self performSegueWithIdentifier:@"Create Account - Proceed to User Information Section" sender:self];
}

// ======================================================================================================================================
// Adult account type is selected (14+)
- (IBAction)adultAccountTypeSelected:(id)sender
{
    ((UserAccount*)self.wizardDataObject).userType = [NSNumber numberWithInt:ACCOUNT_TYPE_ADULT];
    [self performSegueWithIdentifier:@"Create Account - Proceed to User Information Section" sender:self];
}

// ======================================================================================================================================
// Assign current Account object to the next view controller in the wizard
-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Create Account - Proceed to User Information Section"])
    {
        ((CreateAccountUserInformationViewController*)segue.destinationViewController).delegate = self;
        ((CreateAccountUserInformationViewController*)segue.destinationViewController).wizardDataObject = self.wizardDataObject;
    }
}

// ======================================================================================================================================
// User doesn't agree to terms and conditions
- (IBAction)cancelButtonPress:(id)sender
{
    [self dismissModalViewControllerAnimated:NO];
}

#pragma mark - ModalNavigationViewControllerDelegate methods

// ======================================================================================================================================
// One of the pushed views in current vavigations notifies this modal view that the end of navigation is reached
// and may request modal dismissal.
-(void)viewControllerInNavigation:(id)sender finishedNavigationAndRequestsModalDismissal:(BOOL)dismiss
{
    if (dismiss)
    {
        [self dismissModalViewControllerAnimated:YES];
    }
}
@end
