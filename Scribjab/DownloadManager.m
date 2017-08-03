//
//  DownloadManager
//  Scribjab
//
//  Created by Oleg Titov on 12-11-23.
//
//
#import "DownloadManager.h"
#import "NSURLConnectionWithID.h"
#import "URLRequestUtilities.h"
#import "CommonMessageBoxes.h"
#import "Globals.h"
#import "LanguageManager.h"
#import "UserManager.h"
#import "BookManager.h"
#import "UserGroupManager.h"
#import "CommentManager.h"
#import "ZipArchive.h"
#import "LoginRegistrationManager.h"
#import "DocumentHandler.h"

// struct to do faster delegate introspection
struct DelegateRespondsTo
{
    unsigned int downloadCompletedSuccessfullyWithReturnedData:1;
    unsigned int downloadFailed:1;
    unsigned int downloadedTotalSize:1;
    unsigned int downloadedCancelled:1;
};

// **************************************************************************************************************************************
// **************************************************************************************************************************************

// private connection data class
@interface _DownloadConnectionData : NSObject

@property int stepNumber;
@property (nonatomic, strong) Book * book;
@property (nonatomic, weak) id<DownloadManagerDelegate> delegate;
@property struct DelegateRespondsTo delegateRespondsTo;
@property (nonatomic, strong) NSMutableData * httpData;
@property (nonatomic) int totalDownloadSizeInKB;

@end

@implementation _DownloadConnectionData

@synthesize stepNumber = _stepNumber;
@synthesize book = _book;
@synthesize delegateRespondsTo = _delegateRespondsTo;
@synthesize delegate = _delegate;
@synthesize totalDownloadSizeInKB = _totalDownloadSizeInKB;

-(id)init
{
    self = [super init];
    if (self)
    {
        _stepNumber = 0;
        _totalDownloadSizeInKB = 0;
        self.httpData = [[NSMutableData alloc] initWithCapacity:1024];
    }
    return self;
}

-(void)setDelegate:(id<DownloadManagerDelegate>)delegate
{
    _delegate = delegate;
    _delegateRespondsTo.downloadCompletedSuccessfullyWithReturnedData   = (unsigned int)[_delegate respondsToSelector:@selector(downloadCompletedSuccessfullyWithReturnedData:withManager:)];
    _delegateRespondsTo.downloadedTotalSize                             = (unsigned int)[_delegate respondsToSelector:@selector(downloadedTotalSize:withManager:)];
    _delegateRespondsTo.downloadFailed                                  = (unsigned int)[_delegate respondsToSelector:@selector(downloadFailed:)];
    _delegateRespondsTo.downloadedCancelled                             = (unsigned int)[_delegate respondsToSelector:@selector(downloadCancelled:)];
}

@end

// **************************************************************************************************************************************
// **************************************************************************************************************************************

static int const CONNECTION_BOOK_ID_LIST = 1;
static int const CONNECTION_BOOK_PREVIEWS = 2;
static int const CONNECTION_REFRESH_BOOK_DATA = 3;
static int const CONNECTION_MY_LIBRARY_BOOK_ID_LIST = 4;
static int const CONNECTION_MY_LIBRARY_BOOK_PREVIEWS = 5;
static int const CONNECTION_BOOK_PREVIEWS_FOR_SPECIFIC_BOOKS = 6;
static int const DOWNLOAD_CONNECTION_MIN_ID = 1000;
static NSInteger _downloadConnectionLastID = DOWNLOAD_CONNECTION_MIN_ID;        // this value will be incremented to keep track of connections and their related data.

@interface DownloadManager()
{
    NSMutableData * _httpPreviewResponseData;
    NSURLConnectionWithID * _connectionBookPreviews;
    NSArray * _popularBookIDs;
    NSArray * _recentBookIDs;
    BOOL _downloadPreviewsCancelled;
    
    NSMutableDictionary * _downloadConnectionsData;            // key: NSURLConnectionWithID.identification, object _DownloadConnectionData object
    struct DelegateRespondsTo _delegateRespondsTo;      // for faster delegate introspection
    
    NSMutableData * _httpRefreshResponseData;
    NSURLConnectionWithID * _connectionRefreshBook;
    
    //for library
    NSArray * _myBookIDs;
    NSArray * _favouriteBooksIDs;
    NSMutableArray * _groupBookIDs;
    NSMutableArray * myGroupBooks;
    User *loginUser;
    
    // for On demand book preview downloads (search)
    NSArray * _previewsForBooksByIDs;
}

// ------ Download previews for books ----
- (void) processBookIdListHTTPResponse;
- (void) processBookPreviewListHTTPResponse;
- (void) passPreviewBooksToDelegate;

// ------ Download Book processing -------

// Book download STEP 1 - get book and pages
- (void) processBookTextDownloadedDataFromHttpResponseForConnection:(NSURLConnectionWithID*)connection connectionData:(_DownloadConnectionData *)cData;
// Book download STEP 2 - get book's and pages' audio files
-(void) processBookDownloadedAudioDataFromHttpResponseForConnection:(NSURLConnectionWithID*)myConn connectionData:(_DownloadConnectionData *)cData;
// Book download STEP 3 - get book's and pages' image files
-(void) processBookDownloadedImageDataFromHttpResponseForConnection:(NSURLConnectionWithID*)myConn connectionData:(_DownloadConnectionData *)cData;
// Book download STEP 4 - get book's related data for logged-in user, like comments likes, flags, groups, etc
-(void) processBookRelatedDataForLoggedInUserFromHttpResponseForConnection:(NSURLConnectionWithID*)myConn connectionData:(_DownloadConnectionData *)cData;

- (void) moveAudioFilesForBook:(Book*)book fromTempArchiveDir:(NSString*)zipDir; // helper method to move files from temp directory to book's document directory
- (void) moveImageFilesForBook:(Book*)book fromTempArchiveDir:(NSString*)zipDir; // helper method to move files from temp directory to book's document directory

// ------ Refresh Book Data Processing -------
-(void) processRefreshDownloadedBookDataHttpResponse;

// ------ Download previews for specified books - Processing ------
-(void) processPreviewDownloadForBooksSpecifiedByID;
@end

// **************************************************************************************************************************************
// **************************************************************************************************************************************

@implementation DownloadManager

@synthesize delegate = _delegate;
@synthesize isDownloadingPreviews = _isDownloadingPreviews;

// Custom delegate setter
-(void)setDelegate:(id<DownloadManagerDelegate>)delegate
{
    _delegate = delegate;
    _delegateRespondsTo.downloadCompletedSuccessfullyWithReturnedData   = (unsigned int)[_delegate respondsToSelector:@selector(downloadCompletedSuccessfullyWithReturnedData:withManager:)];
    _delegateRespondsTo.downloadedTotalSize                             = (unsigned int)[_delegate respondsToSelector:@selector(downloadedTotalSize:withManager:)];
    _delegateRespondsTo.downloadFailed                                  = (unsigned int)[_delegate respondsToSelector:@selector(downloadFailed:)];
    _delegateRespondsTo.downloadedCancelled                             = (unsigned int)[_delegate respondsToSelector:@selector(downloadCancelled:)];
}

// ======================================================================================================================================
// ======================================================================================================================================
#pragma-mark Public Member Methods

// ======================================================================================================================================
// Indicates if the manager is busy downloading data.
-(BOOL)isDownloadingPreviews
{
    if (_connectionBookPreviews == nil)
        return NO;
    return YES;
}

// ======================================================================================================================================
// Initiate download. One the download is finished, delegate will be notified.
-(void) downloadRecentlyPublishedBooks
{
    if (_connectionBookPreviews != nil)
        return;
    
    _downloadPreviewsCancelled = NO;
    
    // First download IDs of books that need to be downloaded.
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", URL_SERVER_BASE_URL, URL_GET_RECENTLY_PUBLISHED_BOOK_IDS]];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0F];
    
    [URLRequestUtilities setCommonOptionsToURLRequest:request];
    _httpPreviewResponseData = [[NSMutableData alloc] initWithCapacity:1024];
   
    _connectionBookPreviews = [[NSURLConnectionWithID alloc] initWithRequest:request delegate:self identification:CONNECTION_BOOK_ID_LIST];
}

// ======================================================================================================================================
// Initiate download of all the specified number of other books sorted by like count and shuffled, starting at the specified index.
- (void) downloadOtherBooksShuffledStartingAtIndex:(int) startIndex maxNumberOfBooks:(int) bookCount
{
    if (_connectionBookPreviews != nil)
        return;
    
    _downloadPreviewsCancelled = NO;
    
    // First download IDs of books that need to be downloaded.
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%d/%d", URL_SERVER_BASE_URL, URL_GET_ALL_SORTED_BY_POPULARITY_AND_SHUFFLED_BOOK_IDS, startIndex, bookCount]];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0F];
    
    [URLRequestUtilities setCommonOptionsToURLRequest:request];
    _httpPreviewResponseData = [[NSMutableData alloc] initWithCapacity:1024];
    
    _connectionBookPreviews = [[NSURLConnectionWithID alloc] initWithRequest:request delegate:self identification:CONNECTION_BOOK_ID_LIST];
}

// ======================================================================================================================================
// Initiate download. Once the download is finished, delegate will be notified.
// Download all my books, favourite books and books that in those groups the login user belong to.
-(void) downloadRecentlyMyBookAndFavouriteAndGroupBooks:(User *) user
{
    loginUser = user;
    
    if (_connectionBookPreviews != nil)
        return;
    
    _downloadPreviewsCancelled = NO;
    
    // First download IDs of books that need to be downloaded.
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%d", URL_SERVER_BASE_URL_AUTH,  URL_GET_MY_BOOK_AND_FAVORITE_BOOK_IDS, [user.remoteId intValue]]];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0F];
    
    [URLRequestUtilities setCommonOptionsToURLRequest:request];
    _httpPreviewResponseData = [[NSMutableData alloc] initWithCapacity:1024];
    
    _connectionBookPreviews = [[NSURLConnectionWithID alloc] initWithRequest:request delegate:self identification:CONNECTION_MY_LIBRARY_BOOK_ID_LIST];
}

// ======================================================================================================================================
// Download book and notify delegate of the progress. Book object will be updated.
- (void) downloadBook:(Book *)book delegate:(id<DownloadManagerDelegate>)delegateObject
{
    if (book.isDownloaded.boolValue)
    {
        if ([delegateObject respondsToSelector:@selector(downloadCompletedSuccessfullyWithReturnedData:withManager:)])
            [delegateObject downloadCompletedSuccessfullyWithReturnedData:[NSDictionary dictionaryWithObject:book forKey:@"book"] withManager:self];
        return;
    }
    
    if (_downloadConnectionsData == nil)
        _downloadConnectionsData = [[NSMutableDictionary alloc] initWithCapacity:10];

    // create connection data object
    _DownloadConnectionData * cData = [[_DownloadConnectionData alloc] init];
    cData.book = book;
    cData.delegate = delegateObject;
    cData.stepNumber = 1;
    
    // Start download connection
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@", URL_SERVER_BASE_URL, URL_DOWNLOAD_BOOK_DATA_WITHOUT_FILES, book.remoteId]];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0F];

    [URLRequestUtilities setCommonOptionsToURLRequest:request];
    NSURLConnectionWithID * conn = [[NSURLConnectionWithID alloc] initWithRequest:request delegate:self identification:_downloadConnectionLastID];
    _downloadConnectionLastID++;
    
    // save connection data to the local storage.
    [_downloadConnectionsData setObject:cData forKey:[NSNumber numberWithInt:conn.identification]];
}

// ======================================================================================================================================
// Get groups, comments, flags, likes and so on for all downloaded books.
- (void) refreshDownloadedBooksData
{
    if (_connectionRefreshBook != nil)
        return;
    
    User * user = [LoginRegistrationManager getLoginUser];
    NSNumber * userId = [NSNumber numberWithInt:0];
    if (user != nil)
        userId = user.remoteId;
    
    // Get data for user (if logged-in) and all downloaded books
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@/%@", URL_SERVER_BASE_URL, URL_REFRESH_DOWNLOADED_BOOK_DATA_AND_USER, userId, [BookManager getDownloadedBooksRemoteIds]]];

    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0F];
    
    [URLRequestUtilities setCommonOptionsToURLRequest:request];
    _httpRefreshResponseData = [[NSMutableData alloc] initWithCapacity:1024];
    
    _connectionRefreshBook = [[NSURLConnectionWithID alloc] initWithRequest:request delegate:self identification:CONNECTION_REFRESH_BOOK_DATA];
}

// ======================================================================================================================================
// Get new comments and comments' authors for the specified downloaded book and logged-in user.
- (void) refreshCommentsForBook:(Book*)book loggedInUser:(User *)user;
{
    if (_connectionRefreshBook != nil)
    {
        if (_delegateRespondsTo.downloadedCancelled)
            [self.delegate downloadCancelled:self];
        return;
    }
    
    if (book == nil || !book.isDownloaded.boolValue)
    {
        if (_delegateRespondsTo.downloadedCancelled)
            [self.delegate downloadCancelled:self];
        return;
    }
    
    NSNumber * userId = [NSNumber numberWithInt:0];
    if (user != nil)
        userId = user.remoteId;
    
    // Get data for user (if logged-in) and all downloaded books
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@/%@", URL_SERVER_BASE_URL, URL_REFRESH_DOWNLOADED_BOOK_DATA_AND_USER, userId, book.remoteId]];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0F];
    
    [URLRequestUtilities setCommonOptionsToURLRequest:request];
    _httpRefreshResponseData = [[NSMutableData alloc] initWithCapacity:1024];
    
    _connectionRefreshBook = [[NSURLConnectionWithID alloc] initWithRequest:request delegate:self identification:CONNECTION_REFRESH_BOOK_DATA];
}

// ======================================================================================================================================
// Download previews for books specified by remote Book IDs, User IDs, and language IDs in the lists.
- (void) downloadPreviewsForBookWithIDs:(NSSet*)bookIDs authorIDs:(NSSet*)authors languageIDs:(NSSet*)languages;
{
    if (_connectionBookPreviews != nil)
        return;
    
    _downloadPreviewsCancelled = NO;
    
    _previewsForBooksByIDs = [bookIDs allObjects];
    // Remove all object IDs for already downloaded objects:
    
    // missing books
    NSArray * missingBooks = [BookManager getMissingRemoteIdsFromListOfRemoteIds:_previewsForBooksByIDs];

    // If all books are already downloaded - return
    if (missingBooks.count == 0)
    {
        if (_delegateRespondsTo.downloadCompletedSuccessfullyWithReturnedData)
        {
            [self.delegate downloadCompletedSuccessfullyWithReturnedData:[BookManager booksByRemoteIds:_previewsForBooksByIDs] withManager:self];
        }
        return;
    }
    
    // missing languages
    NSArray * missingLanguages = [LanguageManager getMissingRemoteLanguageIdsFromListOfRemoteIds:[languages allObjects]];
    
    // missing users
    NSArray * missingUsers = [UserManager getMissingRemoteIdsFromListOfRemoteIds:[authors allObjects]];
    

    // Send the request to the server to download all of the missing information
    
    NSString * booksParam = [missingBooks componentsJoinedByString:@","];
    if ([missingBooks count] == 0) booksParam = @"none";
    
    NSString * usersParam = [missingUsers componentsJoinedByString:@","];
    if ([missingUsers count] == 0) usersParam = @"none";
    
    NSString * langParam = [missingLanguages componentsJoinedByString:@","];
    if ([missingLanguages count] == 0) langParam = @"none";
    
    // books/users/languages
    NSString * urlWithParams = [NSString stringWithFormat:URL_DOWNLOAD_BOOK_PREVIEWS, booksParam, usersParam, langParam];
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", URL_SERVER_BASE_URL, urlWithParams]];
    
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0F];
    [URLRequestUtilities setCommonOptionsToURLRequest:request];
    _httpPreviewResponseData = [[NSMutableData alloc] initWithCapacity:1024];
    _connectionBookPreviews = [[NSURLConnectionWithID alloc] initWithRequest:request delegate:self identification:CONNECTION_BOOK_PREVIEWS_FOR_SPECIFIC_BOOKS];
}

// ======================================================================================================================================
// ======================================================================================================================================
#pragma-mark Private Methods Supporting Preview Downloads

// ======================================================================================================================================
// Get IDs for the books, validate against the CoreData and fetch missing books.
-(void)processBookIdListHTTPResponse
{
    NSString * errorTitle = NSLocalizedString(@"Cannot fetch a list of books", @"Error title: Browser books section, failed to get a list of popular/new books rom the server");
    NSDictionary * responseData = [URLRequestUtilities getResponseFromData:_httpPreviewResponseData orShowErrorMessageWithDelegate:self andTitle:errorTitle indicateIfError:NULL indicateIfAuthenticationError:NULL];
    
    if (responseData == nil)
    {
        if (_delegateRespondsTo.downloadFailed)
            [self.delegate downloadFailed:self];
        return;
    }
    
    // save ids for later processing, after all missing book previews have been retrieved from the server
    _recentBookIDs = [[responseData objectForKey:@"result"] objectForKey:@"books"];
    
    // Compare with local Book collection and request only the missing books from the server
    NSArray * recentBooks = [BookManager getMissingRemoteIdsFromListOfRemoteIds:_recentBookIDs];
    
    if ([recentBooks count] == 0)
    {
        _connectionBookPreviews = nil;
        [self passPreviewBooksToDelegate];
        return;
    }
    
    // ---------------------------------------------------------
    // Send request to the server to get book's preview details
    
    // 1. Get a list of all missing languages
    NSArray * languages = [[responseData objectForKey:@"result"] objectForKey:@"languages"];
    languages = [LanguageManager getMissingRemoteLanguageIdsFromListOfRemoteIds:languages];
    
    // 2. Get a list of missing users
    NSArray * users = [[responseData objectForKey:@"result"] objectForKey:@"users"];
    users = [UserManager getMissingRemoteIdsFromListOfRemoteIds:users];
    
    // 3. Send the request to the server to download all of the missing information
    
    NSString * usersParam = [users componentsJoinedByString:@","];
    if ([users count] == 0) usersParam = @"none";
    
    NSString * langParam = [languages componentsJoinedByString:@","];
    if ([languages count] == 0) langParam = @"none";
    
    // books/users/languages/groups
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@/%@/%@", URL_SERVER_BASE_URL, URL_BROWSE_DOWNLOAD_BOOK_PREVIEWS, [recentBooks componentsJoinedByString:@","], usersParam, langParam]];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:120.0F];
    [URLRequestUtilities setCommonOptionsToURLRequest:request];
    _httpPreviewResponseData = [[NSMutableData alloc] initWithCapacity:1024];
    _connectionBookPreviews = [[NSURLConnectionWithID alloc] initWithRequest:request delegate:self identification:CONNECTION_BOOK_PREVIEWS];
}

// ======================================================================================================================================
// Get all most recent books from coredata and notify the delegate.
- (void) passPreviewBooksToDelegate
{
    if (self.delegate == nil)
        return;
 
    NSArray * rBooks = [BookManager booksByRemoteIds:_recentBookIDs];
    NSDictionary * ret = [NSDictionary dictionaryWithObjectsAndKeys:rBooks, @"books", nil];
    
    if (_delegateRespondsTo.downloadCompletedSuccessfullyWithReturnedData)
        [self.delegate downloadCompletedSuccessfullyWithReturnedData:ret withManager:self];
}

// ======================================================================================================================================
// Save all received book previews to the core data and rebuild popular and recent book lists.
- (void)processBookPreviewListHTTPResponse
{
    NSString * errorTitle = NSLocalizedString(@"Cannot fetch a list of books", @"Error title: Browser books section, failed to get a list of popular/new books rom the server");
    NSDictionary * responseData = [URLRequestUtilities getResponseFromData:_httpPreviewResponseData orShowErrorMessageWithDelegate:self andTitle:errorTitle indicateIfError:NULL indicateIfAuthenticationError:NULL];
    
    _connectionBookPreviews = nil;
    
    if (responseData == nil)
    {
        if (_delegateRespondsTo.downloadFailed)
            [self.delegate downloadFailed:self];
        return;
    }
    
    // --------- Process Data ----------

    NSDictionary * receivedPreviews = [responseData objectForKey:@"result"];
    
    // 1. Save all users
    NSArray * items1 = [receivedPreviews objectForKey:@"users"];
    [UserManager addOrUpdateUsersWithoutAvatar:items1];
    
    // 2. Save Languages
    NSArray * items2 = [receivedPreviews objectForKey:@"languages"];
    [LanguageManager addOrUpdateLanguages:items2];
    
    // 3. Save books
    NSArray * items3 = [receivedPreviews objectForKey:@"books"];
    [BookManager addOrUpdateBookPreviews:items3];

    // done, send results to caller
    [self passPreviewBooksToDelegate];
}

// ======================================================================================================================================
-(void)cancelPreviewDownload
{
    _downloadPreviewsCancelled = YES;
}






// ======================================================================================================================================
// ======================================================================================================================================
#pragma-mark Private Methods Supporting Book Downloads


// STEP 1: Book download - get pages and comments without files
- (void) processBookTextDownloadedDataFromHttpResponseForConnection:(NSURLConnectionWithID*)connection connectionData:(_DownloadConnectionData *)cData
{
    NSString * errorTitle = NSLocalizedString(@"Book download failed", @"Error title: Cannot download book from the server");
    NSDictionary * responseData = [URLRequestUtilities getResponseFromData:cData.httpData orShowErrorMessageWithDelegate:self andTitle:errorTitle indicateIfError:NULL indicateIfAuthenticationError:NULL];

    // If error
    if (responseData == nil)
    {
        [_downloadConnectionsData removeObjectForKey:[NSNumber numberWithInt:connection.identification]];

        if (cData.delegateRespondsTo.downloadFailed)
            [cData.delegate downloadFailed:self];
        
        return;
    }
    
    responseData = [responseData objectForKey:@"result"];
    
    // 1. Update lastDownloaded time stamp
    cData.book.downloadDate = [NSDate date];
    
    // 2. save comments and comment authors
    NSArray * items = [responseData objectForKey:@"comments"];
    
    for (NSDictionary * dict in items)
    {
        User * user = [UserManager addOrUpdateUserWithoutAvatar:[dict objectForKey:@"author"]];
        [CommentManager addOrUpdateCommentWithData:dict user:user book:cData.book];
        [CommentManager deleteFlaggedCommentByRemoteId:[dict objectForKey:@"id"] flagCount:[dict objectForKey:@"flagCount"]];
    }
    
    // 3. save book pages
    items = [responseData objectForKey:@"pages"];
    [BookManager addOrUpdateDownloadedBookPagesWithoutFilesWithData:items book:cData.book];
    
    // ------------------------
    // Start Step 2: Download all voice files for book and pages
    
    cData.stepNumber = 2;
    
    // Start download connection
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@", URL_SERVER_BASE_URL, URL_DOWNLOAD_BOOK_AUDIO_FILES, cData.book.remoteId]];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0F];
    
    [URLRequestUtilities setCommonOptionsToURLRequest:request];
    NSURLConnection * connection1 = [[NSURLConnectionWithID alloc] initWithRequest:request delegate:self identification:connection.identification];
    connection1 = nil;
}

// ======================================================================================================================================
// STEP 2: Book download - get audio files
-(void) processBookDownloadedAudioDataFromHttpResponseForConnection:(NSURLConnectionWithID*)myConn connectionData:(_DownloadConnectionData *)cData
{
    if ([cData.httpData length] > 0)
    {
        // Create directory in temp folder to store the zip file.
        NSString * zipDir = [NSTemporaryDirectory() stringByAppendingPathComponent:[[[cData.book objectID] URIRepresentation] lastPathComponent]];
        [[NSFileManager defaultManager] createDirectoryAtPath:zipDir withIntermediateDirectories:YES attributes:nil error:nil];
        NSString * zipFile = [zipDir stringByAppendingString:@"/audio.zip"];
        
        // write zip file to the temp directory
        [cData.httpData writeToFile:zipFile atomically:NO];
        
        // Extract files in zip archive
        ZipArchive * zipArchive = [[ZipArchive alloc] init];
        if ([zipArchive UnzipOpenFile:zipFile])
        {
            if ([zipArchive UnzipFileTo:zipDir overWrite:YES])
            {
                [self moveAudioFilesForBook:cData.book fromTempArchiveDir:zipDir];
            }
            
            [zipArchive UnzipCloseFile];
        }
    }
    
    // ------------------------
    // Start Step 3: Download all image files for book and pages
    
    cData.stepNumber = 3;
    
    // Start download connection
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@", URL_SERVER_BASE_URL, URL_DOWNLOAD_BOOK_IMAGE_FILES, cData.book.remoteId]];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0F];
    
    [URLRequestUtilities setCommonOptionsToURLRequest:request];
    NSURLConnection * connection1 = [[NSURLConnectionWithID alloc] initWithRequest:request delegate:self identification:myConn.identification];
    connection1 = nil;
}

// Book download STEP 3 - get book's and pages' image files
-(void) processBookDownloadedImageDataFromHttpResponseForConnection:(NSURLConnectionWithID*)myConn connectionData:(_DownloadConnectionData *)cData
{
    if ([cData.httpData length] > 0)
    {
        // Create directory in temp folder to store the zip file.
        NSString * zipDir = [NSTemporaryDirectory() stringByAppendingPathComponent:[[[cData.book objectID] URIRepresentation] lastPathComponent]];
        [[NSFileManager defaultManager] createDirectoryAtPath:zipDir withIntermediateDirectories:YES attributes:nil error:nil];
        NSString * zipFile = [zipDir stringByAppendingString:@"/images.zip"];
        
        // write zip file to the temp directory
        [cData.httpData writeToFile:zipFile atomically:NO];
        
        // Extract files in zip archive
        ZipArchive * zipArchive = [[ZipArchive alloc] init];
        if ([zipArchive UnzipOpenFile:zipFile])
        {
            if ([zipArchive UnzipFileTo:zipDir overWrite:YES])
            {
                [self moveImageFilesForBook:cData.book fromTempArchiveDir:zipDir];
            }
            
            [zipArchive UnzipCloseFile];
        }
    }
    
    
    // ------------------------
    // Start Step 4: Download all data related to this book if current user is logged-in
 
    User * user = [LoginRegistrationManager getLoginUser];

    if (user != nil)
    {
        cData.stepNumber = 4;
        
        // Start download connection
        NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@/%@", URL_SERVER_BASE_URL_AUTH, URL_USER_GET_LOGGED_IN_USER_RELATED_DATA, user.remoteId, cData.book.remoteId]];
        NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0F];
        
        [URLRequestUtilities setCommonOptionsToURLRequest:request];
          NSURLConnection * connection1 =[[NSURLConnectionWithID alloc] initWithRequest:request delegate:self identification:myConn.identification];
        connection1 = nil;
        return;
    }
    
    // If user is not logged-in, then set book as downloaded and notify delegate of this event
    cData.book.isDownloaded = [NSNumber numberWithBool:YES];
    [[DocumentHandler sharedDocumentHandler] saveContextAndWait];
    
    if (cData.delegateRespondsTo.downloadCompletedSuccessfullyWithReturnedData)
        [cData.delegate downloadCompletedSuccessfullyWithReturnedData:nil withManager:self];
    
    [_downloadConnectionsData removeObjectForKey:[NSNumber numberWithInt:myConn.identification]];
}

// Book download STEP 4 - get book's related data for logged-in user, like comments likes, flags, groups, etc
-(void) processBookRelatedDataForLoggedInUserFromHttpResponseForConnection:(NSURLConnectionWithID*)myConn connectionData:(_DownloadConnectionData *)cData
{
    BOOL authError = NO;
    NSString * errorTitle = NSLocalizedString(@"Book download failed", @"Error title: Cannot download book from the server");
    NSDictionary * responseData = [URLRequestUtilities getResponseFromData:cData.httpData orShowErrorMessageWithDelegate:self andTitle:errorTitle indicateIfError:NULL indicateIfAuthenticationError:&authError];
    
    // If error
    if (responseData == nil)
    {
        [_downloadConnectionsData removeObjectForKey:[NSNumber numberWithInt:myConn.identification]];
        
        if (authError)
        {
#ifdef DEBUG
            NSLog(@"Auth failed for download");
#endif
            [LoginRegistrationManager logout];
        }
    }
    else
    {
        responseData = [responseData objectForKey:@"result"];
    
        if (responseData == nil)
        {
            if (cData.delegateRespondsTo.downloadFailed)
                [cData.delegate downloadFailed:self];
            [_downloadConnectionsData removeObjectForKey:[NSNumber numberWithInt:myConn.identification]];
            return;
        }
    }
    
    User * user = [LoginRegistrationManager getLoginUser];
    if (user != nil && responseData != nil)
    { 
        // 1. Save flagged book
        if ([[responseData objectForKey:@"flaggedBooks"] count] > 0)
            cData.book.flaggedBy = user;
      
        // 2. Save liked book
        if ([[responseData objectForKey:@"likedBooks"] count] > 0)
            cData.book.likedBy = user;
        
        // 3. Save liked comments
        NSArray * items = [responseData objectForKey:@"likedComments"];
        [CommentManager likeCommentsInTheList:items byUser:user];
    
        // 3. Save flagged comments
        items = [responseData objectForKey:@"flaggedComments"];
        [CommentManager flagCommentsInTheList:items byUser:user];
      
        // 4. Save Groups
        [UserGroupManager addOrUpdateUserGroups:[responseData objectForKey:@"groups"]];
        
        // 5. Link books to groups.
        [BookManager linkBooksToGroups:[responseData objectForKey:@"groupBooks"]];
    }
    
    // --------
    // Set book as downloaded and notify delegate of this event
    cData.book.isDownloaded = [NSNumber numberWithBool:YES];
    [[DocumentHandler sharedDocumentHandler] saveContextAndWait];
    
    if (cData.delegateRespondsTo.downloadCompletedSuccessfullyWithReturnedData)
        [cData.delegate downloadCompletedSuccessfullyWithReturnedData:nil withManager:self];
    
    [_downloadConnectionsData removeObjectForKey:[NSNumber numberWithInt:myConn.identification]];
}

// ======================================================================================================================================
// helper method to move files from temp directory to book's document directory
- (void) moveAudioFilesForBook:(Book*)book fromTempArchiveDir:(NSString*)zipDir
{
    // delete old files first
    [[NSFileManager defaultManager] removeItemAtPath:[BookManager getBookItemAbsPath:book fileName:BOOK_TITLE_1_AUDIO_FILENAME_MP3] error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:[BookManager getBookItemAbsPath:book fileName:BOOK_TITLE_2_AUDIO_FILENAME_MP3] error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:[BookManager getBookItemAbsPath:book fileName:BOOK_DESC_1_AUDIO_FILENAME_MP3] error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:[BookManager getBookItemAbsPath:book fileName:BOOK_DESC_2_AUDIO_FILENAME_MP3] error:nil];

    // Save cover page's audio files
    [[NSFileManager defaultManager] moveItemAtPath:[zipDir stringByAppendingPathComponent:BOOK_TITLE_1_AUDIO_FILENAME_MP3] toPath:[BookManager getBookItemAbsPath:book fileName:BOOK_TITLE_1_AUDIO_FILENAME_MP3] error:nil];
    [[NSFileManager defaultManager] moveItemAtPath:[zipDir stringByAppendingPathComponent:BOOK_TITLE_2_AUDIO_FILENAME_MP3] toPath:[BookManager getBookItemAbsPath:book fileName:BOOK_TITLE_2_AUDIO_FILENAME_MP3] error:nil];
    [[NSFileManager defaultManager] moveItemAtPath:[zipDir stringByAppendingPathComponent:BOOK_DESC_1_AUDIO_FILENAME_MP3] toPath:[BookManager getBookItemAbsPath:book fileName:BOOK_DESC_1_AUDIO_FILENAME_MP3] error:nil];
    [[NSFileManager defaultManager] moveItemAtPath:[zipDir stringByAppendingPathComponent:BOOK_DESC_2_AUDIO_FILENAME_MP3] toPath:[BookManager getBookItemAbsPath:book fileName:BOOK_DESC_2_AUDIO_FILENAME_MP3] error:nil];
    
    // Move all files for book's pages
    NSOrderedSet * pageSet = book.pages;
    NSString * zipDirPage = [zipDir stringByAppendingPathComponent:@"pages"];

    for (BookPage * page in pageSet)
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:[BookManager getBookItemAbsPath:page fileName:BOOK_PAGE_TEXT_1_AUDIO_FILENAME_MP3] withIntermediateDirectories:YES attributes:nil error:nil];

        [[NSFileManager defaultManager] removeItemAtPath:[BookManager getBookItemAbsPath:page fileName:BOOK_PAGE_TEXT_1_AUDIO_FILENAME_MP3] error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:[BookManager getBookItemAbsPath:page fileName:BOOK_PAGE_TEXT_2_AUDIO_FILENAME_MP3] error:nil];
        
        [[NSFileManager defaultManager] moveItemAtPath:[zipDirPage stringByAppendingString:[NSString stringWithFormat:@"/%@%@", page.remoteId, BOOK_PAGE_TEXT_1_AUDIO_FILENAME_MP3]]
                                                toPath:[BookManager getBookItemAbsPath:page fileName:BOOK_PAGE_TEXT_1_AUDIO_FILENAME_MP3] error:nil];
        [[NSFileManager defaultManager] moveItemAtPath:[zipDirPage stringByAppendingString:[NSString stringWithFormat:@"/%@%@", page.remoteId, BOOK_PAGE_TEXT_2_AUDIO_FILENAME_MP3]]
                                                toPath:[BookManager getBookItemAbsPath:page fileName:BOOK_PAGE_TEXT_2_AUDIO_FILENAME_MP3] error:nil];
    }

}

// helper method to move files from temp directory to book's document directory
- (void)moveImageFilesForBook:(Book *)book fromTempArchiveDir:(NSString *)zipDir
{
    // delete old files first
    [[NSFileManager defaultManager] removeItemAtPath:[BookManager getBookItemAbsPath:book fileName:BOOK_IMAGE_FILENAME] error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:[BookManager getBookItemAbsPath:book fileName:BOOK_THUMBNAIL_FILENAME] error:nil];
    
    // Save cover page's images files
    [[NSFileManager defaultManager] moveItemAtPath:[zipDir stringByAppendingPathComponent:BOOK_IMAGE_FILENAME] toPath:[BookManager getBookItemAbsPath:book fileName:BOOK_IMAGE_FILENAME] error:nil];
    [[NSFileManager defaultManager] moveItemAtPath:[zipDir stringByAppendingPathComponent:BOOK_THUMBNAIL_FILENAME] toPath:[BookManager getBookItemAbsPath:book fileName:BOOK_THUMBNAIL_FILENAME] error:nil];
    
    // Move all files for book's pages
    NSOrderedSet * pageSet = book.pages;
    NSString * zipDirPage = [zipDir stringByAppendingPathComponent:@"pages"];
    
    for (BookPage * page in pageSet)
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:[BookManager getBookItemAbsPath:page fileName:BOOK_PAGE_IMAGE_FILENAME] withIntermediateDirectories:YES attributes:nil error:nil];
        
        [[NSFileManager defaultManager] removeItemAtPath:[BookManager getBookItemAbsPath:page fileName:BOOK_PAGE_IMAGE_FILENAME] error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:[BookManager getBookItemAbsPath:page fileName:BOOK_PAGE_THUMBNAIL_FILENAME] error:nil];
        
        [[NSFileManager defaultManager] moveItemAtPath:[zipDirPage stringByAppendingString:[NSString stringWithFormat:@"/%@%@", page.remoteId, BOOK_PAGE_IMAGE_FILENAME]]
                                                toPath:[BookManager getBookItemAbsPath:page fileName:BOOK_PAGE_IMAGE_FILENAME] error:nil];
        [[NSFileManager defaultManager] moveItemAtPath:[zipDirPage stringByAppendingString:[NSString stringWithFormat:@"/%@%@", page.remoteId, BOOK_PAGE_THUMBNAIL_FILENAME]]
                                                toPath:[BookManager getBookItemAbsPath:page fileName:BOOK_PAGE_THUMBNAIL_FILENAME] error:nil];
    }
}







// ======================================================================================================================================
// ======================================================================================================================================
#pragma-mark Private Methods Supporting Book Refresh Data Downloads

// Update all comments, user groups, likes, flags, etc.
-(void) processRefreshDownloadedBookDataHttpResponse
{
    NSError * error = NULL;
    NSDictionary * responseDictionary = [NSJSONSerialization JSONObjectWithData:_httpRefreshResponseData options:kNilOptions error:&error];

    if (error != NULL)
    {
#ifdef DEBUG
        NSLog(@"Browse Book Data refresh: data received from the server is not recognized");
#endif
        if (_delegateRespondsTo.downloadFailed)
            [self.delegate downloadFailed:self];
        return;
    }
    
    if (![[responseDictionary objectForKey:@"status"] isEqualToString:REQUEST_RESPONSE_OK])
    {
        // Validation Error?
        if ([[responseDictionary objectForKey:@"status"] isEqualToString:REQUEST_RESPONSE_VALIDATION_FAIL])
        {
#ifdef DEBUG
            NSArray * errArr = [[NSArray alloc] initWithArray:[responseDictionary objectForKey:@"result"]];
            NSLog(@"Browse Book Data refresh: validation error: %@", [errArr componentsJoinedByString:@"\n"]);
#endif
        }
        
        // Failure Error?
        if ([[responseDictionary objectForKey:@"status"] isEqualToString:REQUEST_RESPONSE_FAIL])
        {
#ifdef DEBUG
            NSLog(@"Browse Book Data refresh: fail: %@", [responseDictionary objectForKey:@"message"]);
#endif
        }
        
        if (_delegateRespondsTo.downloadFailed)
            [self.delegate downloadFailed:self];
        return;
    }

    responseDictionary = [responseDictionary objectForKey:@"result"];
    
    // ---------------------------------------------------------------------------
    // Update all comments
    
    NSArray * items = [responseDictionary objectForKey:@"comments"];
    for (NSDictionary * dict in items)
    {
        User * user = [UserManager addOrUpdateUserWithoutAvatar:[dict objectForKey:@"author"]];
        Comment * comment = [CommentManager addOrUpdateCommentWithData:dict user:user];
        comment.book.updateTimeStamp = [NSDate date];
        [CommentManager deleteFlaggedCommentByRemoteId:[dict objectForKey:@"id"] flagCount:[dict objectForKey:@"flagCount"]];
    }
    
    // ---------------------------------------------------------------------------
    // Save data related to logged-in user.
    User * user = [LoginRegistrationManager getLoginUser];
    
    if (user != nil)
    {
        // 1. Save flagged book
        [BookManager flagBooksInTheList:[responseDictionary objectForKey:@"flaggedBooks"] byUser:user];
        
        // 2. Save liked book
        [BookManager likeBooksInTheList:[responseDictionary objectForKey:@"likedBooks"] byUser:user];
        
        // 3. Save flagged comments
        [CommentManager flagCommentsInTheList:[responseDictionary objectForKey:@"flaggedComments"] byUser:user];
        
        // 4. Save liked comments
        [CommentManager likeCommentsInTheList:[responseDictionary objectForKey:@"likedComments"] byUser:user];
        
        // 5. Save Groups
        [UserGroupManager addOrUpdateUserGroups:[responseDictionary objectForKey:@"groups"]];
        
        // 6. Link Books to Groups
        [BookManager linkBooksToGroups:[responseDictionary objectForKey:@"groupBooks"]];
    }
    
    // notify delegate
    if (_delegateRespondsTo.downloadCompletedSuccessfullyWithReturnedData)
        [self.delegate downloadCompletedSuccessfullyWithReturnedData:responseDictionary withManager:self];
}

// ======================================================================================================================================
// ======================================================================================================================================
#pragma-mark Private Methods Supporting On Demand Book Preview Download

-(void) processPreviewDownloadForBooksSpecifiedByID
{
    NSString * errorTitle = NSLocalizedString(@"Error while downloading books", @"Error title: Browser books section, failed to get previews for searched books rom the server");
    NSDictionary * responseData = [URLRequestUtilities getResponseFromData:_httpPreviewResponseData orShowErrorMessageWithDelegate:self andTitle:errorTitle indicateIfError:NULL indicateIfAuthenticationError:NULL];
    
    _connectionBookPreviews = nil;
    
    if (responseData == nil)
    {
        if (_delegateRespondsTo.downloadFailed)
            [self.delegate downloadFailed:self];
        return;
    }
    
    // --------- Process Data ----------
    
    NSDictionary * receivedPreviews = [responseData objectForKey:@"result"];
    
    // 1. Save all users
    NSArray * items1 = [receivedPreviews objectForKey:@"users"];
    [UserManager addOrUpdateUsersWithoutAvatar:items1];
    
    // 2. Save Languages
    NSArray * items2 = [receivedPreviews objectForKey:@"languages"];
    [LanguageManager addOrUpdateLanguages:items2];
    
    // 3. Save books
    NSArray * items3 = [receivedPreviews objectForKey:@"books"];
    [BookManager addOrUpdateBookPreviews:items3];
    
    if (_delegateRespondsTo.downloadCompletedSuccessfullyWithReturnedData)
    {
        [self.delegate downloadCompletedSuccessfullyWithReturnedData:[BookManager booksByRemoteIds:_previewsForBooksByIDs] withManager:self];
        _previewsForBooksByIDs = nil;
    }
}

// ======================================================================================================================================
// ======================================================================================================================================
#pragma-mark Connection Delegate Methods

// THESE ARE TO HANDLE ASYNC REQUESTS

// ======================================================================================================================================
// Process server initial response
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSURLConnectionWithID * myConn = (NSURLConnectionWithID*) connection;

    // ----------------------------------------
    // ONE OF DOWNLOAD BOOK CONNECTIONS?
    
    // is it one of Book Download connections?
    if (myConn.identification >= DOWNLOAD_CONNECTION_MIN_ID)
    {
        _DownloadConnectionData * cData = [_downloadConnectionsData objectForKey:[NSNumber numberWithInt:myConn.identification]];
        [cData.httpData setLength:0];
        
        if (cData.delegateRespondsTo.downloadedTotalSize)
            [cData.delegate downloadedTotalSize:0 withManager:self];
        
        return;
    }
    
    // ----------------------------------------
    // ONE OF REFRESH OR PREVIEW DOWNLOAD CONNECTIONS
    
    if (myConn.identification == CONNECTION_REFRESH_BOOK_DATA)
    {
        [_httpRefreshResponseData setLength:0];
    }
    else
    {
        [_httpPreviewResponseData setLength:0];
    
        if (_delegateRespondsTo.downloadedTotalSize)
            [self.delegate downloadedTotalSize:0 withManager:self];
    }
}
// ======================================================================================================================================
// Process incoming data
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSURLConnectionWithID * myConn = (NSURLConnectionWithID*) connection;
    
    // ----------------------------------------
    // ONE OF DOWNLOAD BOOK CONNECTIONS?
    
    // is it one of Book Download connections?
    if (myConn.identification >= DOWNLOAD_CONNECTION_MIN_ID)
    {
        _DownloadConnectionData * cData = [_downloadConnectionsData objectForKey:[NSNumber numberWithInt:myConn.identification]];
        [cData.httpData appendData:data];
        cData.totalDownloadSizeInKB += [data length] / 1024;
        
        if (cData.delegateRespondsTo.downloadedTotalSize)
            [cData.delegate downloadedTotalSize:cData.totalDownloadSizeInKB withManager:self];

        //NSLog(@"Progress %d or %f", cData.totalDownloadSizeInKB, cData.book.bookSizeKB.floatValue);
       // NSLog(@"Progress %f", roundf(100.0F * cData.totalDownloadSizeInKB / cData.book.bookSizeKB.floatValue));
        
        return;
    }
    
    // ----------------------------------------
    // ONE OF REFRESH OR PREVIEW DOWNLOAD CONNECTIONS
    
    if (myConn.identification == CONNECTION_REFRESH_BOOK_DATA)
    {
        [_httpRefreshResponseData appendData:data];
    }
    else
    {
        [_httpPreviewResponseData appendData:data];
        
        if (_delegateRespondsTo.downloadedTotalSize)
            [self.delegate downloadedTotalSize:[data length] withManager:self];
    }
}
// ======================================================================================================================================
// Process connection error
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSURLConnectionWithID * myConn = (NSURLConnectionWithID*) connection;
    
    // ----------------------------------------
    // ONE OF DOWNLOAD BOOK CONNECTIONS?
    
    // is it one of Book Download connections?
    if (myConn.identification >= DOWNLOAD_CONNECTION_MIN_ID)
    {
        _DownloadConnectionData * cData = [_downloadConnectionsData objectForKey:[NSNumber numberWithInt:myConn.identification]];
        
        if (cData.delegateRespondsTo.downloadFailed)
            [cData.delegate downloadFailed:self];
        
        [CommonMessageBoxes showServerConnectionErrorMessageBoxWithError:error andDelegate:self];   // show error message
        [_downloadConnectionsData removeObjectForKey:[NSNumber numberWithInt:myConn.identification]];
        
        return;
    }
    
    // ----------------------------------------
    // ONE OF REFRESH OR PREVIEW DOWNLOAD CONNECTIONS
    
    if (myConn.identification == CONNECTION_REFRESH_BOOK_DATA)
    {
        if (_delegateRespondsTo.downloadFailed)
            [self.delegate downloadFailed:self];
        return;
    }
    
    _connectionBookPreviews = nil;
    [CommonMessageBoxes showServerConnectionErrorMessageBoxWithError:error andDelegate:self];   // show error message
    
    if (_delegateRespondsTo.downloadFailed)
        [self.delegate downloadFailed:self];
}
// ======================================================================================================================================
// Do something with received data
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSURLConnectionWithID * myConn = (NSURLConnectionWithID*) connection;
    
    // ----------------------------------------
    // ONE OF DOWNLOAD BOOK CONNECTIONS?
    
    // is it one of Book Download connections?
    if (myConn.identification >= DOWNLOAD_CONNECTION_MIN_ID)
    {
        _DownloadConnectionData * cData = [_downloadConnectionsData objectForKey:[NSNumber numberWithInt:myConn.identification]];

        
        if (cData.stepNumber == 1)          // Step1: pages and comments from DB
            [self processBookTextDownloadedDataFromHttpResponseForConnection:myConn connectionData:cData];
        else if (cData.stepNumber == 2)     // Step2: audio files for pages and book
            [self processBookDownloadedAudioDataFromHttpResponseForConnection:myConn connectionData:cData];
        else if (cData.stepNumber == 3)     // Step2: audio files for pages and book
            [self processBookDownloadedImageDataFromHttpResponseForConnection:myConn connectionData:cData];
        else
            [self processBookRelatedDataForLoggedInUserFromHttpResponseForConnection:myConn connectionData:cData];
        return;
    }
    
    // -----------------------------------------------
    // REFRESH DOWNLOAD CONNECTIONS
    
    if (myConn.identification == CONNECTION_REFRESH_BOOK_DATA)
    {
        [self processRefreshDownloadedBookDataHttpResponse];
        _connectionRefreshBook = nil;
        return;
    }
    
    // -----------------------------------------------
    // ONE OF PREVIEW DOWNLOAD CONNECTIONS
    
    if (_downloadPreviewsCancelled)
    {
        _connectionBookPreviews = nil;
        _downloadPreviewsCancelled = NO;
        return;
    }

    switch (((NSURLConnectionWithID*)connection).identification)
    {
        case CONNECTION_BOOK_ID_LIST:
            [self processBookIdListHTTPResponse];
            break;
        case CONNECTION_MY_LIBRARY_BOOK_ID_LIST:
            [self processMyLibraryBookIdListHTTPResponse];
            break;
        case CONNECTION_BOOK_PREVIEWS:
            [self processBookPreviewListHTTPResponse];
            break;
        case CONNECTION_MY_LIBRARY_BOOK_PREVIEWS:
            [self processMyLibraryBookPreviewListHTTPResponse];
            break;
        case CONNECTION_BOOK_PREVIEWS_FOR_SPECIFIC_BOOKS:
            [self processPreviewDownloadForBooksSpecifiedByID];
            break;
        default:                // notify caller, but pass no data. This case should never occur, otherwise there is an error.
            [self.delegate downloadCompletedSuccessfullyWithReturnedData:nil withManager:self];
            break;
    }
    
    _connectionBookPreviews = nil;
}
// ======================================================================================================================================
// return cached respone
- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return cachedResponse;
}


// ======================================================================================================================================
// Get IDs for the books, validate against the CoreData and fetch missing books.
-(void)processMyLibraryBookIdListHTTPResponse
{
    NSString * errorTitle = NSLocalizedString(@"Cannot fetch a list of books", @"Error title: MyLibrary books section, failed to get a list of my books from the server");
    NSDictionary * responseData = [URLRequestUtilities getResponseFromData:_httpPreviewResponseData orShowErrorMessageWithDelegate:self andTitle:errorTitle indicateIfError:NULL indicateIfAuthenticationError:NULL];
    if (responseData == nil)
    {
        if (_delegateRespondsTo.downloadFailed)
            [self.delegate downloadFailed:self];
        return;
    }
    
    NSMutableSet * myBooks = [NSMutableSet setWithArray:[[responseData objectForKey:@"result"] objectForKey:@"myBook"]];
    NSMutableSet * favouriteBooks = [NSMutableSet setWithArray:[[responseData objectForKey:@"result"] objectForKey:@"myFavourite"]];
    
    myGroupBooks = [[responseData objectForKey:@"result"] objectForKey:@"myGroup"];
    if(myGroupBooks != nil)
        _groupBookIDs = [[NSMutableArray alloc]init];
    
    for(NSDictionary * dict in myGroupBooks)
    {
        for(id key in [dict allKeys])
        {
            [_groupBookIDs addObject:[dict objectForKey:key]];
        }
    }
    
    // save ids for later processing, after all missing book previews have been retrieved from the server
    _myBookIDs = [myBooks allObjects];
    _favouriteBooksIDs = [favouriteBooks allObjects];
    
    _httpPreviewResponseData = nil;
    
    // ---------------------------------------------
    // Compare with local Book collection and request only the missing books from the server
    myBooks = [NSMutableSet setWithArray:[BookManager getMissingRemoteIdsFromListOfRemoteIds:_myBookIDs]];
    favouriteBooks = [NSMutableSet setWithArray:[BookManager getMissingRemoteIdsFromListOfRemoteIds:_favouriteBooksIDs]];
    NSMutableSet *myGroupBooksSet = [NSMutableSet setWithArray:[BookManager getMissingRemoteIdsFromListOfRemoteIds:_groupBookIDs]];
    
    // combine two sets to remove duplicate entries before sending HTTP request to retrieve previews for those books
    NSMutableSet * missingbookSet = favouriteBooks;
    [missingbookSet unionSet:myBooks];
    [missingbookSet unionSet:myGroupBooksSet];
    if ([missingbookSet count] == 0)
    {
        _connectionBookPreviews = nil;
        [self passMyLibraryPreviewBooksToDelegate];
        return;
    }
    
    // ---------------------------------------------------------
    // Send request to the server to get book's preview details
    
    // 1. Get a list of all missing languages
    NSArray * languages = [[responseData objectForKey:@"result"] objectForKey:@"languages"];
    languages = [LanguageManager getMissingRemoteLanguageIdsFromListOfRemoteIds:languages];
    
    // 2. Get a list of missing users
    NSArray * users = [[responseData objectForKey:@"result"] objectForKey:@"users"];
    users = [UserManager getMissingRemoteIdsFromListOfRemoteIds:users];
    
    // 3. Send the request to the server to download all of the missing information
    
    NSString * usersParam = [users componentsJoinedByString:@","];
    if ([users count] == 0) usersParam = @"none";
    
    NSString * langParam = [languages componentsJoinedByString:@","];
    if ([languages count] == 0) langParam = @"none";
    
    // books/users/languages/groups
    
    NSString * urlWithParams = [NSString stringWithFormat:URL_DOWNLOAD_BOOK_PREVIEWS, [[missingbookSet allObjects] componentsJoinedByString:@","], usersParam, langParam];
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", URL_SERVER_BASE_URL, urlWithParams]];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:300.0F];
    [URLRequestUtilities setCommonOptionsToURLRequest:request];
    _httpPreviewResponseData = [[NSMutableData alloc] initWithCapacity:1024];
    _connectionBookPreviews = [[NSURLConnectionWithID alloc] initWithRequest:request delegate:self identification:CONNECTION_MY_LIBRARY_BOOK_PREVIEWS];
}

// ======================================================================================================================================
// Get all  my library books from coredata and notify the delegate.
- (void) passMyLibraryPreviewBooksToDelegate
{
    if (self.delegate == nil)
        return;
    
    NSArray * pBooks = [BookManager booksByRemoteIds:_myBookIDs];
    NSArray * rBooks = [BookManager booksByRemoteIds:_favouriteBooksIDs];
    NSArray * gBooks = [BookManager booksByRemoteIds:_groupBookIDs];
    NSArray * allGBooks = myGroupBooks;
    NSDictionary * ret = [NSDictionary dictionaryWithObjectsAndKeys:pBooks, @"myBook", rBooks, @"myFavourite", gBooks, @"myGroup", allGBooks, @"allBooksInGroups", nil];
    
    if (_delegateRespondsTo.downloadCompletedSuccessfullyWithReturnedData)
    {
        [self.delegate downloadCompletedSuccessfullyWithReturnedData:ret withManager:self];
    }
}

// ======================================================================================================================================
// Save all received book previews to the core data and rebuild my library book lists.
- (void)processMyLibraryBookPreviewListHTTPResponse
{
    NSString * errorTitle = NSLocalizedString(@"Cannot fetch a list of books", @"Error title: MyLibrary books section, failed to get a list of my books from the server");
    NSDictionary * responseData = [URLRequestUtilities getResponseFromData:_httpPreviewResponseData orShowErrorMessageWithDelegate:self andTitle:errorTitle indicateIfError:NULL indicateIfAuthenticationError:NULL];
    
    _connectionBookPreviews = nil;
    
    if (responseData == nil)
    {
        if (_delegateRespondsTo.downloadFailed)
            [self.delegate downloadFailed:self];
        return;
    }
    
    // --------- Process Data ----------
    
    NSDictionary * receivedPreviews = [responseData objectForKey:@"result"];
    // 1. Save all users
    NSArray * items1 = [receivedPreviews objectForKey:@"users"];
    [UserManager addOrUpdateUsersWithoutAvatar:items1];
    
    // 2. Save Languages
    NSArray * items2 = [receivedPreviews objectForKey:@"languages"];
    [LanguageManager addOrUpdateLanguages:items2];
    
    // 3. Save books
    NSArray * items3 = [receivedPreviews objectForKey:@"books"];
    [BookManager addOrUpdateBookPreviewsWithGroup:items3];
    
    // done, send results to caller
    [self passMyLibraryPreviewBooksToDelegate];
}

@end
