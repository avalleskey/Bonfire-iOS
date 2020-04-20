//
//  ThemedViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 1/28/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "ThemedViewController.h"
#import "Launcher.h"
#import "UIColor+Palette.h"

@interface ThemedViewController ()

@end

@implementation ThemedViewController

@synthesize spinning = _spinning;
@synthesize loading = _loading;

- (instancetype)init {
    self = [super init];

    if (!self) return nil;

    // some extra initialization
    self.theme = [UIColor bonfireSecondaryColor];
    self.animateLoading = false;

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor contentBackgroundColor];
    
    [self initBigSpinner];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (self.loading && self.animateLoading) {
        [self.view bringSubviewToFront:self.bigSpinner];
        [self.bigSpinner startAnimating];
    }
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    if ([self.bigSpinner isAnimating]) {
        [self.bigSpinner stopAnimating];
    }
}

- (void)setTheme:(UIColor *)theme {
    if (theme != _theme) {
        _theme = theme;

        if (self.bigSpinner) {
            self.bigSpinner.color = theme;
        }
    }
}

- (void)initBigSpinner {
    self.bigSpinner = [[BFActivityIndicatorView alloc] initWithStyle:BFActivityIndicatorViewStyleLarge];
    self.bigSpinner.frame = CGRectMake(0, 0, 128, 128);
    self.bigSpinner.color = [UIColor fromHex:[UIColor toHex:self.theme] adjustForOptimalContrast:true];
    self.bigSpinner.center = self.view.center;
    self.bigSpinner.alpha = 0;
    self.bigSpinner.tag = 1111;
    self.bigSpinner.backgroundColor = [UIColor contentBackgroundColor];
    self.bigSpinner.layer.cornerRadius = 10.f;

    [self.view addSubview:self.bigSpinner];
}

- (void)setSpinning:(BOOL)spinning {
    [self setSpinning:spinning animated:false];
}

- (void)setSpinning:(BOOL)spinning animated:(BOOL)animated {
    if (spinning != _spinning) {
        _spinning = spinning;
    }

    if (spinning) {
//        [self.bigSpinner startAnimating];
        [self.view bringSubviewToFront:self.bigSpinner];

//        self.view.userInteractionEnabled = false;
        [UIView animateWithDuration:animated?0.4f:0 delay:0 usingSpringWithDamping:0.75f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.bigSpinner.alpha = 1;
            self.bigSpinner.transform = CGAffineTransformMakeScale(1, 1);
        } completion:^(BOOL finished) {

        }];
    }
    else {
        [UIView animateWithDuration:animated?0.4f:0 delay:0 usingSpringWithDamping:0.75f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.bigSpinner.alpha = 0;
            self.bigSpinner.transform = CGAffineTransformMakeScale(0.8, 0.8);
        } completion:^(BOOL finished) {
            [self.bigSpinner stopAnimating];
            self.view.userInteractionEnabled = true;
        }];
    }
}

- (void)setLoading:(BOOL)loading {
    if (loading != _loading) {
        _loading = loading;
    }

    if (self.animateLoading) {
        if (self.spinning != _loading) {
            [self setSpinning:_loading animated:true];
        }
    }
}

@end
