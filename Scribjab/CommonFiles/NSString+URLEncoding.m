//
//  NSString (URLEncoding).m
//  Scribjab
//
//  Created by Oleg Titov on 12-08-24.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSString+URLEncoding.h"

@implementation NSString (URLEncoding)
-(NSString *)urlEncode
{
    NSMutableString *output = [NSMutableString string];
    const unsigned char *source = (const unsigned char *)[self UTF8String];
    int sourceLen = strlen((const char *)source);
    
    for (int i = 0; i < sourceLen; ++i) 
    {
        const unsigned char thisChar = source[i];
        
        if (thisChar == ' ')
        {
            [output appendString:@"%20"];
        } 
        else if (thisChar == '.' || thisChar == '-' || thisChar == '_' || thisChar == '~' || 
                   (thisChar >= 'a' && thisChar <= 'z') ||
                   (thisChar >= 'A' && thisChar <= 'Z') ||
                   (thisChar >= '0' && thisChar <= '9')) 
        {
            [output appendFormat:@"%c", thisChar];
        } 
        else 
        {
            [output appendFormat:@"%%%02X", thisChar];
        }
    }
    return output;
}
@end
