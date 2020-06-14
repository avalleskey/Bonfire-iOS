//
//  BFAlternativeHeaderView.m
//  Pulse
//
//  Created by Austin Valleskey on 5/22/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFAlternativeHeaderView.h"
#import "UIColor+Palette.h"

#define HEADER_INSETS UIEdgeInsetsMake(0, 12, 10, 12)

@implementation BFAlternativeHeaderView

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
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.textColor = [UIColor bonfireSecondaryColor];
    self.titleLabel.font = [UIFont systemFontOfSize:13.f weight:UIFontWeightSemibold];
    
    [self addSubview:self.titleLabel];
    
    self.topLineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, HALF_PIXEL)];
    self.topLineSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
    self.topLineSeparator.hidden = true;
    
    //[self addSubview:self.topLineSeparator];
    
    self.bottomLineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - HALF_PIXEL, self.frame.size.width, HALF_PIXEL)];
    self.bottomLineSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
    self.bottomLineSeparator.hidden = true;
    
    [self addSubview:self.bottomLineSeparator];
    
    self.separator = true;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.titleLabel.frame = CGRectMake(HEADER_INSETS.left, self.frame.size.height - HEADER_INSETS.bottom - 17, self.frame.size.width - (HEADER_INSETS.left + HEADER_INSETS.right), 17);
}

- (void)setTitle:(NSString *)title {
    if (title != _title) {
        _title = title;
        
        self.titleLabel.text = [title uppercaseString];
        
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

+ (CGFloat)height {
    return 48;
}

@end
