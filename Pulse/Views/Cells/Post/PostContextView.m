//
//  PostContextView.m
//  Pulse
//
//  Created by Austin Valleskey on 1/8/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "PostContextView.h"
#import "UIColor+Palette.h"

@implementation PostContextView

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
- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    // self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.04];
    
    self.contextIcon = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 10, self.frame.size.height)];
    // self.contextIcon.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1f];
    self.contextIcon.layer.cornerRadius = self.contextIcon.frame.size.height / 2;
    self.contextIcon.layer.masksToBounds = true;
    self.contextIcon.contentMode = UIViewContentModeCenter;
    self.contextIcon.tintColor = [UIColor bonfireGray];
    [self addSubview:self.contextIcon];
    
    self.contextLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, postContextHeight)];
    self.contextLabel.textColor = [UIColor bonfireGray];
    self.contextLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightSemibold];
    self.contextLabel.textAlignment = NSTextAlignmentLeft;
    //self.contextLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1f];
    [self addSubview:self.contextLabel];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.contextIcon.frame = CGRectMake(48 - self.contextIcon.image.size.width, self.frame.size.height / 2 - self.contextIcon.image.size.height / 2, self.contextIcon.image.size.width, self.contextIcon.image.size.height);
    self.contextLabel.frame = CGRectMake(70 - self.frame.origin.x, self.contextLabel.frame.origin.y, self.frame.size.width - (70 - self.frame.origin.x), self.contextLabel.frame.size.height);
}

- (void)setText:(NSString *)text {
    if (![text isEqualToString:_text]) {
        _text = text;
        
        self.contextLabel.text = text;
        
        [self layoutSubviews];
    }
}
- (void)setIcon:(UIImage *)icon {
    if (icon != _icon) {
        _icon = icon;
        
        self.contextIcon.image = icon;
    }
}

@end
