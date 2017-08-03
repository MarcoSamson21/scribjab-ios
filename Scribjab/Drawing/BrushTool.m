//
//  BrushTool.m
//  Scribjab
//
//  Created by Oleg Titov on 12-11-19.
//
//

#import "BrushTool.h"

@interface BrushTool()
{
    UIColor * _alphaColor1;         // alpha color for gradient
    UIColor * _alphaColor2;         // alpha color for gradient
    NSArray * _colors;              // array of gradient colors
    NSMutableArray * _points;
    
    UIImage * _image;               // buffer image for speed
}
-(float) getDistanceBetweenStartPoint:(const CGPoint*)startPoint endPoint:(const CGPoint*)endPoint;
-(float) getAngleInRadiansBetweenStartPoint:(const CGPoint*)startPoint endPoint:(const CGPoint*)endPoint;
@end

@implementation BrushTool

// ======================================================================================================================================
// Get a lollection of path points in this tool
-(NSMutableArray*) getPoints
{
    return _points;
}

// ======================================================================================================================================
-(id)initWithColor:(UIColor *)color width:(float)width andAlpha:(float)alpha
{ 
    self = [super initWithColor:color width:width andAlpha:alpha];
    if (self)
    {
        float r,g,b,a;
        [color getRed:&r green:&g blue:&b alpha:&a];
        _alphaColor1 = [UIColor colorWithRed:r green:g blue:b alpha:0.4F];
        _alphaColor2 = [UIColor colorWithRed:r green:g blue:b alpha:0.05F];
        _colors = [NSArray arrayWithObjects:(id)color.CGColor, (id)_alphaColor1.CGColor, (id)_alphaColor2.CGColor, nil];
    }
    return self;
}

-(void)setColor:(UIColor *)color
{
    if (color == nil)
        return;
    
    super.color = color;
    float r,g,b,a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    _alphaColor1 = [UIColor colorWithRed:r green:g blue:b alpha:0.4F];
    _alphaColor2 = [UIColor colorWithRed:r green:g blue:b alpha:0.05F];
    _colors = [NSArray arrayWithObjects:(id)color.CGColor, (id)_alphaColor1.CGColor, (id)_alphaColor2.CGColor, nil];
}

// ======================================================================================================================================
// Trigonometric functions

// Distance between two points
-(float)getDistanceBetweenStartPoint:(const CGPoint *)startPoint endPoint:(const CGPoint *)endPoint
{
    float dx = endPoint->x - startPoint->x;
    float dy = endPoint->y - startPoint->y;
    return sqrtf(powf(dx, 2.0F) + powf(dy, 2.0F));
}

// angle between two points in radians
-(float)getAngleInRadiansBetweenStartPoint:(const CGPoint *)startPoint endPoint:(const CGPoint *)endPoint
{
    float dx = endPoint->x - startPoint->x;
    float dy = endPoint->y - startPoint->y;
    return atan2f(dy, dx);
}

// ======================================================================================================================================
// Creates path for the specified points
-(void) createPath:(UIBezierPath*)path fromPoint:(CGPoint)startPoint toPoint:(CGPoint)endPoint
{
    if (_points == nil)
        _points = [[NSMutableArray alloc] initWithCapacity:100];
  
    // Get distance between two points
    float dist = [self getDistanceBetweenStartPoint:&startPoint endPoint:&endPoint];
    
    // if two points are two close to each other, then just add the first point
    if (dist < self.width / 2.0f)
    {
//        [_points addObject:[NSValue valueWithCGPoint:startPoint]];
        [_points addObject:[NSValue valueWithCGPoint:endPoint]];
    }
    else
    {
        // add extra points to fill the empty space between the start and end points,
        // if they are too far away from each other.
        float angle = [self getAngleInRadiansBetweenStartPoint:&startPoint endPoint:&endPoint];
        int numberOfExtraPoints = (int)floorf(1.8*dist / self.width);
        dist = dist / (numberOfExtraPoints +1);
        
     //   [_points addObject:[NSValue valueWithCGPoint:startPoint]];
        for (int i = 0; i < numberOfExtraPoints; i++)
        {
            CGPoint newPoint = CGPointMake(startPoint.x + dist*(i+1)*cosf(angle), startPoint.y + dist*(i+1)*sinf(angle));
            [_points addObject:[NSValue valueWithCGPoint:newPoint]];
        }
        [_points addObject:[NSValue valueWithCGPoint:endPoint]];
    }
}

// ======================================================================================================================================
// Renders path to the specified context
-(void) drawPath:(UIBezierPath*)path withContext:(CGContextRef)context boundedBy:(CGRect)rect;
{
    // update buffered image, if there are any points
    if (_points != nil && [_points count] > 0)
    {
        UIGraphicsBeginImageContextWithOptions(rect.size, NO, 1.0F);
        CGContextRef cxc = UIGraphicsGetCurrentContext();
        
        // draw existing image
        [_image drawInRect:rect];
        
        float radiusStart = self.width/4.5F;
        float radiusEnd = self.width/2.0F;
        
        CGFloat locations[] =
        {
            0.0F,           // self.color
            0.5F,           // _alphaColor1
            1.0F            // _alphaColor2
        };
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef) _colors, locations);
        
        for (int i = 0; i < [_points count]; i++)
        {
            CGPoint point = [((NSValue*)[_points objectAtIndex:i]) CGPointValue];
            CGContextDrawRadialGradient(cxc, gradient, point, radiusStart, point, radiusEnd, kCGGradientDrawsBeforeStartLocation);
        }
        
        [_points removeAllObjects];
        
        CGGradientRelease(gradient);
        CGColorSpaceRelease(colorSpace);
        
        _image = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
    }
    
    [_image drawInRect:rect];
}

@end
