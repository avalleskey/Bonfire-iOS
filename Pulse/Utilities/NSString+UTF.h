//
//  NSString+UTF.h
//  Pulse
//
//  Created by Austin Valleskey on 8/23/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (UTF)

- (NSRange)composedRangeWithRange:(NSRange)range;

@end

NS_ASSUME_NONNULL_END
