//
//  ButtonCell.m
//  Pulse
//
//  Created by Austin Valleskey on 10/24/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "ButtonCell.h"
#import "Session.h"

@implementation ButtonCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.kButtonColorDefault = [UIColor colorWithWhite:0.2f alpha:1];
        self.kButtonColorDestructive = [UIColor colorWithDisplayP3Red:0.82 green:0.01 blue:0.11 alpha:1.0];
        self.kButtonColorTheme = [Session sharedInstance].themeColor;
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.buttonLabel = [[UILabel alloc] init];
        self.buttonLabel.text = @"";
        self.buttonLabel.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightSemibold];
        self.buttonLabel.textColor = [UIColor colorWithWhite:0.2f alpha:1];
        [self.contentView addSubview:self.buttonLabel];
        
    }
    
    return self;
}


- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.buttonLabel.frame = CGRectMake(16, 0, self.frame.size.width - 32, self.frame.size.height);
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    
    if (highlighted) {
        [UIView animateWithDuration:0.2f animations:^{
            self.backgroundColor = [UIColor colorWithDisplayP3Red:0.92 green:0.92 blue:0.92 alpha:1.00];
        }];
    }
    else {
        [UIView animateWithDuration:0.2f animations:^{
            self.backgroundColor = [UIColor whiteColor];
        }];
    }
}

@end
