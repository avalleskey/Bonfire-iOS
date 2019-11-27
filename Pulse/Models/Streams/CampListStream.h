//
//  CampListStream.h
//  Pulse
//
//  Created by Austin Valleskey on 7/12/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "GenericStream.h"
#import "Camp.h"

NS_ASSUME_NONNULL_BEGIN

@class CampListStream;
@class CampListStreamPage;

@protocol CampListStreamDelegate <NSObject>

- (void)campListStreamDidUpdate:(CampListStream *)stream;

@end

@interface CampListStream : GenericStream <NSCoding>

@property (nonatomic, weak) id <CampListStreamDelegate> delegate;

@property (nonatomic, strong) NSMutableArray <CampListStreamPage *> *pages;
@property (nonatomic, strong) NSArray <Camp *> *camps;

- (void)prependPage:(CampListStreamPage *)page;
- (void)appendPage:(CampListStreamPage *)page;

@property (nonatomic) NSString * _Nullable prevCursor;
@property (nonatomic) NSString * _Nullable nextCursor;

@end

@interface CampListStreamPage : BFJSONModel

@property (nonatomic) NSArray <Camp *> *data;
@property (nonatomic) GenericStreamPageMeta <Optional> *meta;

@end

NS_ASSUME_NONNULL_END
