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
        
        self.textLabel.font = [UIFont systemFontOfSize:15.f weight:UIFontWeightSemibold];
        self.textLabel.textColor = [UIColor colorWithWhite:0.33 alpha:1];
        
        self.morePostsIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"showMorePostsIcon"]];
        self.morePostsIcon.contentMode = UIViewContentModeCenter;
        [self.contentView addSubview:self.morePostsIcon];
        
        self.lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - (1 / [UIScreen mainScreen].scale), self.frame.size.width, (1 / [UIScreen mainScreen].scale))];
        self.lineSeparator.backgroundColor = [UIColor separatorColor];
        self.lineSeparator.hidden = true;
        [self addSubview:self.lineSeparator];
        
        // [self createLineView];
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.lineSeparator.frame = CGRectMake(0, self.frame.size.height - (1 / [UIScreen mainScreen].scale), self.frame.size.width, (1 / [UIScreen mainScreen].scale));
    
    CGFloat profilePictureWidth = 32;
    self.textLabel.frame = CGRectMake(replyContentOffset.left, 0, self.frame.size.width - replyContentOffset.left - replyContentOffset.right, self.frame.size.height);
    self.morePostsIcon.frame = CGRectMake(postContentOffset.left, self.textLabel.frame.origin.y, profilePictureWidth, self.textLabel.frame.size.height);
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    if (highlighted) {
        [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.contentView.backgroundColor = [UIColor contentHighlightedColor];
        } completion:nil];
    }
    else {
        [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.contentView.backgroundColor = [UIColor contentBackgroundColor];
        } completion:nil];
    }
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
    stackedDotView.center = CGPointMake(stackedDotView.center.x, CONVERSATION_EXPAND_CELL_HEIGHT / 2);
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

@end
