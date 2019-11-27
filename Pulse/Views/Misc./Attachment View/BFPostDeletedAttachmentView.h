//
//  BFUserAttachmentView.h
//  Pulse
//
//  Created by Austin Valleskey on 8/3/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFAttachmentView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BFPostDeletedAttachmentView : BFAttachmentView

- (instancetype)initWithMessage:(NSString *)message frame:(CGRect)frame;
@property (nonatomic, strong) NSString *message;

@property (nonatomic, strong) UILabel *messageLabel;

+ (CGFloat)heightForMessage:(NSString *)message width:(CGFloat)width;

@end

NS_ASSUME_NONNULL_END
