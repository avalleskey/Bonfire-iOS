//
//  UserListStream.h
//  Pulse
//
//  Created by Austin Valleskey on 7/12/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "GenericStream.h"
#import "User.h"

NS_ASSUME_NONNULL_BEGIN

@class UserListStream;
@class UserListStreamPage;

@protocol UserListStreamDelegate <NSObject>

- (void)userListStreamDidUpdate:(UserListStream *)stream;

@end

@interface UserListStream : GenericStream <NSCoding>

@property (nonatomic, weak) id <UserListStreamDelegate> delegate;

@property (nonatomic, strong) NSMutableArray <UserListStreamPage *> *pages;
@property (nonatomic, strong) NSArray <User *> *users;

- (void)prependPage:(UserListStreamPage *)page;
- (void)appendPage:(UserListStreamPage *)page;

@property (nonatomic) NSString * _Nullable prevCursor;
@property (nonatomic) NSString * _Nullable nextCursor;

@end

@interface UserListStreamPage : BFJSONModel

@property (nonatomic) NSArray <User *> *data;
@property (nonatomic) GenericStreamPageMeta <Optional> *meta;

@end

NS_ASSUME_NONNULL_END
