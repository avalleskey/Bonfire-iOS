//
//  FeatureInfoSheetViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 4/8/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "FeatureInfoSheetViewController.h"

@interface FeatureInfoSheetViewController ()

@end

@implementation FeatureInfoSheetViewController

+ (instancetype)featureInfoSheetWithImage:(UIImage *)image title:(nullable NSString *)title message:(nullable NSString *)message {
    FeatureInfoSheetViewController *infoSheet = [[self alloc] init];
    
    return infoSheet;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
