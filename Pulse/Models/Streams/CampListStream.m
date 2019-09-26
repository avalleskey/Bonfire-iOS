//
//  CampListStream.m
//  Pulse
//
//  Created by Austin Valleskey on 7/12/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "CampListStream.h"

@implementation CampListStream

- (id)init {
    self = [super init];
    if (self) {
        self.pages = [[NSMutableArray alloc] init];
        
        self.camps = @[];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        self.camps = [decoder decodeObjectForKey:@"camps"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.camps forKey:@"camps"];
}

- (void)updateCampsArray {
    NSMutableArray *mutableArray = [[NSMutableArray alloc] init];
    
    for (CampListStreamPage *page in self.pages) {
        NSDictionary *pageDict = [page toDictionary];
        NSArray *pageCamps = [pageDict objectForKey:@"data"] ? pageDict[@"data"] : @[];
        [mutableArray addObjectsFromArray:pageCamps];
    }
    
    self.camps = [mutableArray copy];
}

- (void)prependPage:(CampListStreamPage *)page {
    NSMutableArray *pageData = [[NSMutableArray alloc] initWithArray:page.data];
    [pageData enumerateObjectsUsingBlock:^(NSDictionary *campDict, NSUInteger i, BOOL * _Nonnull stop) {
        if ([campDict isKindOfClass:[NSDictionary class]]) {
            NSError *error;
            Camp *camp = [[Camp alloc] initWithDictionary:campDict error:&error];
            [pageData replaceObjectAtIndex:i withObject:camp];
        }
    }];
    page.data = [pageData copy];
    
    [self.pages insertObject:page atIndex:0];
    [self updateCampsArray];
}
- (void)appendPage:(CampListStreamPage *)page {
    NSMutableArray *pageData = [[NSMutableArray alloc] initWithArray:page.data];
    [pageData enumerateObjectsUsingBlock:^(NSDictionary *campDict, NSUInteger i, BOOL * _Nonnull stop) {
        if ([campDict isKindOfClass:[NSDictionary class]]) {
            NSError *error;
            Camp *camp = [[Camp alloc] initWithDictionary:campDict error:&error];
            [pageData replaceObjectAtIndex:i withObject:camp];
        }
    }];
    page.data = [pageData copy];
    
    [self.pages addObject:page];
    [self updateCampsArray];
}

- (NSString * _Nullable)prevCursor {
    if (self.pages.count == 0) return nil;
    
    // find first available page with cursor
    for (CampListStreamPage *page in self.pages) {
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

@implementation CampListStreamPage

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

+ (BOOL)propertyIsOptional:(NSString*)propertyName
{
    return YES; // all are optional
}

@end

