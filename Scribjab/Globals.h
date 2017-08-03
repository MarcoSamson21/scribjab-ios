//
//  Globals.h
//  Scribjab
//
//  Created by Oleg Titov on 12-08-24.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

// Status Codes
FOUNDATION_EXPORT NSString * const REQUEST_RESPONSE_OK;
FOUNDATION_EXPORT NSString * const REQUEST_RESPONSE_FAIL;
FOUNDATION_EXPORT NSString * const REQUEST_RESPONSE_VALIDATION_FAIL;
FOUNDATION_EXPORT NSString * const REQUEST_RESPONSE_AUTH_FAIL;
FOUNDATION_EXPORT NSString * const REQUEST_RESPONSE_AUTH_OK;
FOUNDATION_EXPORT NSString * const REQUEST_RESPONSE_AUTH_FAIL_CODE;

static NSString * const AUTH_FAIL_CODE_BAD_CREDENTIALS     = @"1";
static NSString * const AUTH_FAIL_CODE_DISABLED_ACCOUNT    = @"2";
static NSString * const AUTH_FAIL_CODE_NOT_ACTIVATED       = @"3";
static NSString * const AUTH_FAIL_CODE_ACCOUNT_NOT_FOUNT   = @"4";
static NSString * const AUTH_FAIL_CODE_OTHER               = @"5";

// Custom headers
FOUNDATION_EXPORT NSString * const REQUEST_HEADER_NAME_IPAD_ID;
FOUNDATION_EXPORT NSString * const REQUEST_HEADER_VALUE_IPAD_ID;


// MISC SETTINGS
static const int BOOK_PREVIEW_LAST_ACCESS_AGE_FOR_CLEANUP_IN_DAYS   =   30;         // how long ago should the preview have been accessed to be a candidate for removal.
static const int BROWSE_BOOK_REFRESH_FREQUENCY_IN_MINUTES           =   10;         // How often BrowseBook section will contact web server to refreh its book previews
static const int DOWNLOADED_BOOKS_REFRESH_FREQUENCY_IN_MINUTES      =   15;         // How often to check for new comments and comments' likes and flags for downloaded books.
static const int LANGUAGE_REFRESH_FREQUENCY_IN_MINUTES              =   60*24*7;    // How often to check refresh languages in the database from the server for new comments and comments' likes and flags for downloaded books.


// GOOGLE ANALYTICS TRACKING NUMBER
static NSString * const GOOGLE_ANALYTICS_TRACKING_NUMBER   = @"UA-47052319-1";
static BOOL const GOOGLE_ANALYTICS_DRY_RUN   = NO;

// URLs
// The URL of the server
FOUNDATION_EXPORT NSString * const URL_SERVER_BASE_WEB_URL;
FOUNDATION_EXPORT NSString * const URL_SERVER_BASE_URL;
FOUNDATION_EXPORT NSString * const URL_SERVER_BASE_URL_AUTH;

// Login
FOUNDATION_EXPORT NSString * const URL_LOGIN;
FOUNDATION_EXPORT NSString * const URL_CHECK_LOGIN;

// User Requests
FOUNDATION_EXPORT NSString * const URL_USER_IS_USERNAME_EXISTS;
FOUNDATION_EXPORT NSString * const URL_USER_ADD;
FOUNDATION_EXPORT NSString * const URL_USER_UPDATE_AVATAR;
FOUNDATION_EXPORT NSString * const URL_USER_GET_USER_AND_DATA_BY_NAME;
FOUNDATION_EXPORT NSString * const URL_USER_LOGIN_TROUBLE_RESET_REQUEST;
FOUNDATION_EXPORT NSString * const URL_USER_UPDATE;
FOUNDATION_EXPORT NSString * const URL_USER_GET_LOGGED_IN_USER_RELATED_DATA;
FOUNDATION_EXPORT NSString * const URL_USER_DELETE_ACCOUNT;

// UserType Requests
FOUNDATION_EXPORT NSString * const URL_USERTYPE_GET_ALL;
FOUNDATION_EXPORT NSString * const URL_USERTYPE_GET_CHILD;
FOUNDATION_EXPORT NSString * const URL_USERTYPE_GET_ADULT;
FOUNDATION_EXPORT NSString * const URL_USERTYPE_GET_TEACHER;

// Language Requests
FOUNDATION_EXPORT NSString * const URL_LANGUAGE_GET_ALL;
FOUNDATION_EXPORT NSString * const URL_LANGUAGE_GET_BY_ID_LIST;

// AgeGroup Requests
FOUNDATION_EXPORT NSString * const URL_AGEGROUP_GET_ALL ;

// Group Membership
FOUNDATION_EXPORT NSString * const URL_USERGROUP_MEMBERSHIP ;

// Publish Book
FOUNDATION_EXPORT NSString * const URL_ADD_BOOK_FOR_PUBLISH;
FOUNDATION_EXPORT NSString * const URL_ADD_BOOKPAGES_FOR_PUBLISH;
FOUNDATION_EXPORT NSString * const URL_BOOK_DOWNLOAD_AUDIO_FILES;
FOUNDATION_EXPORT NSString * const URL_BOOK_UPLOAD_FILE;

//Delete Book
FOUNDATION_EXPORT NSString * const URL_DELETE_BOOK;

// Browse Book
//FOUNDATION_EXPORT NSString * const URL_GET_NEW_AND_POPULAR_BOOK_IDS;                  //DEPRECATED
//FOUNDATION_EXPORT NSString * const URL_GET_NEW_AND_POPULAR_BOOK_PREVIEW_DETAILS;      // DEPRECATED
FOUNDATION_EXPORT NSString * const URL_BROWSE_DOWNLOAD_BOOK_PREVIEWS;
FOUNDATION_EXPORT NSString * const URL_REFRESH_DOWNLOADED_BOOK_DATA_AND_USER;
FOUNDATION_EXPORT NSString * const URL_SEARCH_BOOKS;
FOUNDATION_EXPORT NSString * const URL_GET_RECENTLY_PUBLISHED_BOOK_IDS;
FOUNDATION_EXPORT NSString * const URL_GET_ALL_SORTED_BY_POPULARITY_AND_SHUFFLED_BOOK_IDS;

// Download Book
FOUNDATION_EXPORT NSString * const URL_DOWNLOAD_BOOK_DATA_WITHOUT_FILES;
FOUNDATION_EXPORT NSString * const URL_DOWNLOAD_BOOK_AUDIO_FILES;
FOUNDATION_EXPORT NSString * const URL_DOWNLOAD_BOOK_IMAGE_FILES;
FOUNDATION_EXPORT NSString * const URL_DOWNLOAD_BOOK_PREVIEWS;

//MY Library
FOUNDATION_EXPORT NSString * const URL_GET_MY_BOOK_STATUS_FOR_PENDING_APPROVAL;
FOUNDATION_EXPORT NSString * const URL_GET_MY_BOOK_AND_FAVORITE_BOOK_IDS;
FOUNDATION_EXPORT NSString * const URL_GET_MY_BOOK_AND_FAVORITE_BOOK_PREVIEW_DETAILS;

// Read Book
FOUNDATION_EXPORT NSString * const URL_FLAG_BOOK;
FOUNDATION_EXPORT NSString * const URL_LIKE_BOOK;
FOUNDATION_EXPORT NSString * const URL_UNLIKE_BOOK;
FOUNDATION_EXPORT NSString * const URL_ADD_COMMENT;
FOUNDATION_EXPORT NSString * const URL_DELETE_COMMENT;
FOUNDATION_EXPORT NSString * const URL_FLAG_COMMENT;
FOUNDATION_EXPORT NSString * const URL_BOOK_GET_WEB_URL;

// Product Tour
FOUNDATION_EXPORT NSString * const URL_ABOUT_TERMS_OF_USE;
FOUNDATION_EXPORT NSString * const URL_ABOUT_TOUR;
FOUNDATION_EXPORT NSString * const URL_ABOUT_ABOUT;
FOUNDATION_EXPORT NSString * const URL_ABOUT_TEACHER;
FOUNDATION_EXPORT NSString * const URL_ABOUT_CREDITS;
