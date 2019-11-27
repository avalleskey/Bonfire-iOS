//
//  CampsList.h
//  Pulse
//
//  Created by Austin Valleskey on 7/23/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFJSONModel.h"
#import "Camp.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CampsList
@end

@class CampsList;
@class CampsListAttributes;

@interface CampsList : BFJSONModel

@property (nonatomic) NSString <Optional> *identifier;
@property (nonatomic) NSString <Optional> *type;
@property (nonatomic) CampsListAttributes <Optional> *attributes;

@end

@interface CampsListAttributes : BFJSONModel

@property (nonatomic) NSString <Optional> *title;
@property (nonatomic) BOOL isNew;

extern NSString * const CAMPS_LIST_ICON_TYPE_STAR;
extern NSString * const CAMPS_LIST_ICON_TYPE_TRENDING;
extern NSString * const CAMPS_LIST_ICON_TYPE_HEART;
extern NSString * const CAMPS_LIST_ICON_TYPE_HAPPENING;
extern NSString * const CAMPS_LIST_ICON_TYPE_LOCATION;
extern NSString * const CAMPS_LIST_ICON_TYPE_CLOCK;
@property (nonatomic) NSString <Optional> *icon;

@property (nonatomic) NSArray <Camp *> <Camp, Optional> *camps;

@end

@interface NSArray (CampsListArray)

- (NSArray <CampsList *> *)toCampsListArray;
- (NSArray <NSDictionary *> *)toCampsListDictionaryArray;
    
@end

NS_ASSUME_NONNULL_END
