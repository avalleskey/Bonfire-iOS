//
//  SmartList.h
//  Pulse
//
//  Created by Austin Valleskey on 12/28/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "BFJSONModel.h"
#import "UserListStream.h"
#import "CampListStream.h"

NS_ASSUME_NONNULL_BEGIN

@protocol SmartListSection;
@protocol SmartListSectionRow;

@class SmartList;
@class SmartListSection;
@class SmartListSectionRow;
@class SmartListSectionRowInput;

@interface SmartList : BFJSONModel

@property (nonatomic) NSString <Optional> *identifier;
@property (nonatomic) NSString <Optional> *title;
@property (nonatomic) NSArray <SmartListSection *> <SmartListSection> *sections;

@end

@interface SmartListSection : BFJSONModel

typedef enum {
    SmartListStateEmpty = 0,
    SmartListStateLoading = 1,
    SmartListStateLoaded = 2,
    SmartListStateLoadingMore = 3
} SmartListState;

@property (nonatomic) NSString <Optional> *identifier;
@property (nonatomic) NSString <Optional> *title;
@property (nonatomic) NSString <Optional> *footer;
@property (nonatomic) NSString <Optional> *url;
@property (nonatomic) NSString <Optional> *next_cursor;
@property (nonatomic) SmartListState state;
@property (nonatomic) NSArray <SmartListSectionRow *> <SmartListSectionRow, Optional> *rows;

@property (nonatomic) BOOL cursored;
// if cursored
@property (nonatomic) UserListStream <Optional> *userStream;
@property (nonatomic) CampListStream <Optional> *campStream;
// else
@property (nonatomic) NSMutableArray <Optional> *data;

extern NSString * const SmartListSectionDataTypeUser;
extern NSString * const SmartListSectionDataTypeCamp;
@property (nonatomic) NSString <Optional> *type;

@end

@interface SmartListSectionRow : BFJSONModel

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

@interface SmartListSectionRowInput : BFJSONModel

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
