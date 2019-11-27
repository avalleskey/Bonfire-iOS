//
//  BFHeaderView.m
//  Pulse
//
//  Created by Austin Valleskey on 5/22/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFHeaderView.h"
#import "UIColor+Palette.h"

#define HEADER_INSETS UIEdgeInsetsMake(32, 12, 12, 12)
#define HEADER_LABEL_HEIGHT 20
#define TOP_BLOCK_HEIGHT 0

@implementation BFHeaderView

- (id)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.backgroundColor = [UIColor tableViewBackgroundColor];
    
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.textColor = [UIColor bonfireSecondaryColor];
    self.titleLabel.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightBold];
    [self addSubview:self.titleLabel];
    
    self.subTitleLabel = [[UILabel alloc] init];
    self.subTitleLabel.textColor = [UIColor bonfireSecondaryColor];
    self.subTitleLabel.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightMedium];
    self.subTitleLabel.textAlignment = NSTextAlignmentRight;
    self.subTitleLabel.hidden = true;
    [self addSubview:self.subTitleLabel];
    
    self.topBlock = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, TOP_BLOCK_HEIGHT)];
    self.topBlock.backgroundColor = [UIColor tableViewBackgroundColor];
    [self addSubview:self.topBlock];
    
    self.topBlockSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, (1 / [UIScreen mainScreen].scale))];
    self.topBlockSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
    self.topBlockSeparator.hidden = true;
    [self.topBlock addSubview:self.topBlockSeparator];
    
    self.topLineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, self.topBlock.frame.size.height, self.frame.size.width, (1 / [UIScreen mainScreen].scale))];
    self.topLineSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
    self.topLineSeparator.hidden = true;
    //[self addSubview:self.topLineSeparator];
    
    self.bottomLineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - (1 / [UIScreen mainScreen].scale), self.frame.size.width, (1 / [UIScreen mainScreen].scale))];
    self.bottomLineSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
    self.bottomLineSeparator.hidden = true;
    [self addSubview:self.bottomLineSeparator];
    
    self.separator = true;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if ([self.topBlock isHidden]) {
        self.topLineSeparator.frame = CGRectMake(0, 0, self.frame.size.width, (1 / [UIScreen mainScreen].scale));
    }
    else {
        self.topBlock.frame = CGRectMake(0, 0, self.frame.size.width, self.topBlock.frame.size.height);
        self.topBlockSeparator.frame = CGRectMake(0, 0, self.frame.size.width, (1 / [UIScreen mainScreen].scale));
        
        self.topLineSeparator.frame = CGRectMake(0, self.topBlock.frame.size.height, self.frame.size.width, (1 / [UIScreen mainScreen].scale));
    }
    
    if ([self.subTitleLabel isHidden]) {
        self.titleLabel.frame = CGRectMake(HEADER_INSETS.left, self.topLineSeparator.frame.origin.y + HEADER_INSETS.top, self.frame.size.width - (HEADER_INSETS.left + HEADER_INSETS.right), HEADER_LABEL_HEIGHT);
    }
    else {
        CGFloat subTitleWidth = ceilf(self.frame.size.width * .35);
        self.subTitleLabel.frame = CGRectMake(self.frame.size.width - subTitleWidth - HEADER_INSETS.right, self.topLineSeparator.frame.origin.y + HEADER_INSETS.top, subTitleWidth, HEADER_LABEL_HEIGHT);
        self.titleLabel.frame = CGRectMake(HEADER_INSETS.left, self.topLineSeparator.frame.origin.y + HEADER_INSETS.top, self.frame.size.width - (HEADER_INSETS.left + HEADER_INSETS.right) - subTitleWidth - 8, HEADER_LABEL_HEIGHT);
    }
}

- (void)setTitle:(NSString *)title {
    if (![title isEqualToString:_title]) {
        _title = title;
        
        self.titleLabel.text = title;
        
        // Resize label
        [self layoutSubviews];
    }
}

- (void)setSubTitle:(NSString *)subTitle {
    if (![subTitle isEqualToString:_subTitle]) {
        _subTitle = subTitle;
        
        NSLog(@"set subtitle:: %@", subTitle);
        
        self.subTitleLabel.text = subTitle;
        self.subTitleLabel.hidden = (subTitle == nil || subTitle.length == 0 || [subTitle isEqualToString:@"0"]);
        
        // Resize label
        [self layoutSubviews];
    }
}

- (void)setSeparator:(BOOL)separator {
    if (separator != _separator) {
        _separator = separator;
        
        self.topLineSeparator.hidden = !separator;
        self.bottomLineSeparator.hidden = !separator;
    }
}

- (void)setTableViewHasSeparators:(BOOL)tableViewHasSeparators {
    if (tableViewHasSeparators != _tableViewHasSeparators) {
        _tableViewHasSeparators = tableViewHasSeparators;
        
        //self.topBlockSeparator.hidden = tableViewHasSeparators;
        self.bottomLineSeparator.hidden = tableViewHasSeparators;
    }
}

+ (CGFloat)height {
    return [self heightWithTopBlock:true];
}

+ (CGFloat)heightWithTopBlock:(BOOL)includeTopBlock {
    return (includeTopBlock ? TOP_BLOCK_HEIGHT : 0) + HEADER_INSETS.top + HEADER_LABEL_HEIGHT + HEADER_INSETS.bottom;
}

@end
