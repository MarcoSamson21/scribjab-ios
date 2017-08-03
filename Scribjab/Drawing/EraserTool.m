//
//  EraserTool.m
//  Scribjab
//
//  Created by Oleg Titov on 12-11-20.
//
//

#import "EraserTool.h"


@interface EraserTool()
{
    UIImage * _image;
}

@end
@implementation EraserTool

// ======================================================================================================================================
// Renders path to the specified context
-(void) drawPath:(UIBezierPath*)path withContext:(CGContextRef)context boundedBy:(CGRect)rect;
{
    CGContextSaveGState(context);
    CGContextSetShouldAntialias(context, YES);
    CGContextSetStrokeColorWithColor(context, self.color.CGColor);
    //    CGContextSetBlendMode(context, kCGBlendModeClear);    // not supported by the CALayer
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGContextSetAlpha(context, 1.0f);
    CGContextAddPath(context, path.CGPath);
    CGContextSetLineWidth(context, self.width);
    
    CGContextSetLineJoin(context, path.lineJoinStyle);
    CGContextSetLineCap(context, path.lineCapStyle);
    
    CGContextStrokePath(context);
    CGContextRestoreGState(context);
}

@end
