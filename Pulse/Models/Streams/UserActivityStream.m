//
//  UserActivityStream.m
//  Pulse
//
//  Created by Austin Valleskey on 3/8/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "UserActivityStream.h"

@implementation UserActivityStream

- (id)init {
    self = [super init];
    if (self) {
        self.pages = [[NSMutableArray alloc] init];
        
        self.activities = @[];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        self.activities = [decoder decodeObjectForKey:@"activities"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.activities forKey:@"activities"];
}

- (void)updatePostsArray {
    NSMutableArray *mutableArray = [[NSMutableArray alloc] init];
    
    for (NSInteger i = 0; i < self.pages.count; i++) {
        // TODO: Insert 'load missing posts' post if before/after doesn't match previous/next page
        
        UserActivityStreamPage *page = self.pages[i];
        NSDictionary *pageDict = [page toDictionary];
        NSArray *pagePosts = [pageDict objectForKey:@"data"] ? pageDict[@"data"] : @[];
        [mutableArray addObjectsFromArray:pagePosts];
    }
    
    self.activities = [mutableArray copy];
}

- (void)prependPage:(UserActivityStreamPage *)page {
    NSMutableArray *pageData = [[NSMutableArray alloc] initWithArray:page.data];
    for (NSInteger i = 0; i < pageData.count; i++) {
        Post *post = [[Post alloc] initWithDictionary:pageData[i] error:nil];
        [pageData replaceObjectAtIndex:i withObject:post];
    }
    page.data = [pageData copy];
    
    [self.pages insertObject:page atIndex:0];
    [self updatePostsArray];
}
- (void)appendPage:(UserActivityStreamPage *)page {
    NSMutableArray *pageData = [[NSMutableArray alloc] initWithArray:page.data];
    for (NSInteger i = 0; i < pageData.count; i++) {
        if ([pageData[i] isKindOfClass:[NSDictionary class]]) {
            Post *post = [[Post alloc] initWithDictionary:pageData[i] error:nil];
            [pageData replaceObjectAtIndex:i withObject:post];
        }
    }
    page.data = [pageData copy];
    
    [self.pages addObject:page];
    [self updatePostsArray];
}

@end

@implementation UserActivityStreamPage

@end

@implementation UserActivityStreamPageMeta

@end

@implementation UserActivityStreamPageMetaPaging

@end
