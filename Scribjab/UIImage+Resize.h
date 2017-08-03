//
//  UIImage+Resize.h
//  Scribjab
//
//  Created by Gladys Tang on 12-12-19.
//
//

#import <UIKit/UIKit.h>

@interface UIImage (Resize)
+ (UIImage *)resizeImageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize; //resize image.
@end
