//
//  CreateCampViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 10/5/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "CreateCampViewController.h"
#import <BlocksKit/BlocksKit+UIKit.h>
#import <HapticHelper/HapticHelper.h>
#import "L360ConfettiArea.h"
#import "SmallMediumCampCardCell.h"
#import "Session.h"
#import "Camp.h"
#import "ComplexNavigationController.h"
#import "SOLOptionsTransitionAnimator.h"
#import "CampViewController.h"
#import "Launcher.h"
#import "UIColor+Palette.h"
#import "NSString+Validation.h"
#import "HAWebService.h"
#import "BFAlertController.h"
#import "BFMiniNotificationManager.h"

#import <JGProgressHUD/JGProgressHUD.h>
#import <HapticHelper/HapticHelper.h>
#include <stdlib.h>
#import <FBSDKShareKit/FBSDKShareKit.h>
#import <RSKImageCropper/RSKImageCropper.h>


@import Firebase;
//@import FirebasePerformance;

#define UIViewParentController(__view) ({ \
    UIResponder *__responder = __view; \
    while ([__responder isKindOfClass:[UIView class]]) \
    __responder = [__responder nextResponder]; \
    (UIViewController *)__responder; \
    })

@interface CreateCampViewController () <L360ConfettiAreaDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, RSKImageCropViewControllerDelegate, RSKImageCropViewControllerDataSource> {
    UIEdgeInsets safeAreaInsets;
    NSArray *colors;
}

@property (nonatomic) NSInteger themeColor;
@property (nonatomic) NSInteger currentStep;
@property (strong, nonatomic) NSMutableArray *steps;
@property (strong, nonatomic) ComplexNavigationController *launchNavVC;
@property (nonatomic) CGFloat currentKeyboardHeight;
@property (strong, nonatomic) NSMutableArray *similarCamps;
@property (strong, nonatomic) Camp *camp;
//@property (nonatomic) FIRTrace *createTrace;

@end

@implementation CreateCampViewController

static NSString * const mediumCardReuseIdentifier = @"MediumCard";
static NSString * const blankCellIdentifier = @"BlankCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor contentBackgroundColor];
    self.view.tintColor = [UIColor bonfirePrimaryColor]; //[UIColor fromHex:[Session sharedInstance].currentUser.attributes.color];
        
    [self addListeners];
    [self setupViews];
    [self setupSteps];
    
    // –––– show the first step ––––
    self.currentStep = -1;
    [self nextStep:false];
    
    safeAreaInsets.top = 1; // set to 1 so we only set it once in viewWillAppear
    
    self.transitioningDelegate = self;
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"Create Camp" screenClass:nil];
    //self.createTrace = [FIRPerformance startTraceWithName:@"Create Camp"];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (safeAreaInsets.top == 1) {
        safeAreaInsets = [UIApplication sharedApplication].keyWindow.safeAreaInsets;
        [self updateWithSafeAreaInsets];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    /*if (@available(iOS 13.0, *)) {
        return UIStatusBarStyleDarkContent;
    } else {
        // Fallback on earlier versions
        return UIStatusBarStyleDefault;
    }*/
    return UIStatusBarStyleDefault;
}

- (void)updateWithSafeAreaInsets {
    self.closeButton.frame = CGRectMake(self.view.frame.size.width - 44 - 11, safeAreaInsets.top, 44, 44);
}

- (void)addListeners {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(campUpdated:) name:@"CampUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillDismiss:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)campUpdated:(NSNotification *)notification {
    Camp *camp = notification.object;
    
    if (camp != nil) {
        for (NSInteger i = 0; i < self.similarCamps.count; i++) {
            if ([self.similarCamps[i][@"id"] isEqualToString:camp.identifier]) {
                // same camp -> replace it with updated object
                [self.similarCamps replaceObjectAtIndex:i withObject:[camp toDictionary]];
            }
        }
        [self.similarCampsCollectionView reloadData];
        [self resizeSimilarCampsCollectionView];
    }
}

- (void)setupViews {
    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.closeButton setImage:[[UIImage imageNamed:@"navCloseIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.closeButton.tintColor = [UIColor fromHex:[UIColor toHex:self.view.tintColor] adjustForOptimalContrast:true];
    self.closeButton.contentMode = UIViewContentModeCenter;
    self.closeButton.adjustsImageWhenHighlighted = false;
    [self.closeButton bk_whenTapped:^{
        [FIRAnalytics logEventWithName:@"abort_create_camp"
                            parameters:@{@"last_step":self.steps[self.currentStep][@"id"]}];
        
        [self.view endEditing:TRUE];
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    [self.view addSubview:self.closeButton];
    
    self.nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.nextButton.frame = CGRectMake(24, self.view.frame.size.height, self.view.frame.size.width - (24 * 2), 48);
    self.nextButton.backgroundColor = [self.view tintColor];
    self.nextButton.titleLabel.font = [UIFont systemFontOfSize:20.f weight:UIFontWeightSemibold];
    [self.nextButton setTitleColor:[UIColor bonfireSecondaryColor] forState:UIControlStateDisabled];
    [self continuityRadiusForView:self.nextButton withRadius:14.f];
    [self.nextButton setTitle:@"Next" forState:UIControlStateNormal];
    [self.view addSubview:self.nextButton];
    [self greyOutNextButton];
    
    [self.nextButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.nextButton.alpha = 0.8;
            self.nextButton.transform = CGAffineTransformMakeScale(0.92, 0.92);
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
    self.instructionLabel = [[UILabel alloc] initWithFrame:CGRectMake(24, self.view.frame.size.height, self.view.frame.size.width - 48, 42)];
    self.instructionLabel.center = CGPointMake(self.instructionLabel.center.x, (inputCenterY / 2) + 16);
    self.instructionLabel.textAlignment = NSTextAlignmentCenter;
    self.instructionLabel.text = @"";
    self.instructionLabel.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightMedium];
    self.instructionLabel.textColor = [UIColor bonfirePrimaryColor];
    self.instructionLabel.numberOfLines = 0;
    self.instructionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [self.view addSubview:self.instructionLabel];
    
    self.steps = [[NSMutableArray alloc] init];
    
    [self.steps addObject:@{@"id": @"camp_title", @"skip": [NSNumber numberWithBool:false], @"next": @"Next", @"instruction": @"What would you like your\nnew Camp to be called?", @"placeholder": @"Camp Name", @"sensitive": [NSNumber numberWithBool:false], @"keyboard": @"title", @"answer": [NSNull null], @"textField": [NSNull null], @"block": [NSNull null]}];
    [self.steps addObject:@{@"id": @"camp_description", @"skip": [NSNumber numberWithBool:false], @"next": @"Next", @"instruction": @"Briefly describe your Camp\n(optional)", @"placeholder":@"Camp Description", @"sensitive": [NSNumber numberWithBool:false], @"keyboard": @"text", @"answer": [NSNull null], @"textField": [NSNull null], @"block": [NSNull null]}];
    [self.steps addObject:@{@"id": @"camp_similar", @"skip": [NSNumber numberWithBool:false], @"next": @"Continue Anyways", @"instruction": @"Would you like to join a\nsimilar Camp instead?", @"sensitive": [NSNumber numberWithBool:true], @"answer": [NSNull null], @"block": [NSNull null]}];
    [self.steps addObject:@{@"id": @"camp_picture", @"skip": [NSNumber numberWithBool:false], @"next": @"Next", @"instruction": @"Set a Camp picture\n(optional)", @"block": [NSNull null]}];
    [self.steps addObject:@{@"id": @"camp_color", @"skip": [NSNumber numberWithBool:false], @"next": @"Create Camp", @"instruction": @"Select Camp Color\nand Privacy Setting", @"sensitive": [NSNumber numberWithBool:true], @"answer": [NSNull null], @"block": [NSNull null]}];
    [self.steps addObject:@{@"id": @"camp_share", @"skip": [NSNumber numberWithBool:false], @"next": @"Enter Camp", @"instruction": @"Your Camp has been created!\nInvite others to join below", @"sensitive": [NSNumber numberWithBool:true], @"answer": [NSNull null], @"block": [NSNull null]}];
    
    for (NSInteger i = 0; i < [self.steps count]; i++) {
        // add each step to the right
        [self addStep:i usingArray:self.steps];
    }
}

- (void)addStep:(NSInteger)stepIndex usingArray:(NSMutableArray *)parentArray {
    NSMutableDictionary *mutatedStep = [[NSMutableDictionary alloc] initWithDictionary:parentArray[stepIndex]];
    
    if ([mutatedStep objectForKey:@"textField"] && ![mutatedStep[@"textfield"] isEqual:[NSNull null]]) {
        UIView *inputBlock = [[UIView alloc] initWithFrame:CGRectMake(0, (self.view.frame.size.height / 2) - (56 / 2) - (self.view.frame.size.height * .15), self.view.frame.size.width, 56)];
        [self.view addSubview:inputBlock];
        
        UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(24, 0, self.view.frame.size.width - (24 * 2), 56)];
        textField.textColor = [UIColor bonfirePrimaryColor];
        textField.backgroundColor = [UIColor cardBackgroundColor];
        textField.layer.cornerRadius = 14.f;
        textField.layer.masksToBounds = false;
        textField.layer.shadowRadius = 2.f;
        textField.layer.shadowOffset = CGSizeMake(0, 1);
        textField.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.1f].CGColor;
        textField.layer.shadowOpacity = 1.f;
//        textField.keyboardAppearance = UIKeyboardAppearanceLight;
        if ([mutatedStep[@"id"] isEqualToString:@"camp_title"]) {
            textField.tag = 201;
        }
        else if ([mutatedStep[@"id"] isEqualToString:@"camp_description"]) {
            textField.tag = 202;
        }
//        [self continuityRadiusForView:textField withRadius:12.f];
        
        
        if ([mutatedStep objectForKey:@"keyboard"] && [mutatedStep[@"keyboard"] isEqualToString:@"email"]) {
            textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            textField.keyboardType = UIKeyboardTypeEmailAddress;
        }
        else if ([mutatedStep objectForKey:@"keyboard"] && [mutatedStep[@"keyboard"] isEqualToString:@"number"]) {
            
            textField.keyboardType = UIKeyboardTypeNumberPad;
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
        leftView.backgroundColor = [UIColor clearColor];
        textField.leftView = leftView;
        textField.rightView = leftView;
        textField.leftViewMode = UITextFieldViewModeAlways;
        textField.rightViewMode = UITextFieldViewModeAlways;
        textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:([mutatedStep objectForKey:@"placeholder"] ? mutatedStep[@"placeholder"] : @"") attributes:@{NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor]}];
        [textField addTarget:self action:@selector(textFieldChanged:) forControlEvents:UIControlEventEditingChanged];
        
        
        if ([mutatedStep[@"sensitive"] boolValue]) {
            textField.secureTextEntry = true;
        }
        else {
            textField.secureTextEntry = false;
        }
        
        // add a reset password button for password field
        if ([mutatedStep[@"id"] isEqualToString:@"camp_title"]) {
            NSArray *options = @[@"Day Ones", @"family", @"friend group", @"lunch group", @"fantasy sports league", @"weird obsession", @"late night thoughts", @"crazy ideas", @"social club", @"favorite sports team", @"party people", @"team"];
            int available = (int)options.count - 1;
            int random = arc4random_uniform(available);
            NSString *optionString = options[(NSInteger)random];
            
            UILabel *tryCreating = [[UILabel alloc] initWithFrame:CGRectMake(textField.frame.origin.x + leftView.frame.size.width, textField.frame.origin.y + textField.frame.size.height + 16, self.view.frame.size.width - (textField.frame.origin.x + leftView.frame.size.width) - textField.frame.origin.x, 24)];
            tryCreating.text = [NSString stringWithFormat:@"Try a Camp for your %@", optionString];
            tryCreating.font = [UIFont systemFontOfSize:13.f weight:UIFontWeightRegular];
            tryCreating.textColor = [UIColor bonfireSecondaryColor];
            tryCreating.alpha = 0;
            [inputBlock addSubview:tryCreating];
            
            inputBlock.frame = CGRectMake(inputBlock.frame.origin.x, inputBlock.frame.origin.y, inputBlock.frame.size.width, tryCreating.frame.origin.y + tryCreating.frame.size.height);
            
            tryCreating.transform = CGAffineTransformMakeTranslation(0, 8);
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    tryCreating.alpha = 1;
                    tryCreating.transform = CGAffineTransformIdentity;
                } completion:nil];
            });
        }
        
        inputBlock.alpha = 0;
        inputBlock.transform = CGAffineTransformMakeTranslation(self.view.frame.size.width, 0);
        
        [mutatedStep setObject:inputBlock forKey:@"block"];
        [mutatedStep setObject:textField forKey:@"textField"];
    }
    else if ([mutatedStep[@"id"] isEqualToString:@"camp_similar"]) {
        UIView *block = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.width, self.view.frame.size.width, SMALL_MEDIUM_CARD_HEIGHT)];
        block.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
        block.alpha = 0;
        block.transform = CGAffineTransformMakeTranslation(self.view.frame.size.width, 0);
        [self.view addSubview:block];
        
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.minimumLineSpacing = 12.f;
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        self.loadingSimilarCamps = true;
        
        self.similarCampsCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, SMALL_MEDIUM_CARD_HEIGHT) collectionViewLayout:flowLayout];
        self.similarCampsCollectionView.delegate = self;
        self.similarCampsCollectionView.dataSource = self;
        self.similarCampsCollectionView.contentInset = UIEdgeInsetsMake(0, 24, 0, 24);
        self.similarCampsCollectionView.showsHorizontalScrollIndicator = false;
        self.similarCampsCollectionView.layer.masksToBounds = false;
        self.similarCampsCollectionView.backgroundColor = [UIColor clearColor];
        
        [self.similarCampsCollectionView registerClass:[SmallMediumCampCardCell class] forCellWithReuseIdentifier:mediumCardReuseIdentifier];
        [self.similarCampsCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:blankCellIdentifier];
        
        self.similarCamps = [[NSMutableArray alloc] init];
        
        [block addSubview:self.similarCampsCollectionView];
        
        [mutatedStep setObject:block forKey:@"block"];
    }
    else if ([mutatedStep[@"id"] isEqualToString:@"camp_picture"]) {
            UIView *userProfilePictureContainerBlock = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.width, 160, 160)];
            userProfilePictureContainerBlock.layer.cornerRadius = userProfilePictureContainerBlock.frame.size.width / 2;
            userProfilePictureContainerBlock.layer.masksToBounds = false;
            userProfilePictureContainerBlock.layer.shadowRadius = 2.f;
            userProfilePictureContainerBlock.layer.shadowOffset = CGSizeMake(0, 1);
            userProfilePictureContainerBlock.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.1f].CGColor;
            userProfilePictureContainerBlock.layer.shadowOpacity = 1.f;
            userProfilePictureContainerBlock.backgroundColor = [UIColor cardBackgroundColor];
            userProfilePictureContainerBlock.alpha = 0;
            userProfilePictureContainerBlock.center = CGPointMake(self.view.frame.size.width / 2, (self.view.frame.size.height / self.view.transform.d) / 2);
            userProfilePictureContainerBlock.transform = CGAffineTransformMakeTranslation(self.view.frame.size.width, 0);
            userProfilePictureContainerBlock.userInteractionEnabled = true;
            [self.view addSubview:userProfilePictureContainerBlock];
            
            [userProfilePictureContainerBlock bk_whenTapped:^{
                // open camp share
                [self showImagePicker];
            }];
            
            UIImageView *userProfilePictureBlock = [[UIImageView alloc] initWithFrame:userProfilePictureContainerBlock.bounds];
            userProfilePictureBlock.tag = 10;
            userProfilePictureBlock.layer.cornerRadius = userProfilePictureBlock.frame.size.width / 2;
            userProfilePictureBlock.layer.masksToBounds = true;
            userProfilePictureBlock.image = [UIImage imageNamed:@"addCampPicture"];
            userProfilePictureBlock.contentMode = UIViewContentModeScaleAspectFill;
            [userProfilePictureContainerBlock addSubview:userProfilePictureBlock];
            
            [mutatedStep setObject:userProfilePictureContainerBlock forKey:@"block"];
        }
    else if ([mutatedStep[@"id"] isEqualToString:@"camp_color"]) {
        UIView *colorBlock = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.width, 216, 286)];
        colorBlock.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2 + 35);
        colorBlock.layer.cornerRadius = 10.f;
        colorBlock.alpha = 0;
        colorBlock.transform = CGAffineTransformMakeTranslation(self.view.frame.size.width, 0);
        [self.view addSubview:colorBlock];
        
        colors = @[[UIColor bonfireBlue],  // 0
                   [UIColor bonfireViolet],  // 1
                   [UIColor bonfireRed],  // 2
                   [UIColor bonfireOrange],  // 3
                   [UIColor colorWithRed:0.16 green:0.72 blue:0.01 alpha:1.00], // cash green
                   [UIColor brownColor],  // 5
                   [UIColor colorWithRed:0.96 green:0.76 blue:0.23 alpha:1.00],  // 6
                   [UIColor bonfireCyanWithLevel:800],  // 7
                   [UIColor bonfireGrayWithLevel:900]]; // 8
        
        self.themeColor = 0 + arc4random() % (colors.count - 1);
                
        for (NSInteger i = 0; i < 9; i++) {
            NSInteger row = i % 3;
            NSInteger column = floorf(i / 3);
                        
            UIView *colorOption = [[UIView alloc] initWithFrame:CGRectMake(column * 80, row * 80, 56, 56)];
            colorOption.layer.cornerRadius = colorOption.frame.size.height / 2;
            colorOption.backgroundColor = colors[i];
            colorOption.tag = i;
            [colorBlock addSubview:colorOption];
            
            if (i == (int)self.themeColor) {
                // add check image view
                UIImageView *checkView = [[UIImageView alloc] initWithFrame:CGRectMake(-4, -4, colorOption.frame.size.width + 8, colorOption.frame.size.height + 8)];
                checkView.contentMode = UIViewContentModeCenter;
                checkView.image = [UIImage imageNamed:@"selectedColorCheck"];
                checkView.tag = 999;
                checkView.layer.cornerRadius = checkView.frame.size.height / 2;
                checkView.layer.borderColor = [colorOption.backgroundColor colorWithAlphaComponent:0.25f].CGColor;
                checkView.layer.borderWidth = 5.f;
                checkView.backgroundColor = [UIColor clearColor];
                [colorOption addSubview:checkView];
            }
            
            [colorOption bk_whenTapped:^{
                [self setColor:colorOption];
            }];
        }
        
        // add private camp UISwitch
        UISwitch *publicCampSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        publicCampSwitch.on = false;
        publicCampSwitch.frame = CGRectMake(colorBlock.frame.size.width - publicCampSwitch.frame.size.width, colorBlock.frame.size.height - publicCampSwitch.frame.size.height, publicCampSwitch.frame.size.width, publicCampSwitch.frame.size.height);
        publicCampSwitch.tag = 10;
        [colorBlock addSubview:publicCampSwitch];
        
        UILabel *publicCampLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, publicCampSwitch.frame.origin.y, colorBlock.frame.size.width - publicCampSwitch.frame.size.width, publicCampSwitch.frame.size.height)];
        publicCampLabel.text = @"Private Camp";
        publicCampLabel.textColor = [UIColor bonfirePrimaryColor];
        publicCampLabel.textAlignment = NSTextAlignmentLeft;
        publicCampLabel.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightMedium];
        [colorBlock addSubview:publicCampLabel];
        
        UIView *separatorLine = [[UIView alloc] initWithFrame:CGRectMake(0, publicCampSwitch.frame.origin.y - 16 - 1, colorBlock.frame.size.width, 1)];
        separatorLine.backgroundColor = [[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.05];
        [colorBlock addSubview:separatorLine];
        
        [mutatedStep setObject:colorBlock forKey:@"block"];
    }
    else if ([mutatedStep[@"id"] isEqualToString:@"camp_share"]) {
        UIView *shareBlock = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.width, self.view.frame.size.width, 116)];
        shareBlock.center = CGPointMake(shareBlock.center.x, self.view.frame.size.height / 2);
        shareBlock.alpha = 0;
        shareBlock.transform = CGAffineTransformMakeTranslation(self.view.frame.size.width, 0);
        [self.view addSubview:shareBlock];
        
        UIButton *shareField = [[UIButton alloc] initWithFrame:CGRectMake(24, 0, self.view.frame.size.width - (24 * 2), 56)];
        shareField.backgroundColor = [UIColor cardBackgroundColor];
        shareField.layer.cornerRadius = 12.f;
        shareField.layer.masksToBounds = false;
        shareField.layer.shadowRadius = 2.f;
        shareField.layer.shadowOffset = CGSizeMake(0, 1);
        shareField.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.1f].CGColor;
        shareField.layer.shadowOpacity = 1.f;
        [shareField setTitleColor:[UIColor bonfirePrimaryColor] forState:UIControlStateNormal];
        shareField.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        shareField.contentEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 84);
        shareField.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        shareField.titleLabel.font = [UIFont systemFontOfSize:20.f weight:UIFontWeightMedium];
        shareField.tag = 10;
        [shareBlock addSubview:shareField];
        [shareField bk_addEventHandler:^(id sender) {
            [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                shareField.alpha = 0.75;
            } completion:nil];
        } forControlEvents:UIControlEventTouchDown];
        [shareField bk_addEventHandler:^(id sender) {
            [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                shareField.alpha = 1;
            } completion:nil];
        } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
        [shareField bk_whenTapped:^{
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = shareField.currentTitle;
            [HapticHelper generateFeedback:FeedbackType_Notification_Success];
                        
            BFMiniNotificationObject *notificationObject = [BFMiniNotificationObject notificationWithText:@"Copied!" action:nil];
            [[BFMiniNotificationManager manager] presentNotification:notificationObject completion:nil];
        }];
        
        UILabel *copyLabel = [[UILabel alloc] initWithFrame:CGRectMake(shareField.frame.size.width - 20 - 64, 0, 64, shareField.frame.size.height)];
        copyLabel.textAlignment = NSTextAlignmentRight;
        copyLabel.text = @"Copy";
        copyLabel.font = [UIFont systemFontOfSize:20.f weight:UIFontWeightBold];
        copyLabel.tag = 12;
        [shareField addSubview:copyLabel];
        
        NSMutableArray *buttons = [NSMutableArray new];
        
        [buttons addObject:@{@"id": @"bonfire", @"image": [UIImage imageNamed:@"share_bonfire"], @"color": [UIColor fromHex:@"FF513C" adjustForOptimalContrast:false]}];

        BOOL hasInstagram = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"instagram-stories://"]];
        BOOL hasSnapchat = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"snapchat://"]];
        BOOL hasTwitter = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]];
      
        if (hasInstagram) {
            [buttons addObject:@{@"id": @"instagram", @"image": [UIImage imageNamed:@"share_instagram"], @"color": [UIColor fromHex:@"DC3075" adjustForOptimalContrast:false]}];
        }

        if (hasTwitter && (![self.camp.attributes isPrivate] || !hasSnapchat)) {
            [buttons addObject:@{@"id": @"twitter", @"image": [UIImage imageNamed:@"share_twitter"], @"color": [UIColor fromHex:@"1DA1F2" adjustForOptimalContrast:false]}];
        }
      
        if (hasSnapchat) {
            [buttons addObject:@{@"id": @"snapchat", @"image": [UIImage imageNamed:@"share_snapchat"], @"color": [UIColor fromHex:@"fffc00" adjustForOptimalContrast:false]}];
        }
      
        if ([self.camp.attributes isPrivate] || !hasTwitter || !hasSnapchat) {
            [buttons addObject:@{@"id": @"imessage", @"image": [UIImage imageNamed:@"share_imessage"], @"color": [UIColor fromHex:@"36DB52" adjustForOptimalContrast:false]}];
        }
            
        if (buttons.count < 4) {
            // add facebook
            [buttons addObject:@{@"id": @"facebook", @"image": [UIImage imageNamed:@"share_facebook"], @"color": [UIColor fromHex:@"3B5998" adjustForOptimalContrast:false]}];
        }
      
        [buttons addObject:@{@"id": @"more", @"image": [[UIImage imageNamed:@"share_more"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate], @"color": [UIColor tableViewSeparatorColor]}];
        
        CGFloat buttonPadding = 12;
        CGFloat buttonDiameter = (self.view.frame.size.width - (shareField.frame.origin.x * 2) - (20 * 2) - ((buttons.count - 1) * buttonPadding)) / buttons.count;
        
        shareBlock.frame = CGRectMake(shareBlock.frame.origin.x, shareBlock.frame.origin.y, shareBlock.frame.size.width, shareField.frame.origin.y + shareField.frame.size.height + (buttonPadding * 1.5) + buttonDiameter);
        for (NSInteger i = 0; i < buttons.count; i++) {
            NSDictionary *buttonDict = buttons[i];
            NSString *identifier = buttonDict[@"id"];
            
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.frame = CGRectMake(shareField.frame.origin.x + 20 + i * (buttonDiameter + buttonPadding), shareBlock.frame.size.height - buttonDiameter, buttonDiameter, buttonDiameter);
            button.layer.cornerRadius = button.frame.size.width / 2;
            button.backgroundColor = buttonDict[@"color"];
            button.adjustsImageWhenHighlighted = false;
            button.layer.masksToBounds = true;
            button.tintColor = [UIColor bonfirePrimaryColor];
            [button setImage:buttonDict[@"image"] forState:UIControlStateNormal];
            button.contentMode = UIViewContentModeCenter;
            [shareBlock addSubview:button];
            
            [button bk_addEventHandler:^(id sender) {
                [HapticHelper generateFeedback:FeedbackType_Selection];
                [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                    button.transform = CGAffineTransformMakeScale(0.92, 0.92);
                } completion:nil];
            } forControlEvents:UIControlEventTouchDown];
                    
            [button bk_addEventHandler:^(id sender) {
                [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                    button.transform = CGAffineTransformIdentity;
                } completion:nil];
            } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
            
            [button bk_whenTapped:^{
                NSString *campShareLink = [NSString stringWithFormat:@"https://bonfire.camp/c/%@", self.camp.identifier];
                if ([identifier isEqualToString:@"bonfire"]) {
                    [Launcher openComposePost:nil inReplyTo:nil withMessage:nil media:nil quotedObject:self.camp];
                }
                else if ([identifier isEqualToString:@"instagram"]) {
                    [Launcher shareCampOnInstagram:self.camp];
                }
                else if ([identifier isEqualToString:@"twitter"]) {
                    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://post"]]) {
                        NSString *message = [[NSString stringWithFormat:@"Help me start a Camp on @yourbonfire! Join %@: %@", self.camp.attributes.title, campShareLink] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"!*'();:@&=+$,/?%#[]"]];
                        
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"twitter://post?message=%@", message]] options:@{} completionHandler:nil];
                    }
                }
                else if ([identifier isEqualToString:@"snapchat"]) {
                    [Launcher shareCampOnSnapchat:self.camp];
                }
                else if ([identifier isEqualToString:@"imessage"]) {
                    [Launcher shareOniMessage:[NSString stringWithFormat:@"Help me start a Camp on Bonfire! Join %@: %@", self.camp.attributes.title, campShareLink] image:nil];
                }
                else if ([identifier isEqualToString:@"facebook"]) {
                    FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
                    content.contentURL = [NSURL URLWithString:campShareLink];
                    content.hashtag = [FBSDKHashtag hashtagWithString:@"#Bonfire"];
                    [FBSDKShareDialog showFromViewController:[Launcher topMostViewController]
                                                 withContent:content
                                                    delegate:nil];
                }
                else if ([identifier isEqualToString:@"more"]) {
                    [Launcher shareCamp:self.camp];
                }
            }];
        }
        
        [mutatedStep setObject:shareBlock forKey:@"block"];
    }
    
    [parentArray replaceObjectAtIndex:stepIndex withObject:mutatedStep];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *newStr = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if (textField.tag == 201) {
        return [newStr validateBonfireCampTitle] != BFValidationErrorTooLong;
    }
    else if (textField.tag == 202) {
        return [newStr validateBonfireCampDescription] != BFValidationErrorTooLong;
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
        NSInteger colorStep = [self getIndexOfStepWithId:@"camp_color"];
        UIView *colorBlock = self.steps[colorStep][@"block"];
        
        UIView *previousColorView;
        for (UIView *subview in colorBlock.subviews) {
            if (subview.tag == self.themeColor) {
                previousColorView = subview;
                break;
            }
        }

        for (UIImageView *imageView in previousColorView.subviews) {
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
        
        self.themeColor = sender.tag;
        self.view.tintColor = [self currentColor];
        
        // add check image view
        UIImageView *checkView = [[UIImageView alloc] initWithFrame:CGRectMake(-6, -6, sender.frame.size.width + 12, sender.frame.size.height + 12)];
        checkView.contentMode = UIViewContentModeCenter;
        checkView.image = [UIImage imageNamed:@"selectedColorCheck"];
        checkView.tag = 999;
        checkView.layer.cornerRadius = checkView.frame.size.height / 2;
        checkView.layer.borderColor = [sender.backgroundColor colorWithAlphaComponent:0.25f].CGColor;
        checkView.layer.borderWidth = 7.f;
        checkView.backgroundColor = [UIColor clearColor];
        [sender addSubview:checkView];
        
        checkView.transform = CGAffineTransformMakeScale(0.8, 0.8);
        checkView.alpha = 0;
        
        [UIView animateWithDuration:0.6f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.nextButton.backgroundColor = sender.backgroundColor;
            [self.nextButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            self.closeButton.tintColor = [UIColor fromHex:[UIColor toHex:sender.backgroundColor] adjustForOptimalContrast:true];
            
            checkView.transform = CGAffineTransformMakeScale(1, 1);
            checkView.alpha = 1;
        } completion:nil];
    }
    
}

- (NSInteger)getIndexOfStepWithId:(NSString *)stepId {
    for (NSInteger i = 0; i < [self.steps count]; i++) {
        if ([self.steps[i][@"id"] isEqualToString:stepId]) {
            return i;
        }
    }
    return 0;
}

- (void)textFieldChanged:(UITextField *)sender {
    if ([self.steps[self.currentStep][@"id"] isEqualToString:@"camp_title"]) {
        if (sender.text.length <= 1) {
            [self greyOutNextButton];
        }
        else {
            // qualifies
            [self enableNextButton];
        }
    }
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (self.nextButton.enabled) [self handleNext];
    
    return false;
}

- (void)enableNextButton {
    self.nextButton.enabled = true;
    self.nextButton.backgroundColor = self.view.tintColor;
    [self.nextButton setTitleColor:[UIColor colorNamed:@"FullContrastColor_inverted"] forState:UIControlStateNormal];
}
- (void)greyOutNextButton {
    self.nextButton.enabled = false;
    self.nextButton.backgroundColor = [UIColor bonfireDisabledColor];
}

- (void)handleNext {
    NSDictionary *step = self.steps[self.currentStep];
    
    self.nextButton.userInteractionEnabled = false;
    
    // sign in to school
    if ([step[@"id"] isEqualToString:@"camp_description"]) {
        // check for similar names
        [self greyOutNextButton];
        [self showSpinnerForStep:self.currentStep];
        
        [self getSimilarCamps];
    }
    else if ([step[@"id"] isEqualToString:@"camp_color"]) {
        // create that camp!
        
        // check for similar names
        [self greyOutNextButton];
        [self showBigSpinnerForStep:self.currentStep];
        
        [self createCamp];
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
    
    NSInteger next = self.currentStep;

    BOOL isComplete = true; // true until proven false
    for (NSInteger i = self.currentStep + 1; i < [self.steps count]; i++) {
        // steps to the right of the currentStep
        if (i >= [self.steps count]) {
            // does not have a next step // this should never happen
            NSLog(@"Could not find a next step.");
            next = self.currentStep + 1;
        }
        else {
            NSDictionary *step = self.steps[i];
            if (![step[@"skip"] boolValue]) {
                next = i;
            }
            else {
                // skip step
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
        
        NSDictionary *nextStep = self.steps[next];
        UIView *nextBlock = nextStep[@"block"];
          
        if ([nextStep[@"id"] isEqualToString:@"camp_picture"]) {
            [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                [self enableNextButton];
            } completion:nil];
        }
        else if ([nextStep[@"id"] isEqualToString:@"camp_similar"]) {
            [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                [self enableNextButton];
            } completion:nil];
        }
        else if ([nextStep[@"id"] isEqualToString:@"camp_color"]) {
            [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.view.tintColor = [self currentColor];
                self.closeButton.tintColor = [UIColor fromHex:[UIColor toHex:[self currentColor]] adjustForOptimalContrast:true];
                self.nextButton.backgroundColor = [self currentColor];
                [self enableNextButton];
            } completion:nil];
        }
        else if ([nextStep[@"id"] isEqualToString:@"camp_share"]) {
            // remove previously selected color
            UILabel *copyLabel = [nextBlock viewWithTag:12];
            UIButton *shareCampButton = [nextBlock viewWithTag:11];
            copyLabel.textColor = [UIColor fromHex:[UIColor toHex:[self currentColor]] adjustForOptimalContrast:true];
            shareCampButton.tintColor = copyLabel.textColor;
            [shareCampButton setTitleColor:copyLabel.textColor forState:UIControlStateNormal];
            shareCampButton.layer.borderColor = [copyLabel.textColor colorWithAlphaComponent:0.2f].CGColor;
            
            [self enableNextButton];
            
            self.closeButton.userInteractionEnabled = false;
            [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.closeButton.alpha = 0;
            } completion:nil];
            
            // blast some confetti!
            [UIView animateWithDuration:0 animations:^{
                L360ConfettiArea *confettiArea = [[L360ConfettiArea alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
                            
                [self.view insertSubview:confettiArea atIndex:0];
                confettiArea.blastSpread = 0;
                confettiArea.delegate = self;
                confettiArea.swayLength = 75.f;
                [confettiArea burstAt:CGPointMake(self.view.frame.size.width / 2, -80) confettiWidth:12.f numberOfConfetti:60];
            } completion:^(BOOL finished) {
            }];
        }
        
        if ([nextStep objectForKey:@"textField"] && ![nextStep[@"textField"] isEqual:[NSNull null]]) {
            UITextField *nextTextField = nextStep[@"textField"];
            
            CGFloat delay = self.currentStep == -1 ? 0.01f : 0;
            
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
- (void)getSimilarCamps {
    NSInteger campTitleIndex = [self getIndexOfStepWithId:@"camp_title"];
    NSString *campTitle = ((UITextField *)self.steps[campTitleIndex][@"textField"]).text;
    NSInteger campDescriptionIndex = [self getIndexOfStepWithId:@"camp_description"];
    NSString *campDescription = ((UITextField *)self.steps[campDescriptionIndex][@"textField"]).text;
    
    NSString *query = campTitle;
    if (campDescription.length > 0) {
        query = [query stringByAppendingString:[NSString stringWithFormat:@" %@", campDescription]];
    }
    
    [[HAWebService authenticatedManager] GET:@"search/camps" parameters:@{@"q": query} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        // NSLog(@"CreateCampViewController / getSimilarCamps() success! ✅");
        
        NSLog(@"response: %@", responseObject[@"data"][@"results"][@"camps"]);
        
        NSArray *responseData = (NSArray *)responseObject[@"data"][@"results"][@"camps"];
        
        self.loadingSimilarCamps = false;
        
        self.similarCamps = [[NSMutableArray alloc] initWithArray:responseData];
        [self.similarCampsCollectionView reloadData];
        [self.similarCampsCollectionView layoutSubviews];
        [self resizeSimilarCampsCollectionView];
        
        NSInteger similarCampsStepIndex = [self getIndexOfStepWithId:@"camp_similar"];
        NSMutableDictionary *mutableDict = [[NSMutableDictionary alloc] initWithDictionary:self.steps[similarCampsStepIndex]];
        
        if (responseData.count > 0) {
            [mutableDict setObject:[NSNumber numberWithBool:false] forKey:@"skip"];
        }
        else {
            [mutableDict setObject:[NSNumber numberWithBool:true] forKey:@"skip"];
        }
        [self.steps replaceObjectAtIndex:similarCampsStepIndex withObject:mutableDict];
        
        [self enableNextButton];
        
        [self removeSpinnerForStep:self.currentStep];
        [self nextStep:true];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"CreateCampViewController / getSimilarCamps() - error: %@", error);
        //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        
        // just skip it...
        NSInteger similarCampsStepIndex = [self getIndexOfStepWithId:@"camp_similar"];
        NSMutableDictionary *mutableDict = [[NSMutableDictionary alloc] initWithDictionary:self.steps[similarCampsStepIndex]];
        [mutableDict setObject:[NSNumber numberWithBool:true] forKey:@"skip"];
        [self.steps replaceObjectAtIndex:similarCampsStepIndex withObject:mutableDict];
        
        [self nextStep:true];
    }];
}

- (void)resizeSimilarCampsCollectionView {
    if (self.similarCampsCollectionView.contentSize.width >= self.similarCampsCollectionView.superview.frame.size.width) {
        self.similarCampsCollectionView.frame = CGRectMake(0, self.similarCampsCollectionView.frame.origin.y, self.similarCampsCollectionView.superview.frame.size.width, self.similarCampsCollectionView.frame.size.height);
    }
    else {
        CGFloat width = self.similarCampsCollectionView.contentSize.width + self.similarCampsCollectionView.contentInset.left + self.similarCampsCollectionView.contentInset.right;
        
        NSLog(@"new widthhhh: %f", width);
        self.similarCampsCollectionView.frame = CGRectMake(self.similarCampsCollectionView.superview.frame.size.width / 2 - width / 2, self.similarCampsCollectionView.frame.origin.y, width, self.similarCampsCollectionView.frame.size.height);
    }
}

- (UIColor *)currentColor {
    NSInteger colorStep = [self getIndexOfStepWithId:@"camp_color"];
    if (self.currentStep < colorStep - 1) {
        return [UIColor bonfirePrimaryColor];
    }
    
    return colors[self.themeColor];
}
- (void)createCamp {
    [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.closeButton.alpha = 0;
    } completion:nil];
    
    NSInteger titleStep = [self getIndexOfStepWithId:@"camp_title"];
    UITextField *titleTextField = self.steps[titleStep][@"textField"];
    NSString *campTitle = titleTextField.text;
    
    NSInteger descriptionStep = [self getIndexOfStepWithId:@"camp_description"];
    UITextField *descriptionTextField = self.steps[descriptionStep][@"textField"];
    NSString *campDescription = descriptionTextField.text;
    
    NSString *campColor = [UIColor toHex:colors[self.themeColor]];
    
    NSInteger themeAndPrivacyStep = [self getIndexOfStepWithId:@"camp_color"];
    UIView *nextBlock = self.steps[themeAndPrivacyStep][@"block"];
    UISwitch *isPrivateSwitch = [nextBlock viewWithTag:10];
    BOOL private = isPrivateSwitch.on;
    
    NSInteger campPictureStep = [self getIndexOfStepWithId:@"camp_picture"];
    UIView *campPictureView = self.steps[campPictureStep][@"block"];
    UIImageView *campPictureImageView = [campPictureView viewWithTag:10];
    UIImage *campPicture = campPictureImageView.image;
    CGImageRef cgref = [campPicture CGImage];
    CIImage *cim = [campPicture CIImage];
    BOOL hasCampPicture = (cim != nil || cgref != NULL) && campPictureView.tag == 1;
    
    NSLog(@"params: %@", @{@"title": campTitle, @"description": campDescription, @"color": campColor, @"private": [NSNumber numberWithBool:private]});
    
    void (^createCamp)(NSString *uploadedImage) = ^(NSString *uploadedImage) {
        NSMutableDictionary *params = @{@"title": campTitle, @"description": campDescription, @"color": campColor, @"private": [NSNumber numberWithBool:private]}.mutableCopy;
        
        if (uploadedImage.length > 0) {
            [params setObject:uploadedImage forKey:@"avatar"];
        }
        
        [[HAWebService authenticatedManager] POST:@"camps" parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            NSError *error;
            Camp *camp = [[Camp alloc] initWithDictionary:responseObject[@"data"] error:&error];
            self.camp = camp;
            
            // update share url
            NSInteger shareStep = [self getIndexOfStepWithId:@"camp_share"];
            UIView *shareBlock = self.steps[shareStep][@"block"];
            UIButton *shareField = [shareBlock viewWithTag:10];
            [shareField setTitle:[NSString stringWithFormat:@"https://bonfire.camp/c/%@", camp.identifier] forState:UIControlStateNormal];
            
            UIButton *shareCampButton = [shareBlock viewWithTag:11];
            [shareCampButton bk_whenTapped:^{
                // open camp share
                [Launcher shareCamp:camp];
            }];
            
            // refresh my camps
            [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshMyCamps" object:nil];
            
            [self enableNextButton];
            
            // move spinner
            [self removeBigSpinnerForStep:self.currentStep push:true];
            
            [self nextStep:true];
            
            // Google Analytics
            [FIRAnalytics logEventWithName:@"camp_created"
                                parameters:@{
                                             @"public": (private) ? @"NO" : @"FALSE",
                                             @"color": campColor
                                             }];
            //[self.createTrace stop];
            
            for (UIGestureRecognizer *recognizer in self.nextButton.gestureRecognizers) {
                [self.nextButton removeGestureRecognizer:recognizer];
            }
            [self.nextButton bk_whenTapped:^{
                [self setEditing:false animated:YES];
                
                [self dismissViewControllerAnimated:YES completion:^{
                    [Launcher openCamp:camp];
                }];
            }];
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            [self removeBigSpinnerForStep:self.currentStep push:false];
            [self enableNextButton];
            self.nextButton.userInteractionEnabled = true;
            [self shakeInputBlock];
            
            [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.closeButton.alpha = 1;
            } completion:nil];
        }];
    };
    
    if (hasCampPicture) {
        BFMediaObject *campPictureObject = [[BFMediaObject alloc] initWithImage:campPicture];
        
        [BFAPI uploadImage:campPictureObject copmletion:^(BOOL success, NSString * _Nonnull uploadedImageURL) {
            if (success) {
                createCamp(uploadedImageURL);
            }
            else {
                // save it anyways -- despite the profile picture failing
                createCamp(nil);
            }
        }];
    }
    else {
        createCamp(nil);
    }
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

- (void)showSpinnerForStep:(NSInteger)step {
    UIView *block = (UIView *)[[self.steps objectAtIndex:step] objectForKey:@"block"];
    UITextField *textField = (UITextField *)[[self.steps objectAtIndex:step] objectForKey:@"textField"];
    
    UIImageView *miniSpinner = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
    miniSpinner.image = [[UIImage imageNamed:@"miniSpinner"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    miniSpinner.tintColor = self.view.tintColor;
    miniSpinner.center = CGPointMake(block.frame.size.width / 2, block.frame.size.height / 2);
    miniSpinner.alpha = 0;
    miniSpinner.tag = 112;
    
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
        textField.textColor = [[UIColor bonfirePrimaryColor] colorWithAlphaComponent:0];
        if (textField.placeholder != nil) {
            textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:textField.placeholder attributes:@{NSForegroundColorAttributeName: [[UIColor bonfireSecondaryColor] colorWithAlphaComponent:0]}];
        }
        textField.tintColor = [UIColor clearColor];
    } completion:nil];
}
- (void)removeSpinnerForStep:(NSInteger)step {
    UIView *block = (UIView *)[[self.steps objectAtIndex:step] objectForKey:@"block"];
    UITextField *textField = (UITextField *)[[self.steps objectAtIndex:step] objectForKey:@"textField"];
    UIImageView *miniSpinner = [block viewWithTag:112];
    
    [UIView animateWithDuration:0.6f delay:0 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        miniSpinner.alpha = 0;
    } completion:^(BOOL finished) {
        [miniSpinner removeFromSuperview];
                
        [UIView transitionWithView:textField duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            textField.textColor = [UIColor bonfirePrimaryColor];
            textField.tintColor = [self.view tintColor];
            if (textField.placeholder != nil) {
                textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:textField.placeholder attributes:@{NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor]}];
            }
        } completion:nil];
    }];
}

- (void)showBigSpinnerForStep:(NSInteger)step {
    UIView *block = (UIView *)[[self.steps objectAtIndex:step] objectForKey:@"block"];
    
    UIImageView *spinner = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 52, 52)];
    spinner.image = [[UIImage imageNamed:@"spinner"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    spinner.tintColor = [self currentColor];
    spinner.center = self.view.center;
    spinner.alpha = 0;
    spinner.tag = 111;
    
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
- (void)removeBigSpinnerForStep:(NSInteger)step push:(BOOL)push {
    UIView *block = (UIView *)[[self.steps objectAtIndex:step] objectForKey:@"block"];
    UIImageView *spinner = [self.view viewWithTag:111];
    
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
    NSLog(@"safe area insets bottom: %f", window.safeAreaInsets.bottom);
    CGFloat bottomPadding = window.safeAreaInsets.bottom + (HAS_ROUNDED_CORNERS ? (self.nextButton.frame.origin.x / 2) : self.nextButton.frame.origin.x);
    NSLog(@"bottom padding: %f", bottomPadding);
    
    NSNumber *duration = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:[duration floatValue] delay:0 options:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue] << 16 animations:^{
        self.nextButton.frame = CGRectMake(self.nextButton.frame.origin.x, self.view.frame.size.height - self.nextButton.frame.size.height - bottomPadding, self.nextButton.frame.size.width, self.nextButton.frame.size.height);
    } completion:nil];
}

// similar camps collection view
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.similarCamps.count;
}
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.loadingSimilarCamps || self.similarCamps.count > 0) {
        SmallMediumCampCardCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:mediumCardReuseIdentifier forIndexPath:indexPath];
        
        if (self.similarCamps.count > indexPath.item) {
            NSError *error;
            cell.camp = [[Camp alloc] initWithDictionary:self.similarCamps[indexPath.item] error:&error];
            
            [cell layoutSubviews];
        }
        
        return cell;
    }
    
    // if all else fails, return a blank cell
    UICollectionViewCell *blankCell = [collectionView dequeueReusableCellWithReuseIdentifier:blankCellIdentifier forIndexPath:indexPath];
    return blankCell;
}
- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(148, SMALL_MEDIUM_CARD_HEIGHT);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.similarCamps.count) {
        // animate the cell user tapped on
        
        // TODO: Figure out a way to display camp previews
        // Problem: LauncherNavigationController isn't the parent
        
        NSError *error;
        Camp *campAtIndex = [[Camp alloc] initWithDictionary:self.similarCamps[indexPath.row] error:&error];
        
        if (!error) {
            [Launcher openCamp:campAtIndex];
        }
    }
}

- (NSArray *)colorsForConfettiArea:(L360ConfettiArea *)confettiArea {
    NSMutableArray *arrayOfUIColors = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < colors.count; i++) {
        UIColor *color = colors[i];
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

- (void)showImagePicker {
    BFAlertController *imagePickerOptions = [BFAlertController alertControllerWithTitle:@"Set Camp Picture" message:nil preferredStyle:BFAlertControllerStyleActionSheet];
    
    BFAlertAction *takePhoto = [BFAlertAction actionWithTitle:@"Take Photo" style:BFAlertActionStyleDefault handler:^{
        [self takePhotoForProfilePicture:nil];
    }];
    [imagePickerOptions addAction:takePhoto];
    
    BFAlertAction *chooseFromLibrary = [BFAlertAction actionWithTitle:@"Choose from Library" style:BFAlertActionStyleDefault handler:^{
        [self chooseFromLibraryForProfilePicture:nil];
    }];
    [imagePickerOptions addAction:chooseFromLibrary];
    
    BFAlertAction *cancel = [BFAlertAction actionWithTitle:@"Cancel" style:BFAlertActionStyleCancel handler:nil];
    [imagePickerOptions addAction:cancel];
    
    [self presentViewController:imagePickerOptions animated:true completion:nil];
}


- (void)takePhotoForProfilePicture:(id)sender {
    NSString *mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    if (authStatus == AVAuthorizationStatusAuthorized) {
        [self openCamera];
    }
    else if (authStatus == AVAuthorizationStatusDenied ||
             authStatus == AVAuthorizationStatusRestricted) {
        // denied
        [self showNoCameraAccess];
    }
    else if (authStatus == AVAuthorizationStatusNotDetermined) {
        // not determined?!
        [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
            if (granted){
                NSLog(@"Granted access to %@", mediaType);
                [self openCamera];
            }
            else {
                NSLog(@"Not granted access to %@", mediaType);
                [self showNoCameraAccess];
            }
        }];
    }
}
- (void)openCamera {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[Launcher topMostViewController] presentViewController:picker animated:YES completion:nil];
    });
}
- (void)showNoCameraAccess {
    BFAlertController *actionSheet = [BFAlertController alertControllerWithTitle:@"Allow Bonfire to access your camera" message:@"To allow Bonfire to access your camera, go to Settings > Privacy > Camera > Set Bonfire to ON" preferredStyle:BFAlertControllerStyleAlert];

    BFAlertAction *openSettingsAction = [BFAlertAction actionWithTitle:@"Open Settings" style:BFAlertActionStyleDefault handler:^{
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
    }];
    [actionSheet addAction:openSettingsAction];

    BFAlertAction *closeAction = [BFAlertAction actionWithTitle:@"Close" style:BFAlertActionStyleCancel handler:nil];
    [actionSheet addAction:closeAction];
    [[Launcher topMostViewController] presentViewController:actionSheet animated:true completion:nil];
}

- (void)chooseFromLibraryForProfilePicture:(id)sender {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        switch (status) {
            case PHAuthorizationStatusAuthorized: {
                NSLog(@"PHAuthorizationStatusAuthorized");
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
                    picker.delegate = self;
                    picker.allowsEditing = NO;
                    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                    [[Launcher topMostViewController] presentViewController:picker animated:YES completion:nil];
                });
                
                break;
            }
            case PHAuthorizationStatusDenied:
            case PHAuthorizationStatusNotDetermined:
            {
                NSLog(@"PHAuthorizationStatusDenied");
                // confirm action
                dispatch_async(dispatch_get_main_queue(), ^{
                    BFAlertController *actionSheet = [BFAlertController alertControllerWithTitle:@"Allow Bonfire to access your phtoos" message:@"To allow Bonfire to access your photos, go to Settings > Privacy > Camera > Set Bonfire to ON" preferredStyle:BFAlertControllerStyleAlert];

                    BFAlertAction *openSettingsAction = [BFAlertAction actionWithTitle:@"Open Settings" style:BFAlertActionStyleDefault handler:^{
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
                    }];
                    [actionSheet addAction:openSettingsAction];
                
                    BFAlertAction *closeAction = [BFAlertAction actionWithTitle:@"Close" style:BFAlertActionStyleCancel handler:nil];
                    [actionSheet addAction:closeAction];
                    [[Launcher topMostViewController] presentViewController:actionSheet animated:true completion:nil];
                });

                break;
            }
            case PHAuthorizationStatusRestricted: {
                NSLog(@"PHAuthorizationStatusRestricted");
                break;
            }
        }
    }];
}

// Crop image has been canceled.
- (void)imageCropViewControllerDidCancelCrop:(RSKImageCropViewController *)controller
{
    [controller.navigationController dismissViewControllerAnimated:YES completion:nil];
    [self takePhotoForProfilePicture:nil];
}

// The original image has been cropped. Additionally provides a rotation angle used to produce image.
- (void)imageCropViewController:(RSKImageCropViewController *)controller
                   didCropImage:(UIImage *)croppedImage
                  usingCropRect:(CGRect)cropRect
                  rotationAngle:(CGFloat)rotationAngle
{
    // userProfilePictureContainerBlock
    
    NSInteger profilePictureStep = [self getIndexOfStepWithId:@"camp_picture"];
    UIView *profilePictureView = self.steps[profilePictureStep][@"block"];
    profilePictureView.tag = 1;
    
    UIImageView *profilePictureImageView = [profilePictureView viewWithTag:10];
    profilePictureImageView.image = croppedImage;
    
    [controller.navigationController dismissViewControllerAnimated:YES completion:nil];
    
    [self enableNextButton];
    
    [controller.navigationController dismissViewControllerAnimated:YES completion:nil];
}

// The original image will be cropped.
- (void)imageCropViewController:(RSKImageCropViewController *)controller
                  willCropImage:(UIImage *)originalImage
{
    // Use when `applyMaskToCroppedImage` set to YES.
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    // output image
    UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
    
    RSKImageCropViewController *imageCropVC = [[RSKImageCropViewController alloc] initWithImage:chosenImage];
    imageCropVC.delegate = self;
    imageCropVC.dataSource = self;
    imageCropVC.cropMode = RSKImageCropModeCustom;
    
    // move the cancel and choose buttons up
    UIEdgeInsets safeAreaInsets = [UIApplication sharedApplication].keyWindow.safeAreaInsets;
    imageCropVC.cancelButton.transform = CGAffineTransformMakeTranslation(0, -1 * safeAreaInsets.bottom);
    imageCropVC.chooseButton.transform = CGAffineTransformMakeTranslation(0, -1 * safeAreaInsets.bottom);
    
    [picker pushViewController:imageCropVC animated:YES];
}
- (CGRect)imageCropViewControllerCustomMaskRect:(RSKImageCropViewController *)controller
{
    CGSize aspectRatio = CGSizeMake(1, 1);
    
    CGFloat viewWidth = CGRectGetWidth(controller.view.frame);
    CGFloat viewHeight = CGRectGetHeight(controller.view.frame);
    
    CGFloat maskWidth;
    if ([controller isPortraitInterfaceOrientation]) {
        maskWidth = viewWidth;
    } else {
        maskWidth = viewHeight;
    }
    
    CGFloat maskHeight;
    do {
        maskHeight = maskWidth * aspectRatio.height / aspectRatio.width;
        maskWidth -= 1.0f;
    } while (maskHeight != floor(maskHeight));
    maskWidth += 1.0f;
    
    CGSize maskSize = CGSizeMake(maskWidth * .75f, maskHeight * .75);
    
    NSLog(@"maskSize(%f, %f)", maskSize.width, maskSize.height);
    
    CGRect maskRect = CGRectMake((viewWidth - maskSize.width) * 0.5f,
                                 (viewHeight - maskSize.height) * 0.5f,
                                 maskSize.width,
                                 maskSize.height);
    
    return maskRect;
}
- (UIBezierPath *)imageCropViewControllerCustomMaskPath:(RSKImageCropViewController *)controller {
    CGFloat circleRadius = controller.maskRect.size.width * .5;
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:controller.maskRect
                                               byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                     cornerRadii:CGSizeMake(circleRadius, circleRadius)];
    return path;
}
// Returns a custom rect in which the image can be moved.
- (CGRect)imageCropViewControllerCustomMovementRect:(RSKImageCropViewController *)controller
{
    if (controller.rotationAngle == 0) {
        return controller.maskRect;
    } else {
        CGRect maskRect = controller.maskRect;
        CGFloat rotationAngle = controller.rotationAngle;
        
        CGRect movementRect = CGRectZero;
        
        movementRect.size.width = CGRectGetWidth(maskRect) * fabs(cos(rotationAngle)) + CGRectGetHeight(maskRect) * fabs(sin(rotationAngle));
        movementRect.size.height = CGRectGetHeight(maskRect) * fabs(cos(rotationAngle)) + CGRectGetWidth(maskRect) * fabs(sin(rotationAngle));
        
        movementRect.origin.x = CGRectGetMinX(maskRect) + (CGRectGetWidth(maskRect) - CGRectGetWidth(movementRect)) * 0.5f;
        movementRect.origin.y = CGRectGetMinY(maskRect) + (CGRectGetHeight(maskRect) - CGRectGetHeight(movementRect)) * 0.5f;
        
        movementRect.origin.x = floor(CGRectGetMinX(movementRect));
        movementRect.origin.y = floor(CGRectGetMinY(movementRect));
        movementRect = CGRectIntegral(movementRect);
        
        return movementRect;
    }
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
