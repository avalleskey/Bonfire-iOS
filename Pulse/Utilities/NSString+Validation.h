//
//  NSString+Validation.h
//  Pulse
//
//  Created by Austin Valleskey on 12/12/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Regexer/Regexer.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (Validation)

// Define max and min lengths
enum
{
    MAX_EMAIL_LENGTH = 254,
    MIN_PASSWORD_LENGTH = 6,
    MAX_PASSWORD_LENGTH = 64,
    MAX_USER_DISPLAY_NAME_LENGTH = 40,
    MAX_USER_USERNAME_LENGTH = 15,
    MAX_USER_BIO_LENGTH = 150,
    MAX_USER_LOCATION_LENGTH = 30,
    MAX_USER_WEBSITE_LENGTH = 100,
    MAX_ROOM_TITLE_LENGTH = 30,
    MAX_ROOM_TAG_LENGTH = 30,
    MAX_ROOM_DESC_LENGTH = 150
};

typedef enum {
    BFValidationTypeFail = 0,
    BFValidationTypeSoftSuccess = 1, // success but too short
    BFValidationTypeSuccess = 2 // success on all checks
} BFValidationType;

typedef enum {
    BFValidationErrorNone = 0,
    BFValidationErrorTooShort = 1,
    BFValidationErrorTooLong = 2,
    BFValidationErrorContainsInvalidCharacters = 3,
    BFValidationErrorContainsInvalidWords = 4,
    BFValidationErrorInvalidEmail = 5,
    BFValidationErrorInvalidURL = 6
} BFValidationError;

- (BFValidationError)validateBonfireEmail;
- (BFValidationError)validateBonfirePassword;
- (BFValidationError)validateBonfireDisplayName;
- (BFValidationError)validateBonfireUsername;
- (BFValidationError)validateBonfireBio;
- (BFValidationError)validateBonfireLocation;
- (BFValidationError)validateBonfireWebsite;

- (BFValidationError)validateBonfireRoomTitle;
- (BFValidationError)validateBonfireRoomTag;
- (BFValidationError)validateBonfireRoomDescription;

- (NSArray *)rangesForUsernameMatches;
- (NSArray *)rangesForRoomTagMatches;
- (NSArray *)rangesForLinkMatches;

@end

NS_ASSUME_NONNULL_END
