//
//  RCloudFMDatabaseQueue.h
//  fmdb
//
//  Created by August Mueller on 6/22/11.
//  Copyright 2011 Flying Meat Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCloudFMDatabase;

/** To perform queries and updates on multiple threads, you'll want to use `RCloudFMDatabaseQueue`.

 Using a single instance of `<RCloudFMDatabase>` from multiple threads at once is a bad idea.  It has always been OK to
 make a `<RCloudFMDatabase>` object *per thread*.  Just don't share a single instance across threads, and definitely not
 across multiple threads at the same time.

 Instead, use `RCloudFMDatabaseQueue`. Here's how to use it:

 First, make your queue.

    RCloudFMDatabaseQueue *queue = [RCloudFMDatabaseQueue databaseQueueWithPath:aPath];

 Then use it like so:

    [queue inDatabase:^(RCloudFMDatabase *db) {
        [db executeUpdate:@"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:1]];
        [db executeUpdate:@"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:2]];
        [db executeUpdate:@"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:3]];

        RCloudFMResultSet *rs = [db executeQuery:@"select * from foo"];
        while ([rs next]) {
            //…
        }
    }];

 An easy way to wrap things up in a transaction can be done like this:

    [queue inTransaction:^(RCloudFMDatabase *db, BOOL *rollback) {
        [db executeUpdate:@"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:1]];
        [db executeUpdate:@"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:2]];
        [db executeUpdate:@"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:3]];

        if (whoopsSomethingWrongHappened) {
            *rollback = YES;
            return;
        }
        // etc…
        [db executeUpdate:@"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:4]];
    }];

 `RCloudFMDatabaseQueue` will run the blocks on a serialized queue (hence the name of the class).  So if you call
 `RCloudFMDatabaseQueue`'s methods from multiple threads at the same time, they will be executed in the order they are
 received.  This way queries and updates won't step on each other's toes, and every one is happy.

 ### See also

 - `<RCloudFMDatabase>`

 @warning Do not instantiate a single `<RCloudFMDatabase>` object and use it across multiple threads. Use
 `RCloudFMDatabaseQueue` instead.

 @warning The calls to `RCloudFMDatabaseQueue`'s methods are blocking.  So even though you are passing along blocks,
 they will **not** be run on another thread.

 */

@interface RCloudFMDatabaseQueue : NSObject {
    NSString *_path;
    dispatch_queue_t _queue;
    RCloudFMDatabase *_db;
    int _openFlags;
}

/** Path of database */

@property (atomic, retain) NSString *path;

/** Open flags */

@property (atomic, readonly) int openFlags;

///----------------------------------------------------
/// @name Initialization, opening, and closing of queue
///----------------------------------------------------

/** Create queue using path.

 @param aPath The file path of the database.

 - Returns: The `RCloudFMDatabaseQueue` object. `nil` on error.
 */

+ (instancetype)databaseQueueWithPath:(NSString *)aPath;

/** Create queue using path and specified flags.

 @param aPath The file path of the database.
 @param openFlags Flags passed to the openWithFlags method of the database

 - Returns: The `RCloudFMDatabaseQueue` object. `nil` on error.
 */
+ (instancetype)databaseQueueWithPath:(NSString *)aPath flags:(int)openFlags;

/** Create queue using path.

 @param aPath The file path of the database.

 - Returns: The `RCloudFMDatabaseQueue` object. `nil` on error.
 */

- (instancetype)initWithPath:(NSString *)aPath;

/** Create queue using path and specified flags.

 @param aPath The file path of the database.
 @param openFlags Flags passed to the openWithFlags method of the database

 - Returns: The `RCloudFMDatabaseQueue` object. `nil` on error.
 */

- (instancetype)initWithPath:(NSString *)aPath flags:(int)openFlags;

/** Create queue using path and specified flags.

 @param aPath The file path of the database.
 @param openFlags Flags passed to the openWithFlags method of the database
 @param vfsName The name of a custom virtual file system

 - Returns: The `RCloudFMDatabaseQueue` object. `nil` on error.
 */

- (instancetype)initWithPath:(NSString *)aPath flags:(int)openFlags vfs:(NSString *)vfsName;

/** Returns the Class of 'RCloudFMDatabase' subclass, that will be used to instantiate database object.

 Subclasses can override this method to return specified Class of 'RCloudFMDatabase' subclass.

 - Returns: The Class of 'RCloudFMDatabase' subclass, that will be used to instantiate database object.
 */

+ (Class)databaseClass;

/** Close database used by queue. */

- (void)close;

///-----------------------------------------------
/// @name Dispatching database operations to queue
///-----------------------------------------------

/** Synchronously perform database operations on queue.

 @param block The code to be run on the queue of `RCloudFMDatabaseQueue`
 */

- (void)inDatabase:(void (^)(RCloudFMDatabase *db))block;

/** Synchronously perform database operations on queue, using transactions.

 @param block The code to be run on the queue of `RCloudFMDatabaseQueue`
 */

- (void)inTransaction:(void (^)(RCloudFMDatabase *db, BOOL *rollback))block;

/** Synchronously perform database operations on queue, using deferred transactions.

 @param block The code to be run on the queue of `RCloudFMDatabaseQueue`
 */

- (void)inDeferredTransaction:(void (^)(RCloudFMDatabase *db, BOOL *rollback))block;

///-----------------------------------------------
/// @name Dispatching database operations to queue
///-----------------------------------------------

/** Synchronously perform database operations using save point.

 @param block The code to be run on the queue of `RCloudFMDatabaseQueue`
 */

// NOTE: you can not nest these, since calling it will pull another database out of the pool and you'll get a deadlock.
// If you need to nest, use FMDatabase's startSavePointWithName:error: instead.
- (NSError *)inSavePoint:(void (^)(RCloudFMDatabase *db, BOOL *rollback))block;

@end
