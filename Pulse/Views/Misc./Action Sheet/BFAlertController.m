//
//  BFAlertController.m
//  Pulse
//
//  Created by Austin Valleskey on 4/6/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFAlertController.h"

@interface BFAlertAction ()

@property (nullable, readwrite, assign) NSString *title;
@property (readwrite, assign) BFAlertActionStyle style;

@end

@implementation BFAlertAction

@synthesize title = _title;
@synthesize style = _style;

+ (instancetype)actionWithTitle:(nullable NSString *)title style:(BFAlertActionStyle)style handler:(void (^ __nullable)(BFAlertAction *action))handler {
    BFAlertAction *action = [[self alloc] init];
    action.title = title;
    action.style = style;
    
    return action;
}

/*
@property (nullable, nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) BFAlertActionStyle style;
@property (nonatomic, getter=isEnabled) BOOL enabled;*/
- (BOOL)isEnabled {
    return self.enabled;
}

#pragma mark - NSCopying
-(instancetype)copyWithZone:(NSZone *)zone
{
    return [NSKeyedUnarchiver unarchiveObjectWithData:
            [NSKeyedArchiver archivedDataWithRootObject:self]
            ];
}

@end

@interface BFAlertController ()

@property (readwrite, assign) NSArray<BFAlertAction *> *actions;
@property (readwrite, assign) BFAlertControllerStyle preferredStyle;

@end

@implementation BFAlertController

+ (instancetype)alertControllerWithTitle:(nullable NSString *)title message:(nullable NSString *)message preferredStyle:(BFAlertControllerStyle)preferredStyle {
    BFAlertController *alertController = [[self alloc] init];
    alertController.title = title;
    alertController.message = message;
    alertController.preferredStyle = preferredStyle;
    
    /*
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alert addAction:action];
     */
    
    return alertController;
}

- (void)addAction:(BFAlertAction *)action {
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated {
    // animate in
    [super viewDidAppear:animated];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

@end
