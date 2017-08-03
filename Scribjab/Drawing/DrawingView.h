//
//  DrawingAreaScrollView.h
//  DiaryPad
//
//  Created by Oleg Titov on 12-03-25.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DrawingTool.h"
#import "IWizardNavigationViewController.h"
#import "PenTool.h"

@interface DrawingView : UIView

@property (nonatomic, readonly) UIImage * image;
@property (nonatomic, readonly) BOOL canvasBlank;

//@property (nonatomic, strong) PenTool * penTool;
//@property (nonatomic, strong) BrushTool * brushTool;
//@property (nonatomic, strong) EraserTool * eraserTool;
@property (nonatomic, readonly) DrawingTool * currentTool;
@property (nonatomic, readonly) DrawingTool * savedTool;


-(void) usePenTool;
-(void) usePenTool:(PenTool*)pen;
-(void) useBrushTool;
-(void) useEraserTool;
-(void) useCalligraphyTool;
-(void) useCalligraphyTool:calligraphy;
-(void) undoPath;       // removes last created graphical path
-(void) clearAll;       // erases the whole drawing
-(void)setBackgroundImage:(UIImage *)image;   // Set original image to show in drawing canvas.

-(void) releaseResources;       // Call this method to clean up and release any used resources before deallocating the view onject

@end




