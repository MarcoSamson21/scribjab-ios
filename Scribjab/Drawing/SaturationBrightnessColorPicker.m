//
//  SaturationColorPicker.m
//  Custom color picker controller.
//  Allows users to select saturation for the specified color, defined by a hue value.
//
//  Scribjab
//
//  Created by Oleg Titov on 12-11-16.
//
//

#import "SaturationBrightnessColorPicker.h"

@interface SaturationBrightnessColorPicker()
{
    UIImage * _image;   // buffer image
    BOOL _initialized;
}
-(void) drawGradientToImage;
-(void) initialize;
@end

// **************************************************************************************************************************************
// **************************************************************************************************************************************

@implementation SaturationBrightnessColorPicker

@synthesize brightnessValue = _brightnessValue;
@synthesize saturationValue = _saturationValue;
@synthesize hueValue = _hueValue;

// ======================================================================================================================================
- (void)setHueValue:(float)hueValue
{
    if (hueValue < 0.0F || hueValue > 1.0F)
        return;
    
    if (_hueValue != hueValue)
    {
        _hueValue = hueValue;
        _image = nil;
        [self setNeedsDisplay];
    }
}
// ======================================================================================================================================
-(void)setSaturationValue:(float)saturationValue
{
    if (saturationValue < 0.0F || saturationValue > 1.0F)
        return;
    
    if (_saturationValue != saturationValue)
    {
        _saturationValue = saturationValue;
        _image = nil;
        [self setNeedsDisplay];
    }
}

// ======================================================================================================================================
-(void)setBrightnessValue:(float)brightnessValue
{
    if (brightnessValue < 0.0F || brightnessValue > 1.0F)
        return;
    
    if (_brightnessValue != brightnessValue)
    {
        _brightnessValue = brightnessValue;
        _image = nil;
        [self setNeedsDisplay];
    }
}

// ======================================================================================================================================
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self initialize];
    }
    return self;
}

// ======================================================================================================================================
// Custom initialization
- (void) initialize
{
    _saturationValue = 1.0F;
    _brightnessValue = 1.0F;
}

// ======================================================================================================================================
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    if (_image == nil)
        [self drawGradientToImage];
    
    [_image drawInRect:self.bounds];
}

// ======================================================================================================================================
// Buffer gradient background to image first.
- (void)drawGradientToImage
{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, YES, 1.0F);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    CGPoint point1 = CGPointMake(0, 0);
    CGPoint point2 = CGPointMake(self.bounds.size.width, 0);
    
    CGFloat locations[] =
    {
        0.0F,    // black (dark, saturated)
        0.5F,    // base color (light, saturated)
        1.0F     // white (light, unsaturated)
    };
    
    NSMutableArray * colors = [[NSMutableArray alloc] initWithCapacity:3];
    [colors addObject:(id)[UIColor colorWithHue:_hueValue saturation:1.0F brightness:0.0F alpha:1.0F].CGColor];
    [colors addObject:(id)[UIColor colorWithHue:_hueValue saturation:1.0F brightness:1.0F alpha:1.0F].CGColor];
    [colors addObject:(id)[UIColor colorWithHue:_hueValue saturation:0.0F brightness:1.0F alpha:1.0F].CGColor];

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
// Handle value selection. Calculate new saturation and brightness values and notify event listeners. 
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([[[event allTouches] allObjects] count] > 1)        // Only one finger is supported
        return;
    
    UITouch * touch = [[[event allTouches] allObjects] objectAtIndex:0];
    CGPoint point = [touch locationInView:self];
    
    if (point.x < self.bounds.size.width / 2)
    {
        float percent = point.x * 2 / self.bounds.size.width;
        _saturationValue = 1.0F;
        _brightnessValue = percent;
        
    }
    else if (point.x > self.bounds.size.width / 2)
    {
        float percent = (point.x - self.bounds.size.width / 2) / (self.bounds.size.width / 2);
        _saturationValue = 1.0F - percent;
        _brightnessValue = 1.0F;
    }
    else  // exact middle
    {
        _saturationValue = 1.0F;
        _brightnessValue = 1.0F;
    }
    
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}
// ======================================================================================================================================
// Handle value selection. Calculate new saturation and brightness values and notify event listeners.
-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([[[event allTouches] allObjects] count] > 1)        // Only one finger is supported
        return;
    
    UITouch * touch = [[[event allTouches] allObjects] objectAtIndex:0];
    CGPoint point = [touch locationInView:self];
    
    if (![self pointInside:point withEvent:nil])
        return;
    
    if (point.x < self.bounds.size.width / 2)
    {
        float percent = point.x * 2 / self.bounds.size.width;
        _saturationValue = 1.0F;
        _brightnessValue = percent;
        
    }
    else if (point.x > self.bounds.size.width / 2)
    {
        float percent = (point.x - self.bounds.size.width / 2) / (self.bounds.size.width / 2);
        _saturationValue = 1.0F - percent;
        _brightnessValue = 1.0F;
    }
    else  // exact middle
    {
        _saturationValue = 1.0F;
        _brightnessValue = 1.0F;
    }
    
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}
@end
