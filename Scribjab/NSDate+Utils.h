//
//  NSDate+Utils.h
//  Scribjab
//
//  Created by Oleg Titov on 12/10/2013.
//
//

#import <Foundation/Foundation.h>

@interface NSDate (Utils)

// Determine the number of calendar days between two dates
+ (NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime;

@end
