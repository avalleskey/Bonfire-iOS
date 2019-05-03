//
//  TipsManager.m
//  Pulse
//
//  Created by Austin Valleskey on 5/2/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFTipsManager.h"

@implementation BFTipsManager

+ (BFTipsManager *)sharedInstance {
    static BFTipsManager *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    
    return _sharedInstance;
}

- (id)init {
    self = [super init];
    
    if (self) {
        self.presenting = false;
    }
    
    return self;
}

+ (BFTipsManager *)manager {
    return [BFTipsManager sharedInstance];
}

- (BOOL)isPresenting {
    return self.presenting;
}

@end
