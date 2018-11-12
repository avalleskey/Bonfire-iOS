//
//  PostTextView.h
//  Pulse
//
//  Created by Austin Valleskey on 9/20/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PostTextView : UIView <UITextViewDelegate>

@property (strong, nonatomic) UITextView *textView;

- (CGSize)size;
- (void)resize;

@end

NS_ASSUME_NONNULL_END
