//
//  BookPageDrawViewController.h
//  Scribjab
//
//  Created by Gladys Tang on 12-10-05.
//
//

#import <UIKit/UIKit.h>
#import "IWizardNavigationViewController.h"
#import "WizardNavigationViewControllerDelegate.h"
#import "DrawingPadViewController.h"
#import "DrawingView.h"

@interface BookPageDrawViewController : DrawingPadViewController <IWizardNavigationViewController>

@property (nonatomic, weak) id<WizardNavigationViewControllerDelegate> delegate;
@property (strong, nonatomic) IBOutlet UIButton *nextButton;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) IBOutlet DrawingView *drawingAreaView;
@property (strong, nonatomic) IBOutlet UIButton *penToolButton;
@property (strong, nonatomic) IBOutlet UIButton *calligraphyToolButton;

- (IBAction)nextButtonPressed:(id)sender;

- (IBAction)penSelected:(id)sender;
//- (IBAction)brushSelected:(id)sender;
- (IBAction)undoPathDrawing:(id)sender;
- (IBAction)canvasColorClicked:(id)sender;
- (IBAction)eraserSelected:(id)sender;
- (IBAction)clearAll:(id)sender;
- (IBAction)calligraphySelected:(id)sender;
@end
