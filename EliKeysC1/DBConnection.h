//
//  DBConnection.h
//  EliKeysC1
//
//  Created by Dror Kessler on 28/09/2021.
//

#ifndef DBConnection_h
#define DBConnection_h

#import <Foundation/Foundation.h>
#import <sqlite3.h>

// database name demo.sqlite

#define DB_NAME @"words.db"//@"Conferencedata////NSLog"

@interface DBConnection : NSObject
{
    @private sqlite3 *g_database;
}

@property (nonatomic,assign,readwrite) sqlite3 *database;

+ (DBConnection *) sharedConnection;
+ (BOOL) executeQuery:(NSString *)query;
+ (NSMutableArray *) fetchResults:(NSString *)query;
+ (int) rowCountForTable:(NSString *)table where:(NSString *)where;
+ (void) errorMessage:(NSString *)msg;
+ (void) closeConnection;

- (id)initConnection;
- (void)close;

@end

#endif /* DBConnection_h */
