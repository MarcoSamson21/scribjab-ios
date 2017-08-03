//
//  LanguageManager.h
//  Scribjab
//
//  Created by Oleg Titov on 12-11-29.
//
//

#import <Foundation/Foundation.h>
#import "Language.h"

@interface LanguageManager : NSObject
+ (Language *)getLanguageByRemoteId:(int) remoteId;
+ (NSMutableArray *)getAllLanguages;
+ (void)addOrUpdateLanguages:(NSArray *)languageList;
+ (NSArray*) getMissingRemoteLanguageIdsFromListOfRemoteIds:(NSArray*) languageIds;     // check which of these languages already exist in core data and remove then from the list
@end
