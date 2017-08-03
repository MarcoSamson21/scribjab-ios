//
//  HueSaturationPicker.m
//  Custom color picker controller.
//  Scribjab
//
//  Created by Oleg Titov on 12-11-16.
//
//

#import "GreyColorPicker.h"

@interface GreyColorPicker()
{
    UIImage * _image;
}
-(void) drawGradientToImage;
@end

// **************************************************************************************************************************************
// **************************************************************************************************************************************

@implementation GreyColorPicker

@synthesize greyValue;
-(void)setGreyValue:(float)gValue
{
    self.hueValue = gValue;
}
-(float)greyValue
{
    return self.hueValue;
}
//
//// ======================================================================================================================================
//- (id)initWithFrame:(CGRect)frame
//{
//    self = [super initWithFrame:frame];
//    if (self) {
//        self.hueValue = 0.0F;
//    }
//    return self;
//}
//
//- (id)initWithCoder:(NSCoder *)aDecoder
//{
//    self = [super initWithCoder:aDecoder];
//    if (self)
//    {
//        self.hueValue = 0.0F;
//    }
//    return self;
//}

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
        0.0F,           // black
        1.0F            // white
    };
    
    NSMutableArray * colors = [[NSMutableArray alloc] initWithCapacity:2];
    
    // Create colors for hue values: {0.0, 1.0}
    [colors addObject:(id)[UIColor colorWithRed:0 green:0 blue:0 alpha:1.0f].CGColor];
//    for (float i = 1.0F; i < 6.0F; i++)
//    {
//        [colors addObject:(id)[UIColor colorWithHue:i*1.0F/6.0F saturation:1.0F brightness:1.0F alpha:1.0F].CGColor];
//    }
    [colors addObject:(id)[UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f].CGColor];
    
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
//
//// ======================================================================================================================================
//// On touch event - change the hue value and notify event listeners
//-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
//{
//    if ([[[event allTouches] allObjects] count] > 1)        // Only one finger is supported
//        return;
//    
//    UITouch * touch = [[[event allTouches] allObjects] objectAtIndex:0];
//    CGPoint point = [touch locationInView:self];
//    
//    float percent = point.x / self.bounds.size.width;
//    //NSInteger hue = ceill(360.0F * percent);
//    
//    self.greyValue = percent;
//    
//    [self sendActionsForControlEvents:UIControlEventValueChanged];
//}
//// ======================================================================================================================================
//// On touch moved event - change the hue value and notify event listeners
//-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
//{
//    if ([[[event allTouches] allObjects] count] > 1)        // Only one finger is supported
//        return;
//    
//    UITouch * touch = [[[event allTouches] allObjects] objectAtIndex:0];
//    CGPoint point = [touch locationInView:self];
//    
//    
//    if (![self pointInside:point withEvent:nil])
//        return;
//    
//    float percent = point.x / self.bounds.size.width;
//    //NSInteger hue = ceill(360.0F * percent);
//    
//    self = percent;
//    
//    [self sendActionsForControlEvents:UIControlEventValueChanged];
//}
@end
