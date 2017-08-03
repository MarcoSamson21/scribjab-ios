//
//  AgeGroup.m
//  Scribjab
//
//  Created by Oleg Titov on 13-01-08.
//
//

#import "AgeGroup.h"

@implementation AgeGroup

@synthesize remoteId;
@synthesize englishName;
@synthesize frenchName;
@synthesize name;

-(NSString *)name
{
    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
    
    if ([language isEqualToString:@"fr"])
        return self.frenchName;
    return self.englishName;
}



// ======================================================================================================================================
// {"id":1,"name":"5-6 years","frenchName":"ans 5-6"}
-(id) initWithDictionary:(NSDictionary *)data
{
    self = [super init];
    
    if (self)
    {
        self.remoteId = [data objectForKey:@"id"];
        self.frenchName = [data objectForKey:@"frenchName"];
        self.englishName = [data objectForKey:@"name"];
    }
    return self;
}

// ======================================================================================================================================
// Get this object as JSON data
// {"id":1,"name":"5-6 years","frenchName":"ans 5-6"}
-(NSData*) jsonRepresentation;
{
    NSMutableDictionary * data = [[NSMutableDictionary alloc] initWithCapacity:10];
    [data setObject:self.remoteId forKey:@"id"];
    [data setObject:self.englishName forKey:@"name"];
    [data setObject:self.frenchName forKey:@"frenchName"];
    
    //NSJSONWritingPrettyPrinted use this option for a nicely-formatted json
    return [NSJSONSerialization dataWithJSONObject:data options:kNilOptions error:NULL];
}


@end
