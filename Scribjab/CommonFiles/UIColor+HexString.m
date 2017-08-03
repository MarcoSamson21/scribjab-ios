//
//  UIColor+HexString.m
//  Scribjab
//
//  Created by Oleg Titov on 12-11-14.
//
//  Category for UIColor to convert between HEX strings representation of color and UIColor objects.
//  Code taken from http://stackoverflow.com/questions/1560081/how-can-i-create-a-uicolor-from-a-hex-string
//
//

#import "UIColor+HexString.h"

// **************************************************************************************************************************************
// **************************************************************************************************************************************

@interface UIColor()

+ (CGFloat) colorComponentFrom: (NSString *) string start: (NSUInteger) start length: (NSUInteger) length;

@end

// **************************************************************************************************************************************
// **************************************************************************************************************************************

@implementation UIColor(HexString)

+ (UIColor *) colorWithHexString: (NSString *) hexString
{
    NSString *colorString = [[hexString stringByReplacingOccurrencesOfString: @"#" withString: @""] uppercaseString];
    CGFloat alpha, red, blue, green;
    switch ([colorString length]) {
        case 3: // #RGB
            alpha = 1.0f;
            red   = [UIColor colorComponentFrom: colorString start: 0 length: 1];
            green = [UIColor colorComponentFrom: colorString start: 1 length: 1];
            blue  = [UIColor colorComponentFrom: colorString start: 2 length: 1];
            break;
        case 4: // #ARGB
            alpha = [UIColor colorComponentFrom: colorString start: 0 length: 1];
            red   = [UIColor colorComponentFrom: colorString start: 1 length: 1];
            green = [UIColor colorComponentFrom: colorString start: 2 length: 1];
            blue  = [UIColor colorComponentFrom: colorString start: 3 length: 1];
            break;
        case 6: // #RRGGBB
            alpha = 1.0f;
            red   = [UIColor colorComponentFrom: colorString start: 0 length: 2];
            green = [UIColor colorComponentFrom: colorString start: 2 length: 2];
            blue  = [UIColor colorComponentFrom: colorString start: 4 length: 2];
            break;
        case 8: // #AARRGGBB
            alpha = [UIColor colorComponentFrom: colorString start: 0 length: 2];
            red   = [UIColor colorComponentFrom: colorString start: 2 length: 2];
            green = [UIColor colorComponentFrom: colorString start: 4 length: 2];
            blue  = [UIColor colorComponentFrom: colorString start: 6 length: 2];
            break;
        default:
            [NSException raise:@"Invalid color value" format: @"Color value %@ is invalid.  It should be a hex value of the form #RBG, #ARGB, #RRGGBB, or #AARRGGBB", hexString];
            break;
    }
    return [UIColor colorWithRed: red green: green blue: blue alpha: alpha];
}

// to suppress the "Category is implementing a method which will also be implemented by its primary class". warning.
// http://www.cocoabuilder.com/archive/xcode/313767-disable-warning-for-override-in-category.html
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
+ (CGFloat) colorComponentFrom: (NSString *) string start: (NSUInteger) start length: (NSUInteger) length
{
    NSString *substring = [string substringWithRange: NSMakeRange(start, length)];
    NSString *fullHex = length == 2 ? substring : [NSString stringWithFormat: @"%@%@", substring, substring];
    unsigned hexComponent;
    [[NSScanner scannerWithString: fullHex] scanHexInt: &hexComponent];
    return hexComponent / 255.0;
}
#pragma clang diagnostic pop

// ======================================================================================================================================
// get hex string from uicolor. RRGGBB
+ (NSString *)hexStringForColor:(UIColor *)color
{
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    CGFloat r = components[0];
    CGFloat g = components[1];
    CGFloat b = components[2];
    
    return [NSString stringWithFormat:@"%02X%02X%02X", (int)(r * 255), (int)(g * 255), (int)(b * 255)];
}

@end