//
//  DrawingPadViewController.h
//  Scribjab
//
//  Created by Oleg Titov on 12-11-22.
//
//
#import <UIKit/UIKit.h>
#import "DrawingView.h"
#import "IWizardNavigationViewController.h"

#define PEN_BTN         1
#define CALL_BTN        2

// Delegate Desclaration
@protocol DrawingPadViewControllerDelegate <NSObject>
-(void)drawingControllerDidDismissToolPopover:(UIPopoverController *)popoverController;
-(void)drawingControllerDidDismissToolPopoverAfterSave:(UIPopoverController *)popoverController;
-(BOOL)drawingControllerShouldDismissToolPopover:(UIPopoverController *)popoverController;
@end

@interface DrawingPadViewController : UIViewController <IWizardNavigationViewController>

@property (nonatomic, weak) id<DrawingPadViewControllerDelegate> drawingDelegate;
@property (nonatomic, strong) DrawingView * canvasView;     // this is a pointer to the Canvas View

@property (nonatomic) NSInteger drawButtonType;
@property (nonatomic) BOOL isSave;

- (BOOL) isCanvasBlank;
- (void) undoLastPath;
- (void) clearAll;
- (void) selectEraserAndShowPropertiesPopupInView:(UIView*) view withPermittedArrowDirections:(UIPopoverArrowDirection)direction animated:(BOOL)animated;
- (void) selectBrushAndShowPropertiesPopupInView:(UIView*) view withPermittedArrowDirections:(UIPopoverArrowDirection)direction animated:(BOOL)animated;
- (void) selectCalligraphyToolAndShowPropertiesPopupInView:(UIView*) view withPermittedArrowDirections:(UIPopoverArrowDirection)direction animated:(BOOL)animated;
- (void) selectPenAndShowPropertiesPopupInView:(UIView*) view withPermittedArrowDirections:(UIPopoverArrowDirection)direction animated:(BOOL)animated;
- (void) openCanvasColorSelectionPropertiesPopupInView:(UIView*) view withPermittedArrowDirections:(UIPopoverArrowDirection)direction animated:(BOOL)animated;

- (void) selectPenTool;
- (void) selectBrushTool;
- (void) selectEraserTool;
- (void) selectCalligraphyTool;

- (UIImage*) getImageInCanvas;
- (UIColor*) getImageBackgroundColor;
@end
