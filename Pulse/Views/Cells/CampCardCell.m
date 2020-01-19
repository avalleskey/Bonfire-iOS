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
        
        self.layer.cornerRadius = 15.f;
        self.layer.masksToBounds = false;
        self.layer.shadowRadius = 1.f;
        self.layer.shadowOffset = CGSizeMake(0, 1.5);
        self.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.06f].CGColor;
        self.layer.shadowOpacity = 1.f;
        self.contentView.layer.cornerRadius = self.layer.cornerRadius;
        self.contentView.layer.masksToBounds = true;
        self.layer.shouldRasterize = true;
        self.layer.rasterizationScale = [UIScreen mainScreen].scale;
        
        self.layer.borderWidth = (1 / [UIScreen mainScreen].scale);
        self.layer.borderColor = [[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.08].CGColor;
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
