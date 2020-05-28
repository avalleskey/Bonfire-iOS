//
//  PostStream.m
//  Pulse
//
//  Created by Austin Valleskey on 12/6/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "PostStream.h"
#import "Session.h"
#import "PostCell.h"
#import "NSArray+Components.h"

@implementation PostStream

NSString * const PostStreamOptionTempPostPositionKey = @"temp_post_position";

// insert an empty PostStreamPage if
- (id)init {
    self = [super init];
    if (self) {
        [self flush];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        self.finalComponents = [decoder decodeObjectForKey:@"components"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.finalComponents forKey:@"components"];
}

- (void)flush {
    self.pages = [NSMutableArray new];
    self.components = [NSArray<BFStreamComponent *><BFStreamComponent> new];
    self.finalComponents = [NSMutableArray<BFStreamComponent *><BFStreamComponent> new];
    
    [self flushTempPosts];
    
    self.cursorsLoaded = [NSMutableDictionary new];
}
- (void)flushTempPosts {
    self.tempPosts = [NSMutableArray<Post *> new];
    self.tempComponents = [NSMutableArray<BFStreamComponent *><BFStreamComponent> new];
}

#pragma mark - NSCopying
- (id)copyWithZone:(NSZone *)zone
{
    PostStream *copyObject = [PostStream new];
    copyObject.pages = _pages;
    copyObject.components = _components;
    copyObject.tempComponents = _tempComponents;
    copyObject.finalComponents = _finalComponents;
    copyObject.prevCursor = _prevCursor;
    copyObject.nextCursor = _nextCursor;

     return copyObject;
}

- (void)streamUpdated:(BOOL)refreshComponents {
    if (refreshComponents) {
        [self refreshComponents];
    }
    
    if (self.tempPostPosition == PostStreamOptionTempPostPositionTop) {
        self.components = [self.tempComponents arrayByAddingObjectsFromArray:self.finalComponents];
    }
    else {
        self.components = [self.finalComponents arrayByAddingObjectsFromArray:self.tempComponents];
    }
    
    if ([self.delegate respondsToSelector:@selector(postStreamDidUpdate:)]) {
        [self.delegate postStreamDidUpdate:self];
    }
}

- (void)refreshComponents {
    NSMutableArray <BFStreamComponent *><BFStreamComponent> *newComponents = [NSMutableArray<BFStreamComponent *><BFStreamComponent> new];
    
    for (PostStreamPage *page in self.pages) {
        [newComponents addObjectsFromArray:[page.data toStreamComponentsWithDetailLevel:_detailLevel size:self.componentSize]];
    }
    
    self.finalComponents = newComponents;
}
- (void)refreshTempComponents {
    NSArray <BFStreamComponent *> *newComponents = [self.tempPosts toStreamComponentsWithDetailLevel:_detailLevel size:self.componentSize];
    
    self.tempComponents = [newComponents mutableCopy];
}

- (void)prependPage:(PostStreamPage *)page {
    if (self.pages.count > 0 && [self.pages firstObject].meta.paging.prevCursor.length > 0 && [[self.pages firstObject].meta.paging.prevCursor isEqualToString:page.meta.paging.prevCursor]) {
        return;
    }
    
    [self.pages insertObject:page atIndex:0];
    
    [self prependComponentsFromPage:page];
    
    [self streamUpdated:false];
}
- (void)prependComponentsFromPage:(PostStreamPage *)page {
    NSArray <BFStreamComponent *> *components = [page.data toStreamComponentsWithDetailLevel:_detailLevel size:self.componentSize];
    
    [self.finalComponents insertObjects:components atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, components.count)]];
}

- (void)appendPage:(PostStreamPage *)page {
    if (self.pages.count > 0 && [self.pages lastObject].meta.paging.nextCursor.length > 0 && [[self.pages lastObject].meta.paging.nextCursor isEqualToString:page.meta.paging.nextCursor]) {
        return;
    }
    
    [self.pages addObject:page];
    
    [self appendComponentsFromPage:page];
    
    [self streamUpdated:false];
}
- (void)appendComponentsFromPage:(PostStreamPage *)page {
    NSArray <BFStreamComponent *> *components = [page.data toStreamComponentsWithDetailLevel:_detailLevel size:self.componentSize];
    
    [self.finalComponents addObjectsFromArray:components];
}

- (NSString *)addTempPost:(Post *)post {
    NSString *tempId = [NSString stringWithFormat:@"%d", [Session getTempId]];
    post.tempId = tempId;
    
    if (self.tempPostPosition == PostStreamOptionTempPostPositionTop) {
        [self.tempPosts insertObject:post atIndex:0];
    }
    else {
        [self.tempPosts addObject:post];
    }
    
    [self refreshTempComponents];
    [self streamUpdated:false];
    
    return tempId;
}
- (BOOL)updateTempPost:(Post *)post withId:(NSString *)tempId {
    BOOL __block changes = false;
    
    NSMutableArray <Post *> *mutableTempPosts = [[NSMutableArray<Post *> alloc] initWithArray:self.tempPosts];
    [mutableTempPosts enumerateObjectsUsingBlock:^(Post *p, NSUInteger i2, BOOL *stop) {
        if ([post.tempId isEqualToString:tempId]) {
            [mutableTempPosts replaceObjectAtIndex:i2 withObject:post];
            changes = true;
        }
    }];
    
    if (changes) {
        [self refreshTempComponents];
        [self streamUpdated:false];
    }
    
    return changes;
}
- (BOOL)removeTempPost:(NSString *)tempId {
    __block BOOL changes = false;
    
    NSMutableArray <Post *> *markedForDeletion = [NSMutableArray<Post *> new];
    [self.tempPosts enumerateObjectsUsingBlock:^(Post *p, NSUInteger i2, BOOL *stop) {
        if ([p.tempId isEqualToString:tempId]) {
            [markedForDeletion addObject:p];
            changes = true;
        }
    }];
    [self.tempPosts removeObjectsInArray:markedForDeletion];
    
    if (changes) {
        [self refreshTempComponents];
        [self streamUpdated:false];
    }
    
    return changes;
}


- (NSString *)addTempSubReply:(Post *)subReply {
    NSString *tempId = [NSString stringWithFormat:@"%d", [Session getTempId]];
    subReply.tempId = tempId;
    
    // always add newest to top
    __block BOOL changes = false;
    
    [self.pages enumerateObjectsUsingBlock:^(PostStreamPage *page, NSUInteger i1, BOOL *stop) {
        __block BOOL sectionChanges = false;
        
        NSMutableArray <Post *> *mutablePosts = [[NSMutableArray<Post *> alloc] initWithArray:page.data];
        [mutablePosts enumerateObjectsUsingBlock:^(Post *p, NSUInteger i2, BOOL *stop) {
            if ([subReply.attributes.parent.identifier isEqualToString:p.identifier] ||
                [subReply.attributes.parentId isEqualToString:p.identifier]) {
                sectionChanges = true;
                
                // Sort through replies to check for matches
                NSMutableArray <Post *> *mutableReplies = [[NSMutableArray<Post *> alloc] initWithArray:p.attributes.summaries.replies];
                [mutableReplies insertObject:subReply atIndex:0];
                
                p.attributes.summaries.replies = [mutableReplies copy];
            }
        }];
        
        if (sectionChanges) {
            changes = true;
            
            page.data = [mutablePosts copy];
        }
    }];
    
    if (changes) {
        [self streamUpdated:true];
    }
    
    return tempId;
}
- (BOOL)updateTempSubReply:(NSString *)tempId withFinalSubReply:(Post *)finalSubReply {
    return [self updatePost:finalSubReply];
}

- (void)setTempPostPosition:(PostStreamOptionTempPostPosition)tempPostPosition {
    if (tempPostPosition != _tempPostPosition) {
        _tempPostPosition = tempPostPosition;
    }
}

#pragma mark - Post Stream Events (Update, Remove)
- (BOOL)performEventType:(PostStreamEventType)eventType object:(id)object {
    BOOL changes = false;
    
    if (PostStreamEventTypeUnknown) return changes;

    if ([object isKindOfClass:[Post class]]) {
        Post *post = (Post *)object;
        if (eventType == PostStreamEventTypePostUpdated) {
            changes = [self updatePost:post];
        }
        else if (eventType == PostStreamEventTypePostRemoved) {
            changes = [self removePost:post];
        }
    }
    else if ([object isKindOfClass:[Camp class]]) {
        Camp *camp = (Camp *)object;
        if (eventType == PostStreamEventTypeCampUpdated) {
            changes = [self updateCamp:camp];
        }
    }
    else if ([object isKindOfClass:[User class]]) {
        User *user = (User *)object;
        if (eventType == PostStreamEventTypeUserUpdated) {
            changes = [self updateUser:user];
        }
    }
    
    return changes;
}

#pragma mark - Post Events
- (BOOL)updatePost:(Post *)post {
    __block BOOL changes = false;
    
    // Create new instance of object
    post = [[Post alloc] initWithDictionary:[post toDictionary] error:nil];
    
    [self.pages enumerateObjectsUsingBlock:^(PostStreamPage *page, NSUInteger i1, BOOL *stop) {
        __block BOOL sectionChanges = false;
        
        NSMutableArray <Post *> *mutablePosts = [[NSMutableArray<Post *> alloc] initWithArray:page.data];
        [mutablePosts enumerateObjectsUsingBlock:^(Post *p, NSUInteger i2, BOOL *stop) {
            if ([post.identifier isEqualToString:p.identifier]) {
                // Found a match
                sectionChanges = true;
                
                [mutablePosts replaceObjectAtIndex:i2 withObject:post];
            }
            else if (p.attributes.summaries.replies.count > 0) {
                __block BOOL replyChanges = false;
                
                // Sort through replies to check for matches
                NSMutableArray <Post *> *mutableReplies = [[NSMutableArray<Post *> alloc] initWithArray:p.attributes.summaries.replies];
                [mutableReplies enumerateObjectsUsingBlock:^(Post *r, NSUInteger i3, BOOL *stop3) {
                    if ([post.identifier isEqualToString:r.identifier]) {
                        // Found a match
                        sectionChanges = true;
                        replyChanges = true;
                        
                        [mutableReplies replaceObjectAtIndex:i3 withObject:post];
                    }
                }];
                
                if (replyChanges) {
                    p.attributes.summaries.replies = [mutableReplies copy];
                }
            }
        }];
        
        if (sectionChanges) {
            changes = true;
            
            page.data = [mutablePosts copy];
        }
    }];
    
    if (changes) {
        [self streamUpdated:true];
    }
    
    return changes;
}
- (BOOL)removePost:(Post *)post {
    __block BOOL changes = false;
    
    [self.pages enumerateObjectsUsingBlock:^(PostStreamPage *page, NSUInteger i1, BOOL *stop1) {
        __block BOOL sectionChanges = false;
        
        NSMutableArray <Post *> *mutableData = [[NSMutableArray<Post *> alloc] initWithArray:page.data];
        NSMutableArray <Post *> *postsToRemove = [NSMutableArray<Post  *> new];
        [mutableData enumerateObjectsUsingBlock:^(Post *p, NSUInteger i2, BOOL *stop2) {
            if ([post.identifier isEqualToString:p.identifier]) {
                // Found a match
                sectionChanges = true;
                [postsToRemove addObject:p];
            }
            else if (p.attributes.summaries.replies.count > 0) {
                // Sort through replies to check for matches
                NSMutableArray <Post *> *mutableReplies = [[NSMutableArray<Post  *> alloc] initWithArray:p.attributes.summaries.replies];
                NSMutableArray <Post *> *repliesToRemove = [NSMutableArray<Post  *> new];
                [mutableReplies enumerateObjectsUsingBlock:^(Post *r, NSUInteger i3, BOOL *stop3) {
                    if ([post.identifier isEqualToString:r.identifier]) {
                        // Found a match
                        [repliesToRemove addObject:r];
                    }
                }];
                
                if (repliesToRemove.count > 0) {
                    sectionChanges = true;
                    
                    [mutableReplies removeObjectsInArray:repliesToRemove];
                    
                    p.attributes.summaries.counts.replies = MAX(0, p.attributes.summaries.counts.replies - repliesToRemove.count);
                    p.attributes.summaries.replies = [mutableReplies copy];
                }
            }
        }];
        
        if (sectionChanges) {
            changes = true;
            
            if (postsToRemove.count > 0) {
                [mutableData removeObjectsInArray:postsToRemove];
            }
            page.data = [mutableData copy];
        }
    }];
    
    if (changes) {
        [self streamUpdated:true];
    }
    
    return changes;
}

#pragma mark - User Events
- (BOOL)updateUser:(User *)user {
    __block BOOL changes = false;
    
    // Create new instance of object
    user = [user copy];
    
    [self.pages enumerateObjectsUsingBlock:^(PostStreamPage * _Nonnull page, NSUInteger idx, BOOL * _Nonnull stop) {
        __block BOOL sectionChanges = false;
        
        NSMutableArray <Post *> *mutablePosts = [[NSMutableArray<Post *> alloc] initWithArray:page.data];
        [mutablePosts enumerateObjectsUsingBlock:^(Post *post, NSUInteger i3, BOOL *stop) {
            __block BOOL postChanges = false;
            
            // update post creator
            if ([post.attributes.creator.identifier isEqualToString:user.identifier]) {
                sectionChanges = true;
                postChanges = true;
                
                post.attributes.creator = user;
            }
            
            // update replies
            __block BOOL replyChanges = false;
            
            NSMutableArray <Post *> *mutableReplies = [[NSMutableArray<Post *> alloc] initWithArray:post.attributes.summaries.replies];
            [mutableReplies enumerateObjectsUsingBlock:^(Post *reply, NSUInteger i4, BOOL *stop) {
                if (user.identifier.length > 0 && [reply.attributes.creator.identifier isEqualToString:user.identifier]) {
                    sectionChanges = true;
                    postChanges = true;
                    replyChanges = true;
                    
                    reply.attributes.creator = user;
                    
                    if (reply) {
                        [mutableReplies replaceObjectAtIndex:i4 withObject:reply];
                    }
                }
            }];
            
            if (postChanges) {
                if (replyChanges) {
                    post.attributes.summaries.replies = [mutableReplies copy];
                }
                
                post = [post copy];
                
                if (post) {
                    [mutablePosts replaceObjectAtIndex:i3 withObject:post];
                }
            }
        }];
        
        if (sectionChanges) {
            changes = true;
            
            page.data = [mutablePosts copy];
        }
    }];
    
    if (changes) {
        [self streamUpdated:true];
    }
    
    return changes;
}

#pragma mark - Camp Events
- (BOOL)updateCamp:(Camp *)camp {
    __block BOOL changes = false;
    
    // Create new instance of object
    camp = [camp copy];
    
    [self.pages enumerateObjectsUsingBlock:^(PostStreamPage * _Nonnull page, NSUInteger idx, BOOL * _Nonnull stop) {
        __block BOOL sectionChanges = false;
        
        NSMutableArray <Post *> *mutablePosts = [[NSMutableArray<Post *> alloc] initWithArray:page.data];
        [mutablePosts enumerateObjectsUsingBlock:^(Post *post, NSUInteger i3, BOOL *stop) {
            __block BOOL postChanges = false;
            
            // update post creator
            if ([post.attributes.postedIn.identifier isEqualToString:camp.identifier]) {
                sectionChanges = true;
                postChanges = true;
                
                post.attributes.postedIn = camp;
            }
            
            // update replies
            __block BOOL replyChanges = false;
            
            NSMutableArray <Post *> *mutableReplies = [[NSMutableArray<Post *> alloc] initWithArray:post.attributes.summaries.replies];
            [mutableReplies enumerateObjectsUsingBlock:^(Post *reply, NSUInteger i4, BOOL *stop) {
                if ([reply.attributes.postedIn.identifier isEqualToString:camp.identifier]) {
                    sectionChanges = true;
                    postChanges = true;
                    replyChanges = true;
                    
                    reply.attributes.postedIn = camp;
                    
                    [mutableReplies replaceObjectAtIndex:i4 withObject:reply];
                }
            }];
            
            if (postChanges) {
                if (replyChanges) {
                    post.attributes.summaries.replies = [mutableReplies copy];
                }
                
                post = [post copy];
                
                [mutablePosts replaceObjectAtIndex:i3 withObject:post];
            }
        }];
        
        if (sectionChanges) {
            changes = true;
            
            page.data = [mutablePosts copy];
        }
    }];
    
    if (changes) {
        [self streamUpdated:true];
    }
    
    return changes;
}

- (Post *)postWithId:(NSString *)identifier {
    for (BFStreamComponent *component in self.finalComponents) {
        if (component.post && [component.post.identifier isEqualToString:identifier]) {
            return component.post;
        }
    }
    
    return nil;
}

- (NSString *)prevCursor {
    if (self.pages.count == 0) return nil;
    if ([self.pages firstObject].meta.paging.prevCursor.length == 0) return nil;
    
    return [self.pages firstObject].meta.paging.prevCursor;
}
- (NSString *)nextCursor {
    if (self.pages.count == 0) return nil;
    if ([self.pages lastObject].meta.paging.nextCursor.length == 0) return nil;
    
    return [self.pages lastObject].meta.paging.nextCursor;
}


@end

@implementation PostStreamPage

+(BOOL)propertyIsOptional:(NSString*)propertyName
{
    return true;
}

@end
