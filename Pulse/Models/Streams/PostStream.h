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

@protocol PostStreamDelegate <NSObject>

- (void)postStreamDidUpdate:(PostStream *)stream;

@end

@interface PostStream : NSObject <NSCoding>

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
- (BOOL)updatePost:(Post *)post;
- (void)removePost:(Post *)post;
- (void)updateCampObjects:(Camp *)camp;
- (void)updateUserObjects:(User *)user;

@property (nonatomic) NSString *prevCursor;
@property (nonatomic) NSString *nextCursor;

@property (nonatomic, strong) NSMutableDictionary *cursorsLoaded;
- (void)addLoadedCursor:(NSString *)cursor;
- (BOOL)hasLoadedCursor:(NSString *)cursor;

@end

@interface PostStreamPage : JSONModel

@property (nonatomic) NSArray<Post *> *data;
@property (nonatomic) PostStreamPageMeta <Optional> *meta;

@end

@interface PostStreamPageMeta : JSONModel

@property (nonatomic) PostStreamPageMetaPaging <Optional> *paging;

@end

@interface PostStreamPageMetaPaging : JSONModel

typedef enum {
    PostStreamPagingCursorTypeNone,
    PostStreamPagingCursorTypePrevious,
    PostStreamPagingCursorTypeNext
} PostStreamPagingCursorType;
@property (nonatomic) NSString <Optional> *prevCursor;
@property (nonatomic) NSString <Optional> *nextCursor;
@property (nonatomic) NSInteger remaining_results;

@end
