//
//  DocumentHandler.h
//  Scribjab
//
//  Created by Gladys Tang on 12-10-17.
//
//

#import <Foundation/Foundation.h>
#import "ManagedDocument.h"
//typedef void (^OnDocumentReady) (UIManagedDocument *document);


@protocol DocumentHandlerDelegate <NSObject>

// Indicates that UIManagedDocument ihas been created/loaded successfully or not.
-(void) documentLoadedAndIsReady:(BOOL)ready;

@end







@interface DocumentHandler : NSObject 

@property (strong, nonatomic) ManagedDocument *document;
@property (nonatomic, weak) id<DocumentHandlerDelegate> delegate;

//@property (strong, nonatomic) UIViewController *viewController;

//get a shared document handler.
+ (DocumentHandler *)sharedDocumentHandlerWithDelegate:(id)delegate;
+ (DocumentHandler *)sharedDocumentHandler;

- (id)initWithDelegate:(id)delegate;

// **************************
// SYNCHRONOUS METHODS

//save a NSManagedObject to store.
- (void)saveContext;            // same as function below, can be removed 
- (void)saveContextAndWait;     // save context and wait block until done.

//delete a NSManagedObject in store. SYNCHRONOUSLY
- (void)deleteContextForNSManagedObject:(NSManagedObject *)model;   // same as method below. Can be deleted if not used
- (void)deleteAndWaitContextForNSManagedObject:(NSManagedObject *)model;   // delete and block until finished

//fetch data from store
- (NSArray *)fetchContextForEntity:(NSString *)entityName predicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors;

// **************************
// ASYNCHRONOUS METHODS

- (void)saveContextAsyncWithCompletionHandler:(void (^)(BOOL success)) completionHandler;                                       // save context asynchronously.
- (void)deleteContextAsyncForNSManagedObject:(NSManagedObject *)model completionHandler:(void (^)(BOOL success)) completionHandler;  // delete NSManagedObject asynchronously.

@end