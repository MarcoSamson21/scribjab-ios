//
//  DrawingToolPropertiesDelegate.h
//  Scribjab
//
//  Created by Oleg Titov on 12-11-19.
//
//

#import <Foundation/Foundation.h>

@protocol DrawingPropertiesPickerDelegate <NSObject>
-(void) drawingToolColorChanged:(id)sender toColor:(UIColor *)toolColor;      // color changed
-(void) drawingToolWidthChanged:(id)sender toWidth:(float)toolWidth;          // tool width changed
-(void) onClickSave;
-(void) onClickSavedColorBtn:(id)sender;
@end

@protocol CanvasPropertiesPickerDelegate <NSObject>
-(void) canvasToolColorChanged:(id)sender toColor:(UIColor *)newColor;      // color changed
@end
