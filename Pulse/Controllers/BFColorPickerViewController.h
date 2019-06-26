//
//  BFColorPickerViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 5/10/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EFCircularSlider.h"

NS_ASSUME_NONNULL_BEGIN

@interface BFColorPickerViewController : UIViewController

- (id)initWithColor:(NSString *)colorString;

@property (nonatomic, strong) UIView *colorPickerView;
@property (nonatomic, strong) UITextField *hexTextField;
@property (nonatomic, strong) EFCircularSlider *hueSlider;

@property (nonatomic, strong) NSString *selectedColor;

@property (strong, nonatomic) UIBarButtonItem *cancelButton;
@property (strong, nonatomic) UIBarButtonItem *saveButton;

@end

NS_ASSUME_NONNULL_END
