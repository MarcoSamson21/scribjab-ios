//
//  HueSaturationPicker.m
//  Custom color picker controller.
//  Scribjab
//
//  Created by Oleg Titov on 12-11-16.
//
//

#import "HueColorPicker.h"

@interface HueColorPicker()
{
    UIImage * _image;
}
-(void) drawGradientToImage;
@end

// **************************************************************************************************************************************
// **************************************************************************************************************************************

@implementation HueColorPicker

@synthesize hueValue = _hueValue;
-(void)setHueValue:(float)hueValue
{
    if (hueValue < 0.0F || hueValue > 1.0F)
        return;
    
    _hueValue = hueValue;
}

// ======================================================================================================================================
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
       _hueValue = 0.0F;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        _hueValue = 0.0F;
    }
    return self;
}

// ======================================================================================================================================
// Custom draw method. Draw color pallete
 - (void)drawRect:(CGRect)rect
 {
     if (_image == nil)
         [self drawGradientToImage];
     
     [_image drawInRect:self.bounds];
}

// ======================================================================================================================================
// Prepare gradient image to draw on the backgroud of the color picker. 
- (void)drawGradientToImage
{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, YES, 1.0F);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    CGPoint point1 = CGPointMake(0, 0);
    CGPoint point2 = CGPointMake(self.bounds.size.width, 0);
   
    CGFloat locations[] =
    {
        0.0F,           // red
        1.0F / 6.0F,    // orange
        2.0F / 6.0F,    // yellow
        3.0F / 6.0F,    // green
        4.0F / 6.0F,    // aqua
        5.0F / 6.0F,    // blue
        1.0F            // purple
    };
    
    NSMutableArray * colors = [[NSMutableArray alloc] initWithCapacity:7];
    
    // Create colors for hue values: {0.0, 0.17, 0.33, 0.5, 0.67, 0.83, 1.0}
    [colors addObject:(id)[UIColor colorWithHue:0.0000001F saturation:1.0F brightness:1.0F alpha:1.0F].CGColor];
    for (float i = 1.0F; i < 6.0F; i++)
    {
        [colors addObject:(id)[UIColor colorWithHue:i*1.0F/6.0F saturation:1.0F brightness:1.0F alpha:1.0F].CGColor];
    }
    [colors addObject:(id)[UIColor colorWithHue:1.0F saturation:1.0F brightness:1.0F alpha:1.0F].CGColor];
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef) colors, locations);
    
    CGContextAddRect(context, self.bounds);
    CGContextClip(context);
    
    CGContextDrawLinearGradient(context, gradient, point1, point2, 0);
    
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);

    CGContextRestoreGState(context);
    _image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext(); 
}

// ======================================================================================================================================
// On touch event - change the hue value and notify event listeners
-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([[[event allTouches] allObjects] count] > 1)        // Only one finger is supported
        return;
    
    UITouch * touch = [[[event allTouches] allObjects] objectAtIndex:0];
    CGPoint point = [touch locationInView:self];
    
    float percent = point.x / self.bounds.size.width;
    //NSInteger hue = ceill(360.0F * percent);
    
    _hueValue = percent;
    
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}
// ======================================================================================================================================
// On touch moved event - change the hue value and notify event listeners
-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([[[event allTouches] allObjects] count] > 1)        // Only one finger is supported
        return;
    
    UITouch * touch = [[[event allTouches] allObjects] objectAtIndex:0];
    CGPoint point = [touch locationInView:self];
    
    
    if (![self pointInside:point withEvent:nil])
        return;
    
    float percent = point.x / self.bounds.size.width;
    //NSInteger hue = ceill(360.0F * percent);
    
    _hueValue = percent;
    
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}
@end
