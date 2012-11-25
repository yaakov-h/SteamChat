//
// This file is subject to the software licence as defined in
// the file 'LICENCE.txt' included in this source code package.
//

#import <Foundation/Foundation.h>
#import <CRBoilerplate/CRBoilerplate.h>
#import <SKSteamKit/SKSteamClan.h>

@interface SCSteamContext : NSObject

@property (nonatomic, readonly) uint64_t steamId;
@property (nonatomic, readonly) NSArray * clans;
@property (nonatomic, readonly) NSString * localUserPersonaName;
@property (nonatomic, readonly) BOOL isConnected;

+ (SCSteamContext *) globalContext;

- (id) init;
- (void) setAsGlobalContext;
- (CRPromise *)logInWithUsername:(NSString *)username password:(NSString *)password;
- (CRPromise *)logInWithUsername:(NSString *)username password:(NSString *)password steamGuardCode:(NSString *)steamGuardCode;

- (NSArray *) clanChatMessagesForClan:(SKSteamClan *)clan;
- (void) joinClanChatRoom:(SKSteamClan *)clan;
- (BOOL) sendMessage:(NSString*)message ofType:(EChatEntryType)type toClanChatRoom:(SKSteamClan *)clan;

@end
