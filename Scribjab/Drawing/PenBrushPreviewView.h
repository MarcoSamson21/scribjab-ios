//
//  PenBrushPreviewView.h
//  Scribjab
//
//  Created by Oleg Titov on 12-11-19.
//
//

#import <UIKit/UIKit.h>

@interface PenBrushPreviewView : UIView
@property (nonatomic) float width;
@property (nonatomic) float height;
@property (nonatomic, strong) UIColor * color;
@property (nonatomic) BOOL showSoftEdges;
@end
