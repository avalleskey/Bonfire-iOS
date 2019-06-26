//
//  UserActivityStream.h
//  Pulse
//
//  Created by Austin Valleskey on 3/8/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "JSONModel.h"
#import "UserActivity.h"

NS_ASSUME_NONNULL_BEGIN

@class UserActivityStream;
@class UserActivityStreamPage;
@class UserActivityStreamPageMeta;
@class UserActivityStreamPageMetaPaging;

@interface UserActivityStream : NSObject <NSCoding>

@property (nonatomic, strong) NSMutableArray <UserActivityStreamPage *> *pages;
@property (nonatomic, strong) NSArray <UserActivity *> *activities;

- (void)prependPage:(UserActivityStreamPage *)page;
- (void)appendPage:(UserActivityStreamPage *)page;

@property (nonatomic) NSString *prevCursor;
@property (nonatomic) NSString *nextCursor;

@end

@interface UserActivityStreamPage : JSONModel

@property (nonatomic) NSArray <UserActivity *> *data;
@property (nonatomic) UserActivityStreamPageMeta <Optional> *meta;
@property (nonatomic) BOOL replaceCache;

@end

@interface UserActivityStreamPageMeta : JSONModel

@property (nonatomic) UserActivityStreamPageMetaPaging <Optional> *paging;

@end

@interface UserActivityStreamPageMetaPaging : JSONModel

typedef enum {
    UserActivityStreamPagingCursorTypeNone,
    UserActivityStreamPagingCursorTypePrevious,
    UserActivityStreamPagingCursorTypeNext
} UserActivityStreamPagingCursorType;

@property (nonatomic) NSString <Optional> *prevCursor;
@property (nonatomic) NSString <Optional> *nextCursor;
@property (nonatomic) NSInteger remainingResults;

@end

NS_ASSUME_NONNULL_END
