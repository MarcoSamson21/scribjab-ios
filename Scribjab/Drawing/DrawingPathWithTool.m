//
//  DrawingPathWithTool.m
//  Scribjab
//
//  Created by Oleg Titov on 12-11-19.
//
//
#import <UIKit/UIKit.h>
#import "DrawingPathWithTool.h"
@interface DrawingPathWithTool()
{
    CGPoint _previousPoint;
    BOOL _pathStarted;
}
@end


@implementation DrawingPathWithTool

@synthesize path = _path;
@synthesize tool = _tool;

-(id) initWithTool:(DrawingTool*) tool
{
    self = [super init];
    if (self)
    {
        _path = [[UIBezierPath alloc] init];
        _path.lineJoinStyle = kCGLineJoinRound;
        _path.lineCapStyle = kCGLineCapRound;
        _path.lineWidth = 1.0F;
        _tool = [tool copy];
    }
    return self;
}
// ======================================================================================================================================
// Start path. Add starting point to the path.
-(void) moveToPoint:(CGPoint)point
{
    _previousPoint = point;
    _pathStarted = YES;
}
// ======================================================================================================================================
// Add additional points to array
-(void) addPointToPath:(CGPoint)point
{
    if (!_pathStarted)
    {
        _pathStarted = YES;
        [self moveToPoint:point];
        return;
    }

    // create path with tool
    [self.tool createPath:self.path fromPoint:_previousPoint toPoint:point];

    // save last point
    _previousPoint = point;
}
// ======================================================================================================================================
// A place to finilize the path that is drawn by this tool
-(void) closePathAtPoint:(CGPoint)endPoint
{
    [_tool closePath:_path atPoint:endPoint];
}
// ======================================================================================================================================
-(void) drawPathWithContext:(CGContextRef)context boundedBy:(CGRect)rect
{
    [self.tool drawPath:self.path withContext:context boundedBy:rect];
}

@end
