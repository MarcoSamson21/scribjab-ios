//
//  BrowseBooksViewController.h
//  Scribjab
//
//  Created by Oleg Titov on 12-11-23.
//
//

#import <UIKit/UIKit.h>
#import "BooksHorizontalScrollView.h"
#import "NavigationManager.h"

// **************************************************************************************************************************************
// **************************************************************************************************************************************

@interface BrowseBooksViewController : UIViewController <NavigationManagerDelegate>

@property (strong, nonatomic) IBOutlet BooksHorizontalScrollView *recentlyPublishedScrollView;
@property (strong, nonatomic) IBOutlet BooksHorizontalScrollView *mostPopularScrollView;
@property (strong, nonatomic) IBOutlet BooksHorizontalScrollView *downloadedBooksScrollView;
@property (strong, nonatomic) IBOutlet UIScrollView *parentScrollView;
- (IBAction)navigateToHomeView:(id)sender;

@end
