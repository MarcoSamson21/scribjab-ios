//
//  CreateBookNavigationManager.m
//  Scribjab
//
//  Created by Gladys Tang on 13-02-25.
//
//

#import "CreateBookNavigationManager.h"
#import "BrowseBooksViewController.h"
#import "MyLibraryViewController.h"
#import "BookSelectLanguageViewController.h"
#import "BookViewController.h"
#import "PublishBookViewController.h"
#import "BookDrawViewController.h"
#import "BookPageDrawViewController.h"

static UINavigationController * CREATE_BOOK_ROOT_NAVIGATION_CONTROLLER      = nil;
static UIViewController * SELECT_LANGUAGE_VIEW_CONTROLLER          = nil;          // My Library Section main view controller
static UIViewController * BOOK_VIEW_CONTROLLER          = nil;            // About Section main view controller
static UIViewController * DRAW_BOOK_VIEW_CONTROLLER          = nil;
static UIViewController * DRAW_BOOK_PAGE_VIEW_CONTROLLER          = nil;
static UIViewController * PUBLISH_VIEW_CONTROLLER          = nil;
static UIViewController * CREATE_BOOK_HOME_VIEW_CONTROLLER = nil;
@interface CreateBookNavigationManager()
+ (UIViewController *) getSelectLanguageViewController;
+ (UIViewController *) getBookViewController;
+ (UIViewController *) getDrawBookViewController;
+ (UIViewController *) getDrawBookPageViewController;
+ (UIViewController *) getPublishViewController;
+ (UIStoryboard *) getStoryboard;
@end

@implementation CreateBookNavigationManager


// **************************************************************************************************************************************
// INITIALIZE VIEWS
// set home view controller. MUST be in Navigation view controller
+ (void) setHomeControllerForCreateBook:(UIViewController*)vController
{
    CREATE_BOOK_ROOT_NAVIGATION_CONTROLLER = vController.navigationController;
    CREATE_BOOK_HOME_VIEW_CONTROLLER = vController;
}

+ (UIStoryboard *) getStoryboard
{
 return [UIStoryboard storyboardWithName:@"Book" bundle:[NSBundle mainBundle]];
}

+ (UIViewController *) getSelectLanguageViewController
{
    return (SELECT_LANGUAGE_VIEW_CONTROLLER == nil? [[CreateBookNavigationManager getStoryboard] instantiateViewControllerWithIdentifier:@"Create Book - Select Language"]: SELECT_LANGUAGE_VIEW_CONTROLLER);
}
+ (UIViewController *) getBookViewController
{
    return (BOOK_VIEW_CONTROLLER == nil? [[CreateBookNavigationManager getStoryboard] instantiateViewControllerWithIdentifier:@"Edit Book - title page and page"]: BOOK_VIEW_CONTROLLER);

}
+ (UIViewController *) getDrawBookViewController
{
    return (DRAW_BOOK_VIEW_CONTROLLER == nil? [[CreateBookNavigationManager getStoryboard] instantiateViewControllerWithIdentifier:@"Edit Book - title page draw"]: DRAW_BOOK_VIEW_CONTROLLER);
}
+ (UIViewController *) getDrawBookPageViewController
{
    return (DRAW_BOOK_PAGE_VIEW_CONTROLLER == nil? [[CreateBookNavigationManager getStoryboard] instantiateViewControllerWithIdentifier:@"Edit Book - page draw"]: DRAW_BOOK_PAGE_VIEW_CONTROLLER);
}
+ (UIViewController *) getPublishViewController
{
    return (PUBLISH_VIEW_CONTROLLER == nil? [[CreateBookNavigationManager getStoryboard] instantiateViewControllerWithIdentifier:@"Edit Book - publish book"]: PUBLISH_VIEW_CONTROLLER);
}
 
// **************************************************************************************************************************************
// GENERIC PUSH / POP VIEWS

// Push view to the current navigation controller stack
+ (void)pushViewController:(UIViewController *)viewController
{
    [CREATE_BOOK_ROOT_NAVIGATION_CONTROLLER pushViewController:viewController animated:NO];
}

// Push view to the current navigation controller stack with specified animation
+ (void)pushViewControllerAnimated:(UIViewController *)viewController duration:(NSTimeInterval)duration transition:(UIViewAnimationTransition)transition animationCurve:(UIViewAnimationOptions) options
{
    // duration = 0.75F;
    
    [CREATE_BOOK_ROOT_NAVIGATION_CONTROLLER pushViewController:viewController animated:NO];
    [UIView animateWithDuration:duration delay:0.0f options:options
                     animations:
     ^{
         [UIView setAnimationTransition:transition forView:CREATE_BOOK_ROOT_NAVIGATION_CONTROLLER.view cache:YES];
     }
                     completion:^(BOOL finished)
     {
    }
     ];
}

// ============================================================================================================================================================
// Pop to Main Application View with animation
+ (void) popViewControllerAnimatedWithDuration:(NSTimeInterval)duration transition:(UIViewAnimationTransition)transition animationCurve:(UIViewAnimationOptions) options
{
    // duration = 0.75F;
    
    [UIView animateWithDuration:duration delay:0.0f options:options
                     animations:
     ^{
         [UIView setAnimationTransition:transition forView:CREATE_BOOK_ROOT_NAVIGATION_CONTROLLER.view cache:YES];
     }
                     completion:^(BOOL finished)
     {
     }
     ];
    [CREATE_BOOK_ROOT_NAVIGATION_CONTROLLER popViewControllerAnimated:NO];
}



// **************************************************************************************************************************************
// NAVIGATION TO SPECIFIC SECTIONS


// ============================================================================================================================================================
// Go to Home view
//+ (void) navigateToSelectLanguageViewController
//{
//    [CREATE_BOOK_ROOT_NAVIGATION_CONTROLLER popToRootViewControllerAnimated:NO];
//}

+ (void) navigateToSelectLanguageAnimatedWithDuration:(NSTimeInterval)duration transition:(UIViewAnimationTransition)transition animationCurve:(UIViewAnimationOptions) options wizardDataObject:(id)wizardDataObject loginUser:(User *)loginUser isFromHome:(BOOL)isFromHome {
    // duration = 0.75F;
    
    BookSelectLanguageViewController * bookSelectLanguageView = ((BookSelectLanguageViewController*)[CREATE_BOOK_ROOT_NAVIGATION_CONTROLLER.viewControllers objectAtIndex:0]);
    
    bookSelectLanguageView.wizardDataObject = nil;
    bookSelectLanguageView.loginUser = loginUser;
    bookSelectLanguageView.isFromHome = isFromHome;
    
    [UIView animateWithDuration:duration delay:0.0f options:options
                     animations:
     ^{
         [UIView setAnimationTransition:transition forView:CREATE_BOOK_ROOT_NAVIGATION_CONTROLLER.view cache:YES];
     }
                     completion:^(BOOL finished)
     {
     }
     ];
    [CREATE_BOOK_ROOT_NAVIGATION_CONTROLLER popToRootViewControllerAnimated:NO];
}


+ (void) navigateToBookViewControllerAnimatedWithDuration:(NSTimeInterval)duration transition:(UIViewAnimationTransition)transition animationCurve:(UIViewAnimationOptions) options wizardDataObject:(id)wizardDataObject{
    
    if(CREATE_BOOK_HOME_VIEW_CONTROLLER == nil)
    {
        [CreateBookNavigationManager setHomeControllerForCreateBook:[NavigationManager getCreateBookViewController]];
        
    }

    [CREATE_BOOK_ROOT_NAVIGATION_CONTROLLER popToRootViewControllerAnimated:NO];
    BookViewController * vc = (BookViewController *)[CreateBookNavigationManager getBookViewController];
    vc.wizardDataObject = wizardDataObject;
    [CREATE_BOOK_ROOT_NAVIGATION_CONTROLLER pushViewController:vc animated:NO];

    [UIView animateWithDuration:duration delay:0.0f options:options
                     animations:
     ^{
         [UIView setAnimationTransition:transition forView:CREATE_BOOK_ROOT_NAVIGATION_CONTROLLER.view cache:YES];
     }
                     completion:^(BOOL finished)
     {
     }
     ];
}

+ (void) navigateToDrawBookViewControllerAnimatedWithDuration:(NSTimeInterval)duration transition:(UIViewAnimationTransition)transition animationCurve:(UIViewAnimationOptions) options wizardDataObject:(id)wizardDataObject{
    
    [CREATE_BOOK_ROOT_NAVIGATION_CONTROLLER popToRootViewControllerAnimated:NO];
    BookDrawViewController * vc = (BookDrawViewController *)[CreateBookNavigationManager getDrawBookViewController];
    vc.wizardDataObject = wizardDataObject;
    [CREATE_BOOK_ROOT_NAVIGATION_CONTROLLER pushViewController:vc animated:NO];
    [UIView animateWithDuration:duration delay:0.0f options:options
                     animations:
     ^{
         [UIView setAnimationTransition:transition forView:CREATE_BOOK_ROOT_NAVIGATION_CONTROLLER.view cache:YES];
     }
                     completion:^(BOOL finished)
     {
     }
     ];
}
+ (void) navigateToDrawBookPageViewControllerAnimatedWithDuration:(NSTimeInterval)duration transition:(UIViewAnimationTransition)transition animationCurve:(UIViewAnimationOptions) options wizardDataObject:(id)wizardDataObject{
    
    [CREATE_BOOK_ROOT_NAVIGATION_CONTROLLER popToRootViewControllerAnimated:NO];
    BookPageDrawViewController * vc = (BookPageDrawViewController*)[CreateBookNavigationManager getDrawBookPageViewController];
    vc.wizardDataObject = wizardDataObject;
    [CREATE_BOOK_ROOT_NAVIGATION_CONTROLLER pushViewController:vc animated:NO];
    [UIView animateWithDuration:duration delay:0.0f options:options
                     animations:
     ^{
         [UIView setAnimationTransition:transition forView:CREATE_BOOK_ROOT_NAVIGATION_CONTROLLER.view cache:YES];
     }
                     completion:^(BOOL finished)
     {
     }
     ];
}
+ (void) navigateToPublishViewControllerAnimatedWithDuration:(NSTimeInterval)duration transition:(UIViewAnimationTransition)transition animationCurve:(UIViewAnimationOptions) options book:(Book *)book{
    
    [CREATE_BOOK_ROOT_NAVIGATION_CONTROLLER popToRootViewControllerAnimated:NO];
    PublishBookViewController * vc = (PublishBookViewController *)[CreateBookNavigationManager getPublishViewController];
    vc.book = book;

    [CREATE_BOOK_ROOT_NAVIGATION_CONTROLLER pushViewController:vc animated:NO];
    [UIView animateWithDuration:duration delay:0.0f options:options
                     animations:
     ^{
         [UIView setAnimationTransition:transition forView:CREATE_BOOK_ROOT_NAVIGATION_CONTROLLER.view cache:YES];
     }
                     completion:^(BOOL finished)
     {
     }
     ];
}
@end

 