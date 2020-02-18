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
#import "BFPostStreamComponent.h"

@interface ButtonCell () <BFComponentProtocol>

@end

@implementation ButtonCell

NSString *const ButtonCellTitleAttributeName = @"title";
NSString *const ButtonCellTitleColorAttributeName = @"color";

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.gutterPadding = 12;
        
        self.imageView.layer.masksToBounds = true;
        self.imageView.backgroundColor = [UIColor bonfireSecondaryColor];
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.backgroundColor  = [UIColor contentBackgroundColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        
        self.kButtonColorDefault = [UIColor bonfirePrimaryColor];
        self.kButtonColorDestructive = [UIColor fromHex:@"ff0900" adjustForOptimalContrast:true];
        self.kButtonColorTheme = [UIColor bonfirePrimaryColor];
        self.kButtonColorBonfire = [UIColor bonfireBrand];
                
        self.buttonLabel = [[UILabel alloc] init];
        self.buttonLabel.text = @"";
        self.buttonLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightMedium];
        self.buttonLabel.textColor = [UIColor bonfirePrimaryColor];
        [self.contentView addSubview:self.buttonLabel];
        
        self.detailTextLabel.font = [UIFont systemFontOfSize:self.buttonLabel.font.pointSize];
        
        self.checkIcon = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
        self.checkIcon.image = [[UIImage imageNamed:@"tableCellCheckIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.checkIcon.tintColor = [UIColor bonfireBrand];
        self.checkIcon.hidden = true;
        [self.contentView addSubview:self.checkIcon];
        
        self.iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(12, 0, 24, 24)];
        self.iconImageView.tintColor = [UIColor bonfireSecondaryColor];
        self.iconImageView.alpha = 0.5;
        self.iconImageView.hidden = true;
        self.iconImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:self.iconImageView];
        
        self.topSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, HALF_PIXEL)];
        self.topSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
        self.topSeparator.hidden = true;
        [self.contentView addSubview:self.topSeparator];
        
        self.bottomSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - HALF_PIXEL, self.frame.size.width, HALF_PIXEL)];
        self.bottomSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
        self.bottomSeparator.hidden = true;
        [self.contentView addSubview:self.bottomSeparator];
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.contentView.frame = self.bounds;
    
    UIEdgeInsets contentEdgeInsets = UIEdgeInsetsMake(0, self.gutterPadding, 0, self.gutterPadding);
    
    self.iconImageView.hidden = !(self.iconImageView.image);
    if (![self.iconImageView isHidden]) {
        CGFloat iconImageWidth = 32;
        CGFloat iconImageHeight = ceilf(MIN(self.frame.size.height * 0.7, self.iconImageView.image.size.height));
        self.iconImageView.frame = CGRectMake(contentEdgeInsets.left + 4, (self.frame.size.height / 2) - (iconImageHeight / 2), iconImageWidth, iconImageHeight);
        self.iconImageView.layer.cornerRadius = self.imageView.frame.size.height / 2;
        
        contentEdgeInsets.left = self.iconImageView.frame.origin.x + self.iconImageView.frame.size.width + 12;
        contentEdgeInsets.right = contentEdgeInsets.left;
    }
    
    self.detailTextLabel.hidden = self.detailTextLabel.text.length == 0 || [self.detailTextLabel.text isEqualToString:@"0"] || self.detailTextLabel.text.length == 0;
    if (![self.detailTextLabel isHidden]) {
        self.detailTextLabel.frame = CGRectMake(self.frame.size.width - 100 - 16 - (self.accessoryType != UITableViewCellAccessoryNone ? 16 : 0), 0, 100, self.frame.size.height);
        self.detailTextLabel.textColor = [UIColor bonfireSecondaryColor];
        self.detailTextLabel.textAlignment = NSTextAlignmentRight;
        self.detailTextLabel.font = [UIFont systemFontOfSize:self.buttonLabel.font.pointSize weight:UIFontWeightMedium];
        
        contentEdgeInsets.right = self.frame.size.width - self.detailTextLabel.frame.origin.x - 8;
    }
    else if (![self.checkIcon isHidden]) {
        self.checkIcon.frame = CGRectMake(self.frame.size.width - 16 - self.checkIcon.frame.size.width, self.frame.size.height / 2 - self.checkIcon.frame.size.height / 2, self.checkIcon.frame.size.width, self.checkIcon.frame.size.height);
        
        contentEdgeInsets.right = self.frame.size.width - self.checkIcon.frame.origin.x - 8;
    }
    
    self.buttonLabel.frame = CGRectMake(contentEdgeInsets.left, 0, self.frame.size.width - contentEdgeInsets.left - contentEdgeInsets.right, self.frame.size.height);
    
    self.topSeparator.frame = CGRectMake(self.topSeparator.frame.origin.x, 0, self.frame.size.width - self.topSeparator.frame.origin.x, self.topSeparator.frame.size.height);
    self.bottomSeparator.frame = CGRectMake(self.bottomSeparator.frame.origin.x, self.frame.size.height - self.bottomSeparator.frame.size.height, self.frame.size.width - self.bottomSeparator.frame.origin.x, self.bottomSeparator.frame.size.height);
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    
    [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        if (highlighted) {
            self.contentView.backgroundColor = [[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.03];
        }
        else {
            self.contentView.backgroundColor = [[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0];
        }
    } completion:nil];
}

- (void)action {
    
}

+ (CGFloat)height {
    return 52;
}

+ (CGFloat)heightForComponent:(BFPostStreamComponent *)component {
    return [ButtonCell height];
}

@end
