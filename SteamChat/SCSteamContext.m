//
// This file is subject to the software licence as defined in
// the file 'LICENCE.txt' included in this source code package.
//

#import "SCSteamContext.h"
#import <SKSteamKit/SKSteamClient.h>
#import <SKSteamKit/SKSteamUser.h>
#import <SKSteamKit/SKSteamFriends.h>
#import <SKSteamKit/SKSteamChatRoom.h>
#import <SKSteamKit/SKSteamID.h>
#import <SKSteamKit/SKSteamLoggedOffInfo.h>

@implementation SCSteamContext
{
	SKSteamClient * _client;
}

static SCSteamContext * globalContext = nil;

+ (SCSteamContext *) globalContext
{
	return globalContext;
}

- (id) init
{
	self = [super init];
	if (self)
	{
		_client = [[SKSteamClient alloc] init];
		_isConnected = false;
		
		NSNotificationCenter * notificationCenter = [NSNotificationCenter defaultCenter];
		[notificationCenter addObserver:self selector:@selector(steamClientDidDisconnect:) name:SKSteamClientDisconnectedNotification object:_client];
		[notificationCenter addObserver:self selector:@selector(steamClientDidGetLoggedOut:) name:SKSteamLoggedOffNotification object:_client];
	}
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObject:self];
}

- (uint64_t) steamId
{
	return _client.steamID;
}

- (NSArray *) clans
{
	return _client.steamFriends.clans;
}

- (NSString *) localUserPersonaName
{
	return _client.steamFriends.personaName;
}

- (void) setAsGlobalContext
{
	globalContext = self;
}

- (CRPromise *)logInWithUsername:(NSString *)username password:(NSString *)password
{
	return [self logInWithUsername:username password:password steamGuardCode:nil];
}


- (CRPromise *)logInWithUsername:(NSString *)username password:(NSString *)password steamGuardCode:(NSString *)steamGuardCode
{
	SKSteamUser * user = _client.steamUser;
	
	NSMutableDictionary * details = [@{SKLogonDetailUsername : username, SKLogonDetailPassword: password} mutableCopy];
	
	if (steamGuardCode != nil)
	{
		[details setObject:steamGuardCode forKey:SKLogonDetailSteamGuardCode];
	}
	
	CRDeferred * loginDfd = [[CRDeferred alloc] init];
	
	[[[_client connect]
		addSuccessHandler:^(id data) {
			_isConnected = YES;
			[[[user logOnWithDetails:[details copy]]
				addSuccessHandler:^(id data) {
					_client.steamFriends.personaState = EPersonaStateOnline;
					[loginDfd resolveWithResult:data];
				}]
				addFailureHandler:^(NSError *error) {
					[loginDfd rejectWithError:error];
				}];
			}]
		addFailureHandler:^(NSError *error) {
			[loginDfd rejectWithError:error];
		}];
	
	return [loginDfd promise];
}

- (NSArray *) clanChatMessagesForClan:(SKSteamClan *)clan
{
	return [_client.steamFriends chatMessageHistoryForClanWithSteamID:clan.steamId];
}

- (void) joinClanChatRoom:(SKSteamClan *)clan
{
	[_client.steamFriends enterChatRoomForClanID:clan.steamId];
}

- (BOOL) sendMessage:(NSString*)message ofType:(EChatEntryType)type toClanChatRoom:(SKSteamClan *)clan
{
	SKSteamID * clanID = [SKSteamID steamIDWithUnsignedLongLong:clan.steamId];
	
	SKSteamChatRoom * room = [[_client.steamFriends.chats cr_where:^int(id item) {
		SKSteamChatRoom * innerRoom = item;
		SKSteamID * roomID  = [SKSteamID steamIDWithUnsignedLongLong:innerRoom.steamId];
		
		return roomID.universe == clanID.universe && roomID.accountID == clanID.accountID && roomID.instance == SKSteamIDChatInstanceFlagClan;
	}] nextObject];
	
	if (room != nil)
	{
		[_client.steamFriends sendChatMessageToChatRoom:room type:type text:message];
		return YES;
	}
	
	return NO;
}

- (void) steamClientDidDisconnect:(NSNotification *)notification
{
	_isConnected = NO;
}

- (void) steamClientDidGetLoggedOut:(NSNotification *)notification
{
	// Poor man's reconnect
	[_client disconnect];
	_isConnected = NO;
}

@end
