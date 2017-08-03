//
//  BookDrawViewController.m
//  Scribjab
//
//  Created by Gladys Tang on 12-10-03.
//
//

#import "BookDrawViewController.h"
#import "Book.h"
#import "BookManager.h"
#import "UIColor+HexString.h"
#import "CreateBookNavigationManager.h"
#import "UIImage+Resize.h"

// Google Analytics includes
#import "GAI.h"
#import "GAIFields.h"
#import "GAITracker.h"
#import "GAIDictionaryBuilder.h"

@interface BookDrawViewController ()<DrawingPadViewControllerDelegate>
{
    Book *currentBook;
    UIButton * _currentToolButton;
    UIButton * _canvasSelectionButton;
}
- (void) saveBook;
@end

@implementation BookDrawViewController
@synthesize delegate = _delegate;
@synthesize nextButton = _nextButton;
@synthesize activityIndicator = _activityIndicator;
@synthesize wizardDataObject = _wizardDataObject;

@synthesize drawingAreaView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

//save the image, create thumbnail and save current book.
- (void) saveBook
{
    [self.view endEditing:YES];
    
    // SAVE IMAGE HERE
    UIImage * image = [self getImageInCanvas];
    currentBook.backgroundColorCode = [UIColor hexStringForColor:[self getImageBackgroundColor]];
    
    [self savePenCallWidthColor];
    
    if ([self isCanvasBlank])
    {
        image = nil;
    }
    
    [BookManager saveBook:currentBook];
    self.wizardDataObject = currentBook;
    
    //save the image to file.
    [BookManager saveImage:image item:currentBook filename:(NSString *)BOOK_IMAGE_FILENAME];
    
    //create thumbnail and save to file.
    UIImage *thumb = [UIImage resizeImageWithImage:image scaledToSize:CGSizeMake(BOOK_THUMBNAIL_WIDTH, BOOK_THUMBNAIL_HEIGHT)];
    [BookManager saveImage:thumb item:currentBook filename:(NSString *)BOOK_THUMBNAIL_FILENAME];
}

// ======================================================================================================================================
- (void)viewDidLoad
{    
    [super viewDidLoad];

    currentBook = self.wizardDataObject;
    [self.activityIndicator setHidden:YES];
 
    //setup drawing....
    self.drawingAreaView.backgroundColor = (currentBook.backgroundColorCode == nil? [UIColor whiteColor]: [UIColor colorWithHexString:currentBook.backgroundColorCode]);
    [self.drawingAreaView setBackgroundImage:[UIImage imageWithContentsOfFile:[BookManager getBookItemAbsPath:currentBook fileName:BOOK_IMAGE_FILENAME]]];
    self.canvasView = self.drawingAreaView;

    [self.view addSubview:self.drawingAreaView];
    
    PenTool *pen = [[PenTool alloc] initWithColor:currentBook.penColor width:[currentBook.penWidth floatValue] andAlpha:1.0F];
    [self.canvasView usePenTool:pen];
    
    _currentToolButton = self.penToolButton;
    [_currentToolButton setSelected:YES];
    self.drawingDelegate = self;
    
    // --- Send Google Analytics Data ----------
    
    // This screen name value will remain set on the tracker and sent with hits until it is set to a new value or to nil.
    NSString * screenName = [NSString stringWithFormat:@"%@ (%@ class)", @"Book Title Page Drawing Screen", [self class]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName value:screenName];
    
    // Send the screen view.
    [[GAI sharedInstance].defaultTracker send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void) viewDidUnload
{
    [self setNextButton:nil];
    [self setDrawingAreaView:nil];
    [self setActivityIndicator:nil];
    [super viewDidUnload];
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

// save the color in core data
- (void)savePenCallWidthColor {
    
    if (self.drawButtonType == PEN_BTN)
    {
        CGFloat fWidth = self.canvasView.currentTool.width;
        if (fWidth == nanf(NULL))
        {
            currentBook.penWidth = [NSNumber numberWithFloat:10.0f];
        }
        else
        {
            currentBook.penWidth = [NSNumber numberWithFloat:self.canvasView.currentTool.width];
        }
        currentBook.penColor = self.canvasView.currentTool.color;
        if (self.isSave == YES)
        {
            currentBook.savedPenColor = self.canvasView.currentTool.color;
            self.isSave = NO;
        }
    }
    else if (self.drawButtonType == CALL_BTN)
    {
        CGFloat fWidth = self.canvasView.currentTool.width;
        if (fWidth == nanf(NULL))
        {
            currentBook.calligraphyWidth = [NSNumber numberWithFloat:10.0f];
        }
        else
        {
            currentBook.calligraphyWidth = [NSNumber numberWithFloat:self.canvasView.currentTool.width];
        }
        currentBook.calligraphyColor = self.canvasView.currentTool.color;
        if (self.isSave == YES)
        {
            currentBook.savedCalligraphyColor = self.canvasView.currentTool.color;
            self.isSave = NO;
        }
    }
}


//next button is pressed.  Go back to the edit page.
- (IBAction)nextButtonPressed:(id)sender
{
    [self saveBook];
    [drawingAreaView releaseResources];
    //    [[self navigationController] popViewControllerAnimated:YES] ;

    [CreateBookNavigationManager navigateToBookViewControllerAnimatedWithDuration:0 transition:5 animationCurve:UIViewAnimationCurveEaseInOut wizardDataObject:self.wizardDataObject];
 ;
}
// ======================================================================================================================================
#pragma-mark Drawing Controls Methods
#pragma-mark DrawingPadViewController Delegate

-(void)drawingControllerDidDismissToolPopover:(UIPopoverController *)popoverController
{
    [self saveBook];
}

-(void)drawingControllerDidDismissToolPopoverAfterSave:(UIPopoverController *)popoverController
{
    [self saveBook];
}

-(BOOL)drawingControllerShouldDismissToolPopover:(UIPopoverController *)popoverController
{
    [_canvasSelectionButton setSelected:NO];
    return YES;
}

// ======================================================================================================================================
// Undo path
- (IBAction)penSelected:(id)sender
{
    self.drawButtonType = PEN_BTN;
    [self selectPenAndShowPropertiesPopupInView:(UIView *)sender withPermittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    
    PenTool *pen = [[PenTool alloc] initWithColor:currentBook.penColor width:[currentBook.penWidth floatValue] andAlpha:1.0F];
    [self.canvasView usePenTool:pen];
    
    if (_currentToolButton != nil)
        [_currentToolButton setSelected:NO];
    _currentToolButton = (UIButton*)sender;
    [_currentToolButton setSelected:YES];
}

- (IBAction)brushSelected:(id)sender
{
    [self selectBrushAndShowPropertiesPopupInView:(UIView *)sender withPermittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    if (_currentToolButton != nil)
        [_currentToolButton setSelected:NO];
    _currentToolButton = (UIButton*)sender;
    [_currentToolButton setSelected:YES];
}

- (IBAction)undoPathDrawing:(id)sender
{
    [self undoLastPath];
}

- (IBAction)canvasColorClicked:(id)sender
{
    _canvasSelectionButton = sender;
    [_canvasSelectionButton setSelected:YES];
    [self openCanvasColorSelectionPropertiesPopupInView:(UIView *)sender withPermittedArrowDirections:UIPopoverArrowDirectionRight | UIPopoverArrowDirectionUp animated:YES];
}

- (IBAction)eraserSelected:(id)sender
{
    self.drawButtonType = 0;
    [self selectEraserAndShowPropertiesPopupInView:(UIView*)sender withPermittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    if (_currentToolButton != nil)
        [_currentToolButton setSelected:NO];
    _currentToolButton = (UIButton*)sender;
    [_currentToolButton setSelected:YES];
}

- (IBAction)clearAll:(id)sender
{
    [self clearAll];
}

- (IBAction)calligraphySelected:(id)sender
{
    self.drawButtonType = CALL_BTN;
    [self selectCalligraphyToolAndShowPropertiesPopupInView:(UIView *)sender withPermittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    
    PenTool *calligraphy = [[PenTool alloc] initWithColor:currentBook.calligraphyColor width:[currentBook.calligraphyWidth floatValue] andAlpha:1.0F];
    [self.canvasView useCalligraphyTool:calligraphy];
    
    if (_currentToolButton != nil)
        [_currentToolButton setSelected:NO];
    _currentToolButton = (UIButton*)sender;
    [_currentToolButton setSelected:YES];
}
@end
