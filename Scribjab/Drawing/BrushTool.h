//
//  BrushTool.h
//  Scribjab
//
//  Created by Oleg Titov on 12-11-19.
//
//

#import "DrawingTool.h"

@interface BrushTool : DrawingTool
-(NSMutableArray*) getPoints;      // Get a lollection of path points in this tool
@end
