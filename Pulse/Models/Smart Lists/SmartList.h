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

@property (nonatomic) NSArray <SmartListSection *> <SmartListSection> *sections;

@end

@interface SmartListSection : JSONModel

@property (nonatomic) NSString *identifier;
@property (nonatomic) NSString <Optional> *title;
@property (nonatomic) NSString <Optional> *footer;
@property (nonatomic) NSArray <SmartListSectionRow *> <SmartListSectionRow> *rows;

@end

@interface SmartListSectionRow : JSONModel

@property (nonatomic) NSString *identifier;
@property (nonatomic) NSString <Optional> *title;
@property (nonatomic) NSString <Optional> *detail;
@property (nonatomic) BOOL destructive; // optional
@property (nonatomic) SmartListSectionRowInput <Optional> *input;
@property (nonatomic) BOOL push; // optional
@property (nonatomic) BOOL present; // optional

@end

@interface SmartListSectionRowInput : JSONModel

extern NSString * const SmartListInputEmailValidation;
extern NSString * const SmartListInputUsernameValidation;
extern NSString * const SmartListInputDisplayNameValidation;
extern NSString * const SmartListInputPasswordValidation;
extern NSString * const SmartListInputRoomNameValidation;
extern NSString * const SmartListInputRoomDescriptionValidation;

extern NSString * const SmartListInputDefaultKeyboard;
extern NSString * const SmartListInputEmailKeyboard;

@property (nonatomic) NSString <Optional> *text;
@property (nonatomic) NSString <Optional> *placeholder;
@property (nonatomic) NSString <Optional> *validation;
@property (nonatomic) NSString <Optional> *keyboard;
@property (nonatomic) BOOL sensitive;

@end

NS_ASSUME_NONNULL_END
