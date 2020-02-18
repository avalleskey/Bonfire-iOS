//
//  NSArray+Components.h
//  Pulse
//
//  Created by Austin Valleskey on 1/23/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BFPostStreamComponent.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSArray (Components)

- (NSArray<BFPostStreamComponent *> *)toPostStreamComponents;
- (NSArray<BFPostStreamComponent *> *)toPostStreamComponentsWithDetailLevel:(BFComponentDetailLevel)detailLevel;

@end

NS_ASSUME_NONNULL_END
