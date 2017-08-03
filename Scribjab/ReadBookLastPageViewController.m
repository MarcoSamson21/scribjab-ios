//
//  ReadBookLastPageViewController.m
//  Scribjab
//
//  Created by Oleg Titov on 13-01-03.
//
//

#import "ReadBookLastPageViewController.h"
#import "BookManager.h"
#import "UIColor+HexString.h"
#import <QuartzCore/QuartzCore.h>
#import "ReadBookCommentsViewController.h"
#import "NavigationManager.h"

// Google Analytics includes
#import "GAI.h"
#import "GAIFields.h"
#import "GAITracker.h"
#import "GAIDictionaryBuilder.h"

@interface ReadBookLastPageViewController ()
{
    UIPopoverController * _popCommentsController;
}

@end

// **************************************************************************************************************************************
// **************************************************************************************************************************************

@implementation ReadBookLastPageViewController

@synthesize pageManager;

// ======================================================================================================================================
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{ 
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.bookTitle1Label.text = pageManager.book.title1;
    self.bookTitle2Label.text = pageManager.book.title2;
    
    //add a border background view.
    UIView * bgView = [[UIView alloc] initWithFrame:CGRectMake(self.image.frame.origin.x-1.0f, self.image.frame.origin.y-1.0f, self.image.frame.size.width + 2.0f, self.image.frame.size.height+2.0f)];
    bgView.backgroundColor = [UIColor blackColor];
    bgView.layer.cornerRadius = 9.0;
    bgView.layer.masksToBounds = YES;
    [self.view addSubview:bgView];
    [self.view bringSubviewToFront:self.image];
    
    // Add image
    UIImage * img = [UIImage imageWithContentsOfFile:[BookManager getBookItemAbsPath:pageManager.book fileName:BOOK_PAGE_IMAGE_FILENAME]];
    self.image.image = img;
    self.image.backgroundColor = [UIColor colorWithHexString:pageManager.book.backgroundColorCode];
    self.image.layer.cornerRadius = 9.0F;
    self.image.layer.masksToBounds = YES;
    
    
    // --- Send Google Analytics Data ----------
    
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    
    // This screen name value will remain set on the tracker and sent with hits until it is set to a new value or to nil.
    NSString * screenName = [NSString stringWithFormat:@"%@ (%@ class)", @"Read Book (Last Page) Screen", [self class]];
    [tracker set:kGAIScreenName value:screenName];
    
    // Book Title Dimension
    NSString * bookTitleDimentionValue = [NSString stringWithFormat:@"%@ | %@", pageManager.book.title1, pageManager.book.title2];
    [tracker set:[GAIFields customDimensionForIndex:1] value:bookTitleDimentionValue];
    
    // Book ID
    NSString * bookIdDimentionValue = pageManager.book.remoteId.stringValue;
    [tracker set:[GAIFields customDimensionForIndex:2] value:bookIdDimentionValue];
    
    // Send the screen view.
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];

    // Clear custom dimentions
    [tracker set:[GAIFields customDimensionForIndex:1] value:nil];
    [tracker set:[GAIFields customDimensionForIndex:2] value:nil];
    [tracker set:[GAIFields customDimensionForIndex:3] value:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}
// ======================================================================================================================================
- (IBAction)readAgain:(id)sender
{
    [self.pageManager flipToCoverPage];
}
// ======================================================================================================================================
- (IBAction)closeBook:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}
// ======================================================================================================================================
- (IBAction)navigateHome:(id)sender
{
    
    [NavigationManager navigateToHome];
    [self dismissViewControllerAnimated:YES completion:^{}];
}

// ======================================================================================================================================
- (IBAction)openCommentsView:(id)sender
{
    ReadBookCommentsViewController * commentsView = [self.storyboard instantiateViewControllerWithIdentifier:@"Read Book - Comments View Controller"];
    commentsView.book = pageManager.book;
    
    commentsView.modalPresentationStyle = UIModalPresentationPageSheet;
    commentsView.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:commentsView animated:YES completion:^{
        
    }];
   // _popCommentsController = [[UIPopoverController alloc] initWithContentViewController:commentsView];
  //  [_popCommentsController presentPopoverFromRect:self.bookTitle1Label.bounds inView:self.bookTitle1Label permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

// ======================================================================================================================================

- (void)viewDidUnload {
    [self setImage:nil];
    [super viewDidUnload];
}
@end
