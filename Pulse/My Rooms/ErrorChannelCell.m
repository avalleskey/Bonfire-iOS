//
//  ErrorChannelCell.m
//  Pulse
//
//  Created by Austin Valleskey on 10/24/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "ErrorChannelCell.h"

@implementation ErrorChannelCell

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    
    self.layer.cornerRadius = 12.f;
    self.layer.masksToBounds = true;
    
    // setup error view
    self.errorView = [[ErrorView alloc] initWithFrame:CGRectMake(8, 0, self.frame.size.width - 16, 100) title:@"Error Loading" description:@"Check your network settings and tap to try again." type:ErrorViewTypeGeneral];
    [self.contentView addSubview:self.errorView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.errorView.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
}

@end
