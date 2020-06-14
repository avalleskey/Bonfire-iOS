//
//  AddReplyCell.m
//  Pulse
//
//  Created by Austin Valleskey on 6/26/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "AddReplyCell.h"
#import "Session.h"
#import "ReplyCell.h"
#import "UIColor+Palette.h"
#import "BFStreamComponent.h"

@interface AddReplyCell () <BFComponentProtocol>

@end

@implementation AddReplyCell

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
        
        self.profilePicture = [[BFAvatarView alloc] init];
        self.profilePicture.frame = CGRectMake(64, 10, 36, 36);
        self.profilePicture.openOnTap = false;
        self.profilePicture.user = [Session sharedInstance].currentUser;
        self.profilePicture.userInteractionEnabled = false;
        [self.contentView addSubview:self.profilePicture];
        
        self.addReplyButton = [[UIButton alloc] initWithFrame:CGRectMake(114, 0, self.frame.size.width - 114 - replyContentOffset.right, 38)];
        self.addReplyButton.titleLabel.font = [UIFont systemFontOfSize:replyTextViewFont.pointSize-2.f];
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Add a reply..."] attributes:@{NSFontAttributeName: self.addReplyButton.titleLabel.font, NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor]}];
        [self.addReplyButton setAttributedTitle:attributedString forState:UIControlStateNormal];
        self.addReplyButton.layer.cornerRadius = self.addReplyButton.frame.size.height / 2;
        self.addReplyButton.userInteractionEnabled = false;
        self.addReplyButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        self.addReplyButton.contentEdgeInsets = UIEdgeInsetsMake(0, REPLY_BUBBLE_INSETS.left, 0, REPLY_BUBBLE_INSETS.right);
        self.addReplyButton.layer.borderWidth = 1;
        [self.contentView addSubview:self.addReplyButton];
        
        self.lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, HALF_PIXEL)];
        self.lineSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
        [self addSubview:self.lineSeparator];
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    UIEdgeInsets contentEdgeInsets = [ReplyCell contentEdgeInsetsForLevel:self.levelsDeep];
    self.addReplyButton.frame = CGRectMake(contentEdgeInsets.left, self.frame.size.height / 2 - self.addReplyButton.frame.size.height / 2, self.frame.size.width - contentEdgeInsets.left - contentEdgeInsets.right, [AddReplyCell baseHeight]);
    [self.addReplyButton setCornerRadiusType:BFCornerRadiusTypeCircle];
    
    self.profilePicture.frame = CGRectMake([ReplyCell edgeInsetsForLevel:self.levelsDeep].left, self.addReplyButton.frame.origin.y + self.addReplyButton.frame.size.height / 2 - self.profilePicture.frame.size.height / 2, self.profilePicture.frame.size.width, self.profilePicture.frame.size.height);
        
    SetY(self.lineSeparator, self.frame.size.height - self.lineSeparator.frame.size.height);
    SetWidth(self.lineSeparator, self.frame.size.width);
    
    self.addReplyButton.layer.borderColor = [[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.12].CGColor;
}

- (void)setLevelsDeep:(NSInteger)levelsDeep {
    if (levelsDeep != _levelsDeep) {
        _levelsDeep = levelsDeep;
    }
    
    if (levelsDeep > -1) {
        self.addReplyButton.backgroundColor =  [[UIColor fromHex:@"9FA6AD"] colorWithAlphaComponent:0.1];
        self.addReplyButton.layer.borderWidth = 0;
    }
    else {
        self.addReplyButton.backgroundColor =  [UIColor clearColor];
        self.addReplyButton.layer.borderWidth = HALF_PIXEL;
    }
}

+ (CGFloat)baseHeight {
    return REPLY_BUBBLE_INSETS.top + REPLY_BUBBLE_INSETS.bottom + ceilf(replyTextViewFont.lineHeight) + 4;
}
+ (CGFloat)height {
    return [AddReplyCell baseHeight] + (8 * 2);
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
        
    if (highlighted) {
        [UIView animateWithDuration:0.15f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            if (!self.unread) {
                self.contentView.backgroundColor = [UIColor contentHighlightedColor];
            }
            else {
                self.contentView.backgroundColor = [UIColor colorNamed:@"NewBackgroundColor_Highlighted"];
            }
        } completion:nil];
    }
    else {
        [UIView animateWithDuration:0.15f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            if (!self.unread) {
                self.contentView.backgroundColor = [UIColor contentBackgroundColor];
            }
            else {
                self.contentView.backgroundColor = [UIColor colorNamed:@"NewBackgroundColor"];
            }
        } completion:nil];
    }
}

+ (CGFloat)heightForComponent:(BFStreamComponent *)component {
    return [AddReplyCell height];
}

@end
