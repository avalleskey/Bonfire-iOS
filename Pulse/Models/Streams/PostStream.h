//
//  PostStream.h
//  Pulse
//
//  Created by Austin Valleskey on 12/6/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "Post.h"
#import "GenericStream.h"
#import "BFStreamComponent.h"

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

@property (nonatomic, strong) NSArray <BFStreamComponent *><BFStreamComponent> *components;
@property (nonatomic, strong) NSMutableArray <BFStreamComponent *><BFStreamComponent> *tempComponents;
@property (nonatomic, strong) NSMutableArray <BFStreamComponent *><BFStreamComponent> *finalComponents;

- (void)flush;

@property (nonatomic) NSString *prevCursor;
@property (nonatomic) NSString *nextCursor;

- (void)prependPage:(PostStreamPage *)page;
- (void)appendPage:(PostStreamPage *)page;

// Used when creating a post
// returns unique ID for new post, which can be used to remove/replace new post
- (NSString *)addTempPost:(Post *)post;
- (BOOL)removeTempPost:(NSString *)tempId;

- (NSString *)addTempSubReply:(Post *)subReply;
- (BOOL)updateTempSubReply:(NSString *)tempId withFinalSubReply:(Post *)finalSubReply;

- (Post *)postWithId:(NSString *)identifier;

typedef enum {
    PostStreamEventTypeUnknown,

    PostStreamEventTypePostUpdated,
    PostStreamEventTypePostRemoved,
    
    PostStreamEventTypeReplyAdded,
    
    PostStreamEventTypeCampUpdated,
    
    PostStreamEventTypeUserUpdated,
} PostStreamEventType;
- (BOOL)performEventType:(PostStreamEventType)eventType object:(id)object;

@property (nonatomic) BFComponentDetailLevel detailLevel;

@end

@interface PostStreamPage : BFJSONModel

@property (nonatomic) NSArray<Post *><Post> *data;
@property (nonatomic) GenericStreamPageMeta <Optional> *meta;

@end
