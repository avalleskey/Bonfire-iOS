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
#import <Tweaks/FBTweakInline.h>

@implementation PostStream

NSString * const PostStreamOptionTempPostPositionKey = @"temp_post_position";

// insert an empty PostStreamPage if
- (id)init {
    self = [super init];
    if (self) {
        self.pages = [[NSMutableArray alloc] init];
        
        self.tempPosts = [[NSMutableArray alloc] init];
        self.posts = @[];
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

- (void)updatePostsArray {
    NSMutableArray *mutableArray = [[NSMutableArray alloc] init];
    
    if (self.tempPostPosition == PostStreamOptionTempPostPositionTop) {
        [mutableArray addObjectsFromArray:self.tempPosts];
    }
    
    for (int i = 0; i < self.pages.count; i++) {
        // TODO: Insert 'load missing posts' post if before/after doesn't match previous/next page
        
        PostStreamPage *page = self.pages[i];
        NSDictionary *pageDict = [page toDictionary];
        NSArray *pagePosts = [pageDict objectForKey:@"data"] ? pageDict[@"data"] : @[];
        [mutableArray addObjectsFromArray:pagePosts];
    }
    
    if (self.tempPostPosition == PostStreamOptionTempPostPositionBottom) {
        [mutableArray addObjectsFromArray:self.tempPosts];
    }
    
    self.posts = [mutableArray copy];
}

- (void)prependPage:(PostStreamPage *)page {
    NSMutableArray *pageData = [[NSMutableArray alloc] initWithArray:page.data];
    for (int i = 0; i < pageData.count; i++) {
        Post *post = [[Post alloc] initWithDictionary:pageData[i] error:nil];
        [pageData replaceObjectAtIndex:i withObject:post];
    }
    page.data = [pageData copy];
    
    [self.pages insertObject:page atIndex:0];
    [self updatePostsArray];
}
- (void)appendPage:(PostStreamPage *)page {
    NSMutableArray *pageData = [[NSMutableArray alloc] initWithArray:page.data];
    for (int i = 0; i < pageData.count; i++) {
        if ([pageData[i] isKindOfClass:[NSDictionary class]]) {
            Post *post = [[Post alloc] initWithDictionary:pageData[i] error:nil];
            [pageData replaceObjectAtIndex:i withObject:post];
        }
    }
    page.data = [pageData copy];
    
    [self.pages addObject:page];
    [self updatePostsArray];
}

- (BOOL)removeTempPost:(NSString *)tempId {
    return [self updateTempPost:tempId withFinalPost:nil];
}
- (NSString *)addTempPost:(Post *)post {
    NSString *tempId = [NSString stringWithFormat:@"%d", [[Session sharedInstance] getTempId]];
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
    NSString *tempId = [NSString stringWithFormat:@"%d", [[Session sharedInstance] getTempId]];
    subReply.tempId = tempId;
    
    // always add to bottom
    BOOL foundMatch = false;
    for (int i = 0; i < self.pages.count; i++) {
        PostStreamPage *page = self.pages[i];
        for (int p = 0; p < page.data.count; p++) {
            // go through each reply, checking to see if the sub reply parent  == identifier of post
            Post *reply = page.data[p];
            if (reply.identifier == subReply.attributes.details.parent) {
                // match!
                NSLog(@"heh match match !!");
                NSMutableArray *mutableArray = [[NSMutableArray alloc] initWithArray:reply.attributes.summaries.replies];
                [mutableArray addObject:subReply];
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
    
    return tempId;
}
- (BOOL)updateTempSubReply:(NSString *)tempId withFinalSubReply:(Post *)finalSubReply {
    // always add to bottom
    BOOL foundMatch = false;
    for (int i = 0; i < self.pages.count; i++) {
        PostStreamPage *page = self.pages[i];
        for (int p = 0; p < page.data.count; p++) {
            // go through each reply, checking to see if the sub reply parent  == identifier of post
            Post *reply = page.data[p];
            NSMutableArray *mutableSubReplies = [[NSMutableArray alloc] initWithArray:reply.attributes.summaries.replies];
            
            for (int s = 0; s < mutableSubReplies.count; s++) {
                Post *subReply = mutableSubReplies[s];
                if ([subReply.tempId isEqualToString:tempId]) {
                    // match!
                    NSLog(@"heh old temp match match !!");
                    [mutableSubReplies replaceObjectAtIndex:s withObject:finalSubReply];
                    NSArray <Post *> <Post> *copy = [mutableSubReplies copy];
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
    for (int i = 0; i < self.pages.count; i++) {
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
    for (int i = 0; i < self.pages.count; i++) {
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

- (Post *)postWithId:(NSInteger)postId {
    for (int i = 0; i < self.posts.count; i++) {
        if (self.posts[i].identifier == postId) {
            return self.posts[i];
        }
    }
    
    return nil;
}
- (BOOL)updatePost:(Post *)post {
    BOOL changes = false;
    for (int p = 0; p < self.pages.count; p++) {
        PostStreamPage *page = self.pages[p];
        
        NSMutableArray <Post *> *mutableArray = [[NSMutableArray alloc] initWithArray:page.data];
        for (NSInteger i = mutableArray.count - 1; i >= 0; i--) {
            Post *postAtIndex = mutableArray[i];
            if (postAtIndex.identifier == post.identifier) {
                [mutableArray replaceObjectAtIndex:i withObject:post];
                post.rowHeight = 0;
                changes = true;
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
            }
        }
        
        page.data = [mutableArray copy];
        
        [self.pages replaceObjectAtIndex:p withObject:page];
    }
    [self updatePostsArray];
}

- (void)updateRoomObjects:(Room *)room {
    for (int p = 0; p < self.pages.count; p++) {
        PostStreamPage *page = self.pages[p];
        
        NSMutableArray <Post *> *mutableArray = [[NSMutableArray alloc] initWithArray:page.data];
        for (NSInteger i = mutableArray.count - 1; i >= 0; i--) {
            Post *postAtIndex = mutableArray[i];
            if (postAtIndex.attributes.status.postedIn.identifier == room.identifier) {
                postAtIndex.attributes.status.postedIn = room;
                NSLog(@"👀 updated room postedIn");
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
            if ([postAtIndex.attributes.details.creator.identifier isEqualToString:user.identifier]) {
                postAtIndex.attributes.details.creator = user;
                NSLog(@"%ld: replace post creator", i);
            }
            
            // update replies
            NSMutableArray *mutableReplies = [[NSMutableArray alloc] initWithArray:postAtIndex.attributes.summaries.replies];
            for (int x = 0; x < mutableReplies.count; x++) {
                Post *reply = mutableReplies[x];
                if ([reply.attributes.details.creator.identifier isEqualToString:user.identifier]) {
                    reply.attributes.details.creator = user;
                    NSLog(@"%i: replace reply user", x);
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

- (NSInteger)topId {
    if (self.posts.count == 0) return 0;
    
    return [self.posts firstObject].identifier;
}
- (NSInteger)bottomId {
    if (self.posts.count == 0) return 0;
    
    return [self.posts lastObject].identifier;
}

- (void)setTempPostPosition:(PostStreamOptionTempPostPosition)tempPostPosition {
    if (tempPostPosition != _tempPostPosition) {
        _tempPostPosition = tempPostPosition;
        
        [self updatePostsArray];
    }
}

@end

@implementation PostStreamPage

@synthesize topId = _topId;
@synthesize bottomId = _bottomId;

+(BOOL)propertyIsOptional:(NSString*)propertyName
{
    NSArray *optionalProperties = @[@"topId", @"bottomId"];
    if ([optionalProperties containsObject:propertyName]) return YES;
    return NO;
}

- (NSInteger)topId {
    if (self.data.count == 0) return 0;
    
    return [self.data firstObject].identifier;
}
- (NSInteger)bottomId {
    if (self.data.count == 0) return 0;
    
    return [self.data lastObject].identifier;
}


@end

@implementation PostStreamPageMeta

@end

@implementation PostStreamPageMetaPaging

@end
