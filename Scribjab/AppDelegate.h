//
//  AppDelegate.h
//  Scribjab
//
//  Created by Oleg Titov on 12-06-25.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DownloadManager.h"
@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, readonly) DownloadManager * bookDownloadManager;

-(void) refreshDataForDownloadedBooksAndLoginUser;

@end
