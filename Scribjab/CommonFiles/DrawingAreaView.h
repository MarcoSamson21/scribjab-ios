//
//  DrawingAreaScrollView.h
//  DiaryPad
//
//  Created by Oleg Titov on 12-03-25.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>



@interface DrawingAreaView : UIView
-(void) undoPath;       // removes last created graphical path
@property (nonatomic, strong) UIImage * image;  // Returns an image based on the contents of the view's current graphics context.

@property (nonatomic) float strokeWidth;
@property (nonatomic, strong) UIColor * strokeColor;
@property (nonatomic, strong) UIColor * backgroundColor;
-(void) drawWithEraser;     // Indicate that the user wants to erase graphics

- (id)initWithFrameAndImage:(CGRect)frame image:(UIImage *)aImage backgroundColor:(UIColor *)backgroundColor;

@end





// **************************************************************************************************************************************
// Data type for storing bezier paths with associated line colors etc.
@interface OTBezierPath: NSObject 
@property (nonatomic, strong) UIBezierPath * path;
@property (nonatomic, strong) UIColor * strokeColor;
@property (nonatomic, assign) float strokeAlpha;
@end