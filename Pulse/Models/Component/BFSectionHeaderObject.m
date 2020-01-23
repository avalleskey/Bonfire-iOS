//
//  BFSectionHeaderObject.m
//  Pulse
//
//  Created by Austin Valleskey on 1/21/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import "BFSectionHeaderObject.h"

@implementation BFSectionHeaderObject

- (id)initWithTitle:(NSString * _Nullable)title text:(NSString * _Nullable)text target:(id _Nullable)target {
    if (self = [super init]) {
        self.title = title;
        self.text = text;
        self.target = target;
    }
    return self;
}

@end
