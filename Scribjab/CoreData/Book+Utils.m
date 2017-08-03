//
//  Book+Utils.m
//  Scribjab
//
//  Created by Oleg Titov on 12-11-27.
//
//

#import "Book+Utils.h"
#import "ModalConstants.h"

@implementation Book (Utils)

// sets data that comes from the dictionary. No foreign key lookups done here. 
-(void) setBasicDataFromDictionary:(NSDictionary*) dict;    
{
    self.bookSizeKB             = [dict objectForKey:@"bookSizeKB"];
    
    // set date
    NSNumber * interval         = [dict objectForKey:@"dateAdded"];
    self.createDate             = [NSDate dateWithTimeIntervalSince1970:[interval doubleValue] / 1000L];    // date form java time stamp
    
    self.remoteId               = [dict objectForKey:@"id"];
    self.title1                 = [dict objectForKey:@"title1"];
    self.title2                 = [dict objectForKey:@"title2"];
    self.description1           = [dict objectForKey:@"description1"];
    self.description2           = [dict objectForKey:@"description2"];
    self.isDownloaded           = [NSNumber numberWithBool:NO];
    self.backgroundColorCode    = [dict objectForKey:@"imageBgColor"];
//    self.ageGroupRemoteId       = [dict objectForKey:@"ageGroupId"];
    id agC = [dict objectForKey:@"ageGroupId"];
    if (agC == [NSNull null])
        self.ageGroupRemoteId = nil;
    else
        self.ageGroupRemoteId = agC;

    self.isHidden               = [dict objectForKey:@"hidden"];
    
    NSString * approval = [dict objectForKey:@"approvalStatus"];
    if ([approval isEqualToString:@"APPROVED"] )
        self.approvalStatus = [NSNumber numberWithInt:BookApprovalStatusApproved];
    else if ([approval isEqualToString:@"PENDING"])
        self.approvalStatus = [NSNumber numberWithInt:BookApprovalStatusPending];
    else if ([approval isEqualToString:@"REJECTED"])
        self.approvalStatus = [NSNumber numberWithInt:BookApprovalStatusRejected];
    else
        self.approvalStatus = [NSNumber numberWithInt:BookApprovalStatusSaved];

    self.isPublished        = [NSNumber numberWithBool:NO];
    if ([self.approvalStatus isEqualToNumber:[NSNumber numberWithInt:BookApprovalStatusApproved]])
        self.isPublished    = [NSNumber numberWithBool:YES];
    
    self.likeCount          = [NSNumber numberWithInt:0];       // to be set by the caller
    
    
    id rjC = [dict objectForKey:@"rejectionComment"];
    if (rjC == [NSNull null])
        self.rejectionComment = nil;
    else
        self.rejectionComment = rjC;
    
    self.tagSummary         = @"";                              // to be set by the caller
    self.updateTimeStamp    = [NSDate date];
}

@end
