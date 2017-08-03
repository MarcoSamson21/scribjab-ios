//
//  AppDelegate.m
//  Scribjab
//
//  Created by Oleg Titov on 12-06-25.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "DocumentHandler.h"
#import "Globals.h"
#import "NavigationManager.h"
#import "MainViewController.h"
#import "LoginRegistrationManager.h"
#import "GAI.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>

static NSDate * RECENT_BOOKS_LIST_LAST_REFRESH_DATE = nil; //[NSDate distantPast];


@interface AppDelegate ()
-(void) saveUserData;
-(void) loadUserData;
@end


@implementation AppDelegate

@synthesize window = _window;
@synthesize bookDownloadManager = _bookDownloadManager;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    // DON'T DELETE THIS LINE OF CODE
    [DocumentHandler sharedDocumentHandlerWithDelegate:((UINavigationController*)self.window.rootViewController).topViewController];
    _bookDownloadManager = [[DownloadManager alloc] init];
    [self loadUserData];
    
    [[FBSDKApplicationDelegate sharedInstance] application:application
                             didFinishLaunchingWithOptions:launchOptions];
    
    // ----------------------------------
    // GOOGLE ANALYTICS

    // Optional: automatically send uncaught exceptions to Google Analytics.
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    
    // Optional: set Google Analytics dispatch interval to e.g. 20 seconds.
    [GAI sharedInstance].dispatchInterval = 20;
    
    // Optional: set Logger to VERBOSE for debug information.
    [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelVerbose];
    
    // Initialize tracker.
    [[GAI sharedInstance] trackerWithTrackingId:GOOGLE_ANALYTICS_TRACKING_NUMBER];

    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [self saveUserData];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    
    // Refresh languages if it is time
    UIViewController * homeViewController = [NavigationManager getHomeViewController];
    if ([homeViewController isKindOfClass:[MainViewController class]])
    {
        [((MainViewController *) homeViewController) refreshLanguages];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [self saveUserData];
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return UIInterfaceOrientationMaskAll;
    else  /* iphone */
        return UIInterfaceOrientationMaskAllButUpsideDown;
}

// Process the application launch from an external app using registered URL.
-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if (!url)
    {   return NO;  }
    
    if ([[url lastPathComponent] isEqualToString:@"openLogin"])
    {
        //check if login, if yes, go to library.
        User * currentUser = [LoginRegistrationManager getLoginUser];
        
        [NavigationManager navigateToHome];
        
        UIViewController * homeViewController = [NavigationManager getHomeViewController];
        
        // if we were able to navigate to the main view controller - then present login screen, otherwise just show the app
        if (homeViewController.navigationController.visibleViewController == homeViewController)
        {
            if(currentUser != nil)
            {
                //if login, just go to mylibrary.
                [NavigationManager navigateToMyLibraryForUser:currentUser animatedWithDuration:0.75 transition:5 animationCurve:UIViewAnimationOptionCurveEaseInOut];
            }
            else
            {
                
                 [LoginRegistrationManager showLoginWithParent:[NavigationManager getHomeViewController] delegate:(id<LoginViewControllerDelegate>)homeViewController registrationButton:NO];
            }
        }
    }
    
    // FB Handling - this is required to fire the "handler" callback method of
    // [FBDialogs presentShareDialogWithLink:handler:] method
    
    
//    BOOL wasHandled = [FBAppCall handleOpenURL:url
//                             sourceApplication:sourceApplication
//                               fallbackHandler:^(FBAppCall *call) {
    
//                                   // Retrieve the link associated with the post
//                                   NSURL *targetURL = [[call appLinkData] targetURL];
//                                   
//                                   // We just show the target url in an alert view
//                                   // Here's where you'd add your code to analyze the target url and push the relevant view
//                                   [[[UIAlertView alloc] initWithTitle:@"Post's URL: "
//                                                               message:[targetURL absoluteString]
//                                                              delegate:self
//                                                     cancelButtonTitle:@"OK!"
//                                                     otherButtonTitles:nil] show];
//    }];

    
    return true;
}
    
    -(BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
    {
        BOOL handled = [[FBSDKApplicationDelegate sharedInstance] application:app
                                                                      openURL:url
                                                            sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
                                                                   annotation:options[UIApplicationOpenURLOptionsAnnotationKey]
                        ];
        
        return handled;
    }

// ======================================================================================================================================================================================
// fetch updated comments, comment flags, likes, as well as logged-in user groups for all downloaded books
-(void)refreshDataForDownloadedBooksAndLoginUser
{
    // Initialize LAST DATE to a time in the past
    if (RECENT_BOOKS_LIST_LAST_REFRESH_DATE == nil)
        RECENT_BOOKS_LIST_LAST_REFRESH_DATE = [NSDate distantPast];
    
    // if it is not time to refresh yet
    if ([RECENT_BOOKS_LIST_LAST_REFRESH_DATE compare:[NSDate date]] == NSOrderedDescending)
        return;
    
    [_bookDownloadManager refreshDownloadedBooksData];
    RECENT_BOOKS_LIST_LAST_REFRESH_DATE = [[NSDate date] dateByAddingTimeInterval:60*DOWNLOADED_BOOKS_REFRESH_FREQUENCY_IN_MINUTES];      // set the time of the next fetch request
}

// ======================================================================================================================================================================================
-(void)saveUserData
{
    // Save persistent cookies
    NSArray* allCookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
    NSMutableArray * cookieDics = [[NSMutableArray alloc] initWithCapacity:2];
    
    for (NSHTTPCookie *cookie in allCookies)
    {
        [cookieDics addObject:cookie.properties];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:cookieDics forKey:@"MYCOOKIES"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// ======================================================================================================================================================================================
-(void)loadUserData
{
    // Load persistent cookies
   
    NSArray * allCookies = [[NSUserDefaults standardUserDefaults] objectForKey:@"MYCOOKIES"];
    for (NSDictionary * cookieProperties in allCookies)
    {
        NSHTTPCookie* cookie = [NSHTTPCookie cookieWithProperties:cookieProperties];
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
    }
}
@end
