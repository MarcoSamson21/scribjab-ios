//
//  BookViewController.m
//  Scribjab
//
//  Created by Gladys Tang on 12-10-03.
//
//

#import "BookViewController.h"
#import "Book.h"
#import "BookPage.h"
#import "BookManager.h"
#import "CreateBookNavigationManager.h"
#import "CellInBookPageScrollView.h"

#import "BookDrawViewController.h"
#import "BookPageDrawViewController.h"
#import "PublishBookViewController.h"

#import "UIColor+HexString.h"
#import "NavigationManager.h"

// Google Analytics includes
#import "GAI.h"
#import "GAIFields.h"
#import "GAITracker.h"
#import "GAIDictionaryBuilder.h"

#import <MobileCoreServices/MobileCoreServices.h>

@interface BookViewController ()
{
    Book *currentBook;
    BookPage *pageToBeDeleted;
//    int deletePageCellTag;
    id bookItemInPageView;

    CGPoint _priorPoint;
    BOOL didLoad;
    EditTitlePageViewController *titlePageViewController;
    EditBookPageViewController *bookPageViewController;
    
    BOOL publishConfimedByUser;
    
    BookPage* currentPage;
}
- (void) setupWithTitlePage:(BOOL)isLoadingTitlePage;
- (void) highlightTheCell;
- (void) updateImage;
- (void) deletePage:(NSTimer *)timer;
- (void) displayPage:(NSTimer *)timer;
@end

@implementation BookViewController

static int const DELETE_PAGE_ALERT_VIEW = 1;
static int const PUBLISH_CONFIRM_ALERT_VIEW = 2;
static int const DUPLICATE_PAGE_ALERT_VIEW = 3;

static int const FRONT_PAGE_TAG = 0;

static int const YES_BUTTON_INDEX = 1;
static int const NO_BUTTON_INDEX = 0;
static int const PUBLISH_BUTTON_INDEX = 1;

static CGFloat const PAGE_MOVE_ANIMATION_DURATION = 1.0;
static int const MAX_PAGE = 20;


@synthesize pageScrollView = _pageScrollView;
@synthesize pageView = _pageView;
@synthesize addPageButton = _addPageButton;
@synthesize saveAndCloseButton = _saveAndCloseButton;
@synthesize publishButton = _publishButton;
@synthesize wizardDataObject = _wizardDataObject;

//- (BOOL) isTestEmpty:(NSString *)text
//{
//    if (text == nil)
//        return TRUE;
//
//    NSString *temp = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//    if (temp == nil ||  [temp isEqualToString:@""]==TRUE)
//        return TRUE;
//    
//    return FALSE;    
//}

//for testing
//- (void)printAllCell
//{
//    //update thumbnail for scrollview
//    for(UIView *subview in [self.pageScrollView subviews])
//    {
//        if([subview isKindOfClass:[CellInBookPageScrollView class]])
//        {
//            CellInBookPageScrollView * cv = (CellInBookPageScrollView *)subview;
//            id bItem = [cv getBookItem];
//            if([bItem isKindOfClass:[Book class]])
//                NSLog(@"front cell tag: %d.", cv.tag);
//            else
//                NSLog(@"tag: %d, book: %@, order: %d", cv.tag, ((BookPage *)bItem).text1, [((BookPage *)bItem).sortOrder intValue]);
//        }
//    }
//}

- (IBAction)publishBook:(id)sender
{
    BOOL isGoToPublish = TRUE;
    NSString * requiredField = NSLocalizedString(@"You are missing the following items:\r",@"List the valiation errors for publish");
    
    //for validate if all the fields are valid.
    
    //book title 1
    NSString * messageText = NSLocalizedString(@"Title in ", @"Validation text for book title when create/publish a book.");
    if (currentBook.title1 == nil ||  [[currentBook.title1 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]==TRUE )
    {
        isGoToPublish = FALSE;
 
        requiredField = [requiredField stringByAppendingFormat:@"%@%@\r",messageText , currentBook.primaryLanguage.nameEnglish];
    }
    
    //book title 2
    if (currentBook.title2 == nil ||  [[currentBook.title2 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]==TRUE )
    {
        isGoToPublish = FALSE;
        requiredField = [requiredField stringByAppendingFormat:@"%@%@\r",messageText , currentBook.secondaryLanguage.nameEnglish];
    }
    
//    NSString * messageText1 = NSLocalizedString(@"Description in ", @"Validation text for book description when publishing a book.");
//    //book description 1
//    if (currentBook.description1 == nil || [[currentBook.description1 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]==TRUE)
//    {
//        isGoToPublish = FALSE;
//        requiredField = [requiredField stringByAppendingFormat:@"%@%@\r",messageText1, currentBook.primaryLanguage.nameEnglish];
//    }
//
//    //book description 2
//    if (currentBook.description2 == nil || [[currentBook.description2 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]==TRUE)
//    {
//        isGoToPublish = FALSE;
//        requiredField = [requiredField stringByAppendingFormat:@"%@%@\r",messageText1, currentBook.secondaryLanguage.nameEnglish];
//    }
    
    //book title image.
    NSString * messageText2 = NSLocalizedString(@"Image for title page.", @"Validation text for image in title page when publishing a book.");
    if(![[NSFileManager defaultManager] fileExistsAtPath:[BookManager getBookItemAbsPath:currentBook fileName:BOOK_IMAGE_FILENAME]])
    {
        isGoToPublish = FALSE;
        requiredField = [requiredField stringByAppendingFormat:@"%@\r", messageText2];
    }
    
    NSString * messageText3 = NSLocalizedString(@"Book requires at least one page.", @"Validation text for min one page when publishing a book.");
    if([currentBook.pages count]==0)
    {
        requiredField = [requiredField stringByAppendingFormat:@"%@\r", messageText3];
        isGoToPublish = FALSE;
    }
    else
    {
        //check pages.
        for(BookPage *bp in currentBook.pages)
        {
            NSString * messageText4 = NSLocalizedString(@"Page ", @"Part 1 of validation text for book page when publishing a book.");
            NSString * messageText5 = NSLocalizedString(@" (text in ", @"Part 2 of validation text for book page when publishing a book.");
            NSString * messageText5a = NSLocalizedString(@")", @"Part 3 of validation text for book page when publishing a book.");
            //text 1
            if (bp.text1 == nil || [[bp.text1 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]==TRUE)
            {
                isGoToPublish = FALSE;
                requiredField = [requiredField stringByAppendingFormat:@"%@%d%@%@%@\r",messageText4, bp.sortOrder.intValue, messageText5, bp.book.primaryLanguage.nameEnglish, messageText5a];
            }

            //text 2
            if (bp.text2 == nil || [[bp.text2 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]==TRUE)
            {
                isGoToPublish = FALSE;
                requiredField = [requiredField stringByAppendingFormat:@"%@%d%@%@%@\r",messageText4, bp.sortOrder.intValue, messageText5, bp.book.secondaryLanguage.nameEnglish, messageText5a];
            }
            
            //page image
            NSString * messageText6 = NSLocalizedString(@"Image for page ", @"Validation text for image in title page when publishing a book.");
            if(![[NSFileManager defaultManager] fileExistsAtPath:[BookManager getBookItemAbsPath:bp fileName:BOOK_IMAGE_FILENAME]])
            {
                isGoToPublish = FALSE;
                requiredField = [requiredField stringByAppendingFormat:@"%@%d\r" , messageText6, bp.sortOrder.intValue];
            }
        }
    }
    
    if(isGoToPublish)
    {
        if (publishConfimedByUser)          // Publish only if the user has agreed to publish after the message box notification.
        {
            publishConfimedByUser = NO;
            self.wizardDataObject = currentBook;
            [CreateBookNavigationManager navigateToPublishViewControllerAnimatedWithDuration:0 transition:5 animationCurve:UIViewAnimationCurveEaseInOut book:currentBook];
        }
        else                                // Alert user that no further changrs will be allowed after the book is published
        {
            NSString * title = NSLocalizedString(@"Are you sure you want to publish?", @"Alert box title: Confirm that after publishing the book won't be editable");
            NSString * body = NSLocalizedString(@"If you publish, you will not be able to make changes.\nYou can save and edit your book later if you select the \"save & close\" button.", @"Alert box body: Confirm that after publishing the book won't be editable");
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:title
                                                             message:body
                                                            delegate:self
                                                   cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel button label")
                                                   otherButtonTitles:NSLocalizedString(@"Publish", @"Publish button label"), nil];
            alert.tag = PUBLISH_CONFIRM_ALERT_VIEW;
            [alert show];
        }
    }
    else
    {
        NSString * errorTitle = NSLocalizedString(@"Your book can not be published", @"Alert box title: Some fields are required");
        NSString * errorBody = requiredField;
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:errorTitle message:errorBody delegate:self cancelButtonTitle:NSLocalizedString(@"OK", @"OK button label") otherButtonTitles: nil];
        [alert show];
    }
}

- (void) moveAddPageButton
{
//    NSLog(@" contentsize: %f",self.pageScrollView.contentSize.width);
//    NSLog(@"view x, width: %f, %f", self.pageScrollView.frame.origin.x , self.pageScrollView.frame.size.width);
//    NSLog(@"page x: %f",self.addPageButton.frame.origin.x);
    //change the frame size.
    if(self.pageScrollView.contentSize.width >= 820)
    {
        self.addPageButton.frame = CGRectMake(843 , self.addPageButton.frame.origin.y, self.addPageButton.frame.size.width, self.addPageButton.frame.size.height);
        self.pageScrollView.frame = CGRectMake(self.pageScrollView.frame.origin.x
                                           , self.pageScrollView.frame.origin.y, 825, self.pageScrollView.frame.size.height);
    }
    else
    {
        self.pageScrollView.frame = CGRectMake(self.pageScrollView.frame.origin.x
                                               , self.pageScrollView.frame.origin.y, self.pageScrollView.contentSize.width + 5, self.pageScrollView.frame.size.height);
        self.addPageButton.frame = CGRectMake(self.pageScrollView.frame.origin.x + self.pageScrollView.contentSize.width, self.addPageButton.frame.origin.y, self.addPageButton.frame.size.width, self.addPageButton.frame.size.height);
    }
}

//Save and close, save and go back to mylibrary.
- (IBAction)saveAndClose:(id)sender
{
    [BookManager saveBook:currentBook];
    [NavigationManager navigateToMyLibraryForUser:currentBook.author animatedWithDuration:0.75 transition:5 animationCurve:UIViewAnimationOptionCurveEaseInOut];
//    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
//    [self dismissModalViewControllerAnimated:YES];
}


//Go to draw page.
-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Edit Book - Proceed to title page draw"])
    {
        ((BookDrawViewController *)segue.destinationViewController).wizardDataObject = self.wizardDataObject;
    }
    if ([segue.identifier isEqualToString:@"Edit Book Page - Proceed to page draw"])
    {
        ((BookPageDrawViewController *)segue.destinationViewController).wizardDataObject = self.wizardDataObject;
    }
    if ([segue.identifier isEqualToString:@"Publish Book"])
    {
        ((PublishBookViewController *)segue.destinationViewController).book = currentBook;
    }
}

//update image after draw title page or book page.
- (void) updateImage
{
    //update page view. 
    for(UIView *editTitlePageview in [self.pageView subviews])
    {
        for(UIView * subview in [editTitlePageview subviews])
        {
            if([subview isKindOfClass:[UIImageView class]])
            {
                UIImageView * aImageView = (UIImageView *)subview;
                if([bookItemInPageView isKindOfClass:[Book class]])
                {
                    aImageView.image = [UIImage imageWithContentsOfFile:[BookManager getBookItemAbsPath:(Book *)bookItemInPageView fileName:BOOK_IMAGE_FILENAME]];
                    aImageView.backgroundColor = [UIColor colorWithHexString:((Book *)bookItemInPageView).backgroundColorCode];
                }
                if([bookItemInPageView isKindOfClass:[BookPage class]])
                {
                    aImageView.image = [UIImage imageWithContentsOfFile:[BookManager getBookItemAbsPath:(BookPage *)bookItemInPageView fileName:BOOK_PAGE_IMAGE_FILENAME]];
                    aImageView.backgroundColor = [UIColor colorWithHexString:((BookPage *)bookItemInPageView).backgroundColorCode];
                }
                self.pageView.backgroundColor = aImageView.backgroundColor;
                editTitlePageview.backgroundColor = aImageView.backgroundColor;
            }
        }
    }
    
    //update thumbnail for scrollview
    for(UIView *subview in [self.pageScrollView subviews])
    {
        if([subview isKindOfClass:[CellInBookPageScrollView class]])
        {
            CellInBookPageScrollView * cv = (CellInBookPageScrollView *)subview;
            if(cv.tag == self.pageView.tag)
            {
                [cv updateBookItem:bookItemInPageView];
            }
        }
    }
}

//highlight the selected cell.
- (void) highlightTheCell
{
    //update scrollview:
    for(UIView *subview in [self.pageScrollView subviews])
    {
        if(subview.tag == self.pageView.tag)
        {
            if([subview isKindOfClass:[CellInBookPageScrollView class]])
               [((CellInBookPageScrollView *)subview) highlightItself];
        }
        else
        {
            subview.backgroundColor = [UIColor clearColor];
            if([subview isKindOfClass:[CellInBookPageScrollView class]])
                [((CellInBookPageScrollView *)subview) unHighlightIteself];
        }
    }
}

//setup the screen with option to load title page to pageview.
- (void)setupWithTitlePage:(BOOL) isLoadingTitlePage 
{
    self.pageView.layer.cornerRadius = 9.0;
    self.pageView.layer.masksToBounds = YES;
    
    //editing an existing book.
    if([self.wizardDataObject isKindOfClass:[Book class]])
    {
        currentBook = (Book *)self.wizardDataObject;
    }
    if([self.wizardDataObject isKindOfClass:[BookPage class]])
    {
        currentBook = ((BookPage *)self.wizardDataObject).book;
    }
    
    //creating a new book.
    if(currentBook == nil)
    {
        User *loginUser = (User *)[(NSDictionary *)self.wizardDataObject objectForKey:@"user"];
        currentBook = [BookManager getNewBookInstance:loginUser];
        
        //creating a new book and from select language view.
        if([self.wizardDataObject isKindOfClass:[NSDictionary class]])
        {
            currentBook.primaryLanguage = (Language *)[(NSDictionary *)self.wizardDataObject objectForKey:@"primaryLanaguage"];
            currentBook.secondaryLanguage = (Language *)[(NSDictionary *)self.wizardDataObject objectForKey:@"secondaryLanaguage"];
        }
    }
    int i =0;

    //remove all views before setup.
    for(UIView *subview in [self.pageScrollView subviews])
    {
        [subview removeFromSuperview];
    }
    //add the frontpage first to the collectionview.
    CellInBookPageScrollView * frontCV = (CellInBookPageScrollView *)[[CellInBookPageScrollView alloc]initWithFame:self.pageScrollView.bounds book:currentBook bookViewController:(BookViewController *)self tag:FRONT_PAGE_TAG];

    i++;
    [self.pageScrollView addSubview:frontCV];

    //add all other pages to the collectionview.
    NSOrderedSet *bookPageSet = currentBook.pages;
    
    
    for(BookPage *bookPage in bookPageSet)
    {
        CellInBookPageScrollView * pageCV = (CellInBookPageScrollView *)[[CellInBookPageScrollView alloc]initWithFame:self.pageScrollView.bounds book:bookPage bookViewController:(BookViewController *)self tag:[bookPage.sortOrder intValue]];
        pageCV.tag = [bookPage.sortOrder intValue];
        
        UILongPressGestureRecognizer *lpg = [[UILongPressGestureRecognizer alloc]
                                             initWithTarget:self action:@selector(handleLongPressForPageScrollView:)];
        
        [pageCV addGestureRecognizer:lpg];
        [self.pageScrollView addSubview:pageCV];
        i++;
    }
 
    i++;
    
    int titlePageWidth = TITLE_PAGE_IMG_VIEW_FRAME_WIDTH + IMG_VIEW_SPACE;
    int totalPageWidth = (i-2) * (PAGE_IMG_VIEW_FRAME_WIDTH + IMG_VIEW_SPACE);
    self.pageScrollView.contentSize = CGSizeMake(titlePageWidth+totalPageWidth, self.pageScrollView.frame.size.height);
    self.pageScrollView.backgroundColor = [UIColor clearColor];
    
    //set page view.
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Book" bundle:nil];
    if(titlePageViewController == nil)
        titlePageViewController = [sb instantiateViewControllerWithIdentifier:@"editTitlePageIdentifier"];
    if(bookPageViewController == nil)
        bookPageViewController = [sb instantiateViewControllerWithIdentifier:@"editBookPageIdentifier"];
    
    [self addChildViewController:titlePageViewController];
    [self addChildViewController:bookPageViewController];
    titlePageViewController.wizardDataObject = currentBook;

    //display title page by default, otherwise, stay on what the previous book page are.
    if([self.wizardDataObject isKindOfClass:[BookPage class]])
    {
        [NSTimer scheduledTimerWithTimeInterval:0.0
                                         target:self
                                       selector:@selector(displayPage:)
                                       userInfo:self.wizardDataObject
                                        repeats:NO];
    }
    else
    {
    if(isLoadingTitlePage)
    {
        for(UIView *subview in [self.pageView subviews])
        {
            [subview removeFromSuperview];
        }
        self.pageView.tag = FRONT_PAGE_TAG;
        [self.pageView addSubview:titlePageViewController.view];
        [frontCV highlightItself];
    }
    }
    [self moveAddPageButton];
}

//long press gesture.  For rearrange the book page.
- (void)handleLongPressForPageScrollView:(UILongPressGestureRecognizer *)gestureRecognizer
{
    int titlePageViewWidth = TITLE_PAGE_IMG_VIEW_FRAME_WIDTH + IMG_VIEW_SPACE;
    int aPageViewWidth = PAGE_IMG_VIEW_FRAME_WIDTH + IMG_VIEW_SPACE;

    CellInBookPageScrollView *tapView = (CellInBookPageScrollView *)gestureRecognizer.view;
    CGPoint point = [gestureRecognizer locationInView:tapView.superview];
    CGPoint center = tapView.center;
    if(gestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
//        NSLog(@"begin,Height: %f", self.pageScrollView.frame.size.height);
        [NSTimer scheduledTimerWithTimeInterval:0.2
                                         target:self
                                       selector:@selector(displayPage:)
                                       userInfo:[tapView getBookItem]
                                        repeats:NO];
        [self changePageScrollHeight:50];
    }
    else if(gestureRecognizer.state == UIGestureRecognizerStateChanged)
    {
//        self.pageScrollView.backgroundColor = [UIColor yellowColor];
        
        [tapView.superview bringSubviewToFront:tapView];
        center.x += point.x - _priorPoint.x;
        center.y += point.y - _priorPoint.y;
//        NSLog(@"%f, %f", center.x, center.y);
        //move left and across first page.
        //center of a page should be 178/2 = 89
        int minX = titlePageViewWidth + (aPageViewWidth/2);
        int cX = aPageViewWidth/2;
//        NSLog(@"Min: %d, Max: %d",minX, cX);
        if(center.x <  minX)
            center.x = minX;
        if(center.x > self.pageScrollView.contentSize.width-cX)
            center.x = self.pageScrollView.contentSize.width-cX;
        tapView.center = center;        
//        [self.pageScrollView scrollRectToVisible:CGRectMake(center.x-minX, center.y, self.pageScrollView.frame.size.width, self.pageScrollView.frame.size.height) animated:YES];
        [self.pageScrollView scrollRectToVisible:CGRectMake(center.x-minX, center.y, self.pageScrollView.frame.size.width, self.pageScrollView.frame.size.height) animated:YES];
    }
    else if(gestureRecognizer.state == UIGestureRecognizerStateEnded)
    {
        [self changePageScrollHeight:-50];

        //reset the point of the dragged page.
        int draggedCenterX = tapView.center.x;
        int selectedIndex = tapView.tag;
        float m = draggedCenterX - titlePageViewWidth;
 //       NSLog(@"m: %f, x: %d, titlePageView: %d", m, draggedCenterX, titlePageViewWidth);
        int newIndex = ceil(m/aPageViewWidth);
 
        center.x = titlePageViewWidth + (newIndex * aPageViewWidth) + (aPageViewWidth/2);
        tapView.center = center;
        tapView.tag = newIndex;
        //change book tag.
        //loop through the array
        
        if(newIndex != selectedIndex)
        {
        NSOrderedSet *bookPages = currentBook.pages;

        for(BookPage *bp in bookPages)
        {
            int pageIndex = [bp.sortOrder intValue];
            
            if(pageIndex == selectedIndex)
            {
                bp.sortOrder = [NSNumber numberWithInt:newIndex];
//                NSLog(@"dragged page: %d, %d, new, %d",[bp.sortOrder intValue], selectedIndex, newIndex);
                [BookManager saveBookPage:bp];
            }
            else if(selectedIndex < newIndex && pageIndex > selectedIndex && pageIndex <= newIndex)
            {
                bp.sortOrder = [NSNumber numberWithInt:[bp.sortOrder intValue] - 1];
//                NSLog(@"other page: %d, new, %d", [bp.sortOrder intValue], newIndex);
                [BookManager saveBookPage:bp];
            }
            else if(selectedIndex > newIndex && pageIndex < selectedIndex && pageIndex >= newIndex)
            {
                bp.sortOrder = [NSNumber numberWithInt:[bp.sortOrder intValue] + 1];
//                NSLog(@"less page: %d, %d, new, %d",[bp.sortOrder intValue], selectedIndex, newIndex);
                [BookManager saveBookPage:bp];
            }
        }
//            NSLog(@"end================");
//            [self printAllCell];
        }
        
        self.wizardDataObject = currentBook;
        tapView.backgroundColor = [UIColor clearColor];
        [self setupWithTitlePage:FALSE];  //will set up the tag.
        self.pageView.tag = newIndex;
        [self highlightTheCell];
    }
    _priorPoint = point;
}

- (void)changePageScrollHeight:(int)height
{
    self.pageScrollView.frame = CGRectMake(self.pageScrollView.frame.origin.x, self.pageScrollView.frame.origin.y - height, self.pageScrollView.frame.size.width, self.pageScrollView.frame.size.height + height);
    for(UIView * view in [self.pageScrollView subviews])
    {
        if([view isKindOfClass:[CellInBookPageScrollView class]])
        {
            view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y + height, view.frame.size.width, view.frame.size.height);
        }
    }
}
//draw book image
-(void)drawBookImage:(NSTimer *)timer
{
    bookItemInPageView = (id)[timer userInfo];
    if([bookItemInPageView isKindOfClass:[Book class]])
    {
        self.wizardDataObject = bookItemInPageView;
        [CreateBookNavigationManager navigateToDrawBookViewControllerAnimatedWithDuration:0 transition:5 animationCurve:UIViewAnimationCurveEaseInOut wizardDataObject:self.wizardDataObject];
  //      [self performSegueWithIdentifier:@"Edit Book - Proceed to title page draw" sender:self];
    }
    if([bookItemInPageView isKindOfClass:[BookPage class]])
    {
        self.wizardDataObject = bookItemInPageView;
        [CreateBookNavigationManager navigateToDrawBookPageViewControllerAnimatedWithDuration:0 transition:5 animationCurve:UIViewAnimationCurveEaseInOut wizardDataObject:self.wizardDataObject];
//        [self performSegueWithIdentifier:@"Edit Book Page - Proceed to page draw" sender:self];
    }    
}

- (void)displayPage:(NSTimer *)timer
{
    bookItemInPageView = (id)[timer userInfo];
    
    [bookPageViewController reset];
    [titlePageViewController reset];    
    
    if([bookItemInPageView isKindOfClass:[Book class]])
    {
        titlePageViewController.wizardDataObject = bookItemInPageView;
        
        for(UIView *subview in [self.pageView subviews])
        {
            [subview removeFromSuperview];
        }
        self.pageView.tag = FRONT_PAGE_TAG;
        [self.pageView addSubview:titlePageViewController.view];
    }
    
    if([bookItemInPageView isKindOfClass:[BookPage class]])
    {
        bookPageViewController.wizardDataObject = bookItemInPageView;
        
        [bookPageViewController setup];
        
//        [bookPageViewController resetVideoView];
        
        for(UIView *subview in [self.pageView subviews])
        {
            [subview removeFromSuperview];
        }
        
        self.pageView.tag = [((BookPage *)bookItemInPageView).sortOrder intValue];
        [self.pageView addSubview:bookPageViewController.view];
        bookPageViewController.view.frame = self.pageView.bounds;
        currentPage = (BookPage*)bookItemInPageView;
    }
    [self highlightTheCell];
}

//=============================================================================================================================================================================================
//delete book page.
- (void) deletePage:(NSTimer *)timer
{
    pageToBeDeleted = (id)[timer userInfo];
    //    deletePageCellTag = pageToBeDeleted.sortOrder.intValue;
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Delete Page", @"Alert box for delete page")                                                     message:NSLocalizedString(@"Are you sure you want to delete this page?", @"Ask confirmation for deleting a page")
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"No", @"No")
                                          otherButtonTitles:NSLocalizedString(@"Yes", @"Yes"), nil];
    alert.tag = DELETE_PAGE_ALERT_VIEW;
    
    [alert show];
}
// ===========================
// Action after delete message box appear.
- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // -------------- DELETE PAGE ALERT -------------
    
    if (alertView.tag == DELETE_PAGE_ALERT_VIEW && buttonIndex == YES_BUTTON_INDEX)
    {
        [bookPageViewController reset];
        
        for(UIView *subview in [self.pageScrollView subviews])
        {
//            NSLog(@"subview: %d, deletePage: %d", subview.tag, [pageToBeDeleted.sortOrder intValue]);
            if(subview.tag == [pageToBeDeleted.sortOrder intValue])
            {
                [subview removeFromSuperview];
            }
            else if(subview.tag > [pageToBeDeleted.sortOrder intValue])
            {
                subview.tag = subview.tag -1;
                [((CellInBookPageScrollView *)subview) updatePageNumber];
                [UIView animateWithDuration:PAGE_MOVE_ANIMATION_DURATION delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:
                 ^{
                     subview.frame = CGRectMake(subview.frame.origin.x - subview.frame.size.width, subview.frame.origin.y, subview.frame.size.width,subview.frame.size.height);
                 } completion:^(BOOL finished){}];
            }
//            [subview removeFromSuperview];
        }
        [UIView animateWithDuration:PAGE_MOVE_ANIMATION_DURATION delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:
         ^{
             int pageWidth = PAGE_IMG_VIEW_FRAME_WIDTH + IMG_VIEW_SPACE;
             self.pageScrollView.contentSize = CGSizeMake(self.pageScrollView.contentSize.width - pageWidth, self.pageScrollView.frame.size.height);
             [self moveAddPageButton];
         } completion:^(BOOL finished){}];
        
        [BookManager deleteBookPage:pageToBeDeleted];
        self.wizardDataObject = currentBook;
        [NSTimer scheduledTimerWithTimeInterval:1.0
                                         target:self
                                       selector:@selector(displayPage:)
                                       userInfo:currentBook
                                        repeats:NO];
    
        if(self.pageScrollView.contentSize.width > self.pageScrollView.bounds.size.width)
        {
            [UIView animateWithDuration:PAGE_MOVE_ANIMATION_DURATION delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:
             ^{
                 [self.pageScrollView setContentOffset:CGPointMake(0, 0) animated:NO];
             } completion:^(BOOL finished){}];
        }
        pageToBeDeleted = nil;
    }
    
    //  -------  Duplicate the Page confirmation  ---------
    
    if (alertView.tag == DUPLICATE_PAGE_ALERT_VIEW && buttonIndex == YES_BUTTON_INDEX)
    {
//        [bookPageViewController reset];
//        [titlePageViewController reset];
        
        BookPage *oldBookPage = (BookPage*)bookPageViewController.wizardDataObject;
        
        BookPage *currentBookPage = [BookManager getNewBookPageInstance];
        currentBookPage.book = oldBookPage.book;
        currentBookPage.backgroundColorCode = oldBookPage.backgroundColorCode;
        
        NSLog(@"OldBoodPageRemoteID -- %@", oldBookPage.remoteId);
        currentBookPage.remoteId = oldBookPage.remoteId;
        currentBookPage.text1 = oldBookPage.text1;
        currentBookPage.text2 = oldBookPage.text2;
        currentBookPage.penColor = oldBookPage.penColor;
        currentBookPage.penWidth = oldBookPage.penWidth;
        currentBookPage.calligraphyColor = oldBookPage.calligraphyColor;
        currentBookPage.calligraphyWidth = oldBookPage.calligraphyWidth;
        
        currentBookPage.timeStamp = oldBookPage.timeStamp;
        
        currentBookPage.sortOrder = [NSNumber numberWithInt:(int)[currentBook.pages count]];
        
        [bookPageViewController resetVideoView];
        
        bookPageViewController.wizardDataObject = currentBookPage;
        
        UIImage *image = [UIImage imageWithContentsOfFile:[BookManager getBookItemAbsPath:oldBookPage fileName:BOOK_IMAGE_FILENAME]];
        [BookManager saveImage:image item:currentBookPage filename:(NSString *)BOOK_IMAGE_FILENAME];
        
        UIImage *thumb = [UIImage imageWithContentsOfFile:[BookManager getBookItemAbsPath:oldBookPage fileName:BOOK_THUMBNAIL_FILENAME]];
        [BookManager saveImage:thumb item:currentBookPage filename:(NSString *)BOOK_THUMBNAIL_FILENAME];
//
        self.pageView.tag = [currentBookPage.sortOrder intValue];
        
        //add 1 page in scrollpageview.
        CellInBookPageScrollView * pageCV = (CellInBookPageScrollView *)[[CellInBookPageScrollView alloc]initWithFame:self.pageScrollView.bounds book:currentBookPage bookViewController:(BookViewController *)self tag:[currentBookPage.sortOrder intValue]];
        
        pageCV.tag = [currentBookPage.sortOrder intValue];
        
        UILongPressGestureRecognizer *lpg = [[UILongPressGestureRecognizer alloc]
                                             initWithTarget:self action:@selector(handleLongPressForPageScrollView:)];
        
        [pageCV addGestureRecognizer:lpg];
        [self.pageScrollView addSubview:pageCV];
        
        
        int titlePageWidth = TITLE_PAGE_IMG_VIEW_FRAME_WIDTH + IMG_VIEW_SPACE;
        int totalPageWidth = [currentBookPage.sortOrder intValue] * (PAGE_IMG_VIEW_FRAME_WIDTH + IMG_VIEW_SPACE);
        
        self.pageScrollView.contentSize = CGSizeMake(titlePageWidth+totalPageWidth, self.pageScrollView.frame.size.height);
        [UIView animateWithDuration:PAGE_MOVE_ANIMATION_DURATION delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:
         ^{
             [self moveAddPageButton];
         } completion:^(BOOL finished){}];
        
        if(self.pageScrollView.contentSize.width > self.pageScrollView.bounds.size.width)
        {
            CGPoint bottomOffset = CGPointMake(self.pageScrollView.contentSize.width - self.pageScrollView.bounds.size.width + 5, 0);
            [UIView animateWithDuration:PAGE_MOVE_ANIMATION_DURATION delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:
             ^{
                 [self.pageScrollView setContentOffset:bottomOffset animated:NO];
             } completion:^(BOOL finished){}];
        }
        [self highlightTheCell];
        
    } //  --------   No Duplicate the page   -----------
    else if (alertView.tag == DUPLICATE_PAGE_ALERT_VIEW && buttonIndex == NO_BUTTON_INDEX)
    {
//        [bookPageViewController reset];
//        [titlePageViewController reset];
        [self duplicateNoaction];
    }
    
    // ----- PUBLISH CONFIRMATION --------
    
    if (alertView.tag == PUBLISH_CONFIRM_ALERT_VIEW && buttonIndex == PUBLISH_BUTTON_INDEX)
    {
        publishConfimedByUser = YES;
        [self publishBook:nil];
    }
    else
    {
        //NSLog(@"NOT Publish");
    }
}

- (void)duplicateNoaction {
    
    BookPage *currentBookPage = [BookManager getNewBookPageInstance];
    currentBookPage.book = currentBook;
    currentBookPage.backgroundColorCode = @"ffffff";
    currentBookPage.sortOrder = [NSNumber numberWithInt:[currentBook.pages count]];
    NSLog(@"CurrentBoodPageRemoteID -- %@", currentBookPage.remoteId);
    
    bookPageViewController.wizardDataObject = currentBookPage;
    [bookPageViewController setup];
    
    for(UIView *subview in [self.pageView subviews])
    {
        [subview removeFromSuperview];
    }
    self.pageView.backgroundColor = [UIColor whiteColor];
    self.pageView.tag = [currentBookPage.sortOrder intValue];
    [self.pageView addSubview:bookPageViewController.view];
    bookPageViewController.view.frame = self.pageView.bounds;
    
    //add 1 page in scrollpageview.
    CellInBookPageScrollView * pageCV = (CellInBookPageScrollView *)[[CellInBookPageScrollView alloc]initWithFame:self.pageScrollView.bounds book:currentBookPage bookViewController:(BookViewController *)self tag:[currentBookPage.sortOrder intValue]];
    pageCV.tag = [currentBookPage.sortOrder intValue];
    
    UILongPressGestureRecognizer *lpg = [[UILongPressGestureRecognizer alloc]
                                         initWithTarget:self action:@selector(handleLongPressForPageScrollView:)];
    
    [pageCV addGestureRecognizer:lpg];
    [self.pageScrollView addSubview:pageCV];
    
    int titlePageWidth = TITLE_PAGE_IMG_VIEW_FRAME_WIDTH + IMG_VIEW_SPACE;
    int totalPageWidth = [currentBookPage.sortOrder intValue] * (PAGE_IMG_VIEW_FRAME_WIDTH + IMG_VIEW_SPACE);
    
    self.pageScrollView.contentSize = CGSizeMake(titlePageWidth+totalPageWidth, self.pageScrollView.frame.size.height);
    [UIView animateWithDuration:PAGE_MOVE_ANIMATION_DURATION delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:
     ^{
         [self moveAddPageButton];
     } completion:^(BOOL finished){}];
    
    if(self.pageScrollView.contentSize.width > self.pageScrollView.bounds.size.width)
    {
        CGPoint bottomOffset = CGPointMake(self.pageScrollView.contentSize.width - self.pageScrollView.bounds.size.width + 5, 0);
        [UIView animateWithDuration:PAGE_MOVE_ANIMATION_DURATION delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:
         ^{
             [self.pageScrollView setContentOffset:bottomOffset animated:NO];
         } completion:^(BOOL finished){}];
    }
    [self highlightTheCell];
}

// =======================================================================================================================================
//create a book page.
- (IBAction)goToCreatePage:(id)sender
{
    
    if([currentBook.pages count] >= MAX_PAGE)
    {
        NSString * errorTitle = NSLocalizedString(@"Max Page", @"Alert box title: Already reached the max. number of page for a book.");
        NSString * errorBody = NSLocalizedString(@"You have reached the maximum number of pages. No more page can be added to this book.", @"Alert box body: Already reached the max. number of page for a book.");
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:errorTitle message:errorBody delegate:self cancelButtonTitle:NSLocalizedString(@"OK", @"OK button label") otherButtonTitles: nil];
        [alert show];
    }
    else{
        
        [bookPageViewController reset];
        [titlePageViewController reset];
        
        BookPage *oldBookPage = (BookPage*)bookPageViewController.wizardDataObject;
        
        int n = (int)[oldBookPage.sortOrder integerValue];
        NSLog(@"sortOrder - %d", n);
        
        if (n == 0) {
            [self duplicateNoaction];
            
        }
        else {
            
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Duplicate Page", @"Alert box for duplicate page")                                                     message:NSLocalizedString(@"Do you want to duplicate this page?", @"Ask confirmation for duplicating a page")
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"No", @"No")
                                                  otherButtonTitles:NSLocalizedString(@"Yes", @"Yes"), nil];
            alert.tag = DUPLICATE_PAGE_ALERT_VIEW;
            
            [alert show];
        }
    }
}

- (IBAction)uploadBtnClick:(id)sender {
    UIImagePickerController *videoPicker= [[UIImagePickerController alloc] init];
    videoPicker.delegate = self;
    videoPicker.modalPresentationStyle = UIModalPresentationCurrentContext;
    videoPicker.mediaTypes =[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    videoPicker.mediaTypes = @[(NSString*)kUTTypeMovie, (NSString*)kUTTypeAVIMovie, (NSString*)kUTTypeVideo, (NSString*)kUTTypeMPEG4];
    videoPicker.videoQuality = UIImagePickerControllerQualityTypeHigh;
    [self presentViewController:videoPicker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    NSString* mediaType = (NSString*)info[UIImagePickerControllerMediaType];
    
    if(CFStringCompare ((__bridge CFStringRef) mediaType, kUTTypeMovie, 0) == kCFCompareEqualTo) {
        NSURL *videoURL = [info objectForKey:UIImagePickerControllerMediaURL];
        NSData *videoData = [NSData dataWithContentsOfURL:videoURL];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        int videoCount = [currentPage.videoCount intValue] + 1;
        currentPage.videoCount = [NSNumber numberWithInt:videoCount];
        int videoid = [currentPage.sortOrder intValue] + 100;
        NSString *tempPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%d_%@.mp4", videoid, currentPage.videoCount]];
        [videoData writeToFile:tempPath atomically:NO];
        [bookPageViewController addVideo:tempPath];
    }
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

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
    [self setupWithTitlePage:TRUE];
    didLoad = TRUE;
    publishConfimedByUser = NO;
    
    // --- Send Google Analytics Data ----------
    
    // This screen name value will remain set on the tracker and sent with hits until it is set to a new value or to nil.
    NSString * screenName = [NSString stringWithFormat:@"%@ (%@ class)", @"Edit Book Screen", [self class]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName value:screenName];
    
    // Send the screen view.
    [[GAI sharedInstance].defaultTracker send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if(!didLoad)
    {
        [self updateImage];
    }
    else
        didLoad = FALSE;
}
- (void)viewDidUnload
{
    [self setPageScrollView:nil];
    [self setPageView:nil];
    [self setAddPageButton:nil];
    [self setSaveAndCloseButton:nil];
    [self setPublishButton:nil];
    titlePageViewController = nil;
    bookPageViewController = nil;
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
@end
