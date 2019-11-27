//
//  BFUserAttachmentView.m
//  Pulse
//
//  Created by Austin Valleskey on 8/3/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFPostDeletedAttachmentView.h"
#import "UIColor+Palette.h"

#define POST_DELETED_ATTACHMENT_EDGE_INSETS UIEdgeInsetsMake(16, 24, 16, 24)

#define POST_DELETED_ATTACHMENT_MESSAGE_FONT [UIFont systemFontOfSize:14.f weight:UIFontWeightMedium]

@implementation BFPostDeletedAttachmentView

- (instancetype)initWithMessage:(NSString *)message frame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.message = message;
    }
    
    return self;
}

- (void)setup {
    [super setup];
    
    self.selectable = false;
    self.userInteractionEnabled = false;
    
    self.contentView.backgroundColor = [UIColor bonfireDetailColor];
    
    // display name
    self.messageLabel = [[UILabel alloc] init];
    self.messageLabel.font = POST_DELETED_ATTACHMENT_MESSAGE_FONT;
    self.messageLabel.textColor = [UIColor bonfireSecondaryColor];
    self.messageLabel.textAlignment = NSTextAlignmentCenter;
    self.messageLabel.numberOfLines = 0;
    self.messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.messageLabel.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.messageLabel];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat height = ceilf([self.messageLabel.text boundingRectWithSize:CGSizeMake(self.frame.size.width - (POST_DELETED_ATTACHMENT_EDGE_INSETS.left + POST_DELETED_ATTACHMENT_EDGE_INSETS.right), CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName: POST_DELETED_ATTACHMENT_MESSAGE_FONT} context:nil].size.height);
    self.messageLabel.frame = CGRectMake(POST_DELETED_ATTACHMENT_EDGE_INSETS.left, POST_DELETED_ATTACHMENT_EDGE_INSETS.top, self.frame.size.width - (POST_DELETED_ATTACHMENT_EDGE_INSETS.left + POST_DELETED_ATTACHMENT_EDGE_INSETS.right), height);
}

- (void)setMessage:(NSString *)message {
    if (![message isEqualToString:_message]) {
        _message = message;
        
        self.messageLabel.text = message;
    }
}

+ (CGFloat)heightForMessage:(NSString *)message width:(CGFloat)width {
    CGFloat height = ceilf([message boundingRectWithSize:CGSizeMake(width - (POST_DELETED_ATTACHMENT_EDGE_INSETS.left + POST_DELETED_ATTACHMENT_EDGE_INSETS.right), CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName: POST_DELETED_ATTACHMENT_MESSAGE_FONT} context:nil].size.height);
    
    return POST_DELETED_ATTACHMENT_EDGE_INSETS.top + height + POST_DELETED_ATTACHMENT_EDGE_INSETS.bottom;
}

@end
