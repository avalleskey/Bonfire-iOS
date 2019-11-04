//
//  UserListStream.m
//  Pulse
//
//  Created by Austin Valleskey on 7/12/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "UserListStream.h"

@implementation UserListStream

- (id)init {
    self = [super init];
    if (self) {
        self.pages = [[NSMutableArray alloc] init];
        
        self.users = @[];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        self.users = [decoder decodeObjectForKey:@"users"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.users forKey:@"users"];
}

- (void)updateUsersArray {
    NSMutableArray *mutableArray = [[NSMutableArray alloc] init];
    
    for (UserListStreamPage *page in self.pages) {
        NSDictionary *pageDict = [page toDictionary];
        NSArray *pageCamps = [pageDict objectForKey:@"data"] ? pageDict[@"data"] : @[];
        [mutableArray addObjectsFromArray:pageCamps];
    }
    
    self.users = [mutableArray copy];
}

- (void)prependPage:(UserListStreamPage *)page {
    NSMutableArray *pageData = [[NSMutableArray alloc] initWithArray:page.data];
    [pageData enumerateObjectsUsingBlock:^(NSDictionary *userDict, NSUInteger i, BOOL * _Nonnull stop) {
        if ([userDict isKindOfClass:[NSDictionary class]]) {
            NSError *error;
            User *user = [[User alloc] initWithDictionary:userDict error:&error];
            [pageData replaceObjectAtIndex:i withObject:user];
        }
    }];
    page.data = [pageData copy];
    
    [self.pages insertObject:page atIndex:0];
    [self updateUsersArray];
}
- (void)appendPage:(UserListStreamPage *)page {
    NSMutableArray *pageData = [[NSMutableArray alloc] initWithArray:page.data];
    [pageData enumerateObjectsUsingBlock:^(NSDictionary *userDict, NSUInteger i, BOOL * _Nonnull stop) {
        if ([userDict isKindOfClass:[NSDictionary class]]) {
            NSError *error;
            User *user = [[User alloc] initWithDictionary:userDict error:&error];
            [pageData replaceObjectAtIndex:i withObject:user];
        }
    }];
    page.data = [pageData copy];
    
    [self.pages addObject:page];
    [self updateUsersArray];
}

- (NSString * _Nullable)prevCursor {
    if (self.pages.count == 0) return @"";
    
    // find first available page with cursor
    for (UserListStreamPage *page in self.pages) {
        if (page.meta.paging.prevCursor.length > 0) {
            return page.meta.paging.prevCursor;
        }
    }
    
    return nil;
}
- (NSString * _Nullable)nextCursor {
    if (self.pages.count == 0) return nil;
    if ([self.pages lastObject].meta.paging.nextCursor.length == 0) return nil;
    
    return [self.pages lastObject].meta.paging.nextCursor;
}

@end

@implementation UserListStreamPage

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

+ (BOOL)propertyIsOptional:(NSString*)propertyName
{
    return YES; // all are optional
}

@end
