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

@implementation AddReplyCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.contentView.backgroundColor = [UIColor clearColor];
        
        self.profilePicture = [[BFAvatarView alloc] init];
        self.profilePicture.frame = CGRectMake(70, 12, 32, 32);
        self.profilePicture.openOnTap = false;
        self.profilePicture.user = [Session sharedInstance].currentUser;
        self.profilePicture.userInteractionEnabled = false;
        [self.contentView addSubview:self.profilePicture];
        
        self.addReplyLabel = [[UILabel alloc] initWithFrame:CGRectMake(114, 10, self.frame.size.width - 114 - replyContentOffset.right, 32)];
        self.addReplyLabel.text = @"Add a reply...";
        self.addReplyLabel.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightRegular];
        self.addReplyLabel.textColor = [UIColor bonfireGray];
        //self.addReplyLabel.textContainerInset = UIEdgeInsetsZero; // UIEdgeInsetsMake((self.addReplyLabel.frame.size.height - self.addReplyLabel.font.lineHeight) / 2, 6, 0, 6);
        //self.addReplyLabel.layer.cornerRadius = self.addReplyLabel.frame.size.height / 2;
        //self.addReplyLabel.backgroundColor = [[UIColor fromHex:@"9FA6AD"] colorWithAlphaComponent:0.1];
        //self.addReplyLabel.layer.borderWidth = (1 / [UIScreen mainScreen].scale);
        //self.addReplyLabel.layer.borderColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.06f].CGColor;
        self.addReplyLabel.userInteractionEnabled = false;
        
        [self.contentView addSubview:self.addReplyLabel];
        
        self.topLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 3, 0)];
        self.topLine.backgroundColor = [UIColor threadLineColor];
        self.topLine.layer.cornerRadius = self.topLine.frame.size.width / 2;
        //[self addSubview:self.topLine];
        
        self.lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, (1 / [UIScreen mainScreen].scale))];
        self.lineSeparator.backgroundColor = [UIColor separatorColor];
        [self addSubview:self.lineSeparator];
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.addReplyLabel.frame = CGRectMake(114, 0, self.frame.size.width - 114 - replyContentOffset.right, self.frame.size.height);
    self.profilePicture.center = CGPointMake(self.profilePicture.center.x, self.addReplyLabel.center.y);
    
    self.topLine.frame = CGRectMake(12 + (48 / 2) - (self.topLine.frame.size.width / 2), -2, self.topLine.frame.size.width, self.profilePicture.frame.origin.y - 4 + 2);
    
    SetWidth(self.lineSeparator, self.frame.size.width);
    SetY(self.lineSeparator, self.frame.size.height - self.lineSeparator.frame.size.height);
}

+ (CGFloat)height {
    return 10 + 32 + 12;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    if (highlighted) {
        [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.backgroundColor = [UIColor contentHighlightedColor];
        } completion:nil];
    }
    else {
        [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.backgroundColor = [UIColor contentBackgroundColor];
        } completion:nil];
    }
}

@end
