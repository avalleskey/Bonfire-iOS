//
//  ReplyUpsellTableViewCell.h
//  Pulse
//
//  Created by Austin Valleskey on 4/1/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ReplyUpsellTableViewCell : UITableViewCell

@property (nonatomic, strong) UIView *topSeparator;
@property (nonatomic, strong) UIView *bottomSeparator;

@property (nonatomic, strong) UIScrollView *suggestionsScrollView;
@property (nonatomic, strong) UIStackView *suggestionsStackView;

@property (nonatomic, strong) NSArray *suggestions;

@property (nonatomic) BOOL collapsed;

@property (nonatomic, copy) void (^suggestionTappedAction)(NSString *text);

+ (CGFloat)height;
+ (CGFloat)collapsedHeight;

@end

NS_ASSUME_NONNULL_END
