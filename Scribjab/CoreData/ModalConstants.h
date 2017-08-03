//
//  ModalConstants.h
//  Scribjab
//
//  Created by Oleg Titov on 12-11-27.
//
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, BookApprovalStatus)
{
    BookApprovalStatusSaved = 0,
    BookApprovalStatusPending = 1,
    BookApprovalStatusApproved = 2,
    BookApprovalStatusRejected = 3
};