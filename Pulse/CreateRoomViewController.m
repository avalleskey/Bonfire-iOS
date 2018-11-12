//
//  CreateRoomViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 10/5/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "CreateRoomViewController.h"
#import <BlocksKit/BlocksKit+UIKit.h>
#import <HapticHelper/HapticHelper.h>
#import "L360ConfettiArea.h"
#import "MiniChannelCell.h"
#import "Session.h"
#import "Room.h"
#import "LauncherNavigationViewController.h"
#import "SOLOptionsTransitionAnimator.h"
#import "RoomViewController.h"

#define envConfig [[[NSUserDefaults standardUserDefaults] objectForKey:@"config"] objectForKey:[[NSUserDefaults standardUserDefaults] stringForKey:@"environment"]]

#define UIViewParentController(__view) ({ \
    UIResponder *__responder = __view; \
    while ([__responder isKindOfClass:[UIView class]]) \
    __responder = [__responder nextResponder]; \
    (UIViewController *)__responder; \
    })

#define IS_IPHONE        (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_IPHONE_5 ([[UIScreen mainScreen] bounds].size.height == 568.0)
#define IS_TINY ([[UIScreen mainScreen] bounds].size.height == 480)

@interface CreateRoomViewController () <L360ConfettiAreaDelegate> {
    UIEdgeInsets safeAreaInsets;
    NSArray *colors;
}

@property (nonatomic) NSInteger themeColor;
@property (nonatomic) int currentStep;
@property (strong, nonatomic) NSMutableArray *steps;
@property (strong, nonatomic) LauncherNavigationViewController *launchNavVC;
@property (nonatomic) CGFloat currentKeyboardHeight;
@property (strong, nonatomic) NSMutableArray *similarRooms;

@end

@implementation CreateRoomViewController

static NSString * const miniChannelReuseIdentifier = @"MiniChannel";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.view.tintColor = [[Session sharedInstance] themeColor];
    
    self.manager = [HAWebService manager];
    
    [self addListeners];
    [self setupViews];
    [self setupSteps];
    
    // –––– show the first step ––––
    self.currentStep = -1;
    [self nextStep:false];
    
    safeAreaInsets.top = 1; // set to 1 so we only set it once in viewWillAppear
    
    self.transitioningDelegate = self;
}
- (void)viewWillAppear:(BOOL)animated {
    if (safeAreaInsets.top == 1) {
        safeAreaInsets = [UIApplication sharedApplication].keyWindow.safeAreaInsets;
        [self updateWithSafeAreaInsets];
    }
}

- (void)updateWithSafeAreaInsets {
    self.closeButton.frame = CGRectMake(self.view.frame.size.width - 44 - 11, safeAreaInsets.top, 44, 44);
}

- (void)addListeners {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillDismiss:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)setupViews {
    self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.closeButton setImage:[[UIImage imageNamed:@"navCloseIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.closeButton.tintColor = self.view.tintColor;
    self.closeButton.contentMode = UIViewContentModeCenter;
    [self.closeButton bk_whenTapped:^{
        [self.view endEditing:TRUE];
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    [self.view addSubview:self.closeButton];
    
    self.nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.nextButton.frame = CGRectMake(24, self.view.frame.size.height, self.view.frame.size.width - (24 * 2), 48);
    self.nextButton.backgroundColor = [self.view tintColor];
    self.nextButton.titleLabel.font = [UIFont systemFontOfSize:20.f weight:UIFontWeightSemibold];
    [self.nextButton setTitleColor:[UIColor colorWithWhite:0.6f alpha:1] forState:UIControlStateDisabled];
    [self continuityRadiusForView:self.nextButton withRadius:12.f];
    [self.nextButton setTitle:@"Next" forState:UIControlStateNormal];
    [self.view addSubview:self.nextButton];
    [self greyOutNextButton];
    
    [self.nextButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.nextButton.alpha = 0.8;
            self.nextButton.transform = CGAffineTransformMakeScale(0.8, 0.8);
        } completion:nil];
    } forControlEvents:UIControlEventTouchDown];
    
    [self.nextButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.nextButton.alpha = 1;
            self.nextButton.transform = CGAffineTransformMakeScale(1, 1);
        } completion:nil];
    } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
    
    [self.nextButton bk_whenTapped:^{
        [self handleNext];
    }];
}

- (void)setupSteps {
    CGFloat inputCenterY = (self.view.frame.size.height / 2) - (self.view.frame.size.height * .15);
    self.instructionLabel = [[UILabel alloc] initWithFrame:CGRectMake(48, 129, self.view.frame.size.width - 96, 42)];
    self.instructionLabel.center = CGPointMake(self.instructionLabel.center.x, (inputCenterY / 2) + 16);
    self.instructionLabel.textAlignment = NSTextAlignmentCenter;
    self.instructionLabel.text = @"";
    self.instructionLabel.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightMedium];
    self.instructionLabel.textColor = [UIColor colorWithWhite:0.2f alpha:1];
    self.instructionLabel.numberOfLines = 0;
    self.instructionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [self.view addSubview:self.instructionLabel];
    
    self.steps = [[NSMutableArray alloc] init];
    
    [self.steps addObject:@{@"id": @"room_name", @"skip": [NSNumber numberWithBool:false], @"next": @"Next", @"instruction": @"What would you like your new Room to be called?", @"placeholder": @"Room Name", @"sensitive": [NSNumber numberWithBool:false], @"keyboard": @"title", @"answer": [NSNull null], @"textField": [NSNull null], @"block": [NSNull null]}];
    [self.steps addObject:@{@"id": @"room_description", @"skip": [NSNumber numberWithBool:false], @"next": @"Next", @"instruction": @"Briefly describe your Room (optional)", @"placeholder":@"Room Description", @"sensitive": [NSNumber numberWithBool:false], @"keyboard": @"text", @"answer": [NSNull null], @"textField": [NSNull null], @"block": [NSNull null]}];
    [self.steps addObject:@{@"id": @"room_similar", @"skip": [NSNumber numberWithBool:false], @"next": @"Continue Anyways", @"instruction": @"Would you like to join a similar Room instead?", @"sensitive": [NSNumber numberWithBool:true], @"answer": [NSNull null], @"block": [NSNull null]}];
    [self.steps addObject:@{@"id": @"room_color", @"skip": [NSNumber numberWithBool:false], @"next": @"Create Room", @"instruction": @"Select Room Color\nand Privacy Setting", @"sensitive": [NSNumber numberWithBool:true], @"answer": [NSNull null], @"block": [NSNull null]}];
    [self.steps addObject:@{@"id": @"room_share", @"skip": [NSNumber numberWithBool:false], @"next": @"Enter Room", @"instruction": @"Your Room has been created! Invite others to join below", @"sensitive": [NSNumber numberWithBool:true], @"answer": [NSNull null], @"block": [NSNull null]}];
    
    for (int i = 0; i < [self.steps count]; i++) {
        // add each step to the right
        [self addStep:i usingArray:self.steps];
    }
}

- (void)addStep:(int)stepIndex usingArray:(NSMutableArray *)parentArray {
    NSMutableDictionary *mutatedStep = [[NSMutableDictionary alloc] initWithDictionary:parentArray[stepIndex]];
    
    if ([mutatedStep objectForKey:@"textField"] && ![mutatedStep[@"textfield"] isEqual:[NSNull null]]) {
        UIView *inputBlock = [[UIView alloc] initWithFrame:CGRectMake(0, (self.view.frame.size.height / 2) - (56 / 2) - (self.view.frame.size.height * .15), self.view.frame.size.width, 56)];
        [self.view addSubview:inputBlock];
        
        UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(24, 0, self.view.frame.size.width - (24 * 2), 56)];
        textField.textColor = [UIColor colorWithWhite:0.2f alpha:1];
        textField.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1];
        if ([mutatedStep[@"name"] isEqualToString:@"room_name"]) {
            textField.tag = 201;
        }
        else if ([mutatedStep[@"name"] isEqualToString:@"room_description"]) {
            textField.tag = 202;
        }
        [self continuityRadiusForView:textField withRadius:12.f];
        
        
        if ([mutatedStep objectForKey:@"keyboard"] && [mutatedStep[@"keyboard"] isEqualToString:@"email"]) {
            textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            textField.keyboardType = UIKeyboardTypeEmailAddress;
            textField.tag = 101;
        }
        else if ([mutatedStep objectForKey:@"keyboard"] && [mutatedStep[@"keyboard"] isEqualToString:@"number"]) {
            textField.tag = 102;
            
            textField.keyboardType = UIKeyboardTypeNumberPad;
            NSLog(@"keyboard number");
        }
        else {
            textField.keyboardType = UIKeyboardTypeDefault;
            
            if ([mutatedStep objectForKey:@"keyboard"] && [mutatedStep[@"keyboard"] isEqualToString:@"title"]) {
                textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
            }
            else {
                textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
            }
        }
        
        textField.delegate = self;
        textField.returnKeyType = UIReturnKeyNext;
        // textField.autocorrectionType = UITextAutocorrectionTypeNo;
        textField.font = [UIFont systemFontOfSize:20.f weight:UIFontWeightMedium];
        
        [inputBlock addSubview:textField];
        
        // add left-side spacing
        UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, textField.frame.size.height)];
        leftView.backgroundColor = textField.backgroundColor;
        textField.leftView = leftView;
        textField.rightView = leftView;
        textField.leftViewMode = UITextFieldViewModeAlways;
        textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:([mutatedStep objectForKey:@"placeholder"] ? mutatedStep[@"placeholder"] : @"") attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0.2f alpha:0.25]}];
        [textField addTarget:self action:@selector(textFieldChanged:) forControlEvents:UIControlEventEditingChanged];
        
        
        if ([mutatedStep[@"sensitive"] boolValue]) {
            textField.secureTextEntry = true;
        }
        else {
            textField.secureTextEntry = false;
        }
        
        inputBlock.alpha = 0;
        inputBlock.transform = CGAffineTransformMakeTranslation(self.view.frame.size.width, 0);
        
        [mutatedStep setObject:inputBlock forKey:@"block"];
        [mutatedStep setObject:textField forKey:@"textField"];
    }
    else if ([mutatedStep[@"id"] isEqualToString:@"room_similar"]) {
        UIView *block = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.width, self.view.frame.size.width, 156)];
        block.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
        block.alpha = 0;
        block.transform = CGAffineTransformMakeTranslation(self.view.frame.size.width, 0);
        [self.view addSubview:block];
        
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.minimumLineSpacing = 8.f;
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        self.loadingSimilarRooms = true;
        
        self.similarRoomsCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 156) collectionViewLayout:flowLayout];
        self.similarRoomsCollectionView.delegate = self;
        self.similarRoomsCollectionView.dataSource = self;
        self.similarRoomsCollectionView.contentInset = UIEdgeInsetsMake(0, 24, 0, 24);
        [self.similarRoomsCollectionView registerClass:[MiniChannelCell class] forCellWithReuseIdentifier:miniChannelReuseIdentifier];
        self.similarRoomsCollectionView.showsHorizontalScrollIndicator = false;
        self.similarRoomsCollectionView.layer.masksToBounds = true;
        self.similarRoomsCollectionView.backgroundColor = [UIColor clearColor];
        
        self.similarRooms = [[NSMutableArray alloc] init];
        
        [block addSubview:self.similarRoomsCollectionView];
        
        [mutatedStep setObject:block forKey:@"block"];
    }
    else if ([mutatedStep[@"id"] isEqualToString:@"room_color"]) {
        UIView *colorBlock = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.width, 216, 286)];
        colorBlock.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2 + 35);
        colorBlock.layer.cornerRadius = 10.f;
        colorBlock.alpha = 0;
        colorBlock.transform = CGAffineTransformMakeTranslation(self.view.frame.size.width, 0);
        [self.view addSubview:colorBlock];
        
        colors = @[@"0076FF",  // 0
                   @"9013FE",  // 1
                   @"FD1F61",  // 2
                   @"FC6A1E",  // 3
                   @"29C350",  // 4
                   @"8B572A",  // 5
                   @"F5C123",  // 6
                   @"2A6C8B",  // 7
                   @"333333"]; // 8
        
        self.themeColor = 0 + arc4random() % (colors.count - 1);
        
        NSLog(@"self.themeColor: %li", (long)self.themeColor);
        
        for (int i = 0; i < 9; i++) {
            int row = i % 3;
            int column = floorf(i / 3);
            
            NSLog(@"r: %i / c: %i", row, column);
            
            UIView *colorOption = [[UIView alloc] initWithFrame:CGRectMake(column * 80, row * 80, 56, 56)];
            colorOption.layer.cornerRadius = colorOption.frame.size.height / 2;
            colorOption.backgroundColor = [self colorFromHexString:colors[i]];
            colorOption.tag = i;
            [colorBlock addSubview:colorOption];
            
            if (i == (int)self.themeColor) {
                // add check image view
                UIImageView *checkView = [[UIImageView alloc] initWithFrame:CGRectMake(-6, -6, colorOption.frame.size.width + 12, colorOption.frame.size.height + 12)];
                checkView.contentMode = UIViewContentModeCenter;
                checkView.image = [UIImage imageNamed:@"selectedColorCheck"];
                checkView.tag = 999;
                checkView.layer.cornerRadius = checkView.frame.size.height / 2;
                checkView.layer.borderColor = colorOption.backgroundColor.CGColor;
                checkView.layer.borderWidth = 3.f;
                checkView.backgroundColor = [UIColor clearColor];
                [colorOption addSubview:checkView];
            }
            
            [colorOption bk_whenTapped:^{
                [self setColor:colorOption];
            }];
        }
        
        // add public room UISwitch
        UISwitch *publicRoomSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        publicRoomSwitch.on = true;
        publicRoomSwitch.frame = CGRectMake(colorBlock.frame.size.width - publicRoomSwitch.frame.size.width, colorBlock.frame.size.height - publicRoomSwitch.frame.size.height, publicRoomSwitch.frame.size.width, publicRoomSwitch.frame.size.height);
        publicRoomSwitch.tag = 10;
        [colorBlock addSubview:publicRoomSwitch];
        
        UILabel *publicRoomLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, publicRoomSwitch.frame.origin.y, colorBlock.frame.size.width - publicRoomSwitch.frame.size.width, publicRoomSwitch.frame.size.height)];
        publicRoomLabel.text = @"Public Room";
        publicRoomLabel.textColor = [UIColor colorWithWhite:0.33 alpha:1];
        publicRoomLabel.textAlignment = NSTextAlignmentLeft;
        publicRoomLabel.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightMedium];
        [colorBlock addSubview:publicRoomLabel];
        
        UIView *separatorLine = [[UIView alloc] initWithFrame:CGRectMake(0, publicRoomSwitch.frame.origin.y - 16 - 1, colorBlock.frame.size.width, 1)];
        separatorLine.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
        [colorBlock addSubview:separatorLine];
        
        [mutatedStep setObject:colorBlock forKey:@"block"];
    }
    else if ([mutatedStep[@"id"] isEqualToString:@"room_share"]) {
        UIView *shareBlock = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.width, self.view.frame.size.width, 120)];
        shareBlock.center = CGPointMake(shareBlock.center.x, self.view.frame.size.height / 2);
        shareBlock.alpha = 0;
        shareBlock.transform = CGAffineTransformMakeTranslation(self.view.frame.size.width, 0);
        [self.view addSubview:shareBlock];
        
        UIButton *shareField = [[UIButton alloc] initWithFrame:CGRectMake(24, 0, self.view.frame.size.width - (24 * 2), 56)];
        [shareField setTitleColor:[UIColor colorWithWhite:0.2f alpha:1] forState:UIControlStateNormal];
        shareField.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        shareField.contentEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 0);
        shareField.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1];
        [self continuityRadiusForView:shareField withRadius:12.f];
        shareField.titleLabel.font = [UIFont systemFontOfSize:20.f weight:UIFontWeightMedium];
        shareField.tag = 10;
        [shareBlock addSubview:shareField];
        [shareField bk_addEventHandler:^(id sender) {
            [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                [shareField setTitleColor:[UIColor colorWithWhite:0.6f alpha:1] forState:UIControlStateNormal];
            } completion:nil];
        } forControlEvents:UIControlEventTouchDown];
        [shareField bk_addEventHandler:^(id sender) {
            [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                [shareField setTitleColor:[UIColor colorWithWhite:0.2f alpha:1] forState:UIControlStateNormal];
            } completion:nil];
        } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
        [shareField bk_whenTapped:^{
            NSString *copiedText = @"Copied to Clipboard!";
            if (![shareField.currentTitle isEqualToString:copiedText]) {
                NSString *originalText = shareField.currentTitle;
                
                NSLog(@"let's do this thing!");
                [shareField setTitle:copiedText forState:UIControlStateNormal];
                
                [UIView animateWithDuration:0.2f delay:1.f options:UIViewAnimationOptionCurveEaseOut animations:^{
                    [shareField setTitle:originalText forState:UIControlStateNormal];
                } completion:nil];
            }
        }];
        
        UIButton *shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
        shareButton.frame = CGRectMake(shareField.frame.origin.x, shareBlock.frame.size.height - 48, shareField.frame.size.width, 48);
        [shareButton setTitle:@"Share Room" forState:UIControlStateNormal];
        [shareButton setTitleColor:[self currentColor] forState:UIControlStateNormal];
        [shareButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 8, 0, 0)];
        [shareButton setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 8)];
        shareButton.titleLabel.font = [UIFont systemFontOfSize:20.f weight:UIFontWeightSemibold];
        shareButton.adjustsImageWhenHighlighted = false;
        shareButton.layer.cornerRadius = 16.f;
        shareButton.layer.borderColor = [shareButton.currentTitleColor colorWithAlphaComponent:0.2f].CGColor;
        shareButton.layer.borderWidth = 2.f;
        shareButton.layer.masksToBounds = true;
        shareButton.tag = 11;
        [shareButton setImage:[[UIImage imageNamed:@"roomShareIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        
        [shareBlock addSubview:shareButton];
        
        [shareButton bk_addEventHandler:^(id sender) {
            [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                shareButton.transform = CGAffineTransformMakeScale(0.8, 0.8);
                shareButton.backgroundColor = [[self currentColor] colorWithAlphaComponent:0.2f];
                shareButton.layer.borderWidth = 0;
            } completion:nil];
        } forControlEvents:UIControlEventTouchDown];
        
        [shareButton bk_addEventHandler:^(id sender) {
            [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                shareButton.transform = CGAffineTransformMakeScale(1, 1);
                shareButton.backgroundColor = [UIColor clearColor];
                shareButton.layer.borderWidth = 2.f;
            } completion:nil];
        } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
        
        [shareButton bk_whenTapped:^{
            // open room share
            
        }];
        
        [mutatedStep setObject:shareBlock forKey:@"block"];
    }
    
    [parentArray replaceObjectAtIndex:stepIndex withObject:mutatedStep];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *newStr = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    NSLog(@"%@",newStr);
    if (textField.tag == 201) {
        return newStr.length <= 20 ? YES : NO;
    }
    else if (textField.tag == 202) {
        return newStr.length <= 40 ? YES : NO;
    }
    else if (textField.tag == 10) {
        return NO;
    }
    
    return YES;
}

- (void)setColor:(UIView *)sender {
    if (sender.tag != self.themeColor) {
        [HapticHelper generateFeedback:FeedbackType_Selection];
        
        // remove previously selected color
        int colorStep = [self getIndexOfStepWithId:@"room_color"];
        UIView *colorBlock = self.steps[colorStep][@"block"];
        
        NSLog(@"previous color: %li", (long)self.themeColor);
        
        UIView *previousColorView;
        for (UIView *subview in colorBlock.subviews) {
            if (subview.tag == self.themeColor) {
                previousColorView = subview;
                break;
            }
        }
        NSLog(@"previousColorView: %@", previousColorView);
        for (UIImageView *imageView in previousColorView.subviews) {
            NSLog(@"imageView unda: %@", imageView);
            if (imageView.tag == 999) {
                [UIView animateWithDuration:0.25f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    imageView.transform = CGAffineTransformMakeScale(0.1, 0.1);
                    imageView.alpha = 0;
                } completion:^(BOOL finished) {
                    [imageView removeFromSuperview];
                }];
                break;
            }
        }
        
        NSLog(@"new color: %li", (long)sender.tag);
        self.themeColor = sender.tag;
        
        // add check image view
        UIImageView *checkView = [[UIImageView alloc] initWithFrame:CGRectMake(-6, -6, sender.frame.size.width + 12, sender.frame.size.height + 12)];
        checkView.contentMode = UIViewContentModeCenter;
        checkView.image = [UIImage imageNamed:@"selectedColorCheck"];
        checkView.tag = 999;
        checkView.layer.cornerRadius = checkView.frame.size.height / 2;
        checkView.layer.borderColor = sender.backgroundColor.CGColor;
        checkView.layer.borderWidth = 3.f;
        checkView.backgroundColor = [UIColor clearColor];
        [sender addSubview:checkView];
        
        checkView.transform = CGAffineTransformMakeScale(0.8, 0.8);
        checkView.alpha = 0;
        
        [UIView animateWithDuration:0.6f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.nextButton.backgroundColor = sender.backgroundColor;
            self.closeButton.tintColor = sender.backgroundColor;
            
            checkView.transform = CGAffineTransformMakeScale(1, 1);
            checkView.alpha = 1;
        } completion:nil];
    }
    
}

- (int)getIndexOfStepWithId:(NSString *)stepId {
    for (int i = 0; i < [self.steps count]; i++) {
        if ([self.steps[i][@"id"] isEqualToString:stepId]) {
            return i;
        }
    }
    return 0;
}

- (void)textFieldChanged:(UITextField *)sender {
    if ([self.steps[self.currentStep][@"id"] isEqualToString:@"room_name"]) {
        if (sender.text.length <= 1) {
            self.nextButton.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1];
            self.nextButton.enabled = false;
        }
        else {
            // qualifies
            self.nextButton.backgroundColor = self.view.tintColor;
            self.nextButton.enabled = true;
        }
    }
}

- (void)greyOutNextButton {
    self.nextButton.enabled = false;
    self.nextButton.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1];
}

- (void)handleNext {
    NSDictionary *step = self.steps[self.currentStep];
    
    self.nextButton.userInteractionEnabled = false;
    
    // sign in to school
    if ([step[@"id"] isEqualToString:@"room_description"]) {
        UITextField *textField = step[@"textField"];
        
        // check for similar names
        [self greyOutNextButton];
        [self showSpinnerForStep:self.currentStep];
        
        [self getSimilarRooms:textField.text];
    }
    else if ([step[@"id"] isEqualToString:@"room_color"]) {
        // create that room!
        
        // check for similar names
        [self greyOutNextButton];
        [self showBigSpinnerForStep:self.currentStep];
        
        [self createRoom];
    }
    else {
        [self nextStep:true];
    }
}
- (void)nextStep:(BOOL)withAnimation {
    /*
     
     NEXT STEP
     –––––––––
     purpose: show next part of the flow. in most cases, this means animating the next step in and the current step out.
     
     */
    
    // defaults
    float animationDuration = 0.9f;
    if (!withAnimation) {
        animationDuration = 0;
    }
    
    int next = self.currentStep;

    BOOL isComplete = true; // true until proven false
    for (int i = self.currentStep + 1; i < [self.steps count]; i++) {
        // steps to the right of the currentStep
        if (i >= [self.steps count]) {
            // does not have a next step // this should never happen
            NSLog(@"Could not find a next step.");
            next = self.currentStep + 1;
        }
        else {
            NSDictionary *step = self.steps[i];
            if (![step[@"skip"] boolValue]) {
                NSLog(@"this is the next step");
                next = i;
            }
            else {
                NSLog(@"skip step");
            }
        }
        if (next != self.currentStep && i < [self.steps count]) {
            NSDictionary *step = self.steps[i];
            // we found the next step
            // now we need to find if there are any remaining steps (that have skip='false')
            if (![step[@"skip"] boolValue]) {
                isComplete = false;
                break;
            }
        }
    }
    
    if (isComplete) {
        [self.view endEditing:YES];
    }
    else if (next < [self.steps count]) {
        NSDictionary *activeStep;
        UIView *activeBlock = nil;
        if (self.currentStep >= 0) {
            activeStep = self.steps[self.currentStep];
            activeBlock = activeStep[@"block"];
        }
        NSLog(@"activeBlock: %@", activeBlock);
        
        NSDictionary *nextStep = self.steps[next];
        UIView *nextBlock = nextStep[@"block"];
        
        NSLog(@"next step: %@", [nextStep objectForKey:@"textField"]);
        
        if ([nextStep[@"id"] isEqualToString:@"room_similar"]) {
            [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.nextButton.backgroundColor = self.view.tintColor;
                self.nextButton.enabled = true;
            } completion:nil];
        }
        if ([nextStep[@"id"] isEqualToString:@"room_color"]) {
            [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.nextButton.backgroundColor = [self currentColor];
                self.closeButton.tintColor = [self currentColor];
            } completion:nil];
        }
        if ([nextStep[@"id"] isEqualToString:@"room_share"]) {
            // remove previously selected color
            UIButton *shareField = [nextBlock viewWithTag:10];
            UIButton *shareRoomButton = [nextBlock viewWithTag:11];
            shareRoomButton.tintColor = [self currentColor];
            [shareRoomButton setTitleColor:[self currentColor] forState:UIControlStateNormal];
            shareRoomButton.layer.borderColor = [[self currentColor] colorWithAlphaComponent:0.2f].CGColor;
            [shareField setTitle:@"blah blah blah" forState:UIControlStateNormal];
            
            self.closeButton.userInteractionEnabled = false;
            [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.closeButton.alpha = 0;
            } completion:nil];
            
            // blast some confetti!
            L360ConfettiArea *confettiArea = [[L360ConfettiArea alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
            
            [self.view insertSubview:confettiArea atIndex:0];
            confettiArea.blastSpread = 0;
            confettiArea.delegate = self;
            confettiArea.swayLength = 75.f;
            [confettiArea burstAt:CGPointMake(self.view.frame.size.width / 2, -80) confettiWidth:12.f numberOfConfetti:60];
        }
        
        if ([nextStep objectForKey:@"textField"] && ![nextStep[@"textfield"] isEqual:[NSNull null]]) {
            UITextField *nextTextField = nextStep[@"textField"];
            
            CGFloat delay = self.currentStep == -1 ? 0.4f : 0;
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [nextTextField becomeFirstResponder];
            });
        }
        else {
            NSLog(@"end editing");
            [self.view endEditing:TRUE];
        }
        
        // show next step in the flow
        if (nextBlock != nil) {
            nextBlock.alpha = 0;
            nextBlock.transform = CGAffineTransformMakeTranslation(self.view.frame.size.width, 0);
        }
        [UIView animateWithDuration:animationDuration delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.4f options:UIViewAnimationOptionCurveEaseIn animations:^{
            if (nextBlock != nil) {
                nextBlock.transform = CGAffineTransformMakeTranslation(0, 0);
                nextBlock.alpha = 1;
            }
            if (activeBlock != nil) {
                activeBlock.transform = CGAffineTransformMakeTranslation(- 1 * self.view.frame.size.width, 0);
                activeBlock.alpha = 0;
            }
        } completion:^(BOOL finished) {
            self.nextButton.userInteractionEnabled = true;
        }];
        
        // make any instruction changes as needed
        if (![nextStep[@"instruction"] isEqualToString:activeStep[@"instruction"]]) {
            // title change
            NSData *tempInstructionArchive = [NSKeyedArchiver archivedDataWithRootObject:self.instructionLabel];
            UILabel *instructionCopy = [NSKeyedUnarchiver unarchiveObjectWithData:tempInstructionArchive];
            instructionCopy.alpha = 0;
            
            NSString *nextStepTitle = nextStep[@"instruction"];
            instructionCopy.text = nextStepTitle;
            
            CGRect instructionsDynamicFrame = [instructionCopy.text boundingRectWithSize:CGSizeMake(self.instructionLabel.frame.size.width, 100) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:instructionCopy.font} context:nil];
            instructionCopy.frame = CGRectMake(self.instructionLabel.frame.origin.x, self.instructionLabel.frame.origin.y, self.instructionLabel.frame.size.width, instructionsDynamicFrame.size.height);
            
            instructionCopy.transform = CGAffineTransformMakeTranslation(self.view.frame.size.width, 0);
            
            [self.view addSubview:instructionCopy];
            
            [UIView animateWithDuration:animationDuration delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.4f options:UIViewAnimationOptionCurveEaseIn animations:^{
                self.instructionLabel.transform = CGAffineTransformMakeTranslation(-1 * self.view.frame.size.width, 0);
                self.instructionLabel.alpha = 0;
                
                instructionCopy.transform = CGAffineTransformMakeTranslation(0, 0);
                instructionCopy.alpha = 1;
            } completion:^(BOOL finished) {
                // save copy as the original mainNavLabel
                [self.instructionLabel removeFromSuperview];
                self.instructionLabel = instructionCopy;
            }];
        }
        
        if ([nextStep[@"next"] isEqual:[NSNull null]]) {
            [self.nextButton setTitle:@"" forState:UIControlStateNormal];
            [self.nextButton setHidden:true];
        }
        else {
            [self.nextButton setTitle:nextStep[@"next"] forState:UIControlStateNormal];
            [self.nextButton setHidden:false];
        }
        
        self.currentStep = next;
    }
    else if (next == [self.steps count]) {
        // loading
        // [self showLoading];
    }
    else {
        // not sure how this got called.
        
    }
}
- (void)getSimilarRooms:(NSString *)roomName {
    NSLog(@"getSimilarRooms()");
    [[Session sharedInstance] authenticate:^(BOOL success, NSString *token) {
        if (success) {
            [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
            
            NSString *url = [NSString stringWithFormat:@"%@/%@/search/rooms", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"]];
            [self.manager GET:url parameters:@{@"q": roomName} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSLog(@"CreateRoomViewController / getSimilarRooms() success! ✅");
                
                NSLog(@"response: %@", responseObject[@"data"][@"results"][@"rooms"]);
                
                NSArray *responseData = (NSArray *)responseObject[@"data"][@"results"][@"rooms"];
                
                self.loadingSimilarRooms = false;
                
                
                self.similarRooms = [[NSMutableArray alloc] initWithArray:responseData];
                [self.similarRoomsCollectionView reloadData];
                
                int similarRoomsStepIndex = [self getIndexOfStepWithId:@"room_similar"];
                NSMutableDictionary *mutableDict = [[NSMutableDictionary alloc] initWithDictionary:self.steps[similarRoomsStepIndex]];
                
                if (responseData.count > 0) {
                    [mutableDict setObject:[NSNumber numberWithBool:false] forKey:@"skip"];
                }
                else {
                    [mutableDict setObject:[NSNumber numberWithBool:true] forKey:@"skip"];
                }
                
                self.nextButton.enabled = true;
                [self.steps replaceObjectAtIndex:similarRoomsStepIndex withObject:mutableDict];
                
                [self removeSpinnerForStep:self.currentStep];
                [self nextStep:true];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"FeedViewController / getPosts() - error: %@", error);
                //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                
                [self.similarRoomsCollectionView reloadData];
                
                [self nextStep:true];
            }];
        }
    }];
}
- (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    if (hexString != nil && hexString.length == 6) {
        NSScanner *scanner = [NSScanner scannerWithString:hexString];
        [scanner setScanLocation:0]; // bypass '#' character
        [scanner scanHexInt:&rgbValue];
        return [UIColor colorWithDisplayP3Red:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
    }
    else {
        return [UIColor colorWithWhite:0.2f alpha:1];
    }
}
- (UIColor *)currentColor {
    return [self colorFromHexString:colors[self.themeColor]];
}
- (void)createRoom {
    NSString *url;// = [NSString stringWithFormat:@"%@/%@/schools/%@/channels/%@", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"], @"2", @"default"];
    url = [NSString stringWithFormat:@"%@/%@/rooms", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"]]; // sample data
    
    int titleStep = [self getIndexOfStepWithId:@"room_name"];
    UITextField *titleTextField = self.steps[titleStep][@"textField"];
    NSString *roomTitle = titleTextField.text;
    
    int descriptionStep = [self getIndexOfStepWithId:@"room_description"];
    UITextField *descriptionTextField = self.steps[descriptionStep][@"textField"];
    NSString *roomDescription = descriptionTextField.text;
    
    NSString *roomColor = [colors[self.themeColor] stringByReplacingOccurrencesOfString:@"#" withString:@""];
    
    int themeAndPrivacyStep = [self getIndexOfStepWithId:@"room_color"];
    UIView *nextBlock = self.steps[themeAndPrivacyStep][@"block"];
    UISwitch *isPrivateSwitch = [nextBlock viewWithTag:10];
    BOOL isPrivate = !isPrivateSwitch.on;
    
    NSLog(@"params: %@", @{@"title": roomTitle, @"description": roomDescription, @"color": roomColor, @"private": [NSNumber numberWithBool:isPrivate]});

    [[Session sharedInstance] authenticate:^(BOOL success, NSString *token) {
        if (success) {
            NSLog(@"token::: %@", token);
            [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
            
            [self.manager.requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
            [self.manager POST:url parameters:@{@"title": roomTitle, @"description": roomDescription, @"color": roomColor} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSLog(@"responseObject: %@", responseObject);
                
                NSError *error;
                Room *room = [[Room alloc] initWithDictionary:responseObject[@"data"] error:&error];
                NSLog(@"error: %@", error.userInfo);
                NSLog(@"room: %@", room);
                
                int shareStep = [self getIndexOfStepWithId:@"room_share"];
                UIView *shareBlock = self.steps[shareStep][@"block"];
                UIButton *shareField = [shareBlock viewWithTag:10];
                [shareField setTitle:[NSString stringWithFormat:@"https://rooms.co/%@", room.identifier] forState:UIControlStateNormal];
                // update url
                
                
                // refresh my rooms
                [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshMyRooms" object:nil];
                
                self.nextButton.enabled = true;
                self.nextButton.backgroundColor = [self currentColor];
                
                // move spinner
                [self removeBigSpinnerForStep:self.currentStep push:true];
                
                [self nextStep:true];
                
                for (UIGestureRecognizer *recognizer in self.nextButton.gestureRecognizers) {
                    [self.nextButton removeGestureRecognizer:recognizer];
                }
                [self.nextButton bk_whenTapped:^{
                    [self setEditing:false animated:YES];
                    
                    LauncherNavigationViewController *launchNavVC = (LauncherNavigationViewController *)self.presentingViewController;
                    NSLog(@"launchNavVc: %@", launchNavVC);
                    
                    [self dismissViewControllerAnimated:YES completion:^{
                        NSLog(@"launchNavVc 2: %@", launchNavVC);
                        
                        [launchNavVC openRoom:room];
                    }];
                }];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {

                NSLog(@"error: %@", error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey]);
                NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                NSLog(@"%@",ErrorResponse);
                
                [self removeBigSpinnerForStep:self.currentStep push:false];
                self.nextButton.enabled = true;
                self.nextButton.backgroundColor = [self currentColor];
                self.nextButton.userInteractionEnabled = true;
                [self shakeInputBlock];
            }];
        }
    }];
}

- (void)shakeInputBlock {
    UIView *currentBlock = self.steps[self.currentStep][@"block"];
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
    [animation setDuration:0.08];
    [animation setRepeatCount:4];
    [animation setAutoreverses:YES];
    [animation setFromValue:[NSValue valueWithCGPoint:
                             CGPointMake([currentBlock center].x - 8.f, [currentBlock center].y)]];
    [animation setToValue:[NSValue valueWithCGPoint:
                           CGPointMake([currentBlock center].x + 8.f, [currentBlock center].y)]];
    [[currentBlock layer] addAnimation:animation forKey:@"position"];
}

- (void)showSpinnerForStep:(int)step {
    UIView *block = (UIView *)[[self.steps objectAtIndex:step] objectForKey:@"block"];
    UITextField *textField = (UITextField *)[[self.steps objectAtIndex:step] objectForKey:@"textField"];
    
    UIImageView *miniSpinner = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
    miniSpinner.image = [[UIImage imageNamed:@"miniSpinner"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    miniSpinner.tintColor = self.view.tintColor;
    miniSpinner.center = CGPointMake(block.frame.size.width / 2, block.frame.size.height / 2);
    miniSpinner.alpha = 0;
    miniSpinner.tag = 1111;
    
    CABasicAnimation *rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 /* full rotation*/ * 1 * 1.f ];
    rotationAnimation.duration = 1.f;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = HUGE_VALF;
    
    [miniSpinner.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
    
    [block addSubview:miniSpinner];
    
    [UIView animateWithDuration:0.9f delay:0 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        miniSpinner.alpha = 1;
    } completion:nil];
    [UIView transitionWithView:textField duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        textField.textColor = [UIColor colorWithWhite:0.2f alpha:0];
        if (textField.placeholder != nil) {
            textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:textField.placeholder attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0.2f alpha:0]}];
        }
        textField.tintColor = [UIColor clearColor];
    } completion:nil];
}
- (void)removeSpinnerForStep:(int)step {
    UIView *block = (UIView *)[[self.steps objectAtIndex:step] objectForKey:@"block"];
    UITextField *textField = (UITextField *)[[self.steps objectAtIndex:step] objectForKey:@"textField"];
    UIImageView *miniSpinner = [block viewWithTag:1111];
    
    NSLog(@"textField: %@", textField);
    
    [UIView animateWithDuration:0.6f delay:0 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        miniSpinner.alpha = 0;
    } completion:^(BOOL finished) {
        [miniSpinner removeFromSuperview];
        
        NSLog(@"hola: %@", textField);
        
        [UIView transitionWithView:textField duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            textField.textColor = [UIColor colorWithWhite:0.2f alpha:1];
            textField.tintColor = [self.view tintColor];
            if (textField.placeholder != nil) {
                textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:textField.placeholder attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0.2f alpha:0.25]}];
            }
        } completion:^(BOOL finished) {
            NSLog(@"we finished something!!: %@", textField.textColor);
        }];
    }];
}

- (void)showBigSpinnerForStep:(int)step {
    UIView *block = (UIView *)[[self.steps objectAtIndex:step] objectForKey:@"block"];
    
    UIImageView *spinner = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 64, 64)];
    spinner.image = [[UIImage imageNamed:@"spinner"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    spinner.tintColor = [self currentColor];
    spinner.center = self.view.center;
    spinner.alpha = 0;
    spinner.tag = 1111;
    
    CABasicAnimation *rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 /* full rotation*/ * 1 * 1.f ];
    rotationAnimation.duration = 1.f;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = HUGE_VALF;
    
    [spinner.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
    
    [self.view addSubview:spinner];
    
    [UIView animateWithDuration:0.3f animations:^{
        block.alpha = 0;
    }];
    [UIView animateWithDuration:0.3f delay:0.3f options:UIViewAnimationOptionCurveEaseOut animations:^{
        spinner.alpha = 1;
    } completion:nil];
}
- (void)removeBigSpinnerForStep:(int)step push:(BOOL)push {
    UIView *block = (UIView *)[[self.steps objectAtIndex:step] objectForKey:@"block"];
    UIImageView *spinner = [self.view viewWithTag:1111];
    
    [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        spinner.alpha = 0;
        
        if (push) {
            spinner.center = CGPointMake(-0.5 * self.view.frame.size.width, spinner.center.y);
        }
    } completion:^(BOOL finished) {
        [spinner removeFromSuperview];
        
        [UIView animateWithDuration:0.3f animations:^{
            block.alpha = 1;
        }];
    }];
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    _currentKeyboardHeight = keyboardFrameBeginRect.size.height;
    
    self.nextButton.frame = CGRectMake(self.nextButton.frame.origin.x, (self.view.frame.size.height / self.view.transform.d) - _currentKeyboardHeight - self.nextButton.frame.size.height - self.nextButton.frame.origin.x, self.nextButton.frame.size.width, self.nextButton.frame.size.height);
}
    
- (void)keyboardWillDismiss:(NSNotification *)notification {
    _currentKeyboardHeight = 0;
    
    UIWindow *window = UIApplication.sharedApplication.keyWindow;
    CGFloat bottomPadding = window.safeAreaInsets.bottom;
    
    NSNumber *duration = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:[duration floatValue] delay:0 options:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue] << 16 animations:^{
        self.nextButton.frame = CGRectMake(self.nextButton.frame.origin.x, (self.view.frame.size.height / self.view.transform.d) - self.nextButton.frame.size.height - (self.nextButton.frame.origin.x / 2) - bottomPadding, self.nextButton.frame.size.width, self.nextButton.frame.size.height);
    } completion:nil];
}

// similar rooms collection view
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.loadingSimilarRooms) {
        return 4;
    }
    else {
        return self.similarRooms.count;
    }
}
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MiniChannelCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:miniChannelReuseIdentifier forIndexPath:indexPath];
    
    if (self.loadingSimilarRooms) {
        cell.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
        cell.title.layer.cornerRadius = 6.f;
        cell.title.textColor = [UIColor clearColor];
        cell.title.layer.masksToBounds = true;
        cell.title.backgroundColor = [UIColor whiteColor];
        cell.title.text = @"Loading";
        cell.title.textColor = [UIColor whiteColor];
        
        cell.ticker.hidden = true;
    }
    else {
        NSError *error;
        Room *room = [[Room alloc] initWithDictionary:self.similarRooms[indexPath.item] error:&error];
        
        NSLog(@"room at index: %@", room);
        
        if (!error) {
            cell.room = room;
            
            cell.title.text = room.attributes.details.title;
            cell.title.textColor = [UIColor whiteColor];
            cell.title.backgroundColor = [UIColor clearColor];
            
            cell.backgroundColor = [self colorFromHexString:room.attributes.details.color];
            
            if (room.attributes.summaries.counts.live >= [Session sharedInstance].defaults.room.liveThreshold) {
                // show live ticker
                cell.ticker.hidden = false;
                [cell.ticker setTitle:[NSString stringWithFormat:@"%ld", (long)room.attributes.summaries.counts.live] forState:UIControlStateNormal];
                cell.membersView.hidden = true;
            }
            else {
                // show member counts
                cell.ticker.hidden = true;
                
                cell.membersView.hidden = false;
                for (int i = 0; i < cell.membersView.subviews.count; i++) {
                    if ([cell.membersView.subviews[i] isKindOfClass:[UIImageView class]]) {
                        UIImageView *imageView = cell.membersView.subviews[i];
                        if (cell.room.attributes.summaries.members.count > imageView.tag) {
                            imageView.hidden = false;
                            

                            NSError *userError;
                            User *userForImageView = [[User alloc] initWithDictionary:(NSDictionary *)room.attributes.summaries.members[imageView.tag] error:&userError];
                            
                            UIImage *anonymousProfilePic = [UIImage imageNamed:@"anonymous"];
                            
                            if (!userError) {
                                NSString *picURL = userForImageView.attributes.details.media.profilePicture;
                                if (picURL.length > 0) {
                                    [imageView sd_setImageWithURL:[NSURL URLWithString:picURL]];
                                }
                                else {
                                    [imageView setImage:anonymousProfilePic];
                                }
                            }
                            else {
                                [imageView setImage:anonymousProfilePic];
                            }
                        }
                        else {
                            imageView.hidden = true;
                        }
                    }
                }
            }
            
        }
        
        [cell layoutSubviews];
    }
    
    return cell;
}
- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(152, 156);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.loadingSimilarRooms) {
        // animate the cell user tapped on
        
        // TODO: Figure out a way to display room previews
        // Problem: LauncherNavigationController isn't the parent
        
        NSError *error;
        Room *roomAtIndex = [[Room alloc] initWithDictionary:self.similarRooms[indexPath.row] error:&error];
        
        if (!error) {
            [self openRoom:roomAtIndex];
        }
    }
}

- (void)openRoom:(Room *)room {
    RoomViewController *r = [[RoomViewController alloc] init];
    
    r.room = room;
    r.theme = [self colorFromHexString:room.attributes.details.color.length == 6 ? room.attributes.details.color : @"707479"];
    
    r.title = r.room.attributes.details.title ? r.room.attributes.details.title : @"Loading...";
    
    LauncherNavigationViewController *newLauncher = [[LauncherNavigationViewController alloc] initWithRootViewController:r];
    [newLauncher updateSearchText:r.title];
    newLauncher.transitioningDelegate = self;
    
    [newLauncher updateBarColor:r.theme withAnimation:0 statusBarUpdateDelay:NO];
    
    [self presentViewController:newLauncher animated:YES completion:nil];
    
    [newLauncher updateNavigationBarItemsWithAnimation:NO];
}

- (NSArray *)colorsForConfettiArea:(L360ConfettiArea *)confettiArea {
    NSMutableArray *arrayOfUIColors = [[NSMutableArray alloc] init];
    for (int i = 0; i < colors.count; i++) {
        UIColor *color = [self colorFromHexString:[colors[i] isEqualToString:@"#333333"] ? @"#AAAAAA" : colors[i]];
        [arrayOfUIColors addObject:color];
    }
    
    return arrayOfUIColors;
}

- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}

// MODAL TRANSITION
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source
{
    id<UIViewControllerAnimatedTransitioning> animationController;
    
    SOLOptionsTransitionAnimator *animator = [[SOLOptionsTransitionAnimator alloc] init];
    animator.appearing = YES;
    animator.duration = 0.3;
    animationController = animator;
    
    return animationController;
}
/*
 Called when dismissing a view controller that has a transitioningDelegate
 */
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    id<UIViewControllerAnimatedTransitioning> animationController;
    
    SOLOptionsTransitionAnimator *animator = [[SOLOptionsTransitionAnimator alloc] init];
    animator.appearing = NO;
    animator.duration = 0.3;
    animationController = animator;
    
    return animationController;
}

@end
