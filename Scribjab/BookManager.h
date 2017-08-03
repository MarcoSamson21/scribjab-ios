//
//  CreateBookManager.h
//  Scribjab
//
//  Created by Gladys Tang on 12-09-26.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Book.h"
#import "BookPage.h"
#import "Language.h"

static NSString * const BOOK_TITLE_1_AUDIO_FILENAME=@"voiceTitle1.wav";
static NSString * const BOOK_TITLE_2_AUDIO_FILENAME=@"voiceTitle2.wav";
static NSString * const BOOK_TITLE_1_AUDIO_FILENAME_MP3=@"voiceTitle1.mp3";
static NSString * const BOOK_TITLE_2_AUDIO_FILENAME_MP3=@"voiceTitle2.mp3";

static NSString * const BOOK_DESC_1_AUDIO_FILENAME=@"voice1.wav";
static NSString * const BOOK_DESC_2_AUDIO_FILENAME=@"voice2.wav";
static NSString * const BOOK_DESC_1_AUDIO_FILENAME_MP3=@"voice1.mp3";
static NSString * const BOOK_DESC_2_AUDIO_FILENAME_MP3=@"voice2.mp3";

static NSString * const BOOK_TITLE_1_AUDIO_ZIP = @"voiceTitle1.zip";
static NSString * const BOOK_TITLE_2_AUDIO_ZIP = @"voiceTitle2.zip";
static NSString * const BOOK_DESC_1_AUDIO_ZIP = @"voice1.zip";
static NSString * const BOOK_DESC_2_AUDIO_ZIP = @"voice2.zip";
static NSString * const BOOK_IMAGE_FILENAME=@"image.png";
static NSString * const BOOK_THUMBNAIL_FILENAME=@"thumb.png";
static int const BOOK_THUMBNAIL_WIDTH=180;
static int const BOOK_THUMBNAIL_HEIGHT=200;
static int const BOOK_PAGE_THUMBNAIL_WIDTH=150;
static int const BOOK_PAGE_THUMBNAIL_HEIGHT=100;
static int const PUSH_Y_COOD_BY_FOR_KEYBOARD=40;
//static int const PUSH_Y_COOD_BY_FOR_AUDIO=90;

static NSString * const BOOK_PAGE_TEXT_1_AUDIO_FILENAME=@"voice1.wav";
static NSString * const BOOK_PAGE_TEXT_2_AUDIO_FILENAME=@"voice2.wav";
static NSString * const BOOK_PAGE_TEXT_1_AUDIO_ZIP = @"voice1.zip";
static NSString * const BOOK_PAGE_TEXT_2_AUDIO_ZIP = @"voice2.zip";
static NSString * const BOOK_PAGE_TEXT_1_AUDIO_FILENAME_MP3=@"voice1.mp3";
static NSString * const BOOK_PAGE_TEXT_2_AUDIO_FILENAME_MP3=@"voice2.mp3";

//static NSString * const BOOK_PAGE_TEXT_1_AUDIO_FILENAME=@"text1.m4a";
//static NSString * const BOOK_PAGE_TEXT_2_AUDIO_FILENAME=@"text2.m4a";
static NSString * const BOOK_PAGE_IMAGE_FILENAME=@"image.png";
static NSString * const BOOK_PAGE_THUMBNAIL_FILENAME=@"thumb.png";

@interface BookManager : NSObject

+ (NSString *) getBookStorageAbsPath;
+ (NSString *) getBookItemAbsPath:(id)bookItem fileName:(NSString *)fileName;
+ (BOOL)createDirIfNotExist:(id)bookItem;
+ (void)saveImage: (UIImage*)image item:(id)bookItem filename:(NSString *)filename;
+ (NSData *)jsonBookPagesRepresentation:(NSOrderedSet *)bookPages;
+ (NSData *)jsonBookRepresentation:(Book *)book;

+ (Book *)getNewBookInstance:(User *)user;
+ (void)saveBook:(Book *)currentBook;
+ (void)deleteBook:(Book *)currentBook;
+ (void) deleteDownloadedBookButKeepPreview:(Book*)book;
//- (NSArray *)getAllBooks:(User *)user;
+ (void)sortUserBooks:(User *)user;

+ (BookPage *)getNewBookPageInstance;
+ (void)saveBookPage:(BookPage *)currentBookPage;
+ (void)deleteBookPage:(BookPage *)currentBookPage;

+ (void)updateBookPendingStatus:(NSDictionary *) bookList;

+ (void)printBookDetails:(Book *)book;

// check which books in the specified list of IDs already exists in the CoreData. Return only IDs of the missing books what need to be downloaded.
+ (NSArray*) getMissingRemoteIdsFromListOfRemoteIds:(NSArray*) remoteIds;
+ (NSArray*) booksByRemoteIds:(NSArray*) remoteIds;                      // Get all books in core data specified by Remote IDs
+ (Book *) getBookByRemoteId:(int) remoteId;
+ (void) addOrUpdateBookPreviews:(NSArray *)bookPreviewList;
+ (void) addOrUpdateBookPreviewsWithGroup:(NSArray *)bookPreviewList;
+ (NSArray *) getDownloadedBooks;
+ (NSString *) getDownloadedBooksRemoteIds;     // return a comma-delimited list of downloaded book ids, or "none" if no books have been downloaded

+ (BookPage *) getPageByRemoteId:(int) remoteId;
+ (void) addOrUpdateDownloadedBookPagesWithoutFilesWithData:(NSArray *)pageList book:(Book*)book;
+ (void) deleteBookPreviewsLastViewdBefore:(NSDate*)date;

+ (void) flagBooksInTheList:(NSArray*) bookRemoteIds byUser:(User*)user;
+ (void) likeBooksInTheList:(NSArray*) bookRemoteIds byUser:(User*)user;
+ (void) linkBooksToGroups:(NSArray*) bookIdGroupIdTuples;
@end
