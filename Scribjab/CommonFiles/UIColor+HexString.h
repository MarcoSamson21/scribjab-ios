//
//  UIColor+HexString.h
//  Scribjab
//
//  Created by Oleg Titov on 12-11-14.
//
//

#import <UIKit/UIKit.h>

@interface UIColor (HexString)
+ (UIColor *) colorWithHexString: (NSString *) hexString;
+ (NSString *)hexStringForColor:(UIColor *)color;
@end
