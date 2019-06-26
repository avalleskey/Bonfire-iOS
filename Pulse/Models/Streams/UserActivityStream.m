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
        NSLog(@"page.paging: %@", page.meta.paging);
        
        NSDictionary *pageDict = [page toDictionary];
        NSArray *pageActivities = [pageDict objectForKey:@"data"] ? pageDict[@"data"] : @[];
        
        NSMutableArray *mutablePageActivities = [pageActivities mutableCopy];
        
        [mutablePageActivities enumerateObjectsUsingBlock:^(UserActivity *activity, NSUInteger x, BOOL *stop)
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

- (NSString *)prevCursor {
    if (self.pages.count == 0) return nil;
    
    // find first available page with cursor
    for (UserActivityStreamPage *page in self.pages) {
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

//- (void)markAllAsRead {
//    for (UserActivityStreamPage *page in self.pages) {
//        NSMutableArray <UserActivity *> *mutableData = [[NSMutableArray alloc] initWithArray:page.data];
//        for (UserActivity *activity in mutableData) {
//            activity.unread = false;
//        }
//
//        page.data = [mutableData copy];
//    }
//
//    [self updateActivitiesArray];
//}

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

@implementation UserActivityStreamPageMeta

@end

@implementation UserActivityStreamPageMetaPaging

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

@end
