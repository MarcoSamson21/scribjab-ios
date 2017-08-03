//
//  CommonMessageBoxes.h
//  Scribjab
//
//  Created by Oleg Titov on 12-09-07.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CommonMessageBoxes : NSObject


// shortcut to show commont error message
+ (void) showServerConnectionErrorMessageBoxWithError:(NSError*)error andDelegate:(id) delegate;    // Server connection Error message
+ (void) showInvalidResponseFromServerMessageBoxWithDelegate:(id) delegate;                         // Invalid Responce Received From Server message box

+ (void) showCoreDataErrorMessageBoxWithDelegate:(NSError*)error andDelegate:(id) delegate;                 // Core Data Related message box

@end
