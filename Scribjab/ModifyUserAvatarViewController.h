//
//  ModifyUserAvatarViewController.h
//  Scribjab
//
//  Created by Oleg Titov on 12-11-22.
//
//

#import "DrawingPadViewController.h"
#import "DrawingView.h"
#import "DrawingPadImageUpdatedDelegate.h"

@interface ModifyUserAvatarViewController : DrawingPadViewController

@property (nonatomic, strong) UIImage * avatar;
@property (nonatomic, strong) UIColor * avatarBgColor;
@property (nonatomic, weak) id<DrawingPadImageUpdatedDelegate> delegate;

@property (strong, nonatomic) IBOutlet UIButton *penToolButton;
@property (strong, nonatomic) IBOutlet DrawingView *drawingAreaView;
- (IBAction)penSelected:(id)sender;
- (IBAction)brushSeected:(id)sender;
- (IBAction)eraserSelected:(id)sender;
- (IBAction)canvasSelected:(id)sender;
- (IBAction)undoClicked:(id)sender;
- (IBAction)cancelClicked:(id)sender;
- (IBAction)saveCliked:(id)sender;
- (IBAction)clearAll:(id)sender;
- (IBAction)calligraphySelected:(id)sender;
@end
