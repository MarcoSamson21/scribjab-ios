//
//  NavigationManager.m
//  Scribjab
//
//  Created by Oleg Titov on 12-12-04.
//
//

#import "NavigationManager.h"
#import "MainViewController.h"
#import "BrowseBooksViewController.h"
#import "MyLibraryViewController.h"
#import "ProductTourViewController.h"
#import "BookSelectLanguageViewController.h"
#import "ReadBookCoverPageViewController.h"
#import "ReadBookManagerViewController.h"

static UINavigationController * ROOT_NAVIGATION_CONTROLLER      = nil;
static UIViewController * HOME_VIEW_CONTROLLER                  = nil;          // Application's Main View Controller (MUST be inside Navigation Controller
static UIViewController * BROWSE_BOOKS_ROOT_VIEW_CONTROLLER     = nil;          // Browse Section main view controller
static UIViewController * LIBRARY_ROOT_VIEW_CONTROLLER          = nil;          // My Library Section main view controller
static UIViewController * ABOUT_ROOT_VIEW_CONTROLLER          = nil;            // About Section main view controller
static UIViewController * CREATE_BOOKS_ROOT_VIEW_CONTROLLER          = nil;    
@interface NavigationManager()
+ (UIViewController *) getLibraryViewController;
+ (UIViewController *) getBrowseBooksViewController;
+ (UIViewController *) getAboutSectionViewController;
//+ (UIViewController *) getCreateBookViewController;
@end

@implementation NavigationManager


// **************************************************************************************************************************************
// INITIALIZE VIEWS 

// set home view controller. MUST be in Navigation view controller
+ (void) setHomeViewController:(UIViewController*)vController
{
    ROOT_NAVIGATION_CONTROLLER = vController.navigationController;
    HOME_VIEW_CONTROLLER = vController;
}

+ (UIViewController *) getHomeViewController
{
    return HOME_VIEW_CONTROLLER;
}

+ (UIViewController *) getRootViewNavigationController
{
    return ROOT_NAVIGATION_CONTROLLER;
}

+ (UIViewController *) getLibraryViewController
{
    if (LIBRARY_ROOT_VIEW_CONTROLLER == nil)
    {
        UIStoryboard * myLibraryStoryboard = [UIStoryboard storyboardWithName:@"MyLibrary" bundle:[NSBundle mainBundle]];
        UIViewController * vc = [myLibraryStoryboard instantiateViewControllerWithIdentifier:@"My Library - My book and my favourite"];
        LIBRARY_ROOT_VIEW_CONTROLLER = vc;
    }
    return LIBRARY_ROOT_VIEW_CONTROLLER;
}
+ (UIViewController *) getBrowseBooksViewController
{
    if (BROWSE_BOOKS_ROOT_VIEW_CONTROLLER == nil)
    {
        UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"BrowseBooks" bundle:[NSBundle mainBundle]];
        UIViewController * vc = [storyboard instantiateViewControllerWithIdentifier:@"Browse Books - Newly Published And Most Popular"];
        BROWSE_BOOKS_ROOT_VIEW_CONTROLLER = vc;
    }
    return BROWSE_BOOKS_ROOT_VIEW_CONTROLLER;
}
+ (UIViewController *) getAboutSectionViewController
{
    if (ABOUT_ROOT_VIEW_CONTROLLER == nil)
    {
        UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"ProductTour" bundle:[NSBundle mainBundle]];
        UIViewController * vc = [storyboard instantiateViewControllerWithIdentifier:@"Product Tout Section Main View Controller"];
        ABOUT_ROOT_VIEW_CONTROLLER = vc;
    }
    return ABOUT_ROOT_VIEW_CONTROLLER;
}

+ (UIViewController *) getCreateBookViewController
{
    if (CREATE_BOOKS_ROOT_VIEW_CONTROLLER == nil)
    {
        UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Book" bundle:[NSBundle mainBundle]];
        UIViewController * vc = [storyboard instantiateViewControllerWithIdentifier:@"Create Book - Select Language"];
        CREATE_BOOKS_ROOT_VIEW_CONTROLLER = vc;
    }
    return CREATE_BOOKS_ROOT_VIEW_CONTROLLER;
}
// **************************************************************************************************************************************
// GENERIC PUSH / POP VIEWS

// Push view to the current navigation controller stack
+ (void)pushViewController:(UIViewController *)viewController
{
    [ROOT_NAVIGATION_CONTROLLER pushViewController:viewController animated:NO];
}

// Push view to the current navigation controller stack with specified animation
+ (void)pushViewControllerAnimated:(UIViewController *)viewController duration:(NSTimeInterval)duration transition:(UIViewAnimationTransition)transition animationCurve:(UIViewAnimationOptions) options
{
    // duration = 0.75F;
    
    [ROOT_NAVIGATION_CONTROLLER pushViewController:viewController animated:NO];
    [UIView animateWithDuration:duration delay:0.0f options:options
        animations:
        ^{
            [UIView setAnimationTransition:transition forView:ROOT_NAVIGATION_CONTROLLER.view cache:YES];
        }
        completion:^(BOOL finished)
        {
            if ([BROWSE_BOOKS_ROOT_VIEW_CONTROLLER respondsToSelector:@selector(transitionAnimationFinished)])
            {
                [(id<NavigationManagerDelegate>)BROWSE_BOOKS_ROOT_VIEW_CONTROLLER transitionAnimationFinished];
            }
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
            [UIView setAnimationTransition:transition forView:ROOT_NAVIGATION_CONTROLLER.view cache:YES];
        }
        completion:^(BOOL finished)
        {
        }
    ];
    [ROOT_NAVIGATION_CONTROLLER popViewControllerAnimated:NO];
}



// **************************************************************************************************************************************
// NAVIGATION TO SPECIFIC SECTIONS


// ============================================================================================================================================================
// Go to Home view
+ (void) navigateToHome
{
    [ROOT_NAVIGATION_CONTROLLER popToRootViewControllerAnimated:NO];
}

// ============================================================================================================================================================
// Go to Home view with animation. iOS supports animations 0-7, 101-117. http://iphonedevwiki.net/index.php/UIViewAnimationState
+ (void) navigateToHomeAnimatedWithDuration:(NSTimeInterval)duration transition:(UIViewAnimationTransition)transition animationCurve:(UIViewAnimationOptions) options
{
    // duration = 0.75F;
    
    [UIView animateWithDuration:duration delay:0.0f options:options
        animations:
        ^{
            [UIView setAnimationTransition:transition forView:ROOT_NAVIGATION_CONTROLLER.view cache:YES];
        }
        completion:^(BOOL finished)
        {
        }
     ];
    [ROOT_NAVIGATION_CONTROLLER popToRootViewControllerAnimated:NO];
}

// ============================================================================================================================================================
// Go to Browse section view
+ (void) navigateToBrowseBooks
{
    [ROOT_NAVIGATION_CONTROLLER popToRootViewControllerAnimated:NO];
    [ROOT_NAVIGATION_CONTROLLER pushViewController:[NavigationManager getBrowseBooksViewController] animated:NO];
}
// ============================================================================================================================================================
// Go to Browse section view with animation. iOS supports animations 0-7, 101-117. http://iphonedevwiki.net/index.php/UIViewAnimationState
+ (void) navigateToBrowseBooksAnimatedWithDuration:(NSTimeInterval)duration transition:(UIViewAnimationTransition)transition animationCurve:(UIViewAnimationOptions) options
{
    // duration = 0.75F;
    
    [ROOT_NAVIGATION_CONTROLLER popToRootViewControllerAnimated:NO];
    [ROOT_NAVIGATION_CONTROLLER pushViewController:[NavigationManager getBrowseBooksViewController] animated:NO];
    [UIView animateWithDuration:duration delay:0.0f options:options
        animations:
        ^{
            [UIView setAnimationTransition:transition forView:ROOT_NAVIGATION_CONTROLLER.view cache:YES];
        }
        completion:^(BOOL finished)
        {
            if ([BROWSE_BOOKS_ROOT_VIEW_CONTROLLER respondsToSelector:@selector(transitionAnimationFinished)])
            {
                [(id<NavigationManagerDelegate>)BROWSE_BOOKS_ROOT_VIEW_CONTROLLER transitionAnimationFinished];
            }
        }
     ];
}

// ============================================================================================================================================================
// Go to My Library section view
+ (void) navigateToMyLibraryForUser:(User *)loginUser;
{
    [ROOT_NAVIGATION_CONTROLLER popToRootViewControllerAnimated:NO];
    MyLibraryViewController * vc = (MyLibraryViewController*)[NavigationManager getLibraryViewController];
    vc.loginUser = loginUser;
    [ROOT_NAVIGATION_CONTROLLER pushViewController:vc animated:NO];
}

// ============================================================================================================================================================
// Go to My Library section view with animation. iOS supports animations 0-7, 101-117. http://iphonedevwiki.net/index.php/UIViewAnimationState
+ (void) navigateToMyLibraryForUser:(User *)loginUser animatedWithDuration:(NSTimeInterval)duration transition:(UIViewAnimationTransition)transition animationCurve:(UIViewAnimationOptions) options
{
    // duration = 0.75F;
    
    [ROOT_NAVIGATION_CONTROLLER popToRootViewControllerAnimated:NO];
    MyLibraryViewController * vc = (MyLibraryViewController*)[NavigationManager getLibraryViewController];
    vc.loginUser = loginUser;
    [ROOT_NAVIGATION_CONTROLLER pushViewController:vc animated:NO];
    
    [UIView animateWithDuration:duration delay:0.0f options:options animations:^{
         [UIView setAnimationTransition:transition forView:ROOT_NAVIGATION_CONTROLLER.view cache:YES];
    }
    completion:^(BOOL finished){
         if ([BROWSE_BOOKS_ROOT_VIEW_CONTROLLER respondsToSelector:@selector(transitionAnimationFinished)])
         {
             [(id<NavigationManagerDelegate>)BROWSE_BOOKS_ROOT_VIEW_CONTROLLER transitionAnimationFinished];
         }
    }];
}

// ============================================================================================================================================================
// Go to Create Book View in MyLibrary section with animation. iOS supports animations 0-7, 101-117. http://iphonedevwiki.net/index.php/UIViewAnimationState
+ (void) navigateToCreateBookForUser:(User *)loginUser animatedWithDuration:(NSTimeInterval)duration transition:(UIViewAnimationTransition)transition animationCurve:(UIViewAnimationOptions) options isFromHome:(BOOL)isFromHome;

{
    // Get Create Book View Controller
    [ROOT_NAVIGATION_CONTROLLER popToRootViewControllerAnimated:NO];
    BookSelectLanguageViewController * bookSelectLanguageView = (BookSelectLanguageViewController*)[NavigationManager getCreateBookViewController];
    
//    UIStoryboard * sb = [UIStoryboard storyboardWithName:@"Book" bundle:nil];
//    UINavigationController * nc = [sb instantiateInitialViewController];
//    [nc popToRootViewControllerAnimated:NO];
//    BookSelectLanguageViewController * bookSelectLanguageView = ((BookSelectLanguageViewController*)[nc.viewControllers objectAtIndex:0]);
    bookSelectLanguageView.wizardDataObject = nil;
    bookSelectLanguageView.loginUser = loginUser;
    bookSelectLanguageView.isFromHome = isFromHome;
    
//    bookSelectLanguageView.modalTransitionStyle = transition;
//    bookSelectLanguageView.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [ROOT_NAVIGATION_CONTROLLER pushViewController:bookSelectLanguageView animated:NO];
    
    [UIView animateWithDuration:duration delay:0.0f options:options animations:^{
        [UIView setAnimationTransition:transition forView:ROOT_NAVIGATION_CONTROLLER.view cache:YES];
    }
                     completion:^(BOOL finished){
                         if ([BROWSE_BOOKS_ROOT_VIEW_CONTROLLER respondsToSelector:@selector(transitionAnimationFinished)])
                         {
                             [(id<NavigationManagerDelegate>)BROWSE_BOOKS_ROOT_VIEW_CONTROLLER transitionAnimationFinished];
                         }
                     }];
//    [HOME_VIEW_CONTROLLER presentViewController:nc animated:animated completion:^{}];
}

// ============================================================================================================================================================
// Go to About / Tour section view
+ (void) navigateToAbout
{
    [ROOT_NAVIGATION_CONTROLLER popToRootViewControllerAnimated:NO];
    [ROOT_NAVIGATION_CONTROLLER pushViewController:[NavigationManager getAboutSectionViewController] animated:NO];
}

// ============================================================================================================================================================
// Go to About / Tour section view with animation. iOS supports animations 0-7, 101-117. http://iphonedevwiki.net/index.php/UIViewAnimationState
+ (void) navigateToAboutAnimatedWithDuration:(NSTimeInterval)duration transition:(UIViewAnimationTransition)transition animationCurve:(UIViewAnimationOptions) options
{
    // duration = 0.75F;
    
    [ROOT_NAVIGATION_CONTROLLER popToRootViewControllerAnimated:NO];
    [ROOT_NAVIGATION_CONTROLLER pushViewController:[NavigationManager getAboutSectionViewController] animated:NO];
    [UIView animateWithDuration:duration delay:0.0f options:options
                     animations:
     ^{
         [UIView setAnimationTransition:transition forView:ROOT_NAVIGATION_CONTROLLER.view cache:YES];
     }
    completion:^(BOOL finished)
     {
         if ([BROWSE_BOOKS_ROOT_VIEW_CONTROLLER respondsToSelector:@selector(transitionAnimationFinished)])
         {
             [(id<NavigationManagerDelegate>)BROWSE_BOOKS_ROOT_VIEW_CONTROLLER transitionAnimationFinished];
         }
     }
     ];
}

// ============================================================================================================================================================
// Read book
+ (void) openReadBookViewController:(Book *)book parentViewController:(UIViewController *) parent
{
    UIStoryboard * myLibraryStoryboard = [UIStoryboard storyboardWithName:@"Read Book" bundle:[NSBundle mainBundle]];
   // ReadBookCoverPageViewController * vc = [myLibraryStoryboard instantiateViewControllerWithIdentifier:@"Read Book - Title Page View controller"];
  //  UINavigationController * nc = [myLibraryStoryboard instantiateViewControllerWithIdentifier:@"Read Book Navigation Controller"];
   // [nc pushViewController:vc animated:NO];
    ReadBookManagerViewController * vc = [myLibraryStoryboard instantiateViewControllerWithIdentifier:@"Read Book Manager View Controller"];
    

    vc.book = book;
//    Read Book Navigation Controller
  //  vc.book = book;
    vc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [parent presentViewController:vc animated:YES completion:^{}];
}
@end
