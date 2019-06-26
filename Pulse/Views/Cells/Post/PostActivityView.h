//
//  PostActivityView.h
//  Pulse
//
//  Created by Austin Valleskey on 2/28/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Post.h"

NS_ASSUME_NONNULL_BEGIN

@interface PostActivityView : UIView

@property (nonatomic, strong) NSMutableArray *views;

@property (nonatomic, strong) Post *post;

- (void)start;
- (void)stop;
- (void)next;

@end

NS_ASSUME_NONNULL_END
