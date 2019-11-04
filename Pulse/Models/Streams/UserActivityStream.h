//
//  UserActivityStream.h
//  Pulse
//
//  Created by Austin Valleskey on 3/8/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "GenericStream.h"
#import "UserActivity.h"

NS_ASSUME_NONNULL_BEGIN

@class UserActivityStream;
@class UserActivityStreamPage;

@interface UserActivityStream : GenericStream <NSCoding>

@property (nonatomic, strong) NSMutableArray <UserActivityStreamPage *> *pages;
@property (nonatomic, strong) NSArray <UserActivity *> *activities;

- (void)prependPage:(UserActivityStreamPage *)page;
- (void)appendPage:(UserActivityStreamPage *)page;

- (BOOL)updatePost:(Post *)post removeDuplicates:(BOOL)removeDuplicates;
- (BOOL)removePost:(Post *)post;
- (void)updateCampObjects:(Camp *)camp;
- (void)updateUserObjects:(User *)user;

@property (nonatomic) NSString *prevCursor;
@property (nonatomic) NSString *nextCursor;

@end

@interface UserActivityStreamPage : JSONModel

@property (nonatomic) NSArray <UserActivity *> *data;
@property (nonatomic) GenericStreamPageMeta <Optional> *meta;

@end

NS_ASSUME_NONNULL_END
