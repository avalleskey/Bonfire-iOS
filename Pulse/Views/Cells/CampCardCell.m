//
//  CampCardCell.m
//  Pulse
//
//  Created by Austin Valleskey on 10/2/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "CampCardCell.h"

@implementation CampCardCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        self.camp = [[Camp alloc] init];
        
        self.layer.borderWidth = (1 / [UIScreen mainScreen].scale);
        self.layer.borderColor = [[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.1].CGColor;
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    // support dark mode
    self.layer.borderColor = [[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.1].CGColor;
}

@end
