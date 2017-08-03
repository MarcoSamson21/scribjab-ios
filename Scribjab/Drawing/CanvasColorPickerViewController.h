//
//  CanvasColorPickerViewController.h
//  Scribjab
//
//  Created by Oleg Titov on 12-11-20.
//
//

#import <UIKit/UIKit.h>
#import "DrawingPropertiesPickerDelegate.h"

@interface CanvasColorPickerViewController : UIViewController
@property (nonatomic, weak) id<CanvasPropertiesPickerDelegate> delegate;

- (IBAction)colorChanged:(id)sender;

@end
