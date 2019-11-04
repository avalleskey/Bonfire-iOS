//
//  ThreadedPostExpandCell.m
//  Pulse
//
//  Created by Austin Valleskey on 2/17/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "ExpandThreadCell.h"
#import "ReplyCell.h"
#import "StreamPostCell.h"
#import "UIColor+Palette.h"

@implementation ExpandThreadCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.backgroundColor = [UIColor contentBackgroundColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        
        self.textLabel.font = [UIFont systemFontOfSize:15.f weight:UIFontWeightSemibold];
        self.textLabel.textColor = [UIColor colorWithWhite:0.33 alpha:1];
        
        self.morePostsIcon = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"showMorePostsIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        self.morePostsIcon.tintColor = [UIColor bonfireSecondaryColor];
        self.morePostsIcon.layer.masksToBounds = true;
//        self.morePostsIcon.backgroundColor = [[UIColor bonfireSecondaryColor] colorWithAlphaComponent:0.1];
        self.morePostsIcon.contentMode = UIViewContentModeCenter;
        [self.contentView addSubview:self.morePostsIcon];
        
        self.lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - (1 / [UIScreen mainScreen].scale), self.frame.size.width, (1 / [UIScreen mainScreen].scale))];
        self.lineSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
        self.lineSeparator.hidden = true;
        [self addSubview:self.lineSeparator];
        
        // [self createLineView];
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.contentView.frame = CGRectMake(0, 0, self.frame.size.width, [ExpandThreadCell height] - replyContentOffset.bottom);
    
    self.lineSeparator.frame = CGRectMake(0, self.contentView.frame.size.height - (1 / [UIScreen mainScreen].scale), self.frame.size.width, (1 / [UIScreen mainScreen].scale));
    
    CGFloat morePostsIconSize = [ReplyCell avatarSizeForLevel:1];
    UIEdgeInsets contentEdgeInsets = [ReplyCell contentEdgeInsetsForLevel:1];
    self.textLabel.frame = CGRectMake(contentEdgeInsets.left + 10, 0, self.frame.size.width - contentEdgeInsets.left - contentEdgeInsets.right - 10, self.contentView.frame.size.height);
    
    self.morePostsIcon.frame = CGRectMake([ReplyCell edgeInsetsForLevel:1].left, self.contentView.frame.size.height / 2 - morePostsIconSize / 2, morePostsIconSize, morePostsIconSize);
    self.morePostsIcon.layer.cornerRadius = self.morePostsIcon.frame.size.width / 2;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
   [UIView animateWithDuration:0.15f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.contentView.alpha = highlighted ? 0.5 : 1;
    } completion:nil];
}

- (void)createLineView {
    CGFloat lineWidth = 3;
    CGFloat x = 12 + (48 / 2) - (lineWidth / 2);
    
    CGFloat dotSpacing = 3;
    UIView *stackedDotView = [[UIView alloc] initWithFrame:CGRectMake(x, 0, lineWidth, lineWidth * 3 + (dotSpacing * 2))];
    for (NSInteger i = 0; i < 3; i++) {
        UIView *dot = [[UIView alloc] initWithFrame:CGRectMake(0, i * lineWidth + (dotSpacing * i), lineWidth, lineWidth)];
        dot.backgroundColor = [UIColor threadLineColor];
        dot.layer.cornerRadius = lineWidth / 2;
        [stackedDotView addSubview:dot];
    }
    stackedDotView.center = CGPointMake(stackedDotView.center.x, self.contentView.frame.size.height / 2);
    [self.contentView addSubview:stackedDotView];
    
    UIView *topLine = [[UIView alloc] initWithFrame:CGRectMake(x, -2, lineWidth, stackedDotView.frame.origin.y - 4 + 2)];
    topLine.layer.cornerRadius = lineWidth / 2;
    topLine.backgroundColor = [UIColor threadLineColor];
    [self.contentView addSubview:topLine];
    
    UIView *bottomLine = [[UIView alloc] initWithFrame:CGRectMake(x, stackedDotView.frame.origin.y + stackedDotView.frame.size.height + 4, lineWidth, stackedDotView.frame.origin.y - 4 + 2)];
    bottomLine.layer.cornerRadius = lineWidth / 2;
    bottomLine.backgroundColor = [UIColor threadLineColor];
    [self.contentView addSubview:bottomLine];
}

+ (CGFloat)height {
    return 40 + replyContentOffset.bottom;
}

@end
