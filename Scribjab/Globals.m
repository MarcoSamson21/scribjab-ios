//
//  Globals.m
//  Scribjab
//
//  Created by Oleg Titov on 12-08-24.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Globals.h"

// ======================================================================================================================================
// ======================================================================================================================================
// HEADERS

// Status Codes
NSString * const REQUEST_RESPONSE_OK                = @"OK";
NSString * const REQUEST_RESPONSE_FAIL              = @"Fail";
NSString * const REQUEST_RESPONSE_VALIDATION_FAIL   = @"ValidationFail";
NSString * const REQUEST_RESPONSE_AUTH_FAIL         = @"AuthFail";
NSString * const REQUEST_RESPONSE_AUTH_OK           = @"AuthOK";
NSString * const REQUEST_RESPONSE_AUTH_FAIL_CODE    = @"AuthFailCode";

// Custom headers
NSString * const REQUEST_HEADER_NAME_IPAD_ID        = @"Scribjab-Mobile-ID-Code";
NSString * const REQUEST_HEADER_VALUE_IPAD_ID       = @"d0e3b0f4-8526-4a46-af54-1ba963333273";


// ======================================================================================================================================
// ======================================================================================================================================
// URLs

// The URL of the server
//NSString * const URL_SERVER_BASE_WEB_URL    = @"http://142.58.56.152:8080/scribjab/%@/m/";      // no auth required   . param = locale ('en','fr')
//NSString * const URL_SERVER_BASE_URL        = @"http://142.58.56.152:8080/scribjab/ws/mobile/";      // no auth required
//NSString * const URL_SERVER_BASE_URL_AUTH   = @"http://142.58.56.152:8080/scribjab/ws/mobile/auth/";    // authentication required
//NSString * const URL_SERVER_BASE_WEB_URL    = @"http://edb7520oleg1.tlc.sfu.ca:8080/%@/m/";      // no auth required   . param = locale ('en','fr')
//NSString * const URL_SERVER_BASE_URL        = @"http://edb7520oleg1.tlc.sfu.ca:8080/ws/mobile/";      // no auth required
//NSString * const URL_SERVER_BASE_URL_AUTH   = @"http://edb7520oleg1.tlc.sfu.ca:8080/ws/mobile/auth/";    // authentication required
NSString * const URL_SERVER_BASE_WEB_URL    = @"http://www.scribjab.com/%@/m/";      // no auth required   . param = locale ('en','fr')
NSString * const URL_SERVER_BASE_URL        = @"http://www.scribjab.com/ws/mobile/";      // no auth required
NSString * const URL_SERVER_BASE_URL_AUTH   = @"http://www.scribjab.com/ws/mobile/auth/";    // authentication required

// Login
NSString * const URL_LOGIN                          = @"login/";
NSString * const URL_CHECK_LOGIN                    = @"checkIfLoggedIn";

// User Requests
NSString * const URL_USER_IS_USERNAME_EXISTS            = @"user/isUserNameExists/";
NSString * const URL_USER_ADD                           = @"user/add";
NSString * const URL_USER_UPDATE_AVATAR                 = @"user/updateAvatar";
NSString * const URL_USER_GET_USER_AND_DATA_BY_NAME     = @"user/getUserAndLoginDataByNameAndBookIds/"; // userName, bookIds (comma-separated)
NSString * const URL_USER_LOGIN_TROUBLE_RESET_REQUEST   = @"user/login/requestReset";
NSString * const URL_USER_UPDATE                        = @"user/update";
NSString * const URL_USER_GET_LOGGED_IN_USER_RELATED_DATA = @"user/getLoggedInUserRelatedData/";    // userId, bookIds comma separated
NSString * const URL_USER_DELETE_ACCOUNT                = @"user/delete";

// UserType Requests
NSString * const URL_USERTYPE_GET_ALL               = @"userType/getAll";
NSString * const URL_USERTYPE_GET_CHILD             = @"userType/getTypeForChild";
NSString * const URL_USERTYPE_GET_ADULT             = @"userType/getTypeForAdult";
NSString * const URL_USERTYPE_GET_TEACHER           = @"userType/getTypeForTeacher";

// Language Requests
NSString * const URL_LANGUAGE_GET_ALL               = @"language/getAll";
NSString * const URL_LANGUAGE_GET_BY_ID_LIST        = @"language/getByIdList/";

// AgeGroup Requests
NSString * const URL_AGEGROUP_GET_ALL               = @"ageGroup/getAll";

// Group Membership
NSString * const URL_USERGROUP_MEMBERSHIP           = @"groupUserMembership/getByUserId/";

//Publish book
NSString * const URL_ADD_BOOK_FOR_PUBLISH           = @"book/addBookForPublish/";
NSString * const URL_ADD_BOOKPAGES_FOR_PUBLISH      = @"book/addBookPagesForPublish/";
NSString * const URL_BOOK_DOWNLOAD_AUDIO_FILES      = @"book/getBookAudioZip/";
NSString * const URL_BOOK_UPLOAD_FILE               = @"book/uploadFile/"; //uploadFile/bookId/{0}|bookPageId/filename

//My Library
NSString * const URL_GET_MY_BOOK_STATUS_FOR_PENDING_APPROVAL = @"book/getUpdatesForPendingApprovalBooks/";//remoteIds.
NSString * const URL_GET_MY_BOOK_AND_FAVORITE_BOOK_IDS =@"myLibrary/getMyAndFavouriteAndGroupBookIds/"; //userId.
NSString * const URL_GET_MY_BOOK_AND_FAVORITE_BOOK_PREVIEW_DETAILS =@"myLibrary/getMyBookAndFavouriteBookPreviewDetails/";

//Delete book
NSString * const URL_DELETE_BOOK                    = @"book/deleteBook/";

//Browse book
//NSString * const URL_GET_NEW_AND_POPULAR_BOOK_IDS               = @"browse/getNewAndPopularBookIds";
//NSString * const URL_GET_NEW_AND_POPULAR_BOOK_PREVIEW_DETAILS   = @"browse/getNewAndPopularBookPreviewDetails/";  // books/users/languages
NSString * const URL_BROWSE_DOWNLOAD_BOOK_PREVIEWS              = @"browse/downloadBookPreviews/"; // books/users/languages
NSString * const URL_REFRESH_DOWNLOADED_BOOK_DATA_AND_USER      = @"browse/getDownloadedBookAndLoggedInUserRelatedData/";   // userId (can be for "no user") / bookId list
NSString * const URL_SEARCH_BOOKS                               = @"search";    // POST: Get book IDs for:  ageGroupId / 1st lang id / 2nd lang id / keywords (in body of the request)
NSString * const URL_GET_RECENTLY_PUBLISHED_BOOK_IDS            = @"browse/getRecentlyPublishedBookIds";
NSString * const URL_GET_ALL_SORTED_BY_POPULARITY_AND_SHUFFLED_BOOK_IDS = @"browse/getAllSortedByPopularityAndShuffledBookIds/";  //{startIndex}/{count}";


// Browse and Download Book
NSString * const URL_DOWNLOAD_BOOK_DATA_WITHOUT_FILES       = @"browse/downloadBookAndPagesWithoutImagesAndAudioForPreviewBook/";     // bookId
NSString * const URL_DOWNLOAD_BOOK_AUDIO_FILES              = @"browse/downloadBookAudio/";                     // bookId
NSString * const URL_DOWNLOAD_BOOK_IMAGE_FILES              = @"browse/downloadBookImages/";                    // bookId
NSString * const URL_DOWNLOAD_BOOK_PREVIEWS                 = @"browse/downloadBookPreviews/%@/%@/%@";          // bookIDs/userIDs/languageIDs


// Read Book
NSString * const URL_FLAG_BOOK              = @"book/flagForViolation/";            // book ID. FlagNote is in the body. POST.
NSString * const URL_LIKE_BOOK              = @"book/likeToFavorites/";             // book ID. POST.
NSString * const URL_UNLIKE_BOOK            = @"book/unlikeFromFavorites/";         // book ID. POST.
NSString * const URL_ADD_COMMENT            = @"book/%d/addComment";                // bookID. Post method.
NSString * const URL_DELETE_COMMENT         = @"comment/%d/deleteComment";          // commentID. DELETE method.
NSString * const URL_FLAG_COMMENT           = @"comment/%d/flagComment";            // commentID. FLAG method.
NSString * const URL_BOOK_GET_WEB_URL       = @"book/getBookWebURL/%@";             // Get book's URL on the web site for facebook sharing, using remote ID

// ======================================================================================================================================
// ======================================================================================================================================
// Product Tour
NSString * const URL_ABOUT_TERMS_OF_USE   = @"about/terms.html";
NSString * const URL_ABOUT_TOUR           = @"about/tour.html";
NSString * const URL_ABOUT_ABOUT          = @"about/about.html";
NSString * const URL_ABOUT_TEACHER        = @"about/teacher.html";
NSString * const URL_ABOUT_CREDITS        = @"about/credits.html";;