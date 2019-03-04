//
//  SmartList.m
//  Pulse
//
//  Created by Austin Valleskey on 12/28/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "SmartList.h"

@implementation SmartList

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                                                                  @"identifier": @"id"
                                                                  }];
}

@end

@implementation SmartListSection

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                                                                  @"identifier": @"id"
                                                                  }];
}

+ (BOOL)propertyIsOptional:(NSString*)propertyName
{
    return YES; // all are optional
}

@end

@implementation SmartListSectionRow

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                                                                  @"identifier": @"id"
                                                                  }];
}

+ (BOOL)propertyIsOptional:(NSString*)propertyName
{
    NSArray *optionalProperties = @[@"destructive", @"push", @"present"];
    if ([optionalProperties containsObject:propertyName]) return YES;
    return NO;
}

@end

@implementation SmartListSectionRowInput

NSString * const SmartListInputEmailValidation = @"email";
NSString * const SmartListInputUsernameValidation = @"username";
NSString * const SmartListInputDisplayNameValidation = @"display_name";
NSString * const SmartListInputPasswordValidation = @"password";
NSString * const SmartListInputRoomNameValidation = @"room_name";
NSString * const SmartListInputRoomDescriptionValidation = @"room_description";

NSString * const SmartListInputDefaultKeyboard = @"default";
NSString * const SmartListInputEmailKeyboard = @"email";

+ (BOOL)propertyIsOptional:(NSString*)propertyName
{
    NSArray *optionalProperties = @[@"sensitive"];
    if ([optionalProperties containsObject:propertyName]) return YES;
    return NO;
}

@end
