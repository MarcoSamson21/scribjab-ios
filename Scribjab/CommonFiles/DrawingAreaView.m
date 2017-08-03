//
//  DrawingAreaScrollView.m
//  DiaryPad
//
//  Created by Oleg Titov on 12-03-25.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DrawingAreaView.h"

// **************************************************************************************************************************************
// **************************************************************************************************************************************
// **************************************************************************************************************************************
@implementation OTBezierPath
@synthesize path;
@synthesize strokeColor;
@synthesize strokeAlpha;
-(id) init
{
    self = [super init];
    if (self)
    {
        self.path = [[UIBezierPath alloc] init];
        self.path.lineJoinStyle = kCGLineJoinRound;
        self.path.lineCapStyle = kCGLineCapRound;
        self.path.lineWidth = 1.0F;
        self.strokeColor = [UIColor blackColor];
        self.strokeAlpha = 1.0F;
    }
    return self;
}
@end

// **************************************************************************************************************************************
// **************************************************************************************************************************************
// **************************************************************************************************************************************
@interface DrawingAreaView()
{
    NSMutableArray * m_paths;
    
    OTBezierPath * m_currentPath;
    UIImage * m_image;
    BOOL m_drawWithEraser;
}
-(void) initialize;
-(void) pushPath:(OTBezierPath *) path;
@end

// **************************************************************************************************************************************
// **************************************************************************************************************************************
// **************************************************************************************************************************************
@implementation DrawingAreaView

@synthesize image = m_image;
@synthesize strokeWidth = _strokeWidth;
@synthesize strokeColor = _strokeColor;
@synthesize backgroundColor = _backgroundColor;
-(void) setBackgroundColor:(UIColor *)backgroundColor
{
    if (_backgroundColor != backgroundColor)
    {
        if (m_drawWithEraser)
            _strokeColor = backgroundColor;
        
        _backgroundColor = backgroundColor;
        [self setNeedsDisplay];
    }
}

-(void) setStrokeColor:(UIColor *)strokeColor
{
    m_drawWithEraser = NO;
    _strokeColor = strokeColor;
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

- (id)initWithFrameAndImage:(CGRect)frame image:(UIImage *)aImage backgroundColor:(UIColor *)backgroundColor
{
    //Currently, backgroundColor is nil.
    self.image = aImage;
//    self.backgroundColor = backgroundColor;
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
    m_paths = [[NSMutableArray alloc] initWithCapacity:10];
    
    m_currentPath = [[OTBezierPath alloc] init];
//    m_image = nil;
    
    self.strokeWidth = 1.0F;
    self.strokeColor = [UIColor blackColor];
    
    if(self.image != nil)
        self.backgroundColor = [UIColor colorWithPatternImage:self.image];
    else
    {
        self.backgroundColor = [UIColor whiteColor];
        m_image = nil;
    }
    m_drawWithEraser = NO;
}

// ======================================================================================================================================
// Indicate that the user wants to erase graphics
-(void) drawWithEraser
{
    m_drawWithEraser = YES;
    _strokeColor = self.backgroundColor;
}

// ======================================================================================================================================
// Removes last created graphical path
-(void) undoPath
{
    if (m_paths == nil) return;
    [m_paths removeLastObject];
    [self setNeedsDisplay];
}

// ======================================================================================================================================
// Removes last created graphical path
-(void) pushPath:(OTBezierPath *)path
{
    if (path == nil) return;
    [m_paths addObject:path];
}


// ======================================================================================================================================
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, YES, 1.0F);
    
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetFillColorWithColor(context, self.backgroundColor.CGColor);
    CGContextFillRect (context, self.bounds);
    
    // Draw all previous layers, if any
    for (OTBezierPath * path in m_paths)
    {
        [path.strokeColor setStroke];
        [path.path strokeWithBlendMode:kCGBlendModeNormal alpha:path.strokeAlpha];
    }
    
    [m_currentPath.strokeColor setStroke];
    [m_currentPath.path strokeWithBlendMode:kCGBlendModeNormal alpha:m_currentPath.strokeAlpha];

    m_image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    // Draw Image
    [m_image drawInRect:self.bounds];
}

// ======================================================================================================================================
// Start new line when user touches this view
-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    m_currentPath = [[OTBezierPath alloc] init];
    m_currentPath.strokeColor = self.strokeColor;
    m_currentPath.path.lineWidth = self.strokeWidth;
    
    if ([[[event allTouches] allObjects] count] > 1)        // Only one finger is supported
        return;

    UITouch * touch = [[[event allTouches] allObjects] objectAtIndex:0];
    CGPoint point = [touch locationInView:self];
    
    [m_currentPath.path moveToPoint:point]; 
}

// ======================================================================================================================================
// Save all points in the line path
-(void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([[[event allTouches] allObjects] count] > 1)        // Only one finger is supported
        return;
    
    UITouch * touch = [[[event allTouches] allObjects] objectAtIndex:0];
    CGPoint point = [touch locationInView:self];
    
    [m_currentPath.path addLineToPoint:point];
    
    [self setNeedsDisplay];
}

// ======================================================================================================================================
// End line drawing, when user stops touching this view
-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([[[event allTouches] allObjects] count] > 1)        // Only one finger is supported
        return;
    
    UITouch * touch = [[[event allTouches] allObjects] objectAtIndex:0];
    CGPoint point = [touch locationInView:self];
    
    [m_currentPath.path addLineToPoint:point];
    
    [self pushPath:m_currentPath];
    m_currentPath = nil;
    [self setNeedsDisplay];
}

// ======================================================================================================================================
// If drawing was interrupted, throw away current line path
-(void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    m_currentPath = [[OTBezierPath alloc] init];
    [self setNeedsDisplay];
}
@end
