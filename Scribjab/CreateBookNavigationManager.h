//
//  CreateBookNavigationManager.h
//  Scribjab
//
//  Created by Gladys Tang on 13-02-25.
//
//

#import <Foundation/Foundation.h>
#import "User.h"
#import "Book.h"
@protocol CreateBookNavigationManager <NSObject>
-(void) transitionAnimationFinished;
@end




@interface CreateBookNavigationManager : NSObject

// SETTERS
+ (void) setHomeControllerForCreateBook:(UIViewController*)vController;     // set home view controller. MUST be in Navigation view controller

// PUSH VIEWS
+ (void) pushViewController:(UIViewController*)viewController;
+ (void) pushViewControllerAnimated:(UIViewController *)viewController duration:(NSTimeInterval)duration transition:(UIViewAnimationTransition)transition animationCurve:(UIViewAnimationOptions) options;

// POP VIEWS
+ (void) popViewControllerAnimatedWithDuration:(NSTimeInterval)duration transition:(UIViewAnimationTransition)transition animationCurve:(UIViewAnimationOptions) options;





// NAVIGATE TO
+ (void) navigateToSelectLanguageAnimatedWithDuration:(NSTimeInterval)duration transition:(UIViewAnimationTransition)transition animationCurve:(UIViewAnimationOptions) options wizardDataObject:(id)wizardDataObject loginUser:(User *)loginUser isFromHome:(BOOL)isFromHome;
+ (void) navigateToBookViewControllerAnimatedWithDuration:(NSTimeInterval)duration transition:(UIViewAnimationTransition)transition animationCurve:(UIViewAnimationOptions) options wizardDataObject:(id)wizardDataObject;
+ (void) navigateToDrawBookViewControllerAnimatedWithDuration:(NSTimeInterval)duration transition:(UIViewAnimationTransition)transition animationCurve:(UIViewAnimationOptions) options wizardDataObject:(id)wizardDataObject;
+ (void) navigateToDrawBookPageViewControllerAnimatedWithDuration:(NSTimeInterval)duration transition:(UIViewAnimationTransition)transition animationCurve:(UIViewAnimationOptions) options wizardDataObject:(id)wizardDataObject;
+ (void) navigateToPublishViewControllerAnimatedWithDuration:(NSTimeInterval)duration transition:(UIViewAnimationTransition)transition animationCurve:(UIViewAnimationOptions) options book:(Book *)book;
@end
