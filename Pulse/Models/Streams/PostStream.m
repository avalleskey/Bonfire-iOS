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

@implementation PostStream

NSString * const PostStreamOptionTempPostPositionKey = @"temp_post_position";

// insert an empty PostStreamPage if
- (id)init {
    self = [super init];
    if (self) {
        self.pages = [[NSMutableArray alloc] init];
        
        self.tempPosts = [[NSMutableArray alloc] init];
        self.posts = @[];
        
        self.cursorsLoaded = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        self.posts = [decoder decodeObjectForKey:@"posts"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.posts forKey:@"posts"];
}

#pragma mark - NSCopying
- (id)copyWithZone:(NSZone *)zone
{
    PostStream *copyObject = [PostStream new];
    copyObject.pages = _pages;
    copyObject.tempPosts = _tempPosts;
    copyObject.posts = _posts;
    copyObject.prevCursor = _prevCursor;
    copyObject.nextCursor = _nextCursor;

     return copyObject;
}

- (void)updatePostsArray {
    NSMutableArray *mutableArray = [NSMutableArray array];
    
    if (self.tempPostPosition == PostStreamOptionTempPostPositionTop) {
        [mutableArray addObjectsFromArray:self.tempPosts];
    }
    
    NSString *lastPostID = @"";
    
    NSMutableArray *pagesToDelete = [NSMutableArray array];
    for (NSInteger i = 0; i < self.pages.count; i++) {
        // TODO: Insert 'load missing posts' post if before/after doesn't match previous/next page
        
        PostStreamPage *page = self.pages[i];
        NSDictionary *pageDict = [page toDictionary];
        NSArray *pagePosts = [pageDict objectForKey:@"data"] ? pageDict[@"data"] : @[];
        NSMutableArray *mutablePagePosts = [pagePosts mutableCopy];
        
        for (Post *post in mutablePagePosts) {
            if ([lastPostID isEqualToString:post.identifier]) {
                //[postsToRemove addObject:post];
            }
            else {
                lastPostID = post.identifier;
            }

            if (i == 0 && page.meta.paging.prevCursor.length > 0) {
                post.prevCursor = page.meta.paging.prevCursor;
            }
            if (i == mutablePagePosts.count - 1 && page.meta.paging.nextCursor.length > 0) {
                post.nextCursor = page.meta.paging.nextCursor;
            }
        }
        //[mutablePagePosts removeObjectsInArray:postsToRemove];
        
        if (mutablePagePosts.count == 0) {
            [pagesToDelete addObject:page];
        }
        else {
            [mutableArray addObjectsFromArray:mutablePagePosts];
        }
    }
    // remove any empty pages
    [self.pages removeObjectsInArray:pagesToDelete];
    
    if (self.tempPostPosition == PostStreamOptionTempPostPositionBottom) {
        [mutableArray addObjectsFromArray:self.tempPosts];
    }
    
    self.posts = [mutableArray copy];
    
    if ([self.delegate respondsToSelector:@selector(postStreamDidUpdate:)]) {
        [self.delegate postStreamDidUpdate:self];
    }
}

- (void)prependPage:(PostStreamPage *)page {
    if (self.pages.count > 0 && [self.pages firstObject].meta.paging.prevCursor.length > 0 && [[self.pages firstObject].meta.paging.prevCursor isEqualToString:page.meta.paging.prevCursor]) {
        return;
    }
    
    NSMutableArray *pageData = [[NSMutableArray alloc] initWithArray:page.data];
    for (NSInteger i = 0; i < pageData.count; i++) {
        if ([pageData[i] isKindOfClass:[NSDictionary class]]) {
            Post *post = [[Post alloc] initWithDictionary:pageData[i] error:nil];
            [pageData replaceObjectAtIndex:i withObject:post];
        }
    }
    page.data = [pageData copy];

    [self.pages insertObject:page atIndex:0];
    [self updatePostsArray];
}
- (void)appendPage:(PostStreamPage *)page {
    if (self.pages.count > 0 && [self.pages lastObject].meta.paging.nextCursor.length > 0 && [[self.pages lastObject].meta.paging.nextCursor isEqualToString:page.meta.paging.nextCursor]) {
        return;
    }
    
    NSMutableArray *pageData = [[NSMutableArray alloc] initWithArray:page.data];
    for (NSInteger i = 0; i < pageData.count; i++) {
        if ([pageData[i] isKindOfClass:[NSDictionary class]]) {
            NSError *error;
            
            Post *post = [[Post alloc] initWithDictionary:pageData[i] error:&error];
            
            if (error) {
                NSLog(@"error: %@", error);
            }
            if (post != nil) {
                [pageData replaceObjectAtIndex:i withObject:post];
            }
        }
    }
    page.data = [pageData copy];
    
    [self.pages addObject:page];
    [self updatePostsArray];
}

- (BOOL)removeTempPost:(NSString *)tempId {
    NSMutableArray *postsToRemove = [[NSMutableArray alloc] init];
    for (Post *p in self.tempPosts) {
        if ([p.tempId isEqualToString:tempId]) {
            // found match
            [postsToRemove addObject:p];
        }
    }
    [self.tempPosts removeObjectsInArray:postsToRemove];
    [self updatePostsArray];
    
    return postsToRemove.count > 0;
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
    [self updatePostsArray];
    
    return tempId;
}
- (BOOL)updateTempPost:(NSString *)tempId withFinalPost:(Post *)post {
    NSMutableArray *postsToRemove = [[NSMutableArray alloc] init];
    for (Post *p in self.tempPosts) {
        if ([p.tempId isEqualToString:tempId]) {
            // found match
            [postsToRemove addObject:p];
        }
    }
    [self.tempPosts removeObjectsInArray:postsToRemove];
    
    if (post != nil) {
        PostStreamPage *newPage = [[PostStreamPage alloc] initWithDictionary:@{@"data": @[[post toDictionary]]} error:nil];
        if (self.tempPostPosition == PostStreamOptionTempPostPositionTop) {
            [self prependPage:newPage];
        }
        else {
            [self appendPage:newPage];
        }
    }
    
    return true;
}

- (NSString *)addTempSubReply:(Post *)subReply {
    NSString *tempId = [NSString stringWithFormat:@"%d", [Session getTempId]];
    subReply.tempId = tempId;
    
    // always add to bottom
    BOOL foundMatch = false;
    for (NSInteger i = 0; i < self.pages.count; i++) {
        PostStreamPage *page = self.pages[i];
        NSMutableArray<Post *> *mutableData = [[NSMutableArray<Post *> alloc] initWithArray:page.data];
        
        for (int p = 0; p < mutableData.count; p++) {
            // go through each reply, checking to see if the sub reply parent == identifier of post
            Post *reply = mutableData[p];
            if ([reply.identifier isEqualToString:subReply.attributes.parent.identifier]) {
                // match!
                NSLog(@"reply.attributes.summaries.replies BEFORE: %lu", reply.attributes.summaries.replies.count);
                
                NSMutableArray<Post *><Post, Optional> *mutableArray = [[NSMutableArray<Post *><Post, Optional> alloc] initWithArray:reply.attributes.summaries.replies];
                [mutableArray addObject:subReply];
                reply.attributes.summaries.replies = mutableArray;
                
                if (reply.attributes.summaries.counts && reply.attributes.summaries.counts.replies) {
                    reply.attributes.summaries.counts.replies++;
                }
                
                [mutableData replaceObjectAtIndex:p withObject:reply];
                
                foundMatch = true;
                
                break;
            }
        }
        
        if (foundMatch) {
            page.data = mutableData;
        }
    }
    
    if (foundMatch) {
        [self updatePostsArray];
    }

    return tempId;
}
- (BOOL)updateTempSubReply:(NSString *)tempId withFinalSubReply:(Post *)finalSubReply {
    // always add to bottom
    BOOL foundMatch = false;
    for (NSInteger i = 0; i < self.pages.count; i++) {
        PostStreamPage *page = self.pages[i];
        for (int p = 0; p < page.data.count; p++) {
            // go through each reply, checking to see if the sub reply parent  == identifier of post
            Post *reply = page.data[p];
            NSMutableArray *mutableSubReplies = [[NSMutableArray alloc] initWithArray:reply.attributes.summaries.replies];
            
            for (int s = 0; s < mutableSubReplies.count; s++) {
                Post *subReply = mutableSubReplies[s];
                if ([subReply.tempId isEqualToString:tempId]) {
                    // match!
                    [mutableSubReplies replaceObjectAtIndex:s withObject:finalSubReply];
                    NSArray <Post *> <Post> *copy = [mutableSubReplies copy];
                    reply.attributes.summaries.replies = copy;
                    
                    NSMutableArray *mutableData = [[NSMutableArray alloc] initWithArray:page.data];
                    [mutableData replaceObjectAtIndex:p withObject:reply];
                    NSArray <Post *> <Post> *mutableDataCopy = [mutableData copy];
                    page.data = mutableDataCopy;
                    
                    foundMatch = true;
                    
                    break;
                }
            }
            if (foundMatch)
                break;
        }
        if (foundMatch)
            break;
    }
    
    [self updatePostsArray];
    
    return true;
}
- (BOOL)clearSubRepliesForPost:(Post *)reply {
    BOOL foundMatch = false;
    for (NSInteger i = 0; i < self.pages.count; i++) {
        PostStreamPage *page = self.pages[i];
        for (int p = 0; p < page.data.count; p++) {
            // go through each reply, checking to see if the sub reply parent  == identifier of post
            Post *replyAtIndex = page.data[p];
            if (replyAtIndex.identifier == reply.identifier) {
                NSMutableArray *mutableEmptyArray = [[NSMutableArray alloc] init];
                NSArray <Post *><Post> *copy = [mutableEmptyArray copy];
                replyAtIndex.attributes.summaries.replies = copy;
                
                NSMutableArray *mutableData = [[NSMutableArray alloc] initWithArray:page.data];
                [mutableData replaceObjectAtIndex:p withObject:replyAtIndex];
                NSArray <Post *> <Post> *mutableDataCopy = [mutableData copy];
                page.data = mutableDataCopy;
                
                foundMatch = true;
                break;
            }
        }
        if (foundMatch)
            break;
    }
    
    if (foundMatch)
        [self updatePostsArray];
    
    return foundMatch;
}
- (BOOL)addSubReplies:(NSArray *)newSubReplies toPost:(Post *)post {
    // always add to bottom
    BOOL foundMatch = false;
    for (NSInteger i = 0; i < self.pages.count; i++) {
        PostStreamPage *page = self.pages[i];
        for (int p = 0; p < page.data.count; p++) {
            // go through each reply, checking to see if the sub reply parent  == identifier of post
            Post *reply = page.data[p];
            if (reply.identifier == post.identifier) {
                // match!
                NSLog(@"heh match match !!");
                NSMutableArray *mutableArray = [[NSMutableArray alloc] initWithArray:reply.attributes.summaries.replies];
                
                NSMutableArray *subReplyPosts = [[NSMutableArray alloc] initWithArray:newSubReplies];
                for (int s = 0; s < subReplyPosts.count; s++) {
                    Post *newSubReply = [[Post alloc] initWithDictionary:subReplyPosts[s] error:nil];
                    [subReplyPosts replaceObjectAtIndex:s withObject:newSubReply];
                }
                
                [mutableArray addObjectsFromArray:subReplyPosts];
                NSArray <Post *> <Post> *copy = [mutableArray copy];
                reply.attributes.summaries.replies = copy;
                
                NSMutableArray *mutableData = [[NSMutableArray alloc] initWithArray:page.data];
                [mutableData replaceObjectAtIndex:p withObject:reply];
                NSArray <Post *> <Post> *mutableDataCopy = [mutableData copy];
                page.data = mutableDataCopy;
                
                NSLog(@"even more wooo!");
                NSLog(@"page.data: %@", page.data);
                
                foundMatch = true;
                
                break;
            }
            
            if (foundMatch)
                break;
        }
        if (foundMatch)
            break;
    }
    
    if (foundMatch)
        [self updatePostsArray];
    
    return foundMatch;
}

- (Post *)postWithId:(NSString *)postId {
    for (NSInteger i = 0; i < self.posts.count; i++) {
        if ([self.posts[i].identifier isEqualToString:postId]) {
            return self.posts[i];
        }
        
        for (Post *post in self.posts[i].attributes.summaries.replies) {
            if ([post.identifier isEqualToString:postId]) {
                return post;
            }
        }
    }
    
    return nil;
}
- (BOOL)updatePost:(Post *)post removeDuplicates:(BOOL)removeDuplicates {
    BOOL changes = false;
    BOOL foundPost = false;
    for (int p = 0; p < self.pages.count; p++) {
        PostStreamPage *page = self.pages[p];
        
        NSMutableArray <Post *> *mutableArray = [[NSMutableArray alloc] initWithArray:page.data];
        for (NSInteger i = mutableArray.count - 1; i >= 0; i--) {
            Post *postAtIndex = mutableArray[i];
            if ([postAtIndex.identifier isEqualToString:post.identifier]) {
                if (foundPost && removeDuplicates) {
                    // decide whether or not to remove it
                    BOOL remove = false;
                    if (remove) {
                        [mutableArray removeObjectAtIndex:i];
                        changes = true;
                        
                        NSLog(@"remove that dupe!");
                    }
                }
                else {
                    NSLog(@"vote status before:: %@", ((Post *)[mutableArray objectAtIndex:i]).attributes.context.post.vote);
                    
                    // update the post!
                    if (post.attributes.removedAt.length > 0) {
                        [mutableArray removeObjectAtIndex:i];
                    }
                    else {
                        [mutableArray replaceObjectAtIndex:i withObject:post];
                    }
                    changes = true;
                    foundPost = true;
                    
                    NSLog(@"vote status after:: %@", post.attributes.context.post.vote);
                }
            }
        }
        
        page.data = [mutableArray copy];
        
        [self.pages replaceObjectAtIndex:p withObject:page];
    }
    [self updatePostsArray];
        
    return changes;
}

- (void)removePost:(Post *)post {
    for (int p = 0; p < self.pages.count; p++) {
        PostStreamPage *page = self.pages[p];
        
        NSMutableArray <Post *> *mutableArray = [[NSMutableArray alloc] initWithArray:page.data];
        for (NSInteger i = mutableArray.count - 1; i >= 0; i--) {
            Post *postAtIndex = mutableArray[i];
            if (postAtIndex.identifier == post.identifier) {
                [mutableArray removeObjectAtIndex:i];
                continue;
            }
            
            if (post.attributes.parent.identifier.length > 0 && [post.attributes.parent.identifier isEqualToString:postAtIndex.identifier]) {
                NSMutableArray *mutableSummariesArray = [[NSMutableArray alloc] initWithArray:postAtIndex.attributes.summaries.replies];
                for (NSInteger i = mutableSummariesArray.count - 1; i >= 0; i--) {
                    Post *subReply = mutableSummariesArray[i];
                    if (subReply.identifier == post.identifier) {
                        [mutableSummariesArray removeObject:subReply];
                    }
                }
                postAtIndex.attributes.summaries.replies = [mutableSummariesArray copy];
                
                if (postAtIndex.attributes.summaries.counts.replies > 0) {
                    PostCounts *counts = [[PostCounts alloc] init];
                    counts.replies = (postAtIndex.attributes.summaries.counts.replies - 1);
                    postAtIndex.attributes.summaries.counts = counts;
                }
            }
        }
        
        page.data = [mutableArray copy];
        
        [self.pages replaceObjectAtIndex:p withObject:page];
    }
    [self updatePostsArray];
}
- (void)updateCampObjects:(Camp *)camp {
    for (int p = 0; p < self.pages.count; p++) {
        PostStreamPage *page = self.pages[p];
        
        NSMutableArray <Post *> *mutableArray = [[NSMutableArray alloc] initWithArray:page.data];
        for (NSInteger i = mutableArray.count - 1; i >= 0; i--) {
            Post *postAtIndex = mutableArray[i];
            if ([postAtIndex.attributes.postedIn.identifier isEqualToString:camp.identifier]) {
                postAtIndex.attributes.postedIn = camp;
                
                // update replies
                NSMutableArray *mutableReplies = [[NSMutableArray alloc] initWithArray:postAtIndex.attributes.summaries.replies];
                for (int x = 0; x < mutableReplies.count; x++) {
                    Post *reply = mutableReplies[x];
                    reply.attributes.postedIn = camp;
                    [mutableReplies replaceObjectAtIndex:x withObject:reply];
                }
                postAtIndex.attributes.summaries.replies = [mutableReplies copy];
            }
            [mutableArray replaceObjectAtIndex:i withObject:postAtIndex];
        }
        
        page.data = [mutableArray copy];
        
        [self.pages replaceObjectAtIndex:p withObject:page];
    }
    
    [self updatePostsArray];
}
- (void)updateUserObjects:(User *)user {
    for (int p = 0; p < self.pages.count; p++) {
        PostStreamPage *page = self.pages[p];
        
        NSMutableArray <Post *> *mutableArray = [[NSMutableArray alloc] initWithArray:page.data];
        for (NSInteger i = mutableArray.count - 1; i >= 0; i--) {
            Post *postAtIndex = mutableArray[i];
            
            // update post creator
            if ([postAtIndex.attributes.creator.identifier isEqualToString:user.identifier]) {
                postAtIndex.attributes.creator = user;
            }
            
            // update replies
            NSMutableArray *mutableReplies = [[NSMutableArray alloc] initWithArray:postAtIndex.attributes.summaries.replies];
            for (int x = 0; x < mutableReplies.count; x++) {
                Post *reply = mutableReplies[x];
                if ([reply.attributes.creator.identifier isEqualToString:user.identifier]) {
                    reply.attributes.creator = user;
                }
                [mutableReplies replaceObjectAtIndex:x withObject:reply];
            }
            postAtIndex.attributes.summaries.replies = [mutableReplies copy];
            
            [mutableArray replaceObjectAtIndex:i withObject:postAtIndex];
        }
        
        page.data = [mutableArray copy];
        
        [self.pages replaceObjectAtIndex:p withObject:page];
    }
    
    [self updatePostsArray];
}

- (void)setTempPostPosition:(PostStreamOptionTempPostPosition)tempPostPosition {
    if (tempPostPosition != _tempPostPosition) {
        _tempPostPosition = tempPostPosition;
        
        [self updatePostsArray];
    }
}

- (NSString *)prevCursor {
    if (self.pages.count == 0) return nil;
    
    // find first available page with cursor
    for (PostStreamPage *page in self.pages) {
        if (page.meta.paging.prevCursor.length > 0) {
            return page.meta.paging.prevCursor;
        }
    }
    
    return nil;
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
