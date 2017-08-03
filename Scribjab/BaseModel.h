//
//  BaseModel.h
//  Scribjab
//
//  Created by Oleg Titov on 12-08-24.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h> 

@interface BaseModel : NSObject

-(NSData *) jsonRepresentation;                   // Convert  model object to JSON string
-(id) initWithDictionary:(NSDictionary *) data;     // create a new model object using data in Dictionary

@end
