//
//  BFAttachmentView.h
//  Pulse
//
//  Created by Austin Valleskey on 8/3/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BFAttachmentView : UIView

- (void)setup;

@property (nonatomic, strong) UIView *contentView;

@property (nonatomic) BOOL selectable;
@property (nonatomic) BOOL touchDown;

- (CGFloat)height;

@end

NS_ASSUME_NONNULL_END
