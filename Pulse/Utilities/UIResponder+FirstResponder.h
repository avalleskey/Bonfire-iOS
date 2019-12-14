//
//  UIResponder+FirstResponder.h
//  Pulse
//
//  Created by Austin Valleskey on 12/11/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIResponder (FirstResponder)

+ (id)currentFirstResponder;

@end

NS_ASSUME_NONNULL_END
