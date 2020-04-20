//
//  BFEffects.h
//  Pulse
//
//  Created by Austin Valleskey on 4/7/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView(BFEffects)

typedef enum {
    BFEffectTypeBalloons,
    BFEffectTypeEmojis
} BFEffectType;

/// Show an effect
/// @param effectType The type of effect to show
/// @param completion if implemented, the completion handler is called upon completion of the effect
- (void)showEffect:(BFEffectType)effectType completion:(void (^__nullable)(void))completion;

@end

NS_ASSUME_NONNULL_END
