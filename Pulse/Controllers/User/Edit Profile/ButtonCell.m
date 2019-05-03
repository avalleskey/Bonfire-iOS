//
//  ButtonCell.m
//  Pulse
//
//  Created by Austin Valleskey on 10/24/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "ButtonCell.h"
#import "Session.h"
#import "UIColor+Palette.h"

@implementation ButtonCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.kButtonColorDefault = [UIColor bonfireBlack];
        self.kButtonColorDestructive = [UIColor colorWithDisplayP3Red:0.82 green:0.01 blue:0.11 alpha:1.0];
        self.kButtonColorTheme = [UIColor bonfireBlack];
        self.kButtonColorBonfire = [UIColor bonfireBrand];
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.buttonLabel = [[UILabel alloc] init];
        self.buttonLabel.text = @"";
        self.buttonLabel.font = [UIFont systemFontOfSize:17.f weight:UIFontWeightSemibold];
        self.buttonLabel.textColor = [UIColor bonfireBlack];
        [self.contentView addSubview:self.buttonLabel];
        
        self.detailTextLabel.font = [UIFont systemFontOfSize:self.buttonLabel.font.pointSize];
        
        self.checkIcon = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
        self.checkIcon.image = [[UIImage imageNamed:@"tableCellCheckIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.checkIcon.tintColor = [UIColor bonfireBrand];
        self.checkIcon.hidden = true;
        [self.contentView addSubview:self.checkIcon];
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.detailTextLabel.text.length > 0) {
        self.detailTextLabel.frame = CGRectMake(self.frame.size.width - 100 - 16 - (self.accessoryType != UITableViewCellAccessoryNone ? 16 : 0), 0, 100, self.frame.size.height);
        self.detailTextLabel.textColor = [UIColor bonfireGray];
        self.detailTextLabel.textAlignment = NSTextAlignmentRight;
        self.detailTextLabel.font = [UIFont systemFontOfSize:15.f weight:UIFontWeightRegular];
        
        self.buttonLabel.frame = CGRectMake(16, 0, self.detailTextLabel.frame.origin.x - 16 - 8, self.frame.size.height);
    }
    else if (!self.checkIcon.isHidden) {
        self.checkIcon.frame = CGRectMake(self.frame.size.width - 16 - self.checkIcon.frame.size.width, self.frame.size.height / 2 - self.checkIcon.frame.size.height / 2, self.checkIcon.frame.size.width, self.checkIcon.frame.size.height);
        self.buttonLabel.frame = CGRectMake(16, 0, self.checkIcon.frame.origin.x - 32, self.frame.size.height);
    }
    else {
        self.buttonLabel.frame = CGRectMake(16, 0, self.frame.size.width - 32, self.frame.size.height);
    }
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
