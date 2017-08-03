//
//  CommonMessageBoxes.m
//  Scribjab
//
//  Created by Oleg Titov on 12-09-07.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CommonMessageBoxes.h"

@implementation CommonMessageBoxes

// ======================================================================================================================================
// shortcut to show Server Connection Error message box
+ (void) showServerConnectionErrorMessageBoxWithError:(NSError*)error andDelegate:(id) delegate
{
    NSString * errorTitle = NSLocalizedString(@"Server Connection Error", @"Error when can't connect to the server");
    NSString * errorBody = NSLocalizedString(@"Please make sure that you have Internet access", @"Error message: connection to a server can't be established.");
    NSString * myError = [NSString stringWithFormat:@"%@ %@", [error localizedDescription], errorBody];
    
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:errorTitle message:myError delegate:delegate cancelButtonTitle:NSLocalizedString(@"OK", @"OK button label") otherButtonTitles: nil];
    [alert show];
}

// ======================================================================================================================================
// shortcut to show Invalid Responce Received From Server message box
+ (void) showInvalidResponseFromServerMessageBoxWithDelegate:(id) delegate
{
    NSString * errorTitle = NSLocalizedString(@"Received an Invalid Resonse from the server", @"Error title: when unexpected result received from the server");
    NSString * errorBody = NSLocalizedString(@"Server returned data that this application cannot understand", @"Error message: when unexpected result received from the server");
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:errorTitle message:errorBody delegate:delegate cancelButtonTitle:NSLocalizedString(@"OK", @"OK button label") otherButtonTitles: nil];
    [alert show];  
}

// Core Data Related message box
+ (void) showCoreDataErrorMessageBoxWithDelegate:(NSError*)error andDelegate:(id) delegate;                 
{
    NSString * errorTitle = NSLocalizedString(@"Data Error", @"Error title: data error");
    NSString * errorBody = NSLocalizedString(@"Error when saving the data in ipad", @"Error message: Error when saving the data in ipad");
    NSString * myError = [NSString stringWithFormat:@"%@ %@", [error localizedDescription], errorBody];

    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:errorTitle message:myError delegate:delegate cancelButtonTitle:NSLocalizedString(@"OK", @"OK button label") otherButtonTitles: nil];
    [alert show];
}
@end
