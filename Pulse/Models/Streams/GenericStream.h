//
//  GenericStream.h
//  Pulse
//
//  Created by Austin Valleskey on 7/12/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BFJSONModel.h"

NS_ASSUME_NONNULL_BEGIN

@class GenericStreamPageMeta;
@class GenericStreamPageMetaPaging;

@interface GenericStream : NSObject

@property (nonatomic, strong) NSMutableDictionary <Optional> *cursorsLoaded;

- (void)addLoadedCursor:(NSString *)cursor;
- (void)removeLoadedCursor:(NSString *)cursor;

- (BOOL)hasLoadedCursor:(NSString *)cursor;

@end

@interface GenericStreamPageMeta : BFJSONModel

@property (nonatomic) GenericStreamPageMetaPaging <Optional> *paging;

@end

@interface GenericStreamPageMetaPaging : BFJSONModel

typedef enum {
    StreamPagingCursorTypeNone,
    StreamPagingCursorTypePrevious,
    StreamPagingCursorTypeNext
} StreamPagingCursorType;
@property (nonatomic) NSString <Optional> *prevCursor;
@property (nonatomic) NSString <Optional> *nextCursor;
@property (nonatomic) BOOL replaceCache;

@end

NS_ASSUME_NONNULL_END
