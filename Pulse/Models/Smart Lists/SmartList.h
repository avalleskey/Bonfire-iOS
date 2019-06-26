//
//  SmartList.h
//  Pulse
//
//  Created by Austin Valleskey on 12/28/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "JSONModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol SmartListSection;
@protocol SmartListSectionRow;

@class SmartList;
@class SmartListSection;
@class SmartListSectionRow;
@class SmartListSectionRowInput;

@interface SmartList : JSONModel

@property (nonatomic) NSString <Optional> *identifier;
@property (nonatomic) NSString <Optional> *title;
@property (nonatomic) NSArray <SmartListSection *> <SmartListSection> *sections;

@end

@interface SmartListSection : JSONModel

typedef enum {
    SmartListStateEmpty = 0,
    SmartListStateLoading = 1,
    SmartListStateLoaded = 2
} SmartListState;

@property (nonatomic) NSString <Optional> *identifier;
@property (nonatomic) NSString <Optional> *title;
@property (nonatomic) NSString <Optional> *footer;
@property (nonatomic) NSString <Optional> *url;
@property (nonatomic) NSMutableArray <Optional> *data;
@property (nonatomic) NSString <Optional> *next_cursor;
@property (nonatomic) SmartListState state;
@property (nonatomic) NSArray <SmartListSectionRow *> <SmartListSectionRow, Optional> *rows;

@end

@interface SmartListSectionRow : JSONModel

@property (nonatomic) NSString *identifier;
@property (nonatomic) NSString <Optional> *title;
@property (nonatomic) NSString <Optional> *detail;
@property (nonatomic) BOOL destructive; // optional
@property (nonatomic) SmartListSectionRowInput <Optional> *input;
@property (nonatomic) BOOL push; // optional
@property (nonatomic) BOOL present; // optional
@property (nonatomic) BOOL radio; // optional
@property (nonatomic) BOOL toggle; // optional

@end

@interface SmartListSectionRowInput : JSONModel

extern NSString * const SmartListInputEmailValidation;
extern NSString * const SmartListInputUsernameValidation;
extern NSString * const SmartListInputDisplayNameValidation;
extern NSString * const SmartListInputPasswordValidation;
extern NSString * const SmartListInputCampTitleValidation;
extern NSString * const SmartListInputCampDescriptionValidation;

extern NSString * const SmartListInputDefaultKeyboard;
extern NSString * const SmartListInputEmailKeyboard;

@property (nonatomic) NSString <Optional> *text;
@property (nonatomic) NSString <Optional> *placeholder;
@property (nonatomic) NSString <Optional> *validation;
@property (nonatomic) NSString <Optional> *keyboard;
@property (nonatomic) BOOL sensitive;

@end

NS_ASSUME_NONNULL_END
