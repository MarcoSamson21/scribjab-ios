//
//  ModifyUserAvatarViewController.m
//  Scribjab
//
//  Created by Oleg Titov on 12-11-22.
//
//

#import "ModifyUserAvatarViewController.h"

// Google Analytics includes
#import "GAI.h"
#import "GAIFields.h"
#import "GAITracker.h"
#import "GAIDictionaryBuilder.h"

@interface ModifyUserAvatarViewController () <DrawingPadViewControllerDelegate>
{
    UIButton * _currentToolButton;
    UIButton * _canvasSelectionButton;
}
@end

// **************************************************************************************************************************************
// **************************************************************************************************************************************

@implementation ModifyUserAvatarViewController

@synthesize delegate;
@synthesize avatar = _avatar;
-(void)setAvatar:(UIImage *)avatar
{
    [self.drawingAreaView setBackgroundImage:avatar];
}

@synthesize avatarBgColor;
-(void)setAvatarBgColor:(UIColor *)bgColor
{
    self.drawingAreaView.backgroundColor = bgColor;
}
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

    self.canvasView = self.drawingAreaView;
    [self.canvasView usePenTool];
    [self.penToolButton setSelected:YES];
    _currentToolButton = self.penToolButton;
    self.drawingDelegate = self;
    
    // --- Send Google Analytics Data ----------
    
    // This screen name value will remain set on the tracker and sent with hits until it is set to a new value or to nil.
    NSString * screenName = [NSString stringWithFormat:@"%@ (%@ class)", @"Modify User Avatar Screen", [self class]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName value:screenName];
    
    // Send the screen view.
    [[GAI sharedInstance].defaultTracker send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setDrawingAreaView:nil];
    [self setPenToolButton:nil];
    [super viewDidUnload];
}

// ======================================================================================================================================
- (IBAction)penSelected:(id)sender
{
    [self selectPenAndShowPropertiesPopupInView:(UIView*)sender withPermittedArrowDirections:UIPopoverArrowDirectionRight animated:YES];
    
    if (_currentToolButton != nil)
        [_currentToolButton setSelected:NO];
    _currentToolButton = (UIButton*)sender;
    [_currentToolButton setSelected:YES];
}

- (IBAction)brushSeected:(id)sender
{
    [self selectBrushAndShowPropertiesPopupInView:(UIView*)sender withPermittedArrowDirections:UIPopoverArrowDirectionRight animated:YES];
    if (_currentToolButton != nil)
        [_currentToolButton setSelected:NO];
    _currentToolButton = (UIButton*)sender;
    [_currentToolButton setSelected:YES];
}

- (IBAction)eraserSelected:(id)sender
{
    [self selectEraserAndShowPropertiesPopupInView:(UIView*)sender withPermittedArrowDirections:UIPopoverArrowDirectionRight animated:YES];
    if (_currentToolButton != nil)
        [_currentToolButton setSelected:NO];
    _currentToolButton = (UIButton*)sender;
    [_currentToolButton setSelected:YES];
}

- (IBAction)canvasSelected:(id)sender
{
    [self openCanvasColorSelectionPropertiesPopupInView:(UIView*)sender withPermittedArrowDirections:UIPopoverArrowDirectionRight | UIPopoverArrowDirectionUp animated:YES];
    _canvasSelectionButton = sender;
    [_canvasSelectionButton setSelected:YES];
}

- (IBAction)undoClicked:(id)sender
{
    [self undoLastPath];
}

- (IBAction)cancelClicked:(id)sender
{
    [_drawingAreaView releaseResources];
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (IBAction)saveCliked:(id)sender
{
    [delegate imageUpdatedWithImage:[self getImageInCanvas] andBackgroundColor:[self getImageBackgroundColor]];
    [_drawingAreaView releaseResources];
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (IBAction)clearAll:(id)sender
{
    [self clearAll];
}

- (IBAction)calligraphySelected:(id)sender
{
    [self selectCalligraphyToolAndShowPropertiesPopupInView:(UIView*)sender withPermittedArrowDirections:UIPopoverArrowDirectionRight animated:YES];
    
    if (_currentToolButton != nil)
        [_currentToolButton setSelected:NO];
    _currentToolButton = (UIButton*)sender;
    [_currentToolButton setSelected:YES];
}

// ======================================================================================================================================
#pragma-mark DrawingPadViewController Delegate

-(void)drawingControllerDidDismissToolPopover:(UIPopoverController *)popoverController
{
}

-(BOOL)drawingControllerShouldDismissToolPopover:(UIPopoverController *)popoverController
{
    [_canvasSelectionButton setSelected:NO];
    return YES;
}
@end
