//
//  ReadBookManagerViewController.m
//  Scribjab
//
//  Created by Oleg Titov on 12-12-20.
//
//

#import "ReadBookManagerViewController.h"
#import "ReadBookCoverPageViewController.h"
#import "ReadPageViewController.h"
#import "ReadBookLastPageViewController.h"

@interface ReadBookManagerViewController () <UIGestureRecognizerDelegate>
{
    NSMutableArray * _bookPageViewControllers;
    ReadBookLastPageViewController * _lastPageViewController;
    UIViewController * _currentViewController;
    BOOL _pageFlipInProgress;       // for iOS6 bug with page controller
}

- (void) changePageViewControllerGestureRecognizerDelegateToSelf;
@end

// **************************************************************************************************************************************
// **************************************************************************************************************************************

@implementation ReadBookManagerViewController


@synthesize book = _book;
@synthesize pageViewController = _pageViewController;

// ======================================================================================================================================
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// ======================================================================================================================================
// Initialize the controller.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (_book == nil)
        return;
    
    
    // initialize Page View Controller
    
    NSDictionary *options =
    [NSDictionary dictionaryWithObject:
     [NSNumber numberWithInteger:UIPageViewControllerSpineLocationNone]
                                forKey: UIPageViewControllerOptionSpineLocationKey];
    
    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStylePageCurl navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:options];
    
    self.pageViewController.dataSource = self;
    self.pageViewController.delegate = self;
    [self.pageViewController.view setFrame:self.view.frame];
    
    // ----------------------------
    // Initialize the first view - book cover page
    ReadBookCoverPageViewController * coverPageView = [self.storyboard instantiateViewControllerWithIdentifier:@"Read Book - Title Page View controller"];
    _currentViewController = coverPageView;
    coverPageView.book = _book;
    
    // Initialize the last view - book last page
    _lastPageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"Read Book - Last Page View Controller"];
    _lastPageViewController.pageManager = self;
    
    // ----------------------------
    // Sort book's pages
    NSSortDescriptor * sortOrderAsc =[NSSortDescriptor sortDescriptorWithKey:@"sortOrder" ascending:YES];
    NSArray * sortDescriptors = [NSArray arrayWithObject:sortOrderAsc];
    NSArray * pagesArray  = [[_book.pages array] sortedArrayUsingDescriptors:sortDescriptors];
    
    if([pagesArray count]!=0)
        _book.pages = [NSOrderedSet orderedSetWithArray:pagesArray];

    // ---------------------------
    // Initialize dataSource lookup array
    _bookPageViewControllers = [[NSMutableArray alloc] initWithCapacity:_book.pages.count+1];       // cover page + number of pages
    [_bookPageViewControllers addObject:coverPageView];
    
    // Continue with page view
    NSArray * viewControllers = [NSArray arrayWithObject:coverPageView];
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:^(BOOL finished) {}];
    
    [self addChildViewController:self.pageViewController];
    [self.view addSubview:[self.pageViewController view]];
    [self.pageViewController didMoveToParentViewController:self];
    
    [self changePageViewControllerGestureRecognizerDelegateToSelf];
}

// ======================================================================================================================================
// Check if gesture should be recognized.
// This is done to fix menu button whose gesture recognizer
// is overridden by UIPageViewController by default.
- (void) changePageViewControllerGestureRecognizerDelegateToSelf
{
    UIGestureRecognizer* tapRecognizer = nil;
    
    for (UIGestureRecognizer* recognizer in self.pageViewController.gestureRecognizers)
    {
        if ( [recognizer isKindOfClass:[UITapGestureRecognizer class]] )
        {
            tapRecognizer = recognizer;
            break;
        }
    }
    
    if (tapRecognizer != nil)
    {
        tapRecognizer.delegate = self;
        //[self.pageViewController.view removeGestureRecognizer:tapRecognizer];
    }
}

// ======================================================================================================================================
// ======================================================================================================================================
#pragma mark UIGestureRecognizerDelegate DataSource implementation

// Make sure that controlls on the inside view respond to their gesture recognisers on their own and event doesn't bubble up to the parent view.
// This is done to fix menu button whose gesture recognizer is overridden by UIPageViewController by default.
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view isKindOfClass:[UIButton class]] || touch.view.tag == 8008)
    {
        return NO;
    }
       
    return YES;
}

// ======================================================================================================================================
// Prevent tap gestures for cover and last pages. Tap at page edges causes pageController to flip pages,
// but in iOS 6 if you reachecd the last/first page and return nil in these methods, app crashes:
// pageViewController:viewControllerAfterViewController: and pageViewController:viewControllerBeforeViewController:
// More Info: http://stackoverflow.com/questions/8400870/uipageviewcontroller-return-the-current-visible-view
// http://stackoverflow.com/questions/12565400/uipageviewcontroller-in-ios6
-(BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    // this if statement and variable is yet another protection. If user clicks too fast on a page's egde while the page is flipping,
    // then this method thinks that _currentViewController is still the old page, whicle it has already changed to the new page internally.
    
    if (_pageFlipInProgress)
        return NO;
    _pageFlipInProgress = YES;
    
    
    CGPoint p = [gestureRecognizer locationInView:_currentViewController.view];
    float midX = _currentViewController.view.bounds.size.width / 2.0f;
    
    // Cover page?
    if ([_currentViewController isKindOfClass:[ReadBookCoverPageViewController class]])
    {
        if (p.x < midX)
        {
            _pageFlipInProgress = NO;
            return NO;
        }
    }
    
    // Last Page?
    if ([_currentViewController isKindOfClass:[ReadBookLastPageViewController class]])
    {
        if (p.x > midX)
        {
            _pageFlipInProgress = NO;
            return NO;
        }
    }
    
   //  NSLog(@"p=[%f,%f], mid=[%f,%f], %@", p.x,p.y, _currentViewController.view.bounds.size.width/2.0f, _currentViewController.view.bounds.size.height/2.0f, [_currentViewController class]);
    return YES;
}

// ======================================================================================================================================
// Keep trck of the current page
-(void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
   //	 NSLog(@"finished %d, completed %d", finished, completed);
    if (completed)
    {
        _currentViewController = [self.pageViewController.viewControllers objectAtIndex:0];
        _pageFlipInProgress = NO;
    }
}

// ======================================================================================================================================
// ======================================================================================================================================
#pragma mark UIPageViewController DataSource implementation

// ======================================================================================================================================
// Get or create a ViewController for the next page
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    [self changePageViewControllerGestureRecognizerDelegateToSelf];

    // is it a cover page view?
    if ([viewController isKindOfClass:[ReadBookCoverPageViewController class]])
    {
        if (_book.pages.count == 0)
            return _lastPageViewController;
        
        // Is ViewController not yet created?
        if (_bookPageViewControllers.count == 1)
        {
            ReadPageViewController * readView = [viewController.storyboard instantiateViewControllerWithIdentifier:@"Read Book - Regular Page View controller"];
            readView.page = [_book.pages objectAtIndex:0];
            [_bookPageViewControllers addObject:readView];
        }
        
        [((ReadBookCoverPageViewController*)viewController) stopAllSoundPlayback];  // If page is currently playing the sound - stop before going to the next page
        
        ReadPageViewController * rpvc = [_bookPageViewControllers objectAtIndex:1];
        [rpvc setMenuHidden:((ReadBookCoverPageViewController*)viewController).isMenuHidden];
        return rpvc;
    }

    // is it a regular page view?
    if ([viewController isKindOfClass:[ReadPageViewController class]])
    {
        BookPage * page = ((ReadPageViewController *) viewController).page;
        int index = [_book.pages indexOfObject:page];
        
        if (index == NSNotFound)
            return nil;
       
        if (_book.pages.count - 1 == index)
            return _lastPageViewController;
                
        // Is ViewController not yet created? Next page shouw be at: index + 1 (next page) + 1 (book's cover page)
        if (_bookPageViewControllers.count - 2 <= index)
        {
            ReadPageViewController * readView = [viewController.storyboard instantiateViewControllerWithIdentifier:@"Read Book - Regular Page View controller"];
            readView.page = [_book.pages objectAtIndex:index + 1];
            [_bookPageViewControllers addObject:readView];
        }
              
        [((ReadPageViewController*)viewController) stopAllSoundPlayback];   // If page is currently playing the sound - stop before going to the next page
        
        ReadPageViewController * rpvc = [_bookPageViewControllers objectAtIndex:index+2];
        [rpvc setMenuHidden:((ReadPageViewController*)viewController).isMenuHidden];
        return rpvc;
    }
  
    return nil;
}

// ======================================================================================================================================
// Get a ViewController for the previous page
-(UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    // is it a cover page view?
    if ([viewController isKindOfClass:[ReadBookCoverPageViewController class]])
    {
        return nil;
    }
    
    // is it a regular page view?
    if ([viewController isKindOfClass:[ReadPageViewController class]])
    {
        BookPage * page = ((ReadPageViewController *) viewController).page;
        int index = [_book.pages indexOfObject:page];
        
        if (index == NSNotFound)
            return nil;
        
        [((ReadPageViewController*)viewController) stopAllSoundPlayback];   // If page is currently playing the sound - stop before going to the next page
        
        BOOL hideMenu = ((ReadPageViewController*)viewController).isMenuHidden;

        UIViewController * rpvc = [_bookPageViewControllers objectAtIndex:index];       // page is stored at index: index + 1. The first item is always the book cover page
        
        if ([rpvc isKindOfClass:[ReadPageViewController class]])
            [((ReadPageViewController*)rpvc) setMenuHidden:hideMenu];
        else
            [((ReadBookCoverPageViewController*)rpvc) setMenuHidden:hideMenu];
        
        return rpvc;
    }
    
    // Is it the "last page view"?
    if ([viewController isKindOfClass:[ReadBookLastPageViewController class]])
    {
        return [_bookPageViewControllers objectAtIndex:_book.pages.count];
    }
    
    return nil;
}



// ======================================================================================================================================
// Navigate the user to the first page of the book.
-(void) flipToCoverPage
{
    if (_bookPageViewControllers.count == 0)
        return;
    
    _pageFlipInProgress = YES;
    
  //  id __weak weakself = self;  // this is done to prevent 'retain' cycle in block methods.
    //__weak ReadBookManagerViewController * weakself = self;
    
    NSArray * viewControllers = [NSArray arrayWithObject:[_bookPageViewControllers objectAtIndex:0]];
    
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionReverse animated:YES completion:^(BOOL finished) {
        if (finished)
        {
           // _pageFlipInProgress = NO;
//            ((ReadBookManagerViewController * )weakself)->_pageFlipInProgress = NO;
        }
    }];
}

@end
