//
//  DrawingPadImageUpdatedDelegate.h
//  Scribjab
//
//  Created by Oleg Titov on 12-11-22.
//
//

#import <Foundation/Foundation.h>

@protocol DrawingPadImageUpdatedDelegate <NSObject>
-(void) imageUpdatedWithImage:(UIImage*)image andBackgroundColor:(UIColor*)color;
@end
