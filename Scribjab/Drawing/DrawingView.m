//
//  DrawingAreaScrollView.m
//  DiaryPad
//
//  Created by Oleg Titov on 12-03-25.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DrawingView.h"
#import "DrawingPathWithTool.h"
#import <QuartzCore/QuartzCore.h>

#import "PenTool.h"
#import "BrushTool.h"
#import "EraserTool.h"
#import "CalligraphyTool.h"
#import "Book.h"
#import "BookPage.h"

#define MAX_UNDO_LIMIT 10
#define CALLIGRAGHY_ALPHA 0.7f

// **************************************************************************************************************************************
// **************************************************************************************************************************************
// **************************************************************************************************************************************
@interface DrawingView()
{
    NSMutableArray * _paths;
    
    DrawingPathWithTool * _currentPath;
    DrawingTool * _currentTool;
    BookPage *currentBookPage;
    
    UIImage * _image;               // image that will have the whole drawing that will be returned to the caller object.
    
    int _pathCount;                 // to determine if canvas is blank.
    
    CALayer * _imageLayer;
    CALayer * _drawingLayer;
    CALayer * _undoImageLayer;
    
    EraserTool * _eraserTool;
    BrushTool * _brushTool;
    PenTool * _penTool;
    CalligraphyTool * _calligraphyTool;
}

-(void) initialize;
-(void) pushPath:(DrawingPathWithTool *) path;
-(void) flattenLayers;
-(void) updateUndoLayer;
-(void) redrawAfterUndo;
@end

// **************************************************************************************************************************************
// **************************************************************************************************************************************
// **************************************************************************************************************************************
@implementation DrawingView

//@synthesize penTool = _penTool;
//@synthesize brushTool = _brushTool;
//@synthesize eraserTool = _eraserTool;
@synthesize currentTool = _currentTool;
@synthesize image = _image;
@synthesize canvasBlank;
@synthesize savedTool = _savedTool;

- (void)setup
{
    // Do any additional setup after loading the view.
    
}

// Call this method to clean up and release any used resources before deallocating the view onject
-(void) releaseResources
{
    if (_imageLayer != nil)
    {
        _imageLayer.delegate = nil;
        [_imageLayer removeFromSuperlayer];
    }
    if (_undoImageLayer != nil)
    {
        _undoImageLayer.delegate = nil;
        [_undoImageLayer removeFromSuperlayer];
    }
    if (_drawingLayer != nil)
    {
        _drawingLayer.delegate = nil;
        [_drawingLayer removeFromSuperlayer];
    }
    _drawingLayer = nil;
    _imageLayer = nil;
    _undoImageLayer = nil;
}

// custom getter for the image. 
-(UIImage *)image
{
    if (_drawingLayer != nil)
    {
        _drawingLayer.delegate = nil;           // must make sure that this is called, otherwise the app crashes
        [_drawingLayer removeFromSuperlayer];
        _drawingLayer = nil;
    }
    return _image;
}

// ======================================================================================================================================
// Custom getter
-(BOOL)canvasBlank
{
    return _pathCount == 0;
}

//// ======================================================================================================================================
//// Setter
//-(void)setPenTool:(PenTool *)penTool
//{
//    if (_currentTool == _penTool)
//        _currentTool = penTool;
//    
//    _penTool = penTool;
//}
//
//// ======================================================================================================================================
//// Setter
//-(void)setBrushTool:(BrushTool *)brushTool
//{
//    if (_currentTool == _brushTool)
//        _currentTool = brushTool;
//    
//    _brushTool = brushTool;
//}
//
//// ======================================================================================================================================
//// Setter
//-(void)setEraserTool:(EraserTool *)eraserTool
//{
//    if (_currentTool == _eraserTool)
//        _currentTool = eraserTool;
//    
//    _eraserTool = eraserTool;
//}

// ======================================================================================================================================
// Set original image to show in drawing canvas.
-(void)setBackgroundImage:(UIImage *)image
{
    if (image != _image)
    {
        _pathCount = MAX_UNDO_LIMIT + 100;             // if the image is set, canvas will never be blank any more.
        _image = image;
        _imageLayer.contents = (id)_image.CGImage;
        
        _undoImageLayer.contents = (id)_image.CGImage;
    }
}

// ======================================================================================================================================
-(void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:backgroundColor];
    if (_eraserTool != nil)
        _eraserTool.color = self.backgroundColor;
    
    // clear drawing layer contents in order to clear any eraser paths that were left behind (to avoid image flicker).
    // see note at the bottom of the "flattenLayers" method.
    if (_drawingLayer != nil)
        _drawingLayer.contents = nil;
}

// ======================================================================================================================================
// Initialization functions
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        // Initialization code
        [self initialize];
    }
    return self;
}
- (void)awakeFromNib
{
    [self initialize];
}

// ======================================================================================================================================
// My custom initialization
-(void)initialize
{
    // Initialize flattened image layer
    _imageLayer = [CALayer layer];
    _imageLayer.frame = self.bounds;
    [self.layer addSublayer:_imageLayer];
    
    // Initialize layer to keep image that cannot be undone any more.
    // This one is not a sublayer of the view's main layer.
    _undoImageLayer = [CALayer layer];
    _undoImageLayer.frame = self.bounds;
    
    _pathCount = 0;
    _paths = [[NSMutableArray alloc] initWithCapacity:MAX_UNDO_LIMIT+2];
    
    if(_image != nil)
        self.backgroundColor = [UIColor colorWithPatternImage:_image];
    else
        self.backgroundColor = [UIColor whiteColor];
    [self setup];
}

// ======================================================================================================================================
-(void) usePenTool
{
    if (_penTool == nil)
        _penTool = [[PenTool alloc] initWithColor:[UIColor blackColor] width:1.0F andAlpha:1.0F];
    
    _currentTool = _penTool;
}

-(void) usePenTool:(PenTool*)pen
{
    _penTool = pen;
    
    _currentTool = _penTool;
}


// ======================================================================================================================================
-(void)useBrushTool
{
    if (_brushTool == nil)
        _brushTool = [[BrushTool alloc] initWithColor:[UIColor colorWithHue:0.0F saturation:1.0F brightness:1.0F alpha:1.0F] width:30.0F andAlpha:1.0F];
    _currentTool = _brushTool;
}

// ======================================================================================================================================
-(void) useCalligraphyTool
{
    if (_calligraphyTool == nil)
    {
        _calligraphyTool = [[CalligraphyTool alloc] initWithColor:[UIColor blackColor] width:30.0f andAlpha:CALLIGRAGHY_ALPHA];
    }
    _currentTool = _calligraphyTool;
}

-(void) useCalligraphyTool:calligraphy
{
    _calligraphyTool = calligraphy;
    
    _currentTool = _calligraphyTool;
}

// ======================================================================================================================================
-(void)useEraserTool
{
    if (_eraserTool == nil)
        _eraserTool = [[EraserTool alloc] initWithColor:self.backgroundColor width:30.0F andAlpha:1.0F];
    _eraserTool.color = self.backgroundColor;
    _currentTool = _eraserTool;
}

// ======================================================================================================================================
// Removes last created graphical path
-(void) undoPath
{
    if (_paths == nil || [_paths count] == 0)
        return;
    
    _pathCount--;
    [_paths removeLastObject];
    
    if (_drawingLayer != nil)
        _drawingLayer.contents = nil;
    [self redrawAfterUndo];
}

// ======================================================================================================================================
// erases the whole drawing
-(void) clearAll
{
    BOOL layerInitialized = NO;
    
    if (_eraserTool == nil)
        _eraserTool = [[EraserTool alloc] initWithColor:self.backgroundColor width:30.0F andAlpha:1.0F];
    _eraserTool.color = self.backgroundColor;
    
    _currentPath = [[DrawingPathWithTool alloc] initWithTool:_eraserTool];
    _currentPath.tool.width = self.bounds.size.height;
   
    // Initialize drawing layer, if not already initialized
    if (_drawingLayer == nil)
    {
        _drawingLayer = [CALayer layer];
        _drawingLayer.frame = self.bounds;
        _drawingLayer.delegate = self;
        [self.layer addSublayer:_drawingLayer];
    }
    else
    {
        layerInitialized = YES;
        _drawingLayer.contents = nil;
    }
    
    [_currentPath moveToPoint:CGPointMake(0.0f, self.bounds.size.height / 2.0f)];
    [_currentPath addPointToPath:CGPointMake(self.bounds.size.width * 2.0f, self.bounds.size.height / 2.0f)];
    
    [self pushPath:_currentPath];
    [self redrawAfterUndo];
    
    // Whithout this the app crashes when:
    // 1. The first this you do is press "clear all" when drawing view is first loaded
    // 2. Then you try to draw anything
    if (!layerInitialized)
    {
        [_drawingLayer removeFromSuperlayer];
        _drawingLayer = nil;
    }
}

// ======================================================================================================================================
// Adds last created graphical path
-(void) pushPath:(DrawingPathWithTool *)path
{
    if (path == nil)
        return;
    
    _pathCount++;
    [_paths addObject:path];
}

// ======================================================================================================================================
// Render custom layer
-(void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
    [_currentPath drawPathWithContext:ctx boundedBy:layer.bounds];
}



// ======================================================================================================================================
// Draws all CALayers onto a single image.
-(void) flattenLayers
{
    UIGraphicsBeginImageContext(self.bounds.size);
    [_imageLayer renderInContext:UIGraphicsGetCurrentContext()];
    
    // CALayers do not support blending modes, so to imitate eraser we:
    // 1. draw a regular solid line using the color of the current background
    // 2. On touchEnded this method is called that merges previous image with the newly finished path.
    // 3. If last path was drawn using "eraser", then create a shape layer to be the same shape as the erased path
    // 4. Draw that shape onto image using "Clear" blend mode.
    //
    // A regular CALayer cannot be used with clear blending mode because it clears the whole screen.
    if (_currentTool == _eraserTool)
    {
        CAShapeLayer * sl = [CAShapeLayer layer];
        sl.path = _currentPath.path.CGPath;
        sl.frame = self.bounds;
        sl.lineCap = kCALineCapRound;
        sl.lineJoin = kCALineJoinRound;
        sl.lineWidth = _currentTool.width;
        sl.strokeColor = _eraserTool.color.CGColor;
        
        CGContextSetBlendMode(UIGraphicsGetCurrentContext(), kCGBlendModeClear);
        [sl renderInContext:UIGraphicsGetCurrentContext()];
    }
    else
    {
        [_drawingLayer renderInContext:UIGraphicsGetCurrentContext()];
    }
    _image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    _drawingLayer.contents = (id)_image.CGImage;
    [_imageLayer removeFromSuperlayer];
    _imageLayer = _drawingLayer;
    _imageLayer.delegate = nil;
    _drawingLayer = nil;
    
    // To avoid fliker, especially when drawing with transparency,
    // replace the _imageLayer with _drawingLayer, replace _drawingLayer's content with buffer image
    // and create new _drawingLayer for future stokes.
    
    
    // THIS IS OLD DESCRIPTION:
    // To avoid "flicker", don't clear drawingLayer just yet.
    // It will be cleared next time a user draws something, but by that time all CALayer rendering will be complete.
    // In case a user changed the background color, the setter method for bgColor will clear this layer.
    // By the time this happens CALayers will already be drawn.
}

// ======================================================================================================================================
// update the undo perpanent image layer
-(void) updateUndoLayer
{
    if ([_paths count] < MAX_UNDO_LIMIT)
        return;
    
    UIGraphicsBeginImageContext(self.bounds.size);
    [_undoImageLayer renderInContext:UIGraphicsGetCurrentContext()];
    
    int max_index = [_paths count] - MAX_UNDO_LIMIT;
    
    // Draw all paths that are beyond the MAX_UNDO_LIMIT and remove them from the array
    for (int i = 0; i < max_index; max_index--)
    {
        DrawingPathWithTool * path = [_paths objectAtIndex:i];
        
        if ([path.tool isKindOfClass:[EraserTool class]])
        {
            // CALayers do not support blending modes, so to imitate eraser we:
            // 1. draw a regular solid line using the color of the current background
            // 2. On touchEnded this method is called that merges previous image with the newly finished path.
            // 3. If last path was drawn using "eraser", then create a shape layer to be the same shape as the erased path
            // 4. Draw that shape onto image using "Clear" blend mode.
            //
            // A regular CALayer cannot be used with clear blending mode because it clears the whole screen.
            CAShapeLayer * sl = [CAShapeLayer layer];
            sl.path = path.path.CGPath;
            sl.frame = self.bounds;
            sl.lineCap = kCALineCapRound;
            sl.lineJoin = kCALineJoinRound;
            sl.lineWidth = path.tool.width;
            sl.strokeColor = path.tool.color.CGColor;
            
            CGContextSetBlendMode(UIGraphicsGetCurrentContext(), kCGBlendModeClear);
            [sl renderInContext:UIGraphicsGetCurrentContext()];
        }
        else
        {
            CGContextSetBlendMode(UIGraphicsGetCurrentContext(), kCGBlendModeNormal);
            [path drawPathWithContext:UIGraphicsGetCurrentContext() boundedBy:_undoImageLayer.bounds];
        }
        
        [_paths removeObjectAtIndex:i];
    }
    
    UIImage * timg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    _undoImageLayer.contents = (id)timg.CGImage;
}

// ======================================================================================================================================
// restore image to what it was using the paths in the array
-(void) redrawAfterUndo
{
    UIGraphicsBeginImageContext(self.bounds.size);
    [_undoImageLayer renderInContext:UIGraphicsGetCurrentContext()];
    
    
    // Draw all paths that are beyond the MAX_UNDO_LIMIT and remove them from the array
    for (DrawingPathWithTool * path in _paths)
    {
        if ([path.tool isKindOfClass:[EraserTool class]])
        {
            // CALayers do not support blending modes, so to imitate eraser we:
            // 1. draw a regular solid line using the color of the current background
            // 2. On touchEnded this method is called that merges previous image with the newly finished path.
            // 3. If last path was drawn using "eraser", then create a shape layer to be the same shape as the erased path
            // 4. Draw that shape onto image using "Clear" blend mode.
            //
            // A regular CALayer cannot be used with clear blending mode because it clears the whole screen.
            CAShapeLayer * sl = [CAShapeLayer layer];
            sl.path = path.path.CGPath;
            sl.frame = self.bounds;
            sl.lineCap = kCALineCapRound;
            sl.lineJoin = kCALineJoinRound;
            sl.lineWidth = path.tool.width;
            sl.strokeColor = path.tool.color.CGColor;
            
            CGContextSetBlendMode(UIGraphicsGetCurrentContext(), kCGBlendModeClear);
            [sl renderInContext:UIGraphicsGetCurrentContext()];
        }
        else
        {
            CGContextSetBlendMode(UIGraphicsGetCurrentContext(), kCGBlendModeNormal);
            [path drawPathWithContext:UIGraphicsGetCurrentContext() boundedBy:_undoImageLayer.bounds];
        }
    }
    
    _image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    _imageLayer.contents = (id)_image.CGImage;
    _drawingLayer.contents = nil;
}



// ======================================================================================================================================
// Start new line when user touches this view
-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([[[event allTouches] allObjects] count] > 1)        // Only one finger is supported
        return;
    
    _currentPath = [[DrawingPathWithTool alloc] initWithTool:_currentTool];
    _currentPath.tool.width = self.currentTool.width;    
    
    UITouch * touch = [[[event allTouches] allObjects] objectAtIndex:0];
    CGPoint point = [touch locationInView:self];
    
    [_currentPath moveToPoint:point];
    
    // Initialize drawing layer, if not already initialized
    if (_drawingLayer == nil)
    {
        _drawingLayer = [CALayer layer];
        _drawingLayer.frame = self.bounds;
        _drawingLayer.delegate = self;
        [self.layer addSublayer:_drawingLayer];
    }
}

// ======================================================================================================================================
// Save all points in the line path
-(void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([[[event allTouches] allObjects] count] > 1)        // Only one finger is supported
        return;
    
    UITouch * touch = [[[event allTouches] allObjects] objectAtIndex:0];
    CGPoint point = [touch locationInView:self];
    [_currentPath addPointToPath:point];
    
    [_drawingLayer setNeedsDisplay];
}




// ======================================================================================================================================
// End line drawing, when user stops touching this view
-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([[[event allTouches] allObjects] count] > 1)        // Only one finger is supported
        return;
    
    UITouch * touch = [[[event allTouches] allObjects] objectAtIndex:0];
    CGPoint point = [touch locationInView:self];
    
    [_currentPath addPointToPath:point];
    [_currentPath closePathAtPoint:point];
    
    [self pushPath:_currentPath];
    //  _currentPath = nil;
    [_drawingLayer setNeedsDisplay];
    
    [self flattenLayers];
    //    [self updateUndoLayer];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self updateUndoLayer];
    });
}

// ======================================================================================================================================
// If drawing was interrupted, throw away current line path
-(void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    // _currentPath = [[DrawingPathWithTool alloc] initWithTool:_currentTool];
    //  [_currentLayer removeFromSuperlayer];
    // _currentLayer = nil;
    
    //    _currentPath = [[DrawingPathWithTool alloc] initWithTool:_currentTool];
    //    [self setNeedsDisplay];
}
@end
