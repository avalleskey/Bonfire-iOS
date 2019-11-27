//
//  ThemedTableTableViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 1/28/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "ThemedTableViewController.h"
#import "Launcher.h"
#import "UIColor+Palette.h"

@interface ThemedTableViewController ()

@end

@implementation ThemedTableViewController

@synthesize spinning = _spinning;
@synthesize loading = _loading;

NSString * const rotationAnimationKey = @"rotationAnimation";

- (id)init {
    if (self = [super init]) {
        self.theme = [UIColor bonfireSecondaryColor];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setup];
    [self initBigSpinner];
}

- (void)setup {
    self.view.backgroundColor = [UIColor contentBackgroundColor];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.backgroundColor = [UIColor contentBackgroundColor];
    self.tableView.alpha = 0;
    [self.view addSubview:self.tableView];
    
    self.refreshControl = [[UIRefreshControl alloc]init];
    self.tableView.refreshControl = self.refreshControl;
}

- (void)setTableView:(UITableView *)tableView {
    if (tableView != _tableView) {
        _tableView = tableView;
        
        if (tableView && self.rs_tableView) {
            self.rs_tableView = nil;
        }
    }
}
- (void)setRs_tableView:(RSTableView *)rs_tableView {
    if (rs_tableView != _rs_tableView) {
        _rs_tableView = rs_tableView;
        
        if (rs_tableView && self.tableView) {
            self.tableView = nil;
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!self.loading) {
        [self setSpinning:false animated:false];
    }
    
    if (![self.bigSpinner isHidden]) {
        [self.bigSpinner.layer removeAnimationForKey:rotationAnimationKey];
        [self addAnimationToBigSpinner];
    }
}

- (void)setTheme:(UIColor *)theme {
    if (theme != _theme) {
        _theme = theme;
        
        self.bigSpinner.tintColor = theme;
        self.tableView.tintColor = theme;
    }
}

- (void)initBigSpinner {
    self.bigSpinner = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 52, 52)];
    self.bigSpinner.image = [[UIImage imageNamed:@"spinner"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.bigSpinner.tintColor = [UIColor fromHex:[UIColor toHex:self.theme] adjustForOptimalContrast:true];
    self.bigSpinner.center = self.view.center;
    self.bigSpinner.alpha = 0;
    self.bigSpinner.tag = 1111;
    
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
        [self addAnimationToBigSpinner];
        
        self.tableView.userInteractionEnabled = false;
        [UIView animateWithDuration:animated?0.4f:0 delay:0 usingSpringWithDamping:0.75f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.tableView.transform = CGAffineTransformMakeTranslation(0, 56);
            self.tableView.alpha = 0;
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
            [self.bigSpinner.layer removeAnimationForKey:rotationAnimationKey];
        }];
        [UIView animateWithDuration:animated?0.56f:0 delay:0.1f usingSpringWithDamping:0.7f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.tableView.transform = CGAffineTransformMakeTranslation(0, 0);
            self.tableView.alpha = 1;
        } completion:^(BOOL finished) {
            self.tableView.userInteractionEnabled = true;
        }];
    }
}

- (void)setLoading:(BOOL)loading {
    if (loading != _loading) {
        _loading = loading;
    }
    
    if (_loading) {
        if (!self.spinning) {
            [self setSpinning:true animated:true];
        }
    }
    else {
        if (self.spinning) {
            [self setSpinning:false animated:true];
        }
        [self.refreshControl performSelector:@selector(endRefreshing) withObject:nil afterDelay:0.0];
    }
}

- (void)addAnimationToBigSpinner {
    [self.bigSpinner.layer removeAnimationForKey:rotationAnimationKey];
    
    CABasicAnimation *rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 /* full rotation*/ * 1 * 1.f ];
    rotationAnimation.duration = 0.8f;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = HUGE_VALF;
    [self.bigSpinner.layer addAnimation:rotationAnimation forKey:rotationAnimationKey];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == self.tableView) {
        UINavigationController *navController = UIViewParentController(self).navigationController;
        if (navController) {
            if ([navController isKindOfClass:[ComplexNavigationController class]]) {
                ComplexNavigationController *complexNav = (ComplexNavigationController *)navController;
                [complexNav childTableViewDidScroll:self.tableView];
            }
            else if ([navController isKindOfClass:[SimpleNavigationController class]]) {
                SimpleNavigationController *simpleNav = (SimpleNavigationController *)navController;
                [simpleNav childTableViewDidScroll:self.tableView];
            }
        }
    }
}

@end
