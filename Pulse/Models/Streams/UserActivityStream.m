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

- (void)updateActivitiesArray {
    NSMutableArray *mutableArray = [[NSMutableArray alloc] init];
    
    for (UserActivityStreamPage *page in self.pages) {
        NSDictionary *pageDict = [page toDictionary];
        NSArray *pageActivities = [pageDict objectForKey:@"data"] ? pageDict[@"data"] : @[];
        
        NSMutableArray *mutablePageActivities = [pageActivities mutableCopy];
        
        [mutablePageActivities enumerateObjectsUsingBlock:^(UserActivity *activity, NSUInteger x, BOOL *stop)
        {
            if (x == 0 && page.meta.paging.prevCursor.length > 0) {
                activity.prevCursor = page.meta.paging.prevCursor;
            }
            if (x == mutablePageActivities.count - 1 && page.meta.paging.nextCursor.length > 0) {
                activity.nextCursor = page.meta.paging.nextCursor;
            }
            [mutablePageActivities replaceObjectAtIndex:x withObject:activity];
        }];
        
        [mutableArray addObjectsFromArray:[mutablePageActivities copy]];
    }
    
    self.activities = [mutableArray copy];
}

- (void)prependPage:(UserActivityStreamPage *)page {
    NSMutableArray *pageData = [[NSMutableArray alloc] initWithArray:page.data];
    for (NSInteger i = 0; i < pageData.count; i++) {
        if ([pageData[i] isKindOfClass:[NSDictionary class]]) {
            NSError *error;
            UserActivity *activity = [[UserActivity alloc] initWithDictionary:pageData[i] error:&error];
            [pageData replaceObjectAtIndex:i withObject:activity];
        }
    }
    
    /*
     TODO: make more efficient
     [pageData enumerateObjectsUsingBlock:^(UserActivity *activity, NSUInteger i, BOOL *stop)
     {
     if (x == 0 && page.meta.paging.prevCursor.length > 0) {
     activity.prevCursor = page.meta.paging.prevCursor;
     NSLog(@"found a prev cursor:: %@", page.meta.paging.prevCursor);
     }
     if (x == mutablePageActivities.count - 1 && page.meta.paging.nextCursor.length > 0) {
     activity.nextCursor = page.meta.paging.nextCursor;
     NSLog(@"found a next cursor:: %@", page.meta.paging.nextCursor);
     }
     [mutablePageActivities replaceObjectAtIndex:x withObject:activity];
     }];
     */
    
    page.data = [pageData copy];
    
    [self.pages insertObject:page atIndex:0];
    [self updateActivitiesArray];
}
- (void)appendPage:(UserActivityStreamPage *)page {
    NSMutableArray *pageData = [[NSMutableArray alloc] initWithArray:page.data];
    for (NSInteger i = 0; i < pageData.count; i++) {
        if ([pageData[i] isKindOfClass:[NSDictionary class]]) {
            NSError *error;
            UserActivity *activity = [[UserActivity alloc] initWithDictionary:pageData[i] error:&error];
            [pageData replaceObjectAtIndex:i withObject:activity];
        }
    }
    page.data = [pageData copy];
    
    [self.pages addObject:page];
    [self updateActivitiesArray];
}


- (BOOL)updatePost:(Post *)post removeDuplicates:(BOOL)removeDuplicates {
    BOOL changes = false;
    
    for (int p = 0; p < self.pages.count; p++) {
        UserActivityStreamPage *page = self.pages[p];
        
        NSMutableArray <UserActivity *> *mutableArray = [[NSMutableArray alloc] initWithArray:page.data];
        for (NSInteger i = mutableArray.count - 1; i >= 0; i--) {
            UserActivity *activityAtIndex = mutableArray[i];
            if (activityAtIndex.attributes.post &&
                [activityAtIndex.attributes.post.identifier isEqualToString:post.identifier]) {
                changes = true;
                activityAtIndex.attributes.post = post;
            }
            else if (activityAtIndex.attributes.replyPost &&
                    [activityAtIndex.attributes.replyPost.identifier isEqualToString:post.identifier]) {
                changes = true;
                activityAtIndex.attributes.replyPost = post;
            }
            
            if (changes) {
                [mutableArray replaceObjectAtIndex:i withObject:activityAtIndex];
            }
        }
        
        page.data = [mutableArray copy];
        
        [self.pages replaceObjectAtIndex:p withObject:page];
    }
    
    if (changes) {
        [self updateActivitiesArray];
    }
    
    return changes;
}

- (BOOL)removePost:(Post *)post {
    BOOL updates = false;
    for (int p = 0; p < self.pages.count; p++) {
        UserActivityStreamPage *page = self.pages[p];
        
        NSMutableArray <UserActivity *> *mutableArray = [[NSMutableArray alloc] initWithArray:page.data];
        for (NSInteger i = mutableArray.count - 1; i >= 0; i--) {
            UserActivity *activityAtIndex = mutableArray[i];
            
            Post *activityPost = activityAtIndex.attributes.post;
            Post *activityReplyPost = activityAtIndex.attributes.replyPost;
            if ((activityPost &&
                 [activityPost.identifier isEqualToString:post.identifier]) ||
                (activityReplyPost &&
                [activityReplyPost.identifier isEqualToString:post.identifier])) {
                [mutableArray removeObjectAtIndex:i];
                
                updates = true;
                
                continue;
            }
        }
        
        page.data = [mutableArray copy];
        
        [self.pages replaceObjectAtIndex:p withObject:page];
    }
    [self updateActivitiesArray];
    
    return updates;
}
- (void)updateCampObjects:(Camp *)camp {
    for (int p = 0; p < self.pages.count; p++) {
        UserActivityStreamPage *page = self.pages[p];
        
        NSMutableArray <UserActivity *> *mutableArray = [[NSMutableArray alloc] initWithArray:page.data];
        for (NSInteger i = mutableArray.count - 1; i >= 0; i--) {
            UserActivity *activityAtIndex = mutableArray[i];
            if ([activityAtIndex.attributes.camp.identifier isEqualToString:camp.identifier]) {
                activityAtIndex.attributes.camp = camp;
                NSLog(@"👀 updated camp objects in activities array");
            }
            [mutableArray replaceObjectAtIndex:i withObject:activityAtIndex];
        }
        
        page.data = [mutableArray copy];
        
        [self.pages replaceObjectAtIndex:p withObject:page];
    }
    
    [self updateActivitiesArray];
}
- (void)updateUserObjects:(User *)user {
    for (int p = 0; p < self.pages.count; p++) {
        UserActivityStreamPage *page = self.pages[p];
        
        NSMutableArray <UserActivity *> *mutableArray = [[NSMutableArray alloc] initWithArray:page.data];
        for (NSInteger i = mutableArray.count - 1; i >= 0; i--) {
            UserActivity *activityAtIndex = mutableArray[i];
            if ([activityAtIndex.attributes.actioner.identifier isEqualToString:user.identifier]) {
                activityAtIndex.attributes.actioner = user;
                NSLog(@"👀 updated user objects in activities array");
            }
            [mutableArray replaceObjectAtIndex:i withObject:activityAtIndex];
        }
        
        page.data = [mutableArray copy];
        
        [self.pages replaceObjectAtIndex:p withObject:page];
    }
    
    [self updateActivitiesArray];
}

- (void)updateAttributedStrings {
    for (int p = 0; p < self.pages.count; p++) {
        UserActivityStreamPage *page = self.pages[p];
        
        NSMutableArray <UserActivity *> *mutableArray = [[NSMutableArray alloc] initWithArray:page.data];
        for (NSInteger i = mutableArray.count - 1; i >= 0; i--) {
            UserActivity *activityAtIndex = mutableArray[i];
            [activityAtIndex updateAttributedString];
            [mutableArray replaceObjectAtIndex:i withObject:activityAtIndex];
        }
        
        page.data = [mutableArray copy];
        
        [self.pages replaceObjectAtIndex:p withObject:page];
    }
    
    [self updateActivitiesArray];
}

- (NSString * _Nullable)prevCursor {
    if (self.pages.count == 0) return @"";
    
    // find first available page with cursor
    for (UserActivityStreamPage *page in self.pages) {
        if (page.meta.paging.prevCursor.length > 0) {
            return page.meta.paging.prevCursor;
        }
    }
    
    return nil;
}
- (NSString * _Nullable)nextCursor {
    if (self.pages.count == 0) return @"";
    if ([self.pages lastObject].meta.paging.nextCursor.length == 0) return @"";
    
    return [self.pages lastObject].meta.paging.nextCursor;
}

- (void)markAllAsRead {
    for (int p = 0; p < self.pages.count; p++) {
        UserActivityStreamPage *page = self.pages[p];
        
        NSMutableArray <UserActivity *> *mutableArray = [[NSMutableArray alloc] initWithArray:page.data];
        for (NSInteger i = mutableArray.count - 1; i >= 0; i--) {
            UserActivity *activityAtIndex = mutableArray[i];
            [activityAtIndex markAsRead];
            [mutableArray replaceObjectAtIndex:i withObject:activityAtIndex];
        }
        
        page.data = [mutableArray copy];
        
        [self.pages replaceObjectAtIndex:p withObject:page];
    }
    
    [self updateActivitiesArray];
}
- (NSInteger)unreadCount {
    NSInteger unread = 0;
    for (UserActivity *activity in self.activities) {
        if (!activity.attributes.read) {
            unread++;
        }
    }
    
    return unread;
}

@end

@implementation UserActivityStreamPage

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

+ (BOOL)propertyIsOptional:(NSString*)propertyName
{
    return YES; // all are optional
}

@end
