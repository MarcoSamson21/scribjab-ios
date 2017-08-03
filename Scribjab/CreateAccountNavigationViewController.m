//
//  CreateAccountBaseViewController.m
//  Scribjab
//
//  Created by Oleg Titov on 12-09-10.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CreateAccountNavigationViewController.h"

@interface CreateAccountNavigationViewController ()

@end

@implementation CreateAccountNavigationViewController

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
	// Do any additional setup after loading the view.
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
-(BOOL)disablesAutomaticKeyboardDismissal
{
    return NO;
}

@end
