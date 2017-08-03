//
//  AgeGroup.h
//  Scribjab
//
//  Created by Oleg Titov on 13-01-08.
//
//

#import "BaseModel.h"

@interface AgeGroup : BaseModel

@property (nonatomic, strong) NSNumber * remoteId;
@property (nonatomic, readonly) NSString * name;        // Localized name
@property (nonatomic, strong) NSString * englishName;
@property (nonatomic, strong) NSString * frenchName;

@end
