//
//  PostStream.h
//  Pulse
//
//  Created by Austin Valleskey on 12/6/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "JSONModel.h"
#import "Post.h"

#define STREAM_PAGE_SIZE 10

@class PostStream;
@class PostStreamPage;
@class PostStreamPageMeta;
@class PostStreamPageMetaPaging;

@interface PostStream : NSObject <NSCoding>

typedef enum {
    PostStreamOptionTempPostPositionTop = 0,
    PostStreamOptionTempPostPositionBottom = 1
} PostStreamOptionTempPostPosition;
@property (nonatomic) PostStreamOptionTempPostPosition tempPostPosition;

@property (strong, nonatomic) NSMutableArray <PostStreamPage *> *pages;

@property (strong, nonatomic) NSMutableArray <Post *> *tempPosts;
@property (strong, nonatomic) NSArray <Post *> *posts;

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

- (Post *)postWithId:(NSInteger)postId;
- (BOOL)updatePost:(Post *)post;
- (void)removePost:(Post *)post;
- (void)updateRoomObjects:(Room *)room;
- (void)updateUserObjects:(User *)user;


@property (nonatomic) NSInteger topId;
@property (nonatomic) NSInteger bottomId;

@end

@interface PostStreamPage : JSONModel

@property (nonatomic) NSArray<Post *> *data;
@property (nonatomic) PostStreamPageMeta <Optional> *meta;

@property (nonatomic) NSInteger topId;
@property (nonatomic) NSInteger bottomId;

@end

@interface PostStreamPageMeta : JSONModel

@property (nonatomic) PostStreamPageMetaPaging <Optional> *paging;

@end

@interface PostStreamPageMetaPaging : JSONModel

@property (nonatomic) NSString <Optional> *next_cursor;
@property (nonatomic) NSInteger remaining_results;

@end
