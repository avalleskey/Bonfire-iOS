//
//  BFColorPickerViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 5/10/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BFColorPickerViewControllerDelegate <NSObject>

- (void)colorPicker:(id)colorPicker didSelectColor:(NSString *)color;

@end

@interface BFColorPickerViewController : UIViewController

- (id)initWithColor:(UIColor *)color;

@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) UIColor *selectedColor;

@property (strong, nonatomic) UIButton *cancelButton;
@property (strong, nonatomic) UIButton *saveButton;

@property (nonatomic, weak) id <BFColorPickerViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
