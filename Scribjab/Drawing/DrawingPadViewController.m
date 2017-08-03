//
//  DrawingPadViewController.m
//  Scribjab
//
//  Created by Oleg Titov on 12-11-22.
//
//

#import "DrawingPadViewController.h"
#import "DrawingPropertiesPickerDelegate.h"
#import "EraserToolPropertiesPickerViewController.h"
#import "CanvasColorPickerViewController.h"
#import "DrawingToolPropertiesPickerViewController.h"
#import "Book.h"
#import "BookPage.h"

@interface DrawingPadViewController () <DrawingPropertiesPickerDelegate, CanvasPropertiesPickerDelegate, UIPopoverControllerDelegate>
{
    UIPopoverController * _popController;
    BookPage *currentBookPage;
    Book *currentBook;
    UIButton * _currentToolButton;
}
@end

// **************************************************************************************************************************************
// **************************************************************************************************************************************

@implementation DrawingPadViewController

@synthesize canvasView = _canvasView;
@synthesize drawingDelegate = _delegate;
@synthesize wizardDataObject = _wizardDataObject;

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
    currentBookPage = self.wizardDataObject;
    currentBook = self.wizardDataObject;
    self.drawButtonType = 0;
    self.isSave = NO;
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
// Remove last last path in the array from the drawing
- (void) undoLastPath
{
    [_canvasView undoPath];
}

// ======================================================================================================================================
// Clear the whole drawing
-(void)clearAll
{
    [_canvasView clearAll];
}

// ======================================================================================================================================
// select eraser and show eraser tool's properties picker
- (void) selectEraserAndShowPropertiesPopupInView:(UIView*) view withPermittedArrowDirections:(UIPopoverArrowDirection)direction animated:(BOOL)animated
{
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Drawing" bundle:[NSBundle mainBundle]];
    
    EraserToolPropertiesPickerViewController * pickerVC = [storyboard instantiateViewControllerWithIdentifier:@"Eraser Properties Picker"];
    
    pickerVC.delegate = self;
    
    _popController = [[UIPopoverController alloc] initWithContentViewController:pickerVC];
    _popController.delegate = self;
    _popController.contentViewController.preferredContentSize = CGSizeMake(500, 130);
    [_popController presentPopoverFromRect:view.bounds inView:view permittedArrowDirections:direction animated:animated];
    [_canvasView useEraserTool];
    pickerVC.toolWidth = _canvasView.currentTool.width;
}

// ======================================================================================================================================
- (void) selectBrushAndShowPropertiesPopupInView:(UIView*) view withPermittedArrowDirections:(UIPopoverArrowDirection)direction animated:(BOOL)animated
{
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Drawing" bundle:[NSBundle mainBundle]];
    
    DrawingToolPropertiesPickerViewController * pickerVC = [storyboard instantiateViewControllerWithIdentifier:@"Drawing Tool Properties Picker View Controller"];
    
    pickerVC.delegate = self;
    
    _popController = [[UIPopoverController alloc] initWithContentViewController:pickerVC];
    _popController.delegate = self;
    [_popController presentPopoverFromRect:view.bounds inView:view permittedArrowDirections:direction animated:animated];
    [_canvasView useBrushTool];
    pickerVC.toolWidth = _canvasView.currentTool.width;
    pickerVC.toolColor = _canvasView.currentTool.color;
    pickerVC.showSoftEdges = YES;
}

// ======================================================================================================================================
- (void) selectPenAndShowPropertiesPopupInView:(UIView*) view withPermittedArrowDirections:(UIPopoverArrowDirection)direction animated:(BOOL)animated
{
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Drawing" bundle:[NSBundle mainBundle]];
    
    DrawingToolPropertiesPickerViewController * pickerVC = [storyboard instantiateViewControllerWithIdentifier:@"Drawing Tool Properties Picker View Controller"];
    
    pickerVC.delegate = self;
    
    _popController = [[UIPopoverController alloc] initWithContentViewController:pickerVC];
    _popController.delegate = self;
    _popController.contentViewController.preferredContentSize = CGSizeMake(500, 280);
    [_popController presentPopoverFromRect:view.bounds inView:view permittedArrowDirections:direction animated:animated];
//    [_canvasView usePenTool];
    pickerVC.minWidth = 0.5f;
    pickerVC.maxWidth = 17.0f;
    
    if([self.wizardDataObject isKindOfClass:[Book class]])
    {
        pickerVC.toolWidth = [currentBook.penWidth floatValue];
        pickerVC.toolColor = [currentBook.penColor copy];
        pickerVC.savedColor = [currentBook.savedPenColor copy];
    }
    else if ([self.wizardDataObject isKindOfClass:[BookPage class]])
    {
        pickerVC.toolWidth = [currentBookPage.penWidth floatValue];
        pickerVC.toolColor = [currentBookPage.penColor copy];
        pickerVC.savedColor = [currentBookPage.savedPenColor copy];
    }
    
    pickerVC.showSoftEdges = NO;
}

// ======================================================================================================================================
- (void) selectCalligraphyToolAndShowPropertiesPopupInView:(UIView*) view withPermittedArrowDirections:(UIPopoverArrowDirection)direction animated:(BOOL)animated
{
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Drawing" bundle:[NSBundle mainBundle]];
    
    DrawingToolPropertiesPickerViewController * pickerVC = [storyboard instantiateViewControllerWithIdentifier:@"Drawing Tool Properties Picker View Controller"];
    
    pickerVC.delegate = self;
    
    _popController = [[UIPopoverController alloc] initWithContentViewController:pickerVC];
    _popController.delegate = self;
    _popController.contentViewController.preferredContentSize = CGSizeMake(500, 280);
    [_popController presentPopoverFromRect:view.bounds inView:view permittedArrowDirections:direction animated:animated];
//    [_canvasView useCalligraphyTool];
    
    if([self.wizardDataObject isKindOfClass:[Book class]])
    {
        pickerVC.toolWidth = [currentBook.calligraphyWidth floatValue];
        pickerVC.toolColor = [currentBook.calligraphyColor copy];
        pickerVC.savedColor = [currentBook.savedCalligraphyColor copy];
    }
    else if ([self.wizardDataObject isKindOfClass:[BookPage class]])
    {
        pickerVC.toolWidth = [currentBookPage.calligraphyWidth floatValue];
        pickerVC.toolColor = [currentBookPage.calligraphyColor copy];
        pickerVC.savedColor = [currentBookPage.savedCalligraphyColor copy];
    }
    
    pickerVC.showSoftEdges = NO;

}
// ======================================================================================================================================
// Select tools with previously selected color properties
- (void) selectPenTool
{
    [_canvasView usePenTool];
}
- (void) selectBrushTool
{
    [_canvasView useBrushTool];
}
- (void) selectEraserTool
{
    [_canvasView useEraserTool];
}
- (void) selectCalligraphyTool
{
    [_canvasView useCalligraphyTool];
}
// ======================================================================================================================================
- (void) openCanvasColorSelectionPropertiesPopupInView:(UIView*) view withPermittedArrowDirections:(UIPopoverArrowDirection)direction animated:(BOOL)animated
{
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Drawing" bundle:[NSBundle mainBundle]];
    
    CanvasColorPickerViewController * pickerVC = [storyboard instantiateViewControllerWithIdentifier:@"Canvas Color Picker"];
    
    pickerVC.delegate = self;
    
    _popController = [[UIPopoverController alloc] initWithContentViewController:pickerVC];
    _popController.delegate = self;
    _popController.contentViewController.preferredContentSize = CGSizeMake(780, 200);
    [_popController presentPopoverFromRect:view.bounds inView:view permittedArrowDirections:direction animated:animated];
  
}

// ======================================================================================================================================
- (UIImage*) getImageInCanvas
{
    if (_canvasView != nil)
        return _canvasView.image;
    return nil;
}

// ======================================================================================================================================
// Get BG/Canvas color of the image
- (UIColor*) getImageBackgroundColor
{
    if (_canvasView != nil)
        return _canvasView.backgroundColor;
    return [UIColor whiteColor];
}

// ======================================================================================================================================
// Returns true if the drawing area has a blank image, false otherwise.
-(BOOL)isCanvasBlank
{
    return _canvasView.canvasBlank;
}

#pragma Drawing Properties Picker Delegate Methods

// ======================================================================================================================================
// Color selection changed
- (void)drawingToolColorChanged:(id)sender toColor:(UIColor *)toolColor
{
    _canvasView.currentTool.color = toolColor;
}

// ======================================================================================================================================
// Width selection changed
- (void)drawingToolWidthChanged:(id)sender toWidth:(float)toolWidth
{
    _canvasView.currentTool.width = toolWidth;
}

// ======================================================================================================================================
// Save Button Clicked
-(void)onClickSave
{
    self.isSave = YES;
    
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Drawing" bundle:[NSBundle mainBundle]];
    
    DrawingToolPropertiesPickerViewController * pickerVC = [storyboard instantiateViewControllerWithIdentifier:@"Drawing Tool Properties Picker View Controller"];
    
    pickerVC.delegate = self;
    
    if (self.drawButtonType == PEN_BTN)
    {
        [_canvasView usePenTool];
    }
    else if(self.drawButtonType == CALL_BTN)
    {
        [_canvasView useCalligraphyTool];
    }
    
    pickerVC.savedBtn.backgroundColor = self.canvasView.currentTool.color;
    
    [_popController.delegate popoverControllerDidDismissPopover:_popController];
}

-(void)onClickSavedColorBtn:(id)sender
{
    PenTool *pen;
    if (self.drawButtonType == PEN_BTN)
    {
        if([self.wizardDataObject isKindOfClass:[Book class]])
        {
            pen = [[PenTool alloc] initWithColor:currentBook.savedPenColor width:[currentBook.penWidth floatValue] andAlpha:1.0F];
        }
        else if ([self.wizardDataObject isKindOfClass:[BookPage class]])
        {
            pen = [[PenTool alloc] initWithColor:currentBookPage.savedPenColor width:[currentBookPage.penWidth floatValue] andAlpha:1.0F];
        }
        
        [self.canvasView usePenTool:pen];
        
        if (_currentToolButton != nil)
            [_currentToolButton setSelected:NO];
        _currentToolButton = (UIButton*)sender;
        [_currentToolButton setSelected:YES];
    }
    else if (self.drawButtonType == CALL_BTN)
    {
        PenTool *pen;
        
        if([self.wizardDataObject isKindOfClass:[Book class]])
        {
            pen = [[PenTool alloc] initWithColor:currentBook.savedCalligraphyColor width:[currentBook.calligraphyWidth floatValue] andAlpha:1.0F];
        }
        else if ([self.wizardDataObject isKindOfClass:[BookPage class]])
        {
            pen = [[PenTool alloc] initWithColor:currentBookPage.savedCalligraphyColor width:[currentBookPage.calligraphyWidth floatValue] andAlpha:1.0F];
        }

        
        [self.canvasView usePenTool:pen];
        
        if (_currentToolButton != nil)
            [_currentToolButton setSelected:NO];
        _currentToolButton = (UIButton*)sender;
        [_currentToolButton setSelected:YES];
    }
    [_popController.delegate popoverControllerDidDismissPopover:_popController];
}

// ======================================================================================================================================
// Color selection changed
-(void)canvasToolColorChanged:(id)sender toColor:(UIColor *)newColor
{
    _canvasView.backgroundColor = newColor;
}
// ======================================================================================================================================
-(void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{    
    if ([self.drawingDelegate respondsToSelector:@selector(drawingControllerDidDismissToolPopover:)])
    {
        if (self.isSave) {
            [self.drawingDelegate drawingControllerDidDismissToolPopoverAfterSave:popoverController];
        }
        else {
            [self.drawingDelegate drawingControllerDidDismissToolPopover:popoverController];
        }
        [_popController dismissPopoverAnimated:YES];
    }
}
// ======================================================================================================================================
-(BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
    if ([self.drawingDelegate respondsToSelector:@selector(drawingControllerShouldDismissToolPopover:)])
    {
        return [self.drawingDelegate drawingControllerShouldDismissToolPopover:popoverController];
    }
    return YES;
}
@end
