//
//  ThreadedPostExpandCell.m
//  Pulse
//
//  Created by Austin Valleskey on 2/17/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "ExpandThreadCell.h"
#import "ReplyCell.h"
#import "MiniReplyCell.h"
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
        
        self.textLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightSemibold];
        self.textLabel.textColor = [UIColor colorWithWhite:0.33 alpha:1];
        
        self.morePostsIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"showMorePostsIcon"]];
        self.morePostsIcon.contentMode = UIViewContentModeCenter;
        [self.contentView addSubview:self.morePostsIcon];
        
        self.lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, (1 / [UIScreen mainScreen].scale))];
        self.lineSeparator.backgroundColor = [UIColor separatorColor];
        [self addSubview:self.lineSeparator];
        self.lineSeparator.hidden = true;
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat profilePictureWidth = 36;
    self.textLabel.frame = CGRectMake(miniReplyContentOffset.left, 0, self.frame.size.width - miniReplyContentOffset.left - miniReplyContentOffset.right, self.frame.size.height);
    self.morePostsIcon.frame = CGRectMake(replyContentOffset.left, self.textLabel.frame.origin.y, profilePictureWidth, self.textLabel.frame.size.height);
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    if (highlighted) {
        [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.contentView.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1];
        } completion:nil];
    }
    else {
        [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.contentView.backgroundColor = [UIColor clearColor];
        } completion:nil];
    }
}

@end
