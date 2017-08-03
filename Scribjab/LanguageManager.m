//
//  LanguageManager.m
//  Scribjab
//
//  Created by Oleg Titov on 12-11-29.
//
//

#import "LanguageManager.h"
#import "DocumentHandler.h"


@implementation LanguageManager

// **************************************************************************************************************************************
// **************************************************************************************************************************************
// **************************************************************************************************************************************
// STATIC METHODS
#pragma-mark Static Methods

// ======================================================================================================================================
// this function will update changes to the core data or add a new Language, if one doesn't exist
+ (void)addOrUpdateLanguages:(NSArray *)languageList
{
    for(NSDictionary *item in languageList)
    {
        if(item == nil)
            continue;
    
        Language * langObj = [LanguageManager getLanguageByRemoteId:[[item objectForKey:@"id"] intValue]];
        
        if (langObj == nil)
        {
            langObj = [NSEntityDescription insertNewObjectForEntityForName:@"Language" inManagedObjectContext:[DocumentHandler sharedDocumentHandler].document.managedObjectContext];
            [langObj.managedObjectContext obtainPermanentIDsForObjects:[NSArray arrayWithObject:langObj] error:NULL];
        }
        
        // set field values or update
        langObj.remoteId = [item objectForKey:@"id"];
        langObj.nameEnglish = [item objectForKey:@"englishName"];
        langObj.nameFrench = [item objectForKey:@"name"];
        langObj.code = [item objectForKey:@"code"];
    }
    [[DocumentHandler sharedDocumentHandler] saveContextAndWait];
}

// ======================================================================================================================================
+ (NSMutableArray *)getAllLanguages
{
    NSArray *objects = [[DocumentHandler sharedDocumentHandler] fetchContextForEntity:@"Language" predicate:nil sortDescriptors:nil];
    if (objects == nil) {
        //handle error;
    }
    NSMutableArray * languagesArray = [[NSMutableArray alloc]initWithArray:objects];
    return languagesArray;
}

// ======================================================================================================================================
+ (Language *)getLanguageByRemoteId:(int) remoteId
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"remoteId = %@", [NSNumber numberWithInt:remoteId]];
    NSArray *objects = [[DocumentHandler sharedDocumentHandler] fetchContextForEntity:@"Language" predicate:predicate sortDescriptors:nil];
   
    Language * lang = nil;
    
    if (objects != nil && [objects count] > 0)
        lang = [objects objectAtIndex:0];
    
    return lang;
}

// ======================================================================================================================================
// Find out which of the specified languages already exist in core data and return nly IDs of the missing languages
+ (NSArray*) getMissingRemoteLanguageIdsFromListOfRemoteIds:(NSArray*) languageIds
{
    NSPredicate * predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"remoteId IN {%@}", [languageIds componentsJoinedByString:@","]]];
    NSArray * languages = [[DocumentHandler sharedDocumentHandler] fetchContextForEntity:@"Language" predicate:predicate sortDescriptors:nil];
    
    NSMutableArray * newList = [NSMutableArray arrayWithArray:languageIds];
    
    for (Language * lang in languages)
    {
        [newList removeObject:lang.remoteId];
    }
    
    return newList;
}


@end
