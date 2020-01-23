//
//  GenericStream.m
//  Pulse
//
//  Created by Austin Valleskey on 7/12/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "GenericStream.h"
#import <UIKit/UIKit.h>

@implementation GenericStream

- (id)init {
    self = [super init];
    if (self) {
        self.cursorsLoaded = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)addLoadedCursor:(NSString *)cursor {
    if (!cursor) return;
    
    [self.cursorsLoaded setObject:[NSDate new] forKey:cursor];
}
- (void)removeLoadedCursor:(NSString *)cursor {
    if (!cursor) return;
    
    [self.cursorsLoaded removeObjectForKey:cursor];
}
- (BOOL)hasLoadedCursor:(NSString *)cursor {
    if (!cursor) return false;
    
    if (![[self.cursorsLoaded allKeys] containsObject:cursor]) {
        return false;
    }
    
    NSDate *dateLoaded = [self.cursorsLoaded objectForKey:cursor];
    NSTimeInterval secondsElapsed = [dateLoaded timeIntervalSinceNow];
    
    CGFloat minutesElapsed = secondsElapsed / 60;
    if (minutesElapsed < -2) {
        [self.cursorsLoaded removeObjectForKey:cursor];
        
        return false;
    }
    else {
        return true;
    }
}

@end

@implementation GenericStreamPageMeta

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

+(BOOL)propertyIsOptional:(NSString*)propertyName
{
    return true;
}

@end

@implementation GenericStreamPageMetaPaging

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

+(BOOL)propertyIsOptional:(NSString*)propertyName
{
    return true;
}

@end
