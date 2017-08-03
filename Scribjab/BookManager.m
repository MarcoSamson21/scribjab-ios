//
//  CreateBookManager.m
//  Scribjab
//
//  Created by Gladys Tang on 12-09-26.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BookManager.h"
#import "Utilities.h"
#import "DocumentHandler.h"
#import "User.h"
#import "UserGroups.h"
#import "Book+Utils.h"
#import "UserManager.h"
#import "LanguageManager.h"
#import "Comment.h"
#import "UserGroupManager.h"
#import "ModalConstants.h"

@implementation BookManager

//save book and bookpage image
+ (void)saveImage: (UIImage*)image item:(id)bookItem filename:(NSString *)filename
{
    if (!([bookItem isKindOfClass:[Book class]] || [bookItem isKindOfClass:[BookPage class]]))
        return;
    
    if (image != nil)
    {
        NSString * path = [self getBookItemAbsPath:bookItem fileName:filename];
        NSData* data = UIImagePNGRepresentation(image);
        [BookManager createDirIfNotExist:bookItem];
        [data writeToFile:path atomically:NO];
    }
}

// ======================================================================================================================================
// Get the directory path of where books' images will be saved
// i.e., return /<DocumentDirectory>/books/
+ (NSString *) getBookStorageAbsPath
{
    return [Utilities getAbsoluteFile:@"books/"];
}

// ======================================================================================================================================
//this is used for book and book page's images and audios
+ (NSString *)getBookItemAbsPath:(id)bookItem fileName:(NSString *)fileName
{
    NSString *absPath=nil;
    if([bookItem isKindOfClass:[Book class]])
    {
        Book * bk = (Book *)bookItem;
        NSString *objectId = [[[bk objectID] URIRepresentation] lastPathComponent];

        if(fileName != nil)
            absPath = [NSString stringWithFormat:@"%@%@%@%@", [self getBookStorageAbsPath], objectId, @"/", fileName];
        else
            absPath = [NSString stringWithFormat:@"%@%@%@", [self getBookStorageAbsPath], objectId, @"/"];
    }
    else if([bookItem isKindOfClass:[BookPage class]])
    {
        BookPage * bookPage = (BookPage *)bookItem;
        NSString *bookObjectId = [[[bookPage.book objectID] URIRepresentation] lastPathComponent];
        NSString *objectId = [[[bookPage objectID] URIRepresentation] lastPathComponent];
        
        if(fileName != nil)
            absPath =  [NSString stringWithFormat:@"%@%@%@%@%@%@", [self getBookStorageAbsPath], bookObjectId, @"/pages/", objectId, @"/", fileName];
        else
            absPath =  [NSString stringWithFormat:@"%@%@%@%@%@", [self getBookStorageAbsPath], bookObjectId, @"/pages/", objectId, @"/"];
    }
    return absPath;
}

//create dir for book and bookpage
+ (BOOL)createDirIfNotExist:(id)bookItem
{
    NSString * dir=nil;
    if([bookItem isKindOfClass:[Book class]])
    {
        Book *book = (Book *)bookItem;
        dir = [self getBookItemAbsPath:book fileName:nil];
    }
    else if([bookItem isKindOfClass:[BookPage class]])
    {
        BookPage *bookPage = (BookPage *)bookItem;
        dir = [self getBookItemAbsPath:bookPage fileName:nil];
    }
    
    if(dir == nil)
        return false;
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:dir])
    {
            NSError *error = nil;
            //create directory.
            BOOL success = [[NSFileManager defaultManager] createDirectoryAtURL:[NSURL fileURLWithPath:dir] withIntermediateDirectories:YES attributes:nil error:&error];
            if(!success)
            {
#ifdef DEBUG
                NSLog(@"error");
#endif
            }
    }
    return TRUE;
}

//create thumbnail for image.
+ (UIImage *) createThumbnail:(UIImage *)image isTitlePage:(BOOL)isTitlePage
{
    CGSize size;
    if(isTitlePage) //title page
        size = CGSizeMake(180, 200);
    else //page
        size = CGSizeMake(158, 100);
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0,0, size.width, size.height)];
    
    UIImage *thumbnailImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return thumbnailImage;
}

//get a new book instance.
+ (Book *)getNewBookInstance:(User *)user
{
    NSEntityDescription *bookDesc = [NSEntityDescription entityForName:@"Book" inManagedObjectContext:[DocumentHandler sharedDocumentHandler].document.managedObjectContext];
    NSError *error=nil;
    
    Book * book = [[Book alloc] initWithEntity:bookDesc insertIntoManagedObjectContext:[DocumentHandler sharedDocumentHandler].document.managedObjectContext];
    [[DocumentHandler sharedDocumentHandler].document.managedObjectContext obtainPermanentIDsForObjects:[[NSArray alloc] initWithObjects:book, nil] error:&error];
    book.author = user;
    book.approvalStatus = [NSNumber numberWithInt:BookApprovalStatusSaved];
    book.bookSizeKB = [NSNumber numberWithInt:0]; 
    book.createDate = [NSDate date];
    book.remoteId = [NSNumber numberWithInt:0];
    book.isDownloaded = [NSNumber numberWithInt:0];
    book.isPublished = [NSNumber numberWithInt:0];
    book.likeCount = [NSNumber numberWithInt:0];
    book.rejectionComment = @"";

    return book;
}

//get a new bookpage instance
+ (BookPage *)getNewBookPageInstance
{
    NSEntityDescription *bookPageDesc = [NSEntityDescription entityForName:@"BookPage" inManagedObjectContext:[DocumentHandler sharedDocumentHandler].document.managedObjectContext];
    
    BookPage * bookPage = [[BookPage alloc] initWithEntity:bookPageDesc insertIntoManagedObjectContext:[DocumentHandler sharedDocumentHandler].document.managedObjectContext];
    
    NSError *error=nil;
    [[DocumentHandler sharedDocumentHandler].document.managedObjectContext obtainPermanentIDsForObjects:[[NSArray alloc] initWithObjects:bookPage, nil] error:&error];
    
    bookPage.timeStamp = [NSDate date];
    bookPage.remoteId = [NSNumber numberWithInt:0];
    bookPage.videoCount = 0;
    bookPage.videoPathArray = [[NSData alloc] init];
    
    return bookPage;
}

+ (void) saveBook:(Book *)currentBook
{
    [currentBook setValue:[NSDate date] forKey:@"updateTimeStamp"];
    [[DocumentHandler sharedDocumentHandler] saveContext];
}

+ (void)saveBookPage:(BookPage *)currentBookPage
{
    [currentBookPage setValue:[NSDate date] forKey:@"timeStamp"];
    [[DocumentHandler sharedDocumentHandler] saveContext];
}

//get all books from core data.
+ (void)sortUserBooks:(User *)user
{
 //   NSLog(@"User has: %d book", [user.book count]);
    if([user.book count] ==0)
    {
        return;
    }

    NSMutableArray *saveAndRejectArray = [[NSMutableArray alloc]init];
    NSMutableArray *pendingArray = [[NSMutableArray alloc]init];
    NSMutableArray *approvedArray = [[NSMutableArray alloc]init];

    for(Book *book in user.book)
    {
        switch ([book.approvalStatus intValue]) {
            case BookApprovalStatusPending:
                [pendingArray addObject:book];
                break;
            case BookApprovalStatusApproved:
                [approvedArray addObject:book];
                break;
            case BookApprovalStatusSaved:
            case BookApprovalStatusRejected:
                [saveAndRejectArray addObject:book];
                break;
            default:
                break;
        }
    }
    
    //sort book
//    NSSortDescriptor *sortBookIsPublished =[NSSortDescriptor sortDescriptorWithKey:@"isPublished" ascending:YES];
//    NSSortDescriptor *sortBookApprovedStatus =[NSSortDescriptor sortDescriptorWithKey:@"approvalStatus" ascending:YES];
    //    NSArray *sortDescriptors = @[sortBookIsPublished,sortBookApprovedStatus,sortByUpdateTimeStampDesc];
    //    NSArray *bookArray  = [[user.book array] sortedArrayUsingDescriptors:sortDescriptors];

    NSSortDescriptor *sortByUpdateTimeStampDesc =[[NSSortDescriptor alloc]initWithKey:@"updateTimeStamp" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortByUpdateTimeStampDesc];
    NSMutableArray *bookArray = [[NSMutableArray alloc]init];
    
    if([saveAndRejectArray count]!=0)
    {
        [saveAndRejectArray sortUsingDescriptors:sortDescriptors];
        [bookArray addObjectsFromArray:saveAndRejectArray];
    }
    if([pendingArray count]!=0)
    {
        [pendingArray sortUsingDescriptors:sortDescriptors];
        [bookArray addObjectsFromArray:pendingArray];
    }
    if([approvedArray count]!=0)
    {
        [approvedArray sortUsingDescriptors:sortDescriptors];
        [bookArray addObjectsFromArray:approvedArray];
    }
    
    if([bookArray count]!=0)
        user.book = [NSOrderedSet orderedSetWithArray:bookArray];

    //sort bookpage
    NSSortDescriptor *sortBySortOrder =[[NSSortDescriptor alloc] initWithKey:@"sortOrder" ascending:YES];
    NSArray *ch = nil;
    for(Book * book in user.book)
    {
        ch = [[book.pages array] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortBySortOrder]];
        if([ch count]!=0)
            book.pages = [NSOrderedSet orderedSetWithArray:ch];
    }

    return;
}

//delete a book. (ipad only)
// ======================================================================================================================================
// Delete book and related date from iPad: Delete book, book's pages, audio files, images, and comments.
+ (void)deleteBook:(Book *)currentBook
{
    NSMutableSet * authors = [[NSMutableSet alloc] initWithCapacity:10];
    
    // Delete Book's file directory
    NSString *bookPath = [BookManager getBookItemAbsPath:currentBook fileName:nil];
    
    NSURL *bookDir = [NSURL fileURLWithPath:bookPath];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:bookPath isDirectory:nil])
    {
        //delete everything in the directory.
        [[NSFileManager defaultManager] removeItemAtURL:bookDir error:nil];
    }

    // Delete all book's comments
    NSArray * commentsToDelete = [currentBook.comments allObjects];
    for (Comment * comm in commentsToDelete)
    {
        [authors addObject:comm.author];
        [currentBook.managedObjectContext deleteObject:comm];
    }
 
    // Delete all pages
    NSArray * bookPagesToDelete = currentBook.pages.array;
    for (BookPage * page in bookPagesToDelete)
    {
        [currentBook.managedObjectContext deleteObject:page];
    }
    
    // delete book itself
    [authors addObject:currentBook.author];
    [currentBook.managedObjectContext deleteObject:currentBook];
 
    // commit changes
    [[DocumentHandler sharedDocumentHandler] saveContextAndWait];
    
    // Delete orphaned users
    [UserManager deleteUsersIfOrphan:authors.allObjects];
}

//delete a book page.
+ (void)deleteBookPage:(BookPage *)currentBookPage
{
    int order = [currentBookPage.sortOrder intValue];
    NSString *bookPagePath = [BookManager getBookItemAbsPath:currentBookPage fileName:nil];
    Book *book = currentBookPage.book;
    
    [[DocumentHandler sharedDocumentHandler] deleteContextForNSManagedObject:currentBookPage];
    
    //change and update pages that have the sort order if greater than the deleted page sort order.
    for (BookPage *otherBookPage in book.pages)
    {
        if([otherBookPage.sortOrder intValue] > order)
        {
            otherBookPage.sortOrder = [NSNumber numberWithInt:[otherBookPage.sortOrder intValue] - 1];
            
            NSError *error=nil;
            BookPage *bookPage = (BookPage *)[[DocumentHandler sharedDocumentHandler].document.managedObjectContext existingObjectWithID:[otherBookPage objectID] error:&error];
            if(bookPage != nil)
            {
                [bookPage setValue:otherBookPage.sortOrder forKey:@"sortOrder"];
                [[DocumentHandler sharedDocumentHandler] saveContext];
            }
//            NSLog(@"new other book Page:%d", [otherBookPage.sortOrder intValue]);
        }
//        else
//            NSLog(@"other book Page:%d", [otherBookPage.sortOrder intValue]);
    }
    //delete book page audio and images.
    NSError *error = NULL;
    BOOL *isDir = NULL;

    NSURL *bookPathURL = [NSURL fileURLWithPath:bookPagePath];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:bookPagePath isDirectory:isDir])
    {
        //delete everything in the directory.
        [[NSFileManager defaultManager] removeItemAtURL:bookPathURL error:&error];
    }
}

//this is for testing.
+ (void)printBookDetails:(Book *)book
{
    NSLog(@"====Printing book details for %@", book.title1);
    for(BookPage *page in book.pages)
    {
        NSLog(@"Page %d, text: %@", [page.sortOrder intValue], page.text1);
    }
    NSLog(@"====END");

}


// ======================================================================================================================================
// Get book as JSON data
+ (NSData *)jsonBookRepresentation:(Book *)book
{
    NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithCapacity:10];
    [data setObject:book.remoteId forKey:@"id"];
    [data setObject:(book.ageGroupRemoteId==nil? [NSNull null]:book.ageGroupRemoteId) forKey:@"ageGroupId"];
    [data setObject:book.primaryLanguage.remoteId forKey:@"primaryLanguageId"];
    [data setObject:book.secondaryLanguage.remoteId forKey:@"secondaryLanguageId"];
    [data setObject:(book.userGroup==nil? [NSNumber numberWithInt:0] : book.userGroup.remoteId) forKey:@"groupId"]; //book.userGroup.remoteId
    [data setObject:book.author.remoteId forKey:@"authorId"];//book.author.remoteId
    [data setObject:(book.title1==nil? [NSNull null]:book.title1) forKey:@"title1"];
    [data setObject:(book.title2==nil? [NSNull null]:book.title2) forKey:@"title2"];
    [data setObject:(book.description1==nil? [NSNull null]:book.description1) forKey:@"description1"];
    [data setObject:(book.description2==nil? [NSNull null]:book.description2) forKey:@"description2"];
    [data setObject:@"" forKey:@"voice1"];
    [data setObject:@"" forKey:@"voice2"];
    [data setObject:@"" forKey:@"voiceTitle1"];
    [data setObject:@"" forKey:@"voiceTitle2"];
    [data setObject:@"" forKey:@"image"];
    [data setObject:@"" forKey:@"thumbnailImage"];
    [data setObject:(book.backgroundColorCode==nil? [NSNull null]:book.backgroundColorCode) forKey:@"imageBgColor"];
    [data setObject:[NSNumber numberWithInt:0] forKey:@"hidden"];
    [data setObject:[Utilities NSDateToJSONString:book.createDate] forKey:@"dateAdded"];
    [data setObject:@"PENDING" forKey:@"approvalStatus"];
    [data setObject:[NSNumber numberWithInt:0]  forKey:@"downloadCount"];
    [data setObject:[NSNull null] forKey:@"rejectionComment"];
    [data setObject:(book.bookSizeKB==nil? [NSNumber numberWithInt:0] : book.bookSizeKB) forKey:@"bookSizeKB"];
    [data setObject:(book.tagSummary==nil? [NSNull null]:book.tagSummary) forKey:@"tagSummary"];
    
    return [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:NULL];
}

// ======================================================================================================================================
// Get this bookPages as JSON data
+ (NSData *)jsonBookPagesRepresentation:(NSOrderedSet *)bookPages
{
    NSMutableArray *bookPagesdata = [[NSMutableArray alloc]initWithCapacity:[bookPages count]];
        
    for(BookPage *bp in bookPages)
    {
        NSMutableDictionary *bookData = [[NSMutableDictionary alloc] initWithCapacity:10];
        [bookData setObject:bp.book.remoteId forKey:@"bookId"];
        [bookData setObject:bp.remoteId forKey:@"id"];
        [bookData setObject:(bp.text1 == nil? [NSNull null]:bp.text1) forKey:@"text1"];
        [bookData setObject:(bp.text2 == nil? [NSNull null]:bp.text2) forKey:@"text2"];
        [bookData setObject:(bp.backgroundColorCode == nil? [NSNull null]:bp.backgroundColorCode) forKey:@"imageBgColor"];
        [bookData setObject:bp.sortOrder forKey:@"sortOrder"];
        [bookData setObject:[Utilities NSDateToJSONString:bp.timeStamp] forKey:@"timeStamp"];
        [bookPagesdata addObject:bookData];
    }
    return [NSJSONSerialization dataWithJSONObject:bookPagesdata options:NSJSONWritingPrettyPrinted error:NULL];
}

// ======================================================================================================================================
// update book status, reject message for pending approval books.
+ (void)updateBookPendingStatus:(NSDictionary *) bookList
{
    NSMutableArray * arr = [bookList objectForKey:@"approved"];
    NSDictionary * rejectedDict = [bookList objectForKey:@"rejected"];
    NSDictionary * deleteDict = [bookList objectForKey:@"deleted"];
    
    //change the approved status
    for(NSString *remoteId in arr)
    {
        Book * bookObj = [BookManager getBookByRemoteId:[remoteId intValue]];
        bookObj.isDownloaded   = [NSNumber numberWithBool:YES];
        bookObj.isHidden       = [NSNumber numberWithBool:FALSE];
        bookObj.approvalStatus = [NSNumber numberWithInt:BookApprovalStatusApproved];
        bookObj.isPublished    = [NSNumber numberWithBool:YES];
        bookObj.updateTimeStamp    = [NSDate date];
    }
    
    //change the approved status
    for(NSString *key in rejectedDict)
    {
        Book * bookObj = [BookManager getBookByRemoteId:[key intValue]];
        bookObj.isDownloaded   = [NSNumber numberWithBool:NO];
        bookObj.isHidden       = [NSNumber numberWithBool:TRUE];
        bookObj.approvalStatus = [NSNumber numberWithInt:BookApprovalStatusRejected];
        bookObj.isPublished    = [NSNumber numberWithBool:NO];
        bookObj.updateTimeStamp    = [NSDate date];
        bookObj.rejectionComment = [rejectedDict objectForKey:key];
    }

    //delete book if it is no longer exists
    for(NSString *remoteId in deleteDict)
    {
        Book * bookObj = [BookManager getBookByRemoteId:[remoteId intValue]];
        [self deleteBook:bookObj];
    }
    [[DocumentHandler sharedDocumentHandler] saveContext];
}

// ======================================================================================================================================
// check which books in the specified list of IDs already exists in the CoreData. Return only IDs of the missing books what need to be downloaded.
+ (NSArray*) getMissingRemoteIdsFromListOfRemoteIds:(NSArray*) remoteIds
{
    NSPredicate * predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"remoteId IN {%@}", [remoteIds componentsJoinedByString:@","]]];
    NSArray * books = [[DocumentHandler sharedDocumentHandler] fetchContextForEntity:@"Book" predicate:predicate sortDescriptors:nil];
    
    NSMutableArray * newList = [NSMutableArray arrayWithArray:remoteIds];
    
    for (Book * book in books)
    {
        [newList removeObject:book.remoteId];
        
        if (book.isDownloaded.boolValue == NO)
        {
            book.updateTimeStamp = [NSDate date];   // update last search hit timestamp, so that we keep this book longer.
        }
    }
    
    [[DocumentHandler sharedDocumentHandler] saveContextAndWait];
    return newList;
}

// ======================================================================================================================================
// Get all books in core data specified by Remote IDs 
+ (NSArray*) booksByRemoteIds:(NSArray*) remoteIds
{
    if (remoteIds == nil || [remoteIds count] == 0)
        return [[NSArray alloc] init];
    
    NSPredicate * predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"remoteId IN {%@}", [remoteIds componentsJoinedByString:@","]]];
    return [[DocumentHandler sharedDocumentHandler] fetchContextForEntity:@"Book" predicate:predicate sortDescriptors:nil];
}

// ======================================================================================================================================
// Retrieve book by remote ID
+ (Book *)getBookByRemoteId:(int) remoteId
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"remoteId = %d", remoteId];
    NSArray *objects = [[DocumentHandler sharedDocumentHandler] fetchContextForEntity:@"Book" predicate:predicate sortDescriptors:nil];
    
    Book * book = nil;
    
    if (objects != nil && [objects count] > 0)
        book = [objects objectAtIndex:0];

    return book;
}

// ======================================================================================================================================
// Save a new book preview (without pages, sound) or update existing one.
+ (void) addOrUpdateBookPreviews:(NSArray *)bookPreviewList
{
    for(NSDictionary *item in bookPreviewList)
    {
        if(item == nil)
            continue;
        
        Book * bookObj = [BookManager getBookByRemoteId:[[item objectForKey:@"id"] intValue]];
        
        if (bookObj == nil)
        {
            bookObj = [NSEntityDescription insertNewObjectForEntityForName:@"Book" inManagedObjectContext:[DocumentHandler sharedDocumentHandler].document.managedObjectContext];
            [bookObj.managedObjectContext obtainPermanentIDsForObjects:[NSArray arrayWithObject:bookObj] error:NULL];
        }

        [bookObj setBasicDataFromDictionary:item];
        bookObj.likeCount           = [item objectForKey:@"likeCount"];
        bookObj.author              = [UserManager getUserByRemoteId:[[item objectForKey:@"authorId"] intValue]];
        bookObj.primaryLanguage     = [LanguageManager getLanguageByRemoteId:[[item objectForKey:@"primaryLanguageId"] intValue]];
        bookObj.secondaryLanguage   = [LanguageManager getLanguageByRemoteId:[[item objectForKey:@"secondaryLanguageId"] intValue]];
        bookObj.updateTimeStamp     = [NSDate date];

        bookObj.tagSummary          = @"";
        if ([item objectForKey:@"tagSummary"] != [NSNull null])
        {
            bookObj.tagSummary      = [item objectForKey:@"tagSummary"];
            bookObj.tagSummary      = [bookObj.tagSummary stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
        
        // --- save cover image --------

        if ([item objectForKey:@"image"] != [NSNull null])
        {
            NSString * imgString = [item objectForKey:@"image"];
            if (imgString != nil && ![imgString isEqualToString:@""])
            {
                UIImage * image = [UIImage imageWithData:[Utilities base64DataFromString:[item objectForKey:@"image"]]];
                [BookManager saveImage:image item:bookObj filename:BOOK_IMAGE_FILENAME];
            }
        }

        // --- save cover image thumbnail --------
        
        if ([item objectForKey:@"thumbnailImage"] != [NSNull null])
        {
            NSString * imgString = [item objectForKey:@"thumbnailImage"];
            if (imgString != nil && ![imgString isEqualToString:@""])
            {
                UIImage * image = [UIImage imageWithData:[Utilities base64DataFromString:[item objectForKey:@"thumbnailImage"]]];
                [BookManager saveImage:image item:bookObj filename:BOOK_THUMBNAIL_FILENAME];
            }
        }
    }

    [[DocumentHandler sharedDocumentHandler] saveContextAndWait];
}

// ======================================================================================================================================
// Save a new book preview with group id (without pages, sound) or update existing one.
+ (void) addOrUpdateBookPreviewsWithGroup:(NSArray *)bookPreviewList
{
    for(NSDictionary *item in bookPreviewList)
    {
        if(item == nil)
            continue;
        
        Book * bookObj = [BookManager getBookByRemoteId:[[item objectForKey:@"id"] intValue]];
        
        if (bookObj == nil)
        {
            bookObj = [NSEntityDescription insertNewObjectForEntityForName:@"Book" inManagedObjectContext:[DocumentHandler sharedDocumentHandler].document.managedObjectContext];
            [bookObj.managedObjectContext obtainPermanentIDsForObjects:[NSArray arrayWithObject:bookObj] error:NULL];
        }
        
        [bookObj setBasicDataFromDictionary:item];
        bookObj.likeCount           = [item objectForKey:@"likeCount"];
        bookObj.author              = [UserManager getUserByRemoteId:[[item objectForKey:@"authorId"] intValue]];
        bookObj.primaryLanguage     = [LanguageManager getLanguageByRemoteId:[[item objectForKey:@"primaryLanguageId"] intValue]];
        bookObj.secondaryLanguage   = [LanguageManager getLanguageByRemoteId:[[item objectForKey:@"secondaryLanguageId"] intValue]];
        bookObj.updateTimeStamp     = [NSDate date];
        if([item objectForKey:@"groupId"]   != [NSNull null])
        {
            int groupR              = [[item objectForKey:@"groupId"] intValue];
            bookObj.userGroup       = [UserGroupManager getUserGroupByRemoteId:groupR];
        }
        bookObj.tagSummary          = @"";
        if ([item objectForKey:@"tagSummary"] != [NSNull null])
        {
            bookObj.tagSummary      = [item objectForKey:@"tagSummary"];
            bookObj.tagSummary      = [bookObj.tagSummary stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
        
        // --- save cover image --------
        
        if ([item objectForKey:@"image"] != [NSNull null])
        {
            NSString * imgString = [item objectForKey:@"image"];
            if (imgString != nil && ![imgString isEqualToString:@""])
            {
                UIImage * image = [UIImage imageWithData:[Utilities base64DataFromString:[item objectForKey:@"image"]]];
                [BookManager saveImage:image item:bookObj filename:BOOK_IMAGE_FILENAME];
            }
        }
        
        // --- save cover image thumbnail --------
        
        if ([item objectForKey:@"thumbnailImage"] != [NSNull null])
        {
            NSString * imgString = [item objectForKey:@"thumbnailImage"];
            if (imgString != nil && ![imgString isEqualToString:@""])
            {
                UIImage * image = [UIImage imageWithData:[Utilities base64DataFromString:[item objectForKey:@"thumbnailImage"]]];
                [BookManager saveImage:image item:bookObj filename:BOOK_THUMBNAIL_FILENAME];
            }
        }
    }
    
    [[DocumentHandler sharedDocumentHandler] saveContextAndWait];
}

// ======================================================================================================================================
// Return all Book object for books that are downloaded to this iPad
+ (NSArray *) getDownloadedBooks
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isDownloaded = %@", [NSNumber numberWithBool:YES]];
    
    NSSortDescriptor * sort = [NSSortDescriptor sortDescriptorWithKey:@"downloadDate" ascending:NO];
   // FOR SOME REASON THIS DOESN"T WORK: NSArray *objects = [[DocumentHandler sharedDocumentHandler] fetchContextForEntity:@"Book" predicate:predicate sortDescriptors:[NSArray arrayWithObject:sort]];
    NSArray *objects = [[DocumentHandler sharedDocumentHandler] fetchContextForEntity:@"Book" predicate:predicate sortDescriptors:nil];
    return [objects sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]];
}

// ======================================================================================================================================
// return a comma-delimited list of downloaded book ids, or "none" if no books have been downloaded
+ (NSString *) getDownloadedBooksRemoteIds
{
    // Get all downloaded books
    NSArray * books = [BookManager getDownloadedBooks];
    NSMutableString * bookIds = [[NSMutableString alloc] init];
    
    if ([books count] == 0)
        return @"none";
    
    for (Book * b in books)
    {
        [bookIds appendFormat:@",%d", b.remoteId.intValue];
    }
    return [bookIds substringFromIndex:1];
}

// ======================================================================================================================================
// Get book page by remoteId
+ (BookPage *) getPageByRemoteId:(int) remoteId
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:[@"remoteId = " stringByAppendingString:[NSString stringWithFormat:@"%d", remoteId]]];
    NSArray *objects = [[DocumentHandler sharedDocumentHandler] fetchContextForEntity:@"BookPage" predicate:predicate sortDescriptors:nil];
    
    BookPage * page = nil;
    
    if (objects != nil && [objects count] > 0)
        page = [objects objectAtIndex:0];
    
    return page;
}

// ======================================================================================================================================
// Create or update book pages with data in array of NSDictionaries. 
+ (void) addOrUpdateDownloadedBookPagesWithoutFilesWithData:(NSArray *)pageList book:(Book*)book
{
    for(NSDictionary *item in pageList)
    {
        if(item == nil)
            continue;
        
        BookPage * page = [BookManager getPageByRemoteId:[[item objectForKey:@"id"] intValue]];
        
        if (page == nil)
        {
            page = [NSEntityDescription insertNewObjectForEntityForName:@"BookPage" inManagedObjectContext:[DocumentHandler sharedDocumentHandler].document.managedObjectContext];
            [page.managedObjectContext obtainPermanentIDsForObjects:[NSArray arrayWithObject:page] error:nil];
            page.book = book;
            page.remoteId = [item objectForKey:@"id"];
        }
        
        NSNumber * interval = [item objectForKey:@"timeStamp"];
        page.timeStamp      = [NSDate dateWithTimeIntervalSince1970:[interval doubleValue] / 1000L];    // date form java time stamp
        
        page.backgroundColorCode    = [item objectForKey:@"imageBgColor"];
        page.sortOrder              = [item objectForKey:@"sortOrder"];
        page.text1                  = [item objectForKey:@"text1"];
        page.text2                  = [item objectForKey:@"text2"];
    }
    
    [[DocumentHandler sharedDocumentHandler] saveContextAndWait];
}

// ======================================================================================================================================
// Reduce the book from "Downloaded" to "Preview" version: Delete downloaded book's pages, audio files, pages' images, and comments.
+ (void) deleteDownloadedBookButKeepPreview:(Book*)book
{
    if (!book.isDownloaded.boolValue)
        return;

    NSMutableSet * authors = [[NSMutableSet alloc] initWithCapacity:10];
    
    NSString * tempDir = [NSTemporaryDirectory() stringByAppendingPathComponent:[[[book objectID] URIRepresentation] lastPathComponent]];
    [[NSFileManager defaultManager] createDirectoryAtPath:tempDir withIntermediateDirectories:YES attributes:nil error:nil];
    NSString * tempImagePath = [tempDir stringByAppendingPathComponent:BOOK_IMAGE_FILENAME];
    NSString * tempThumbPath = [tempDir stringByAppendingPathComponent:BOOK_THUMBNAIL_FILENAME];
    NSString * permImagePath = [BookManager getBookItemAbsPath:book fileName:BOOK_IMAGE_FILENAME];
    NSString * permThumbPath = [BookManager getBookItemAbsPath:book fileName:BOOK_THUMBNAIL_FILENAME];
    

    // 1. Move preview images (cover page's image and thumbnail) to the temp directory
    [[NSFileManager defaultManager] moveItemAtPath:permImagePath toPath:tempImagePath error:nil];
    [[NSFileManager defaultManager] moveItemAtPath:permThumbPath toPath:tempThumbPath error:nil];
    
    // 2. Delete Book's directory
    NSString *bookPath = [BookManager getBookItemAbsPath:book fileName:nil];
    NSURL *bookDir = [NSURL fileURLWithPath:bookPath];
    if([[NSFileManager defaultManager] fileExistsAtPath:bookPath isDirectory:nil])
    {
        //delete everything in the directory.
       [[NSFileManager defaultManager] removeItemAtURL:bookDir error:nil];
   }
    
    // 3. Copy cover page images back to book's folder
    [BookManager createDirIfNotExist:book];
    [[NSFileManager defaultManager] moveItemAtPath:tempImagePath toPath:permImagePath error:nil];
    [[NSFileManager defaultManager] moveItemAtPath:tempThumbPath toPath:permThumbPath error:nil];
    
    // 4. Mark Book as not downloaded
    book.isDownloaded = [NSNumber numberWithBool:NO];
    
    // 5. Delete all comments
    for (Comment * comm in book.comments)
    {
        [authors addObject:comm.author];
        [book.managedObjectContext deleteObject:comm];
    }
    
    // 6. Delete all book pages
    for (BookPage * page in book.pages)
    {
        [book.managedObjectContext deleteObject:page];
    }
    
    // 7. Delete user connections
    book.flaggedBy = nil;
    book.likedBy = nil;
    
    [[DocumentHandler sharedDocumentHandler] saveContextAndWait];
    
    // 8. remove orphaned users
    [UserManager deleteUsersIfOrphan:authors.allObjects];
}

// ======================================================================================================================================
// Delete all book preview that haven't been hit by searches in a log time (last access date specified as parameter)
+ (void) deleteBookPreviewsLastViewdBefore:(NSDate*)date;
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"updateTimeStamp <= %@ AND isDownloaded = %@", date, [NSNumber numberWithBool:NO]];
    NSArray * bookArr = [[DocumentHandler sharedDocumentHandler] fetchContextForEntity:@"Book" predicate:predicate sortDescriptors:nil];
    
    for (Book * book in bookArr)
    {
        [BookManager deleteBook:book];
    }
}

// ======================================================================================================================================
// Mark specified books as flagged by this user and create necesary relational links.
// Book must be downloaded, User must be logged-in
+ (void) flagBooksInTheList:(NSArray*) bookRemoteIds byUser:(User*)user
{
    if (user == nil || !user.isLoggedIn.boolValue)
        return;
    
    for (NSNumber * number in bookRemoteIds)
    {
        Book * book = [BookManager getBookByRemoteId:number.intValue];
        if (book != nil)
        {
            book.flaggedBy = user;
        }
    }
    
    [[DocumentHandler sharedDocumentHandler] saveContextAndWait];
}

// ======================================================================================================================================
// Mark specified books as liked by this user and create necesary relational links.
// Book must be downloaded, User must be logged-in
+ (void) likeBooksInTheList:(NSArray*) bookRemoteIds byUser:(User*)user
{
    if (user == nil || !user.isLoggedIn.boolValue)
        return;
    
    for (NSNumber * number in bookRemoteIds)
    {
        Book * book = [BookManager getBookByRemoteId:number.intValue];
        if (book != nil)
        {
            book.likedBy = user;
        }
    }
    
    [[DocumentHandler sharedDocumentHandler] saveContextAndWait];
}

// ======================================================================================================================================
// Add book group reference to the book. Group and Book relations are specified by the paramenter,
// which contains array of ["groupId":remoteId, "bookId":remoteId] dictionaries
// Book must be downloaded.
+ (void) linkBooksToGroups:(NSArray*) bookIdGroupIdTuples
{
    if (bookIdGroupIdTuples == nil)
        return;
    
    for (NSDictionary * item in bookIdGroupIdTuples)
    {
        if (item == nil)
            continue;
        
        Book * book = [BookManager getBookByRemoteId:[[item objectForKey:@"bookId"] intValue]];
        if (book == nil)
            continue;
        
        UserGroups * group = [UserGroupManager getUserGroupByRemoteId:[[item objectForKey:@"groupId"] intValue]];
        if (group == nil)
            continue;
        
        book.userGroup = group;
    }
    
    [[DocumentHandler sharedDocumentHandler] saveContextAndWait];
}
@end
