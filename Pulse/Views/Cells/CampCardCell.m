//
//  CampCardCell.m
//  Pulse
//
//  Created by Austin Valleskey on 10/2/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "CampCardCell.h"
#import "UIColor+Palette.h"

@implementation CampCardCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        self.camp = [[Camp alloc] init];
        
        [self setCornerRadiusType:BFCornerRadiusTypeMedium];
        [self setElevation:1];
        
        self.contentView.layer.cornerRadius = self.layer.cornerRadius;
        self.contentView.layer.masksToBounds = true;
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    // support dark mode
    [self themeChanged];
}

@end
