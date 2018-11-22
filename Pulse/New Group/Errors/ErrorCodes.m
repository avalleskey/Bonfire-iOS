//
//  ErrorCodes.m
//  Pulse
//
//  Created by Austin Valleskey on 10/11/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "ErrorCodes.h"

@implementation ErrorCodes

/**
 * Errors 40-49: Authentication/Client error
 */
const NSInteger BAD_AUTHENTICATION    = 40;
const NSInteger OUT_OF_DATE_CLIENT    = 41;
const NSInteger IDENTITY_REQUIRED     = 42;
const NSInteger MISSING_AUTHTOKEN     = 43;
const NSInteger BAD_ORIGIN            = 44;
const NSInteger BAD_ACCESS_TOKEN      = 45;
const NSInteger BAD_REFRESH_TOKEN     = 46;
const NSInteger MISMATCH_TOKEN        = 47;
const NSInteger BAD_REFRESH_LOGIN_REQ = 48;

/**
 * Errors 60-69: Action failure
 */
const NSInteger OPERATION_NOT_PERMITTED = 60;
const NSInteger USER_MISSING_PERMISSION = 61;
const NSInteger RESOURCE_ACTION_FAILURE = 62;
const NSInteger MISSING_PARAMETER       = 63;
const NSInteger INVALID_PARAMETER       = 64;
const NSInteger INVALID_MEDIA           = 65;

/**
 * Errors 70-79: Resource failure
 */
const NSInteger RESOURCE_VALIDITY_FAILURE  = 70;
const NSInteger ROOM_NOT_EXISTS            = 71;
const NSInteger USER_NOT_EXISTS            = 72;
const NSInteger POST_NOT_EXISTS            = 73;
const NSInteger ROOM_INACCESSIBLE_BLOCKED  = 74;
const NSInteger USER_INACCESSIBLE_BLOCKED  = 75;
const NSInteger POST_INACCESSIBLE          = 76;
const NSInteger SEARCH_TOO_COMPLEX         = 77;
const NSInteger RESOURCE_OWNERSHIP_FAILURE = 78;

/**
 * Errors 80-89: User information failure
 */
const NSInteger USER_PASSWORD_REQ_RESET = 80;
const NSInteger USER_PROFILE_SUSPENDED  = 81;
const NSInteger USER_EMAIL_TAKEN        = 82;

/**
 * Errors 90-99: Generic errors
 */
const NSInteger INVALID_HTTP_METHOD = 90;
const NSInteger BAD_API_VERSION     = 91;
// ...
const NSInteger DATABASE_QUERY_ERROR  = 98;
const NSInteger DEFAULT_UNKNOWN_ERROR = 99;

@end
