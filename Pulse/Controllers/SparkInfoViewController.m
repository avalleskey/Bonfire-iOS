//
//  SparkInfoViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 4/10/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "SparkInfoViewController.h"
#import "UIColor+Palette.h"

@interface SparkInfoViewController ()

@end

@implementation SparkInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupViews];
}

- (void)setupViews {
    self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
    
    CGFloat overlayWidth = 311;
    if (overlayWidth > self.view.frame.size.width - 64) {
        overlayWidth = self.view.frame.size.width - 64;
    }
    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width / 2 - overlayWidth / 2, self.view.frame.size.height, overlayWidth, 262)];
    self.contentView.layer.cornerRadius = 20.f;
    self.contentView.layer.masksToBounds = true;
    [self.view addSubview:self.contentView];
    
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.contentView.frame.size.width / 2 - 72 / 2, 32, 72, 72)];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.image = [UIImage imageNamed:@"sparkInfoIcon"];
    [self.contentView addSubview:self.imageView];
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 114, self.contentView.frame.size.width - 32, 28)];
    self.titleLabel.textColor = [UIColor bonfireBlack];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.text = @"Help Posts Go Viral 🚀";
    self.titleLabel.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightSemibold];
    [self.contentView addSubview:self.titleLabel];
}

@end
