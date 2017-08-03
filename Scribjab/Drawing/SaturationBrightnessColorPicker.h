//
//  SaturationColorPicker.h
//  Custom color picker controller.
//  Allows users to select saturation and brightness for the specified color, defined by a hue value.
//  Scribjab
//
//  Created by Oleg Titov on 12-11-16.
//
//

#import <UIKit/UIKit.h>

@interface SaturationBrightnessColorPicker : UIControl
@property (nonatomic) float hueValue;           // current hue value for which saturation picker is shown
@property (nonatomic) float saturationValue;    // current value of the controller range [0.0, 1.0]
@property (nonatomic) float brightnessValue;    // current value of the controller range [0.0, 1.0]
@end
