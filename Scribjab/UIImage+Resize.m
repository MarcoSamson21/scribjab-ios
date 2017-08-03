//
//  UIImage+Resize.m
//  Scribjab
//
//  Created by Gladys Tang on 12-12-19.
//
//

#import "UIImage+Resize.h"

@implementation UIImage (Resize)

// ======================================================================================================================================
// resize image to the new size.
+ (UIImage *)resizeImageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;  
{
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}
@end
