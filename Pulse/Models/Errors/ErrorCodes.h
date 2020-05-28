//
//  ErrorCodes.h
//  Pulse
//
//  Created by Austin Valleskey on 10/11/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ErrorCodes : NSObject

/**
 * Errors 400-499: Authentication/Client error
 */
extern const NSInteger BAD_AUTHENTICATION;
extern const NSInteger MISSING_ACCESS_TOKEN;
extern const NSInteger PHONE_AUTHCODE_THRESHOLD; // Requested a new AuthCode too soon
extern const NSInteger OUT_OF_DATE_CLIENT;
extern const NSInteger IDENTITY_REQUIRED;
extern const NSInteger BAD_ORIGIN;
extern const NSInteger BAD_ACCESS_TOKEN;
extern const NSInteger BAD_REFRESH_TOKEN;
extern const NSInteger MISMATCH_TOKEN;
extern const NSInteger BAD_REFRESH_LOGIN_REQ;

/**
 * Errors 600-699: Action failure
 */
extern const NSInteger OPERATION_NOT_PERMITTED;
extern const NSInteger USER_MISSING_PERMISSION;
extern const NSInteger RESOURCE_ACTION_FAILURE;
extern const NSInteger MISSING_PARAMETER;
extern const NSInteger INVALID_PARAMETER;
extern const NSInteger INVALID_MEDIA;
extern const NSInteger CAMP_MIN_MEMBERS_VIOLATION;
extern const NSInteger IDENTIFIER_TAKEN;
extern const NSInteger NO_CHANGE_OCCURRED;
extern const NSInteger BAD_MEDIA_COMBINATION;

/**
 * Errors 700-799: Resource failure
 */
extern const NSInteger RESOURCE_VALIDITY_FAILURE;
extern const NSInteger CAMP_NOT_EXISTS;
extern const NSInteger USER_NOT_EXISTS;
extern const NSInteger POST_NOT_EXISTS;
extern const NSInteger LINK_NOT_EXISTS;
extern const NSInteger FRIEND_CODE_NOT_EXISTS;
extern const NSInteger CAMP_INACCESSIBLE_BLOCKED;
extern const NSInteger USER_INACCESSIBLE_BLOCKED;
extern const NSInteger POST_INACCESSIBLE;
extern const NSInteger SEARCH_TOO_COMPLEX;
extern const NSInteger RESOURCE_OWNERSHIP_FAILURE;
extern const NSInteger CAMP_INACCESSIBLE_BLOCKS_THEM;

/**
 * Errors 800-899: User information failure
 */
extern const NSInteger USER_PASSWORD_REQ_RESET;
extern const NSInteger ACTIONER_PROFILE_SUSPENDED;
extern const NSInteger USER_EMAIL_TAKEN;
extern const NSInteger USER_PHONE_TAKEN; // Phone is already registered to a user
extern const NSInteger USER_USERNAME_SUSPENDED;
extern const NSInteger USER_USERNAME_TAKEN;

/**
 * Errors 900-999: Generic errors
 */
extern const NSInteger INVALID_HTTP_METHOD;
extern const NSInteger BAD_API_VERSION;
// ...
extern const NSInteger DATABASE_QUERY_CONFLICT;
extern const NSInteger DATABASE_QUERY_ERROR;
extern const NSInteger DEFAULT_UNKNOWN_ERROR;

@end

@interface NSError (Bonfire)

- (NSInteger)bonfireErrorCode;

@end

NS_ASSUME_NONNULL_END
