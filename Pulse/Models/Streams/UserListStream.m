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
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userUpdated:) name:@"UserUpdated" object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

- (void)userUpdated:(NSNotification *)notification {
    User *user = notification.object;
    
    if (user != nil) {
        BOOL foundChange = false;
        
        for (int p = 0; p < self.pages.count; p++) {
            UserListStreamPage *page = self.pages[p];
            
            NSMutableArray <User *> *mutableArray = [[NSMutableArray alloc] initWithArray:page.data];
            for (NSInteger i = mutableArray.count - 1; i >= 0; i--) {
                User *userAtIndex = mutableArray[i];
                
                // update post creator
                if ([userAtIndex.identifier isEqualToString:user.identifier]) {
                    userAtIndex = user;
                    
                    foundChange = true;
                    
                    [mutableArray replaceObjectAtIndex:i withObject:userAtIndex];
                }
            }
            
            page.data = [mutableArray copy];
            
            [self.pages replaceObjectAtIndex:p withObject:page];
        }
        
        if (foundChange) {
            [self updateUsersArray];
        }
    }
}

- (void)updateUsersArray {
    NSMutableArray *mutableArray = [[NSMutableArray alloc] init];
    
    for (UserListStreamPage *page in self.pages) {
        NSDictionary *pageDict = [page toDictionary];
        NSArray *pageCamps = [pageDict objectForKey:@"data"] ? pageDict[@"data"] : @[];
        [mutableArray addObjectsFromArray:pageCamps];
    }
    
    self.users = [mutableArray copy];
    
    if ([self.delegate respondsToSelector:@selector(userListStreamDidUpdate:)]) {
        [self.delegate userListStreamDidUpdate:self];
    }
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
