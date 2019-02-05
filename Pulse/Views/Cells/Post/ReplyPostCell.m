//
//  ReplyCellTableViewCell.m
//  Pulse
//
//  Created by Austin Valleskey on 1/31/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "ReplyPostCell.h"

@implementation ReplyPostCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.selectable = false;
        
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        
        self.profilePicture.frame = CGRectMake(self.profilePicture.frame.origin.x, self.profilePicture.frame.origin.y, 30, 30);
        
        self.textView.messageLabel.font = textViewReplyFont;
        
        self.threaded = true;
        self.repliesSnapshotView.hidden = true;
        self.lineSeparator.hidden = true;
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    
    
}

@end
