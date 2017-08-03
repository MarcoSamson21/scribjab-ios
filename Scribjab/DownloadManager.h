//
//  DownloadManager
//  Scribjab
//
//  Created by Oleg Titov on 12-11-23.
//
//

#import <Foundation/Foundation.h>
#import "Book.h"

// Delegate for communicating with the user Controllers.
@protocol DownloadManagerDelegate <NSObject>
@optional
-(void) downloadCompletedSuccessfullyWithReturnedData:(id)responseData withManager:(id)manager;
-(void) downloadFailed:(id)manager;
-(void) downloadedTotalSize:(NSUInteger) size withManager:(id)manager;
-(void) downloadCancelled:(id)manager;
@end

// **************************************************************************************************************************************
// **************************************************************************************************************************************


@interface DownloadManager : NSObject

@property (nonatomic, weak) id<DownloadManagerDelegate> delegate;
@property (nonatomic, readonly) BOOL isDownloadingPreviews;

- (void) downloadRecentlyPublishedBooks;
- (void) downloadOtherBooksShuffledStartingAtIndex:(int) startIndex maxNumberOfBooks:(int) bookCount;
- (void) downloadRecentlyMyBookAndFavouriteAndGroupBooks:(User *) user;

- (void) cancelPreviewDownload;

// Download book and notify delegate of the progress. Book object will be updated.
- (void) downloadBook:(Book *)book delegate:(id<DownloadManagerDelegate>) delegateObject;

// Get groups, comments, flags, likes and so on for all downloaded books.
- (void) refreshDownloadedBooksData;

// Get new comments and comments' authors for the specified downloaded book.
- (void) refreshCommentsForBook:(Book*)book loggedInUser:(User *)user;

// Download previews for books specified by remote Book IDs, User IDs, and language IDs in the lists.
- (void) downloadPreviewsForBookWithIDs:(NSSet*)bookIDs authorIDs:(NSSet*)authors languageIDs:(NSSet*)languages;
@end
