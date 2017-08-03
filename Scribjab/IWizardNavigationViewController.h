//
//  IWizardNavigationViewController.h
//  Scribjab
//
//  Created by Oleg Titov on 12-08-22.
//  Copyright (c) 2012 SFU. All rights reserved.
// 
//  Base controller class for wizard-type navigation user interface views. 
//  Defines data that each wizard view contributes to. 
//

#import <UIKit/UIKit.h>

@protocol IWizardNavigationViewController <NSObject>
    @property (nonatomic, strong) id wizardDataObject;              // Data that wizard gathers through multiple windows 
@end

