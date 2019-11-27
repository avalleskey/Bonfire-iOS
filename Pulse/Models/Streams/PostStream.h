//
//  PostStream.h
//  Pulse
//
//  Created by Austin Valleskey on 12/6/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "Post.h"
#import "GenericStream.h"

#define STREAM_PAGE_SIZE 10

@class PostStream;
@class PostStreamPage;

@protocol PostStreamDelegate <NSObject>

- (void)postStreamDidUpdate:(PostStream *)stream;

@end

@interface PostStream : GenericStream <NSCoding>

@property (nonatomic, weak) id <PostStreamDelegate> delegate;

typedef enum {
    PostStreamOptionTempPostPositionTop = 0,
    PostStreamOptionTempPostPositionBottom = 1
} PostStreamOptionTempPostPosition;
@property (nonatomic) PostStreamOptionTempPostPosition tempPostPosition;

@property (nonatomic, strong) NSMutableArray <PostStreamPage *> *pages;

@property (nonatomic, strong) NSMutableArray <Post *> *tempPosts;
@property (nonatomic, strong) NSArray <Post *> *posts;

- (void)prependPage:(PostStreamPage *)page;
- (void)appendPage:(PostStreamPage *)page;

// Used when creating a post
// returns unique ID for new post, which can be used to remove/replace new post
- (BOOL)removeTempPost:(NSString *)tempId;
- (NSString *)addTempPost:(Post *)post;
- (BOOL)updateTempPost:(NSString *)tempId withFinalPost:(Post *)post;

- (NSString *)addTempSubReply:(Post *)subReply;
- (BOOL)updateTempSubReply:(NSString *)tempId withFinalSubReply:(Post *)finalSubReply;
- (BOOL)clearSubRepliesForPost:(Post *)reply;
- (BOOL)addSubReplies:(NSArray *)newSubReplies toPost:(Post *)post;

- (Post *)postWithId:(NSString *)postId;

- (BOOL)updatePost:(Post *)post removeDuplicates:(BOOL)removeDuplicates;
- (void)removePost:(Post *)post;
- (void)updateCampObjects:(Camp *)camp;
- (void)updateUserObjects:(User *)user;

@property (nonatomic) NSString *prevCursor;
@property (nonatomic) NSString *nextCursor;

@end

@interface PostStreamPage : BFJSONModel

@property (nonatomic) NSArray<Post *> *data;
@property (nonatomic) GenericStreamPageMeta <Optional> *meta;

@end
