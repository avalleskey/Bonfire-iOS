//
//  PostContextView.h
//  Pulse
//
//  Created by Austin Valleskey on 1/8/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

#define postContextHeight 18

NS_ASSUME_NONNULL_BEGIN

@interface PostContextView : UIView

typedef enum {
    PostContextViewTypeRespark = 0,
    PostContextViewTypeReply = 1, // this post is a reply to user's post
    PostContextViewTypeReplied = 2 // user replied to this post
} PostContextViewType;

@property (nonatomic) PostContextViewType type;

@property (strong, nonatomic) UILabel *contextLabel;
@property (strong, nonatomic) UIImageView *contextIcon;

@end

NS_ASSUME_NONNULL_END
