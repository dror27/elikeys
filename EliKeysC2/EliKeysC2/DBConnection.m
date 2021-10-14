//
//  DBConnection.m
//  EliKeysC1
//
//  Created by Dror Kessler on 28/09/2021.
//

#import <Foundation/Foundation.h>
#import "DBConnection.h"
#import <UIKit/UIKit.h>
#include <sys/xattr.h>

//static sqlite3_stmt *statement = nil;

@interface DBConnection (Private)
- (void) createEditableCopyOfDatabaseIfNeeded;
- (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL;
- (void) initializeDatabase;
@end

@implementation DBConnection
static DBConnection *conn = NULL;

@synthesize database = g_database;

+ (DBConnection *) sharedConnection {
if (!conn) {
conn = [[DBConnection alloc] initConnection];
}
return conn;
}

#pragma mark - Static Methods

+(BOOL) executeQuery:(NSString *)query{
    BOOL isExecuted = NO;

    sqlite3 *database = [DBConnection sharedConnection].database;
    sqlite3_stmt *statement = nil;
    const char *sql = [query UTF8String];
    if (sqlite3_prepare_v2(database, sql, -1, &statement , NULL) != SQLITE_OK) {
        //NSLog(@"Error: failed to prepare agenda query statement with message '%s'.", sqlite3_errmsg(database));
        //NSString *errorMsg = [NSString stringWithFormat:@"Failed to prepare query statement - '%s'.", sqlite3_errmsg(database)];
        //[DBConnection errorMessage:errorMsg];
        //NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
        return isExecuted;
    }

    // Execute the query.
if(SQLITE_DONE == sqlite3_step(statement)) {
        isExecuted = YES;
    }

// finlize the statement.
sqlite3_finalize(statement);
    statement = nil;

    return isExecuted;
}
+(NSMutableArray *) fetchResults:(NSString *)query{
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:0];
    sqlite3 *database = [DBConnection sharedConnection].database;
    sqlite3_stmt *statement = nil;

    const char *sql = [query UTF8String];
    if (sqlite3_prepare_v2(database, sql, -1, &statement , NULL) != SQLITE_OK) {
        //NSLog(@"Error: failed to prepare fetch results statement with message '%s'.", sqlite3_errmsg(database));
        NSString *errorMsg = [NSString stringWithFormat:@"Failed to prepare query statement - '%s'.", sqlite3_errmsg(database)];
        [DBConnection errorMessage:errorMsg];
        //NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
        return results;
    }

    while (sqlite3_step(statement) == SQLITE_ROW) {

        id value = nil;
        NSMutableDictionary *rowDict = [NSMutableDictionary dictionaryWithCapacity:0];
        for (int i = 0 ; i < sqlite3_column_count(statement) ; i++) {

            /*
if (strcasecmp(sqlite3_column_decltype(statement,i),"Boolean") == 0) {
value = [NSNumber numberWithBool:(BOOL)sqlite3_column_int(statement,i)];
} else */

            if (sqlite3_column_type(statement,i) == SQLITE_INTEGER) {
                value = [NSNumber numberWithInt:(int)sqlite3_column_int(statement,i)];
            } else if (sqlite3_column_type(statement,i) == SQLITE_FLOAT) {
                value = [NSNumber numberWithFloat:(float)sqlite3_column_double(statement,i)];
            } else {

                if (sqlite3_column_text(statement,i) != nil) {
                    value = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,i)];
                } else {
                    value = @"";
                }
            }

            if (value) {
                [rowDict setObject:value forKey:[NSString stringWithUTF8String:sqlite3_column_name(statement,i)]];
            }
        }

        [results addObject:rowDict];
        ////NSLog(@"rowDict -- %@", rowDict);
    }

    sqlite3_finalize(statement);
    statement = nil;

    return results;
}
+(int) rowCountForTable:(NSString *)table where:(NSString *)where{
    int tableCount = 0;
NSString *query = @"";

    if (where != nil && ![where isEqualToString:@""]) {
        query = [NSString stringWithFormat:@"SELECT COUNT(*) FROM %@ WHERE %@",
                 table,where];
    } else {
        [NSString stringWithFormat:@"SELECT COUNT(*) FROM %@",
         table];
    }

sqlite3_stmt *statement = nil;

    sqlite3 *database = [DBConnection sharedConnection].database;
    const char *sql = [query UTF8String];
    if (sqlite3_prepare_v2(database, sql, -1, &statement , NULL) != SQLITE_OK) {
        return 0;
    }

if (sqlite3_step(statement) == SQLITE_ROW) {
        tableCount = sqlite3_column_int(statement,0);
    }

sqlite3_finalize(statement);
return tableCount;
}
+(void) errorMessage:(NSString *)msg{
    //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ERROR" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    //[alert show];
    //[alert release];
}
+(void) closeConnection{
    sqlite3 *database = [DBConnection sharedConnection].database;
    if (sqlite3_close(database) != SQLITE_OK) {
        //NSAssert1(0, @"Error: failed to close database with message '%s'.", sqlite3_errmsg(g_database));
        NSString *errorMsg = [NSString stringWithFormat:@"Failed to open database with message - '%s'.", sqlite3_errmsg(database)];
        [DBConnection errorMessage:errorMsg];
    }
}
-(id) initConnection {

    self = [super init];

if (self) {
//database = g_database;
if (g_database == nil) {
// The application ships with a default database in its bundle. If anything in the application
// bundle is altered, the code sign will fail. We want the database to be editable by users,
// so we need to create a copy of it in the application's Documents directory.
[self createEditableCopyOfDatabaseIfNeeded];
// Call internal method to initialize database connection
[self initializeDatabase];
}
}
return self;
}

#pragma mark - save db

-(void)createEditableCopyOfDatabaseIfNeeded {
    // First, test for existence.
    BOOL success;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dbDirectory = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"]]];

    if (![fileManager fileExistsAtPath:dbDirectory]) {
        [fileManager createDirectoryAtPath:dbDirectory withIntermediateDirectories:NO attributes:nil error:nil];
        [self addSkipBackupAttributeToItemAtURL:[[NSURL alloc] initFileURLWithPath:dbDirectory isDirectory:YES]];
    }

    NSString *writableDBPath = [dbDirectory stringByAppendingPathComponent:DB_NAME];
    success = [fileManager fileExistsAtPath:writableDBPath];
if (success) return;
    // The writable database does not exist, so copy the default to the appropriate location.
    NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:DB_NAME];
    success = [fileManager copyItemAtPath:defaultDBPath toPath:writableDBPath error:&error];
    if (!success) {
        //NSAssert1(0, @"Failed to create writable database file with message '%@'.", [error localizedDescription]);

        NSString *errorMsg = [NSString stringWithFormat:@"Failed to create writable database file with message - %@.", [error localizedDescription]];
        [DBConnection errorMessage:errorMsg];
    }
}
-(BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL{
    const char* filePath = [[URL path] fileSystemRepresentation];

    const char* attrName = "com.apple.MobileBackup";
    u_int8_t attrValue = 1;

    int result = setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
    return result == 0;
}

#pragma mark - Open the database connection and retrieve minimal information for all objects.

-(void)initializeDatabase {
    // The database is stored in the application bundle.
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);

    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dbDirectory = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"]]];


    NSString *path = [dbDirectory stringByAppendingPathComponent:DB_NAME];
////NSLog(@"SQLite Root: %s", [path UTF8String]);

    // Open the database. The database was prepared outside the application.
    if (sqlite3_open([path UTF8String], &g_database) != SQLITE_OK) {
        // Even though the open failed, call close to properly clean up resources.
        sqlite3_close(g_database);
g_database = nil;
        //NSAssert1(0, @"Failed to open database with message '%s'.", sqlite3_errmsg(g_database));
        NSString *errorMsg = [NSString stringWithFormat:@"Failed to open database with message - '%s'.", sqlite3_errmsg(g_database)];
        [DBConnection errorMessage:errorMsg];
    }
}
-(void)close {

if (g_database) {
// Close the database.
if (sqlite3_close(g_database) != SQLITE_OK) {
//NSAssert1(0, @"Error: failed to close database with message '%s'.", sqlite3_errmsg(g_database));
            NSString *errorMsg = [NSString stringWithFormat:@"Failed to open database with message - '%s'.", sqlite3_errmsg(g_database)];
            [DBConnection errorMessage:errorMsg];
}
g_database = nil;
}
}

@end
