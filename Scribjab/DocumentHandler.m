//
//  DocumentHandler.m
//  Scribjab
//
//  Created by Gladys Tang on 12-10-17.
//
//

#import "DocumentHandler.h"
#import "Language.h"
#import "Utilities.h"

@interface DocumentHandler ()
- (void)objectsDidChange:(NSNotification *)notification;
- (void)contextDidSave:(NSNotification *)notification;
- (void)checkDocumentStateForErrors;
@end;

@implementation DocumentHandler

@synthesize document = _document;
@synthesize delegate = _delegate;

static DocumentHandler *sharedInstance =nil;

+ (DocumentHandler *)sharedDocumentHandlerWithDelegate:(id)delegate
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[DocumentHandler alloc] initWithDelegate:delegate];
    });
    
    return sharedInstance;
}

+ (DocumentHandler *)sharedDocumentHandler
{
    return [DocumentHandler sharedDocumentHandlerWithDelegate:nil];
    /*
    static dispatch_once_t once;
    dispatch_once(&once, ^{
            sharedInstance = [[DocumentHandler alloc] init];
    });
    
    return sharedInstance;
     */
}

// add or save context SYNCHRONOUSLY. Same as "saveContextAndWait" below. Can be deleted is not used
- (void)saveContext
{
    [self saveContextAndWait];
}

// save context and wait block until done.
- (void)saveContextAndWait
{
    [self checkDocumentStateForErrors];
    
    [_document.managedObjectContext performBlockAndWait:^{
        [_document saveToURL:_document.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
//            NSLog(@"success? %d", success);
        }];
    }];
}

// save context ASYNCHRONOUSLY.
- (void)saveContextAsyncWithCompletionHandler:(void (^)(BOOL success)) completionHandler
{
    [self checkDocumentStateForErrors];
    
    [_document.managedObjectContext performBlock:^{
        [_document saveToURL:_document.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
//             NSLog(@"success? %d", success);
            return completionHandler(success);
        }];
    }];
}



- (NSArray *)fetchContextForEntity:(NSString *)entityName predicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors
{
    [self checkDocumentStateForErrors];
    
    NSEntityDescription *userDesc = [NSEntityDescription entityForName:entityName inManagedObjectContext:_document.managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:userDesc];
    
    if(predicate != nil)
       request.predicate = predicate;
    
    if (sortDescriptors != nil)
        request.sortDescriptors = sortDescriptors;
    
    NSError *error;
    NSArray *objects =[_document.managedObjectContext executeFetchRequest:request error:&error];
    return objects;
}

// delete context. SYNCHRONOUS CALL. same as deleteAndWaitContextForNSManagedObject method below. Delete if not used any more
- (void)deleteContextForNSManagedObject:(NSManagedObject *)model
{
    [self deleteAndWaitContextForNSManagedObject:model];
}

   // delete and block until finished. SYNCHRONOUS CALL
- (void)deleteAndWaitContextForNSManagedObject:(NSManagedObject *)model
{
    [self checkDocumentStateForErrors];
    
    [_document.managedObjectContext deleteObject:model];
    
    [_document.managedObjectContext performBlockAndWait:^{
        [_document saveToURL:_document.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success){
//            NSLog(@"delete success?%d", success);
        }];
    }];
}

// delete NSManagedObject ASYNCHRONOUSLY.
- (void)deleteContextAsyncForNSManagedObject:(NSManagedObject *)model completionHandler:(void (^)(BOOL success)) completionHandler
{
    [self checkDocumentStateForErrors];
    
    [_document.managedObjectContext deleteObject:model];
    
    [_document.managedObjectContext performBlock:
    ^{
        [_document saveToURL:_document.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success){
            //NSLog(@"delete success?%d", success);
            return completionHandler(success);
        }];
    }];
}


- (void)setDocument:(ManagedDocument *)document
{
    if (_document != document) {
        _document = document;
        [self useDocument];
    }
}

// check the state of the document. If not exist, create it. If not open, open it.
- (void)useDocument
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:[self.document.fileURL path]])
    {
        [self.document saveToURL:self.document.fileURL
                forSaveOperation:UIDocumentSaveForCreating
               completionHandler:^(BOOL success){
                   
                   // Make sure that coreData database is not backed up to iCloud
                   [Utilities excludeFromBackupItemAtURL:self.document.fileURL];
                  
                   if ([self.delegate respondsToSelector:@selector(documentLoadedAndIsReady:)])
                   {
                       [self.delegate documentLoadedAndIsReady:success];
                   }
//                   NSLog(@"DB created.");
               }];
    }
    else if (self.document.documentState == UIDocumentStateClosed)
    {
        [self.document openWithCompletionHandler:^(BOOL success)
        {
            if ([self.delegate respondsToSelector:@selector(documentLoadedAndIsReady:)])
            { [self.delegate documentLoadedAndIsReady:success];}
           //  NSLog(@"DB opened");
        }];
    }
    else if (self.document.documentState == UIDocumentStateNormal)
    {
        if ([self.delegate respondsToSelector:@selector(documentLoadedAndIsReady:)])
        { [self.delegate documentLoadedAndIsReady:YES];}
//        NSLog(@"DB in normal state");
    }
    else if (self.document.documentState == UIDocumentStateSavingError)
    {
        if ([self.delegate respondsToSelector:@selector(documentLoadedAndIsReady:)])
        { [self.delegate documentLoadedAndIsReady:NO];}
//        NSLog(@"DB error");
    }
}

// init the Document handler. 
- (id)initWithDelegate:(id)delegate
{
    self = [super init];
    if (self)
    {
        self.delegate = delegate;
        NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
        
        url = [url URLByAppendingPathComponent:@"MyDocument.md"]; //this should be in properities file or a constant.
        
        self.document = [[ManagedDocument alloc] initWithFileURL:url];
        // Set our document up for automatic migrations and will have a persistentStore.
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                                 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
        self.document.persistentStoreOptions = options;
        
        
        
        // Register for notifications. This is not used for now but maybe useful later.
        /**
         *      IMPORTANT: responding to a notification, e.g. NSManagedObjectContextDidSaveNotification, from the Google Analytics CoreData
         *      object may result in an exception. Instead, Apple recommends filtering CoreData notifications by specifying the managed object
         *      context as a parameter to your listener.
         *      see: https://developers.google.com/analytics/devguides/collection/ios/v3/
         *
         **/
         
/*        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(objectsDidChange:)
                                                     name:NSManagedObjectContextObjectsDidChangeNotification
                                                   object:self.document.managedObjectContext];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(contextDidSave:)
                                                     name:NSManagedObjectContextDidSaveNotification
                                                   object:self.document.managedObjectContext];*/
    }
    return self;
}

- (void)objectsDidChange:(NSNotification *)notification
{
#ifdef DEBUG
//    NSLog(@"NSManagedObjects did change.");
#endif
}

- (void)contextDidSave:(NSNotification *)notification
{
#ifdef DEBUG
 //   NSLog(@"NSManagedContext did save.");
#endif
}

- (void)checkDocumentStateForErrors
{
#ifdef DEBUG
    if (_document.documentState == UIDocumentStateClosed)
        NSLog(@"CoreData ERROR: Document State is CLOSED");
    else if (_document.documentState == UIDocumentStateInConflict)
        NSLog(@"CoreData ERROR: Document State is IN CONFLICT");
    else if (_document.documentState == UIDocumentStateSavingError)
        NSLog(@"CoreData ERROR: Document State is SAVING ERROR");
    else if (_document.documentState == UIDocumentStateEditingDisabled)
        NSLog(@"CoreData ERROR: Document State is EDITING DISABLED");
#endif
}
@end