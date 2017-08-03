//
//  ManagedDocument.m
//  Scribjab
//
//  Created by Oleg Titov on 12-12-18.
//
//

#import "ManagedDocument.h"

@implementation ManagedDocument
-(void)handleError:(NSError *)error userInteractionPermitted:(BOOL)userInteractionPermitted
{
#ifdef DEBUG
    NSLog(@"ManagedDocumetn error: %@", error);
#endif
}
@end
