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
@synthesize bfTableView = _bfTableView;
@synthesize sectionTableView = _sectionTableView;

NSString * const rotationAnimationKey = @"rotationAnimation";

- (id)init {
    if (self = [super init]) {
        self.theme = [UIColor bonfireSecondaryColor];
        self.animateLoading = true;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor contentBackgroundColor];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.backgroundColor = [UIColor contentBackgroundColor];
    self.tableView.alpha = 0;
    [self.view addSubview:self.tableView];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.tableView.refreshControl = self.refreshControl;
    
    [self initBigSpinner];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.loading) {
        [self.bigSpinner startAnimating];
    }
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    if ([self.bigSpinner isAnimating]) {
        [self.bigSpinner stopAnimating];
    }
}

- (UITableView * _Nullable)activeTableView {
    if (self.tableView) {
        return self.tableView;
    }
    else if (self.bfTableView) {
        return self.bfTableView;
    }
    else if (self.sectionTableView) {
        return self.sectionTableView;
    }
    
    return nil;
}
- (void)setBfTableView:(BFComponentTableView *)bfTableView {
    if (bfTableView != _bfTableView) {
        _bfTableView = bfTableView;

        if (_bfTableView == nil) {
            return;
        }
        else {
            [_tableView removeFromSuperview];
            _tableView = nil;
            
            [_sectionTableView removeFromSuperview];
            _sectionTableView = nil;
            
            if (_bfTableView.superview) {
                [_bfTableView removeFromSuperview];
            }
            
            _bfTableView.frame = self.view.bounds;
            [self.view addSubview:_bfTableView];
            
            _bfTableView.refreshControl = self.refreshControl;
        }
    }
}
- (void)setSectionTableView:(BFComponentSectionTableView *)bf_tableView {
    if (bf_tableView != _sectionTableView) {
        _sectionTableView = bf_tableView;

        if (_sectionTableView == nil) {
            return;
        }
        else {
            [_tableView removeFromSuperview];
            _tableView = nil;
            
            [_bfTableView removeFromSuperview];
            _bfTableView = nil;
            
            if (_sectionTableView.superview) {
                [_sectionTableView removeFromSuperview];
            }
            
            _sectionTableView.frame = self.view.bounds;
            [self.view addSubview:_sectionTableView];
            
            _sectionTableView.refreshControl = self.refreshControl;
        }
    }
}

- (void)setTheme:(UIColor *)theme {
    if (theme != _theme) {
        _theme = theme;
        
        self.bigSpinner.color = theme;
        [self activeTableView].tintColor = theme;
    }
}

- (void)initBigSpinner {
    self.bigSpinner = [[BFActivityIndicatorView alloc] initWithStyle:BFActivityIndicatorViewStyleLarge];
    self.bigSpinner.color = [UIColor fromHex:[UIColor toHex:self.theme] adjustForOptimalContrast:true];
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
//        [self.bigSpinner startAnimating];
        
        [self activeTableView].userInteractionEnabled = false;
        [UIView animateWithDuration:animated?0.4f:0 delay:0 usingSpringWithDamping:0.75f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            [self activeTableView].transform = CGAffineTransformMakeTranslation(0, 56);
            [self activeTableView].alpha = 0;
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
        }];
        [UIView animateWithDuration:animated?0.56f:0 delay:0.1f usingSpringWithDamping:0.7f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            [self activeTableView].transform = CGAffineTransformMakeTranslation(0, 0);
            [self activeTableView].alpha = 1;
        } completion:^(BOOL finished) {
            [self activeTableView].userInteractionEnabled = true;
        }];
    }
}

- (void)setLoading:(BOOL)loading {
    if (loading != _loading) {
        _loading = loading;
    }
    
    if (self.animateLoading) {
        if ([self activeTableView] && self.spinning != _loading) {
            [self setSpinning:_loading animated:true];
        }
    }
    
    if (!_loading) {
        [self.refreshControl performSelector:@selector(endRefreshing) withObject:nil afterDelay:0.0];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == [self activeTableView]) {
        if (self.navigationController) {
            if ([self.navigationController isKindOfClass:[ComplexNavigationController class]]) {
                ComplexNavigationController *complexNav = (ComplexNavigationController *)self.navigationController;
                [complexNav childTableViewDidScroll:[self activeTableView]];
            }
            else if ([self.navigationController isKindOfClass:[SimpleNavigationController class]]) {
                SimpleNavigationController *simpleNav = (SimpleNavigationController *)self.navigationController;
                [simpleNav childTableViewDidScroll:[self activeTableView]];
            }
        }
    }
}

@end
