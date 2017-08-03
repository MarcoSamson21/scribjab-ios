//
//  GreyColorPicker.h
//  Scribjab
//
//  Created by Oleg Titov on 13-04-18.
//
//

#import <UIKit/UIKit.h>
#import "HueColorPicker.h"

@interface GreyColorPicker : HueColorPicker
@property (nonatomic) float greyValue;     // current value of the controller range [0.0, 1.0]
@end
