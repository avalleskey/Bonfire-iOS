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
#import "BFStreamComponent.h"

@interface ExpandThreadCell () <BFComponentProtocol>

@end

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
        self.textLabel.textColor = [UIColor bonfireSecondaryColor];
        
        self.levelsDeep = -1;
        
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
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.contentView.frame = CGRectMake(0, 0, self.frame.size.width, [ExpandThreadCell height]);
    
    self.lineSeparator.frame = CGRectMake(0, self.contentView.frame.size.height - (1 / [UIScreen mainScreen].scale), self.frame.size.width, (1 / [UIScreen mainScreen].scale));
    
    CGFloat morePostsIconSize = [ReplyCell avatarSizeForLevel:self.levelsDeep];
    UIEdgeInsets contentEdgeInsets = [ReplyCell contentEdgeInsetsForLevel:self.levelsDeep];
    self.textLabel.frame = CGRectMake(contentEdgeInsets.left + REPLY_BUBBLE_INSETS.left, 0, self.frame.size.width - contentEdgeInsets.left - contentEdgeInsets.right - REPLY_BUBBLE_INSETS.right - REPLY_BUBBLE_INSETS.left, self.contentView.frame.size.height);
    
    self.morePostsIcon.frame = CGRectMake([ReplyCell edgeInsetsForLevel:self.levelsDeep].left, self.contentView.frame.size.height / 2 - morePostsIconSize / 2 + HALF_PIXEL, morePostsIconSize, morePostsIconSize);
    self.morePostsIcon.layer.cornerRadius = self.morePostsIcon.frame.size.width / 2;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
   [UIView animateWithDuration:0.15f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
       self.contentView.backgroundColor = [[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:highlighted?0.04:0];
    } completion:nil];
}

- (void)setPost:(Post *)post {
    if (post != _post) {
        _post = post;
        
        BOOL hasExistingSubReplies = post.attributes.summaries.replies.count != 0;
        self.textLabel.text = [NSString stringWithFormat:@"View%@ replies (%ld)", (hasExistingSubReplies ? @" more" : @""), (long)post.attributes.summaries.counts.replies - post.attributes.summaries.replies.count];
        
        if (hasExistingSubReplies) {
            // view more replies
            
        }
        else {
            // start replies chain
            
        }
    }
}

+ (CGFloat)height {
    return 40;
}

+ (CGFloat)heightForComponent:(nonnull BFStreamComponent *)component {
    return [self height];
}

@end
