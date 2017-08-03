//
//  PenTool.m
//  Scribjab
//
//  Created by Oleg Titov on 12-11-19.
//
//
#import "PenTool.h"
#import "CGPointUtils.h"

@interface PenTool()
{
    BOOL _pathStarted;
    CGPoint _point1, _point2, _midPoint1, _midPoint2;
}

void MyColoredPatternPainting (CGContextRef myContext,CGRect rect);

@end

@implementation PenTool

// ======================================================================================================================================
// Creates path for the specified points
-(void) createPath:(UIBezierPath*)path fromPoint:(CGPoint)startPoint toPoint:(CGPoint)endPoint
{
    if (!_pathStarted)
    {
        _pathStarted = YES;
        _point1 = startPoint;
        _midPoint1 = _point1;
    }
    
    _point2 = endPoint;
    _midPoint2 = spuMidPoint(_point1, _point2);
    
    [path moveToPoint:_midPoint1];
    [path addQuadCurveToPoint:_midPoint2 controlPoint:_point1];
    
    // shift points and remove last one
    _point1 = _point2;
    _midPoint1 = _midPoint2;
}

// ======================================================================================================================================
// Renders path to the specified context
-(void) drawPath:(UIBezierPath*)path withContext:(CGContextRef)context boundedBy:(CGRect)rect;
{
    CGContextSaveGState(context);
    CGContextSetShouldAntialias(context, YES);
    CGContextSetStrokeColorWithColor(context, self.color.CGColor);
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGContextSetAlpha(context, self.alpha);
    CGContextAddPath(context, path.CGPath);
    CGContextSetLineWidth(context, self.width);
    
    CGContextSetLineJoin(context, path.lineJoinStyle);
    CGContextSetLineCap(context, path.lineCapStyle);
    
    CGContextStrokePath(context);
    CGContextRestoreGState(context);
}





@end
