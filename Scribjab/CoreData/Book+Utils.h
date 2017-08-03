//
//  Book+Utils.h
//  Scribjab
//
//  Created by Oleg Titov on 12-11-27.
//
//

#import "Book.h"

@interface Book (Utils)
-(void) setBasicDataFromDictionary:(NSDictionary*) dict;    // sets data that comes from the dictionary. No foreign key lookups done here. 
@end
