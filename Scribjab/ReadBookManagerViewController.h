//
//  ReadBookManagerViewController.h
//  Scribjab
//
//  Created by Oleg Titov on 12-12-20.
//
//

#import <UIKit/UIKit.h>
#import "Book.h"

static float const ROUNDED_CORNER_RADIUS = 9.0F;

@interface ReadBookManagerViewController : UIViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (nonatomic, strong) Book * book;
@property (nonatomic, strong) UIPageViewController * pageViewController;

- (void) flipToCoverPage;

@end
