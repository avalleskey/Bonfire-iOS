//
//  PaginationCell.m
//  Hallway App
//
//  Created by Austin Valleskey on 6/18/18.
//  Copyright © 2018 Hallway App. All rights reserved.
//

#import "PaginationCell.h"
#import "UIColor+Palette.h"
#import "BFComponent.h"

@interface PaginationCell () <BFComponentProtocol>

@end

@implementation PaginationCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.accessoryType = UITableViewCellAccessoryNone;
        
        self.backgroundColor = [UIColor contentBackgroundColor];
        
        self.topSeparator = [[UIView alloc] init];
        self.topSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
        self.topSeparator.hidden = true;
        [self.contentView addSubview:self.topSeparator];
        
        self.bottomSeparator = [[UIView alloc] init];
        self.bottomSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
        self.bottomSeparator.hidden = true;
        [self.contentView addSubview:self.bottomSeparator];
        
        self.loading = false;
        
        self.spinner = [[BFActivityIndicatorView alloc] init];
        self.spinner.color = [[UIColor bonfireSecondaryColor] colorWithAlphaComponent:0.5];
        self.spinner.frame = CGRectMake(0, 0, 40, 40);
        [self.contentView addSubview:self.spinner];
        
        self.textLabel.textColor = [UIColor bonfireSecondaryColor];
        self.textLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightRegular];
        self.textLabel.hidden = true;
        self.textLabel.textAlignment = NSTextAlignmentCenter;
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.topSeparator.frame = CGRectMake(0, 0, self.frame.size.width, HALF_PIXEL);
    self.bottomSeparator.frame = CGRectMake(0, self.frame.size.height - HALF_PIXEL, self.frame.size.width, HALF_PIXEL);
    
    self.spinner.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    
    self.textLabel.frame = CGRectMake(12, 0, self.frame.size.width - 12 * 2, self.frame.size.height);
}

+ (CGFloat)height {
    return 52 + 8;
}

+ (CGFloat)heightForComponent:(nonnull BFComponent *)component {
    return [PaginationCell height];
}

@end
