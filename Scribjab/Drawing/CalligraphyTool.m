//
//  CalligraphyTool.m
//  Scribjab
//
//  Created by Oleg Titov on 12-11-19.
//
//

#import "CalligraphyTool.h"
#import "CGPointUtils.h"

//#define ALPHA 0.4f

@interface CalligraphyTool()
{
    float _prevWidthOffset;
    BOOL _pathStarted;
    CGPoint _point1, _point2, _midPointTop1, _midPointTop2, _midPointBottom1, _midPointBottom2;
}

@end

@implementation CalligraphyTool


// ======================================================================================================================================
// Creates path for the specified points
-(void) createPath:(UIBezierPath*)path fromPoint:(CGPoint)startPoint toPoint:(CGPoint)endPoint
{    
    float MAX_WIDTH = self.width;// 60.0f;
    float MIN_WIDTH = 2.0f;
    
    float widthOffset = MIN_WIDTH / 2.0f;
    
    float MAX_DISTANCE = 2.0f * MAX_WIDTH;
    
    if (!_pathStarted)
    {
        _point1 = startPoint;
        _prevWidthOffset = MIN_WIDTH / 2.0f;
    }
    
    // Calculate direction and perpendicular to vector.
    CGPoint dir = spuSubtractPoints(_point1, endPoint);
    CGPoint perpendicular = spuNormalizeVector(spuPerpendicularVector(dir));
    
    float distance = spuDistanceBetweenPoints(_point1, endPoint);
    
    if (distance < MIN_WIDTH * 2.0f) //(float)self.width/2.5f)
    {
        return;
    }
    
    if (isnan(perpendicular.x) || isnan(perpendicular.y))
    {
        return;
    }
    
    widthOffset = distance / MAX_DISTANCE;
    
    if (widthOffset > 1.0f)
        widthOffset = MAX_WIDTH;
    else
    {
        widthOffset = MAX_WIDTH * widthOffset;
        if (widthOffset < MIN_WIDTH)
            widthOffset = MIN_WIDTH;
        else
            widthOffset = widthOffset;
    }
    
    
    widthOffset = widthOffset * 0.2f + _prevWidthOffset * 0.8f;
    _prevWidthOffset = widthOffset;
    widthOffset = widthOffset / 2.0f;
    
    if (!_pathStarted)
    {
        _pathStarted = YES;
        _midPointTop1       = spuMidPoint(_point1, endPoint);
        _midPointBottom1    = _midPointTop1;
        
        _midPointTop1       = spuAddPoints(_midPointTop1, spuMultiplyPoint(perpendicular, widthOffset));
        _midPointBottom1    = spuSubtractPoints(_midPointBottom1, spuMultiplyPoint(perpendicular, widthOffset));
    }
    
    _point2 = endPoint;
    
    dir = spuSubtractPoints(_point1, _point2);
    perpendicular = spuNormalizeVector(spuPerpendicularVector(dir));
    
    // Calculate current mid points for new endPoint
    _midPointTop2       = spuAddPoints(spuMidPoint(_point1, _point2), spuMultiplyPoint(perpendicular, widthOffset));
    _midPointBottom2    = spuSubtractPoints(spuMidPoint(_point1, _point2), spuMultiplyPoint(perpendicular, widthOffset));
    
    // Calculate current control points
    CGPoint controlTop       = spuAddPoints(_point1, spuMultiplyPoint(perpendicular, widthOffset));
    CGPoint controlBottom    = spuSubtractPoints(_point1, spuMultiplyPoint(perpendicular, widthOffset));
    
    
    UIBezierPath *tempPath = [[UIBezierPath alloc] init];
    
    [tempPath moveToPoint:_midPointTop1];
    [tempPath addQuadCurveToPoint:_midPointTop2 controlPoint:controlTop];
    [tempPath addLineToPoint:_midPointBottom2];
    [tempPath addQuadCurveToPoint:_midPointBottom1 controlPoint:controlBottom];
    [tempPath addLineToPoint:_midPointTop1];
    
    [tempPath closePath];

    _point1             = _point2;
    _midPointTop1       = _midPointTop2;
    _midPointBottom1    = _midPointBottom2;

    [path appendPath:tempPath]; 
}

// ======================================================================================================================================
// Add a circle at the end of the path to avoid abrupt edges
-(void)closePath:(UIBezierPath *)path atPoint:(CGPoint)endPoint
{
    CGPoint midPoint = endPoint;
    
    // If path started - calculate the center of the circle using the last end-mid points.
    if (_pathStarted)
    {
        midPoint = spuMidPoint(_midPointTop2, _midPointBottom2);
    }
    else
    {
        // make a dot that is visible
        _prevWidthOffset = 4.0f;
    }
    
    [path addArcWithCenter:midPoint radius:_prevWidthOffset / 2.0f startAngle:0 endAngle:(2.0f*M_PI) clockwise:YES];
}

// ======================================================================================================================================
// Renders path to the specified context
-(void)drawPath:(UIBezierPath *)path withContext:(CGContextRef)context boundedBy:(CGRect)rect
{
    CGContextSaveGState(context);
    CGContextSetShouldAntialias(context, YES);
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGContextSetFillColorWithColor(context, self.color.CGColor);
    CGContextSetAlpha(context, self.alpha);
    CGContextAddPath(context, path.CGPath);
    CGContextSetLineWidth(context, self.width);
    
    CGContextSetLineJoin(context, path.lineJoinStyle);
    CGContextSetLineCap(context, path.lineCapStyle);
    
    CGContextFillPath(context);
    CGContextRestoreGState(context);
}

@end
