//
//  ModalNavigationViewControllerDelegate.h
//  Scribjab
//
//  Created by Oleg Titov on 12-08-22.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol WizardNavigationViewControllerDelegate <NSObject>
 
@optional
-(void) viewControllerInNavigation:(id)sender finishedNavigationAndRequestsModalDismissal:(BOOL)dismiss;

@end
