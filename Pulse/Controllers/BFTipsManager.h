//
//  TipsManager.h
//  Pulse
//
//  Created by Austin Valleskey on 5/2/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BFTipView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BFTipsManager : NSObject

+ (BFTipsManager *)manager;

@property (nonatomic) BOOL presenting;

@property (nonatomic, strong) NSMutableArray <BFTipView *> * tips;
- (void)presentTip:(BFTipObject *)tipObject completion:(void (^ __nullable)(void))completion;
- (void)presentTipView:(BFTipView *)tipView completion:(void (^ __nullable)(void))completion;
- (void)hideAllTips;

@end

NS_ASSUME_NONNULL_END
