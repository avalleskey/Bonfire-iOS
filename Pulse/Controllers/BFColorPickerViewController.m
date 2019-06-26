//
//  BFColorPickerViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 5/10/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFColorPickerViewController.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "UIColor+Palette.h"

@interface BFColorPickerViewController ()

@end

@implementation BFColorPickerViewController

- (id)initWithColor:(NSString *)colorString {
    self = [super init];
    if (self) {
        self.selectedColor = colorString;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"Custom Color";
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    [self.cancelButton setTintColor:[UIColor fromHex:self.selectedColor]];
    [self.cancelButton setTitleTextAttributes:@{
                                                NSFontAttributeName: [UIFont systemFontOfSize:18.f weight:UIFontWeightMedium]
                                                } forState:UIControlStateNormal];
    [self.cancelButton setTitleTextAttributes:@{
                                                NSFontAttributeName: [UIFont systemFontOfSize:18.f weight:UIFontWeightMedium]
                                                } forState:UIControlStateHighlighted];
    self.navigationItem.leftBarButtonItem = self.cancelButton;
    
    self.saveButton = [[UIBarButtonItem alloc] bk_initWithTitle:@"Set" style:UIBarButtonItemStyleDone handler:^(id sender) {
        [self save];
    }];
    [self.saveButton setTintColor:[UIColor fromHex:self.selectedColor]];
    [self.saveButton setTitleTextAttributes:@{
                                              NSFontAttributeName: [UIFont systemFontOfSize:18.f weight:UIFontWeightBold]
                                              } forState:UIControlStateNormal];
    [self.saveButton setTitleTextAttributes:@{
                                              NSFontAttributeName: [UIFont systemFontOfSize:18.f weight:UIFontWeightBold]
                                              } forState:UIControlStateHighlighted];
    self.navigationItem.rightBarButtonItem = self.saveButton;
    
    [self.navigationController.navigationBar setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor bonfireBlack],
       NSFontAttributeName:[UIFont systemFontOfSize:18.f weight:UIFontWeightBold]}];
    
    [self setupPicker];
}

- (void)viewWillAppear:(BOOL)animated {
    // hide hairline
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:[UIImage new]];
    
    [self positionPicker];
}

- (void)setSelectedColor:(NSString *)selectedColor {
    if (![selectedColor isEqualToString:_selectedColor]) {
        _selectedColor = selectedColor;
        
        UIColor *color = [UIColor fromHex:selectedColor];
        
        self.cancelButton.tintColor = color;
        self.saveButton.tintColor = color;
        
        self.hexTextField.tintColor = color;
        
        self.hexTextField.text = [@"#" stringByAppendingString:selectedColor];
    }
}

- (void)setupPicker {
    self.colorPickerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 268, 268)];
    self.colorPickerView.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2 - self.navigationController.navigationBar.frame.size.height - self.navigationController.navigationBar.frame.origin.y);
    self.colorPickerView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.08];
    self.colorPickerView.layer.masksToBounds = false;
    [self.view addSubview:self.colorPickerView];
    
    self.hexTextField = [[UITextField alloc] initWithFrame:CGRectMake(self.colorPickerView.frame.size.width / 2 - (156 / 2), 86, 156, 48)];
    self.hexTextField.textColor = [UIColor bonfireBlack];
    self.hexTextField.font = [UIFont systemFontOfSize:20.f weight:UIFontWeightMedium];
    self.hexTextField.textAlignment = NSTextAlignmentCenter;
    self.hexTextField.backgroundColor = [UIColor colorWithWhite:1 alpha:1];
    self.hexTextField.layer.cornerRadius = 12.f;
    self.hexTextField.layer.masksToBounds = false;
    self.hexTextField.layer.shadowRadius = 2.f;
    self.hexTextField.layer.shadowOffset = CGSizeMake(0, 1);
    self.hexTextField.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.1f].CGColor;
    self.hexTextField.layer.shadowOpacity = 1.f;
    self.hexTextField.tintColor = [UIColor fromHex:self.selectedColor];
    self.hexTextField.text = [@"#" stringByAppendingString:self.selectedColor];
    [self.colorPickerView addSubview:self.hexTextField];
    
    CGRect sliderFrame = CGRectMake(0, 0, self.colorPickerView.frame.size.width, self.colorPickerView.frame.size.height);
    self.hueSlider = [[EFCircularSlider alloc] initWithFrame:sliderFrame];
    [self.hueSlider addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.colorPickerView addSubview:self.hueSlider];
    //[circularSlider setCurrentValue:10.0f];
    
    [self.hexTextField becomeFirstResponder];
}
- (void)positionPicker {
    self.colorPickerView.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2 - self.navigationController.navigationBar.frame.size.height - self.navigationController.navigationBar.frame.origin.y);
}

- (void)valueChanged:(UIControl *)sender {
    NSLog(@"value changed: %f", self.hueSlider.currentValue);
}

- (void)dismiss {
    [self.view endEditing:YES];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}
- (void)save {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
