//
//  CreateAccountAvatarDrawingViewControllerViewController.h
//  Scribjab
//
//  Created by Oleg Titov on 12-09-10.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DrawingPadViewController.h"
#import "IWizardNavigationViewController.h"
#import "WizardNavigationViewControllerDelegate.h"
#import "DrawingView.h"

@interface CreateAccountAvatarDrawingViewController : DrawingPadViewController <IWizardNavigationViewController>
@property (nonatomic, weak) id<WizardNavigationViewControllerDelegate> delegate;
@property (strong, nonatomic) IBOutlet UIButton *submitButton;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

- (IBAction)submitButtonClicked:(id)sender;
- (IBAction)useDefaultAvatarButtonPressed:(id)sender;

// Drawing related outlets and actions
@property (strong, nonatomic) IBOutlet DrawingView *drawingAreaView;
@property (strong, nonatomic) IBOutlet UIButton *penToolButton;
- (IBAction)penSelected:(id)sender;
- (IBAction)brushSelected:(id)sender;
- (IBAction)undoPathDrawing:(id)sender;
- (IBAction)canvasColorClicked:(id)sender;
- (IBAction)eraserSelected:(id)sender;
- (IBAction)clearAll:(id)sender;
- (IBAction)calligraphySelected:(id)sender;
@end
