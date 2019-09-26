//
//  CampsList.h
//  Pulse
//
//  Created by Austin Valleskey on 7/23/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "JSONModel.h"
#import "Camp.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CampsList
@end

@class CampsList;
@class CampsListAttributes;

@interface CampsList : JSONModel

@property (nonatomic) NSString <Optional> *identifier;
@property (nonatomic) NSString <Optional> *type;
@property (nonatomic) CampsListAttributes <Optional> *attributes;

@end

@interface CampsListAttributes : JSONModel

@property (nonatomic) NSString <Optional> *title;
@property (nonatomic) NSArray <Camp *> <Camp, Optional> *camps;

@end

@interface NSArray (CampsListArray)

- (NSArray <CampsList *> *)toCampsListArray;
- (NSArray <NSDictionary *> *)toCampsListDictionaryArray;
    
@end

NS_ASSUME_NONNULL_END
