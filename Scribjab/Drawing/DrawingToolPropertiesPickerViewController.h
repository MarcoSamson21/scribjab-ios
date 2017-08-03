//
//  BrushToolPickerViewController.h
//  Scribjab
//
//  Created by Oleg Titov on 12-11-15.
//
//

#import <UIKit/UIKit.h>
#import "HueColorPicker.h"
#import "SaturationBrightnessColorPicker.h"
#import "PenBrushPreviewView.h"
#import "DrawingPropertiesPickerDelegate.h"
#import "GreyColorPicker.h"

@interface DrawingToolPropertiesPickerViewController : UIViewController

@property (nonatomic, weak) id<DrawingPropertiesPickerDelegate> delegate;
@property (nonatomic, strong) UIColor * toolColor;
@property (nonatomic, strong) UIColor * savedColor;
@property (nonatomic) float toolWidth;
//@property (nonatomic) float toolHeight;
@property (nonatomic) BOOL showSoftEdges;           // to display selection for brush

@property (nonatomic) float maxWidth;
@property (nonatomic) float minWidth;

- (IBAction)hueValueChanged:(id)sender;
- (IBAction)saturationBrightnessValueChanged:(id)sender;
- (IBAction)widthValueChanged:(id)sender;
- (IBAction)greyValueChanged:(id)sender;
- (IBAction)saveBtnClick:(id)sender;
- (IBAction)savedColorBtnClick:(id)sender;
@property (strong, nonatomic) IBOutlet PenBrushPreviewView *selectionPreview;
@property (strong, nonatomic) IBOutlet HueColorPicker *hueColorPicker;
@property (strong, nonatomic) IBOutlet SaturationBrightnessColorPicker *saturationBrightnessColorPicker;
@property (strong, nonatomic) IBOutlet GreyColorPicker *greyColorPicker;
@property (strong, nonatomic) IBOutlet UISlider *widthSelectionSlider;
@property (strong, nonatomic) IBOutlet UISlider *heightSelectionSlider;
@property (weak, nonatomic) IBOutlet UIButton *savedBtn;

@end
