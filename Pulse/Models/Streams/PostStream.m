//
//  PostStream.m
//  Pulse
//
//  Created by Austin Valleskey on 12/6/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "PostStream.h"

@implementation PostStream

// insert an empty PostStreamPage if
- (id)init {
    self = [super init];
    if (self) {
        self.pages = [[NSMutableArray alloc] init];
        self.posts = @[];
    }
    return self;
}

- (void)updatePostsArray {
    NSMutableArray *mutableArray = [[NSMutableArray alloc] init];
    for (int i = 0; i < self.pages.count; i++) {
        // TODO: Insert 'load missing posts' post if before/after doesn't match previous/next page
        
        PostStreamPage *page = self.pages[i];
        NSDictionary *pageDict = [page toDictionary];
        NSArray *pagePosts = [pageDict objectForKey:@"data"] ? pageDict[@"data"] : @[];
        [mutableArray addObjectsFromArray:pagePosts];
    }
    
    self.posts = [mutableArray copy];
}

- (void)prependPage:(PostStreamPage *)page {
    NSMutableArray *pageData = [[NSMutableArray alloc] initWithArray:page.data];
    for (int i = 0; i < pageData.count; i++) {
        Post *post = [[Post alloc] initWithDictionary:[page toDictionary][@"data"][i] error:nil];
        [pageData replaceObjectAtIndex:i withObject:post];
    }
    page.data = [pageData copy];
    NSLog(@"page.data: %@", page.data);
    
    [self.pages insertObject:page atIndex:0];
    [self updatePostsArray];
}
- (void)appendPage:(PostStreamPage *)page {
    NSMutableArray *pageData = [[NSMutableArray alloc] initWithArray:page.data];
    for (int i = 0; i < pageData.count; i++) {
        Post *post = [[Post alloc] initWithDictionary:pageData[i] error:nil];
        [pageData replaceObjectAtIndex:i withObject:post];
    }
    page.data = [pageData copy];
    
    [self.pages addObject:page];
    [self updatePostsArray];
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
