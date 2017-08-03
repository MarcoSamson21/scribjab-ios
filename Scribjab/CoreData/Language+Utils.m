//
//  Language+Utils.m
//  Scribjab
//
//  Created by Oleg Titov on 12-12-03.
//
//

#import "Language+Utils.h"
#import "Utilities.h"

@implementation Language (Utils)

// Return language name in English or French, based on the Device's current language
-(NSString *)name
{
    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
  
    if ([language isEqualToString:FRENCH_LOCALE])
        return self.nameFrench;
    return self.nameEnglish;
}
@end
