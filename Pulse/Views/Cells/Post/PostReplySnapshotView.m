//
//  PostReplySnapshotView.m
//  Pulse
//
//  Created by Austin Valleskey on 2/8/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "PostReplySnapshotView.h"
#import "UIColor+Palette.h"

@implementation PostReplySnapshotView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.thirdAvatar = [[BFAvatarView alloc] init];
        [self addSubview:self.thirdAvatar];
        
        self.secondAvatar = [[BFAvatarView alloc] init];
        [self addSubview:self.secondAvatar];
        
        self.firstAvatar = [[BFAvatarView alloc] init];
        [self addSubview:self.firstAvatar];
        
        [self stylizeAvatar:self.thirdAvatar];
        [self stylizeAvatar:self.secondAvatar];
        [self stylizeAvatar:self.firstAvatar];
        
        self.postPreviewLabel = [[UILabel alloc] init];
        self.postPreviewLabel.font = [UIFont systemFontOfSize:13.f];
        [self addSubview:self.postPreviewLabel];
    }
    return self;
}
- (void)stylizeAvatar:(BFAvatarView *)avatar {
    if (avatar != self.firstAvatar) {
        avatar.alpha = 0.5;
    }
    
    CGFloat strokeWidth = 2;
    UIView *outlineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, avatar.frame.size.width + (strokeWidth * 2), avatar.frame.size.height + (strokeWidth * 2))];
    
    outlineView.layer.cornerRadius = outlineView.frame.size.width / 2;
    outlineView.layer.masksToBounds = true;
    outlineView.backgroundColor = [UIColor whiteColor];
    
    UIView *superview = avatar.superview;
    
    [avatar removeFromSuperview];
    [outlineView addSubview:avatar];
    
    [superview addSubview:outlineView];
    
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.firstAvatar.frame = CGRectMake(2, 2, self.frame.size.height, self.frame.size.height);
    self.firstAvatar.superview.frame = CGRectMake(-2, -2, self.firstAvatar.frame.size.width + (self.firstAvatar.frame.origin.x * 2), self.firstAvatar.frame.size.height + (self.firstAvatar.frame.origin.y * 2));
    self.firstAvatar.superview.layer.cornerRadius = self.firstAvatar.superview.frame.size.width / 2;
    
    self.secondAvatar.frame = CGRectMake(2, 2, self.frame.size.height, self.frame.size.height);
    self.secondAvatar.superview.frame = CGRectMake(self.firstAvatar.superview.frame.origin.x + (self.firstAvatar.superview.frame.size.width / 2), -2, self.secondAvatar.frame.size.width + (self.secondAvatar.frame.origin.x * 2), self.secondAvatar.frame.size.height + (self.secondAvatar.frame.origin.y * 2));
    self.secondAvatar.superview.layer.cornerRadius = self.secondAvatar.superview.frame.size.width / 2;
    
    self.thirdAvatar.frame = CGRectMake(2, 2, self.frame.size.height, self.frame.size.height);
    self.thirdAvatar.superview.frame = CGRectMake(self.secondAvatar.superview.frame.origin.x + (self.secondAvatar.superview.frame.size.width / 2), -2, self.thirdAvatar.frame.size.width + (self.thirdAvatar.frame.origin.x * 2), self.thirdAvatar.frame.size.height + (self.thirdAvatar.frame.origin.y * 2));
    self.thirdAvatar.superview.layer.cornerRadius = self.thirdAvatar.superview.frame.size.width / 2;
    
    [self positionPostPreviewLabel];
}

- (void)setReplies:(NSArray <Post *> *)replies {
    if (replies != _replies) {
        _replies = replies;
        
        NSInteger count = _replies.count;
        
        NSMutableSet *existingIds = [NSMutableSet set];
        NSMutableArray <Post *> *filteredReplies = [NSMutableArray array];
        for (Post *object in _replies) {
            if (![existingIds containsObject:object.identifier]) {
                [existingIds addObject:object.identifier];
                [filteredReplies addObject:object];
            }
        }
        NSInteger filteredCount = filteredReplies.count;
                
        if (count == 0)
            return;
        
        Post *firstReply = filteredReplies[0];
        
        self.firstAvatar.user = firstReply.attributes.details.creator;
        
        self.secondAvatar.hidden = (filteredCount < 2); // TRUE
        if (!self.secondAvatar.isHidden && self.secondAvatar.user != filteredReplies[1].attributes.details.creator) { // !TRUE -> FALSE
            self.secondAvatar.user = filteredReplies[1].attributes.details.creator;
        }
        
        self.thirdAvatar.hidden = (filteredCount < 3);
        if (!self.thirdAvatar.isHidden && self.thirdAvatar.user != filteredReplies[2].attributes.details.creator) {
            self.thirdAvatar.user = filteredReplies[2].attributes.details.creator;
        }
        
        [self positionPostPreviewLabel];
        
        User *userToHighlight = firstReply.attributes.details.creator;
        
        NSString *usernameString = userToHighlight.attributes.details.identifier;
        NSString *messageString = firstReply.attributes.details.message;
        
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:usernameString];
        [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor fromHex:userToHighlight.attributes.details.color] range:NSMakeRange(0, usernameString.length)];
        UIFont *heavyItalicFont = [UIFont fontWithDescriptor:[[[UIFont systemFontOfSize:self.postPreviewLabel.font.pointSize weight:UIFontWeightHeavy] fontDescriptor] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic] size:self.postPreviewLabel.font.pointSize];
        [attributedString addAttribute:NSFontAttributeName value:heavyItalicFont range:NSMakeRange(0, usernameString.length)];
        
        NSMutableAttributedString *message = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"  %@", messageString]];
        [message addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:self.postPreviewLabel.font.pointSize weight:UIFontWeightRegular] range:NSMakeRange(0, messageString.length)];
        [message addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithWhite:0.2f alpha:1] range:NSMakeRange(0, messageString.length)];
        [attributedString appendAttributedString:message];
        self.postPreviewLabel.attributedText = attributedString;
    }
}

- (void)positionPostPreviewLabel {
    BFAvatarView *lastAvatar = self.firstAvatar;
    
    if (!self.thirdAvatar.isHidden) {
        lastAvatar = self.thirdAvatar;
    }
    else if (!self.secondAvatar.isHidden) {
        lastAvatar = self.secondAvatar;
    }
    
    CGFloat postPreviewX = lastAvatar.superview.frame.origin.x + lastAvatar.superview.frame.size.width + 8;
    self.postPreviewLabel.frame = CGRectMake(postPreviewX, 0, self.frame.size.width - postPreviewX, self.frame.size.height);
}

@end
