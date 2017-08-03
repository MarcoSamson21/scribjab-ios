//
//  EraserToolPropertiesPickerViewController.h
//  Scribjab
//
//  Created by Oleg Titov on 12-11-20.
//
//

#import <UIKit/UIKit.h>
#import "PenBrushPreviewView.h"
#import "DrawingPropertiesPickerDelegate.h"

@interface EraserToolPropertiesPickerViewController : UIViewController
@property (nonatomic) float toolWidth;
@property (nonatomic, weak) id<DrawingPropertiesPickerDelegate> delegate;

- (IBAction)widthSliderChanged:(id)sender;
@property (strong, nonatomic) IBOutlet PenBrushPreviewView *previewArea;
@property (strong, nonatomic) IBOutlet UISlider *toolWidthSlider;
@end
