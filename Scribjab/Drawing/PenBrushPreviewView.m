//
//  PenBrushPreviewView.m
//  Scribjab
//
//  Created by Oleg Titov on 12-11-19.
//
//

#import "PenBrushPreviewView.h"

@implementation PenBrushPreviewView

@synthesize width = _width;
@synthesize height = _height;
@synthesize color = _color;
@synthesize showSoftEdges = _showSoftEdges;

// ======================================================================================================================================

// set drawing tool width for preview.
-(void) setWidth:(float)width
{
//    if (_width != width)
//    {
        _width = width+3.0f;
        if (_width < 0.0F)
            _width = 0.0F;
        
        CGRect size = self.bounds;
        self.bounds = CGRectMake(size.origin.x, size.origin.y, _width, _width);
        [self setNeedsDisplay];
//    }
}

// ==================================================================================================================================
-(void) setHeight:(float)height
{
    _height = height+3.0f;
    if(_height < 0.0F)
        _height = 0.0F;
    CGRect size = self.bounds;
    self.bounds = CGRectMake(size.origin.x, size.origin.y, _width, _height);
    [self setNeedsDisplay];
}

// ======================================================================================================================================
// set preview selection color
-(void)setColor:(UIColor *)color
{
    if (color == nil) {
        return;
    }
    
    if (_color != color) {
        _color = color;
        [self setNeedsDisplay];
    }
}
//-(void) setColor:(UIColor *)color
//{
//    if (_color != color)
//    {
//        _color = color;
//        [self setNeedsDisplay];
//    }
//}

// ======================================================================================================================================
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor colorWithRed:0.0F green:0.0F blue:0.0F alpha:0.0F];     // set background to transparent
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        self.backgroundColor = [UIColor colorWithRed:0.0F green:0.0F blue:0.0F alpha:0.0F];     // set background to transparent
    }
    return self;
}

// ======================================================================================================================================
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGPoint center;
    center.x = CGRectGetMidX(self.bounds);
    center.y = CGRectGetMidY(self.bounds);

    float radius = MIN(self.bounds.size.width, self.bounds.size.height) / 2;
    
    if (_showSoftEdges)
    {
        float r,g,b,a = 0.0F;
        [_color getRed:&r green:&g blue:&b alpha:&a];
   
        UIColor * alphaColor1 = [UIColor colorWithRed:r green:g blue:b alpha:0.4F];
        UIColor * alphaColor2 = [UIColor colorWithRed:r green:g blue:b alpha:0.05F];
        
        NSArray * colors = [NSArray arrayWithObjects:(id)_color.CGColor, (id)alphaColor1.CGColor, (id)alphaColor2.CGColor, nil];
        
        float radiusStart = radius/2.5F;
        
        CGFloat locations[] = {0.0F, 0.8F, 1.0F};  // _color, alpha1,  alpha2
   
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef) colors, locations);
  
        CGContextDrawRadialGradient(context, gradient, center, radiusStart, center, radius, kCGGradientDrawsBeforeStartLocation);
  
        CGGradientRelease(gradient);
        CGColorSpaceRelease(colorSpace);
    }
    else
    {
      
        // Filled circle
        CGContextBeginPath(context);
        [_color setFill];
        CGContextAddArc(context, center.x, center.y, radius-1.0F, 0.0F, 2*M_PI, YES);
        CGContextClosePath(context);
        CGContextFillPath(context);
        
        // borders
        CGContextBeginPath(context);
        UIColor * grey = [UIColor colorWithWhite:0.5f alpha:1.0f];
        [grey setStroke];
        CGContextAddArc(context, center.x, center.y, radius-1.0f, 0.0F, 2*M_PI, YES);
        CGContextStrokePath(context);
        
        CGContextBeginPath(context);
        grey = [UIColor colorWithWhite:0.8f alpha:1.0f];
        [grey setStroke];
        CGContextAddArc(context, center.x, center.y, radius-0.5f, 0.0F, 2*M_PI, YES);
        CGContextStrokePath(context);
        
        CGContextBeginPath(context);
        grey = [UIColor colorWithWhite:0.93f alpha:1.0f];
        [grey setStroke];
        CGContextAddArc(context, center.x, center.y, radius, 0.0F, 2*M_PI, YES);
        CGContextStrokePath(context);
       
    }
}


@end
