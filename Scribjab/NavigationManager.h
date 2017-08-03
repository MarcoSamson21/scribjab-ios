//
//  NavigationManager.h
//  Scribjab
//
//  Created by Oleg Titov on 12-12-04.
//
//

#import <Foundation/Foundation.h>
#import "User.h"

@protocol NavigationManagerDelegate <NSObject>
-(void) transitionAnimationFinished;
@end




@interface NavigationManager : NSObject

// SETTERS
+ (void) setHomeViewController:(UIViewController*)vController;     // set home view controller. MUST be in Navigation view controller

// PUSH VIEWS
+ (void) pushViewController:(UIViewController*)viewController;
+ (void) pushViewControllerAnimated:(UIViewController *)viewController duration:(NSTimeInterval)duration transition:(UIViewAnimationTransition)transition animationCurve:(UIViewAnimationOptions) options;

// POP VIEWS
+ (void) popViewControllerAnimatedWithDuration:(NSTimeInterval)duration transition:(UIViewAnimationTransition)transition animationCurve:(UIViewAnimationOptions) options;

// NAVIGATE TO
+ (void) navigateToHome;
+ (void) navigateToHomeAnimatedWithDuration:(NSTimeInterval)duration transition:(UIViewAnimationTransition)transition animationCurve:(UIViewAnimationOptions) options;

+ (void) navigateToBrowseBooks;
+ (void) navigateToBrowseBooksAnimatedWithDuration:(NSTimeInterval)duration transition:(UIViewAnimationTransition)transition animationCurve:(UIViewAnimationOptions) options;

+ (void) navigateToMyLibraryForUser:(User *)loginUser;
+ (void) navigateToMyLibraryForUser:(User *)loginUser animatedWithDuration:(NSTimeInterval)duration transition:(UIViewAnimationTransition)transition animationCurve:(UIViewAnimationOptions) options;

+ (void) navigateToCreateBookForUser:(User *)loginUser animatedWithDuration:(NSTimeInterval)duration transition:(UIViewAnimationTransition)transition animationCurve:(UIViewAnimationOptions) options isFromHome:(BOOL)isFromHome;
+ (void) navigateToAbout;
+ (void) navigateToAboutAnimatedWithDuration:(NSTimeInterval)duration transition:(UIViewAnimationTransition)transition animationCurve:(UIViewAnimationOptions) options;

+ (void) openReadBookViewController:(Book *)book parentViewController:(UIViewController *) parent;

+ (UIViewController *) getCreateBookViewController;
+ (UIViewController *) getHomeViewController;
+ (UIViewController *) getRootViewNavigationController;
@end
