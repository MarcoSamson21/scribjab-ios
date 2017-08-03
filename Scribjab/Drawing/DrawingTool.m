//
//  DrawingTool.m
//  Scribjab
//
//  Created by Oleg Titov on 12-11-19.
//
//

#import "DrawingTool.h"

@implementation DrawingTool
@synthesize color = _color;
@synthesize width = _width;
@synthesize alpha = _alpha;

-(id) initWithColor:(UIColor*) color width:(float)width andAlpha:(float)alpha
{
    self = [super init];
    if (self)
    {
        self.color = color;
        self.width = width;
        self.alpha = alpha;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    DrawingTool *copy = [[self class] allocWithZone:zone];
    if (copy)
    {
        [copy setColor:self.color];
        [copy setWidth:self.width];
        [copy setAlpha:self.alpha];
    }
    return copy;
}

-(void) createPath:(UIBezierPath*)path fromPoint:(CGPoint)startPoint toPoint:(CGPoint)endPoint
{ /* must be implemented in a subclass */ }
-(void) drawPath:(UIBezierPath*)path withContext:(CGContextRef)context boundedBy:(CGRect)rect
{ /* must be implemented in a subclass */ }
-(void) closePath:(UIBezierPath*)path atPoint:(CGPoint)endPoint
{ /* must be implemented in a subclass */ }
@end


