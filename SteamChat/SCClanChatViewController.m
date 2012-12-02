//
// This file is subject to the software licence as defined in
// the file 'LICENCE.txt' included in this source code package.
//

#import "SCClanChatViewController.h"
#import "SCSteamContext.h"
#import <SKSteamKit/SKSteamChatMessageInfo.h>
#import <SKSteamKit/SKSteamFriend.h>
#import <SKSteamKit/SKNSNotificationExtensions.h>
#import <CRBoilerplate/CRBoilerplate.h>
#import <SKSteamKit/SKSteamClient.h>
#import <SKSteamKit/SKSteamLoggedOffInfo.h>
#import <SKSteamKit/SKSteamChatRoom.h>
#import <SKSteamKit/SKEnterChatRoomInfo.h>
#import <SKSteamKit/SKSteamID.h>
#import "SCChatMembersViewController.h"

@interface SCClanChatViewController ()

@end

@implementation SCClanChatViewController
{
	SCSteamContext * _context;
	SKSteamChatRoom * _chatRoom;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObject:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	_context = [SCSteamContext globalContext];
	
	NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
	[center addObserver:self selector:@selector(didRecieveChatMessage:) name:SKSteamChatMessageInfoNotification object:nil];
	[center addObserver:self selector:@selector(steamClientDidDisconnect:) name:SKSteamClientDisconnectedNotification object:nil];
	[center addObserver:self selector:@selector(steamClientDidGetLoggedOut:) name:SKSteamLoggedOffNotification object:nil];
	[center addObserver:self selector:@selector(didEnterChatRoom:) name:SKEnterChatRoomInfoNotification object:nil];
	[center addObserver:self selector:@selector(chatRoomDidUpdateMembers:) name:SKSteamChatRoomMembersChangedNotification object:nil];
	
	[_chatMessageEntryTextField setEnabled:NO];
	
	[_context joinClanChatRoom:_clan];
	self.navigationItem.title = _clan.name;
	
	NSURL * url = [[NSBundle mainBundle] URLForResource:@"chat_clan" withExtension:@"html"];
	NSURLRequest * request = [[NSURLRequest alloc] initWithURL:url];
	[self.webView loadRequest:request];
	
	self.cr_resizesToFitKeyboard = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) didRecieveChatMessage:(NSNotification *) notification
{
	SKSteamChatMessageInfo * info = [notification steamInfo];
	if (info.chatRoomClan.steamId == _clan.steamId && (info.chatEntryType == EChatEntryTypeChatMsg || info.chatEntryType == EChatEntryTypeEmote))
	{
		[self addMessage:info];
	}
}

- (void) addMessage:(SKSteamChatMessageInfo *)info
{
	NSString * functionName = nil;
	CGSize contentSize = self.webView.scrollView.contentSize;
	CGPoint contentOffset = self.webView.scrollView.contentOffset;
	CGRect bounds = self.webView.scrollView.bounds;
	BOOL wasAtBottom = bounds.size.height >= contentSize.height - contentOffset.y;
	
	switch (info.chatEntryType)
	{
		case EChatEntryTypeChatMsg:
		{
			functionName = @"window.steam_addChatLine";
			break;
		}
			
		case EChatEntryTypeEmote:
		{
			functionName = @"window.steam_addActionLine";
			break;
		}
			
		default: break;
	}
	
	if (functionName != nil)
	{
		NSString * name = [info.steamFriendFrom.personaName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		NSString * state = [[self nameOfPersonaState:info.steamFriendFrom.personaState] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		
		if (info.steamFriendFrom.gameAppId != 0 || info.steamFriendFrom.gameId != 0 || (info.steamFriendFrom.gameName != nil && info.steamFriendFrom.gameName.length > 0))
		{
			state = @"ingame";
		}
		
		NSString * text = [info.message stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		NSString * myMessage = _context.steamId == info.steamFriendFrom.steamId ? @"true" : @"false";
		
		NSString * functionCall = [NSString stringWithFormat:@"%@(\"%@\", \"%@\", \"%@\", %@);", functionName, name, state, text, myMessage];
		
		[self.webView stringByEvaluatingJavaScriptFromString:functionCall];
		
		if (wasAtBottom)
		{
			NSInteger height = [[self.webView stringByEvaluatingJavaScriptFromString:@"document.body.offsetHeight;"] intValue];
			NSString * js = [NSString stringWithFormat:@"window.scrollBy(0, %d);", height];
			[self.webView stringByEvaluatingJavaScriptFromString:js];
		}
	}
}

- (NSString *)  nameOfPersonaState:(EPersonaState)state
{
	switch (state)
	{
		case EPersonaStateAway:
			return @"away";
		case EPersonaStateBusy:
			return @"busy";
		case EPersonaStateOffline:
			return @"offline";
		case EPersonaStateOnline:
			return @"online";
		case EPersonaStateSnooze:
			return @"snooze";
		default: return @"unknown";
	}
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	NSLog(@"request: %@", request.URL);
	return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	if (webView == _webView)
	{
		for (SKSteamChatMessageInfo * info in [_context clanChatMessagesForClan:_clan])
		{
			[self addMessage:info];
		}
	}
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if ([textField.text length] > 0)
	{
		NSString * actionPrefix = @"/me";
		
		EChatEntryType type = EChatEntryTypeChatMsg;
		NSString * text = textField.text;
		
		if ([text hasPrefix:actionPrefix])
		{
			text = [text substringFromIndex:[actionPrefix length]];
			type = EChatEntryTypeEmote;
		}
		
		[_context sendMessage:text ofType:type toClanChatRoom:_clan];
		textField.text = nil;
		return YES;
	}
	
	return NO;
}

- (void) steamClientDidDisconnect:(NSNotification *)notification
{
	[self.navigationController popViewControllerAnimated:YES];
}

- (void) steamClientDidGetLoggedOut:(NSNotification *)notification
{
	[self.navigationController popViewControllerAnimated:YES];
}

- (void) didEnterChatRoom:(NSNotification *)notification
{
	SKEnterChatRoomInfo * info = [notification steamInfo];
	SKSteamID * chatID = [SKSteamID steamIDWithUnsignedLongLong:info.chatRoom.steamId];
	SKSteamID * clanID = [SKSteamID steamIDWithUnsignedLongLong:_clan.steamId];
	
	if (chatID.universe == clanID.universe && chatID.accountID == clanID.accountID && chatID.instance == SKSteamIDChatInstanceFlagClan)
	{
		_chatRoom = info.chatRoom;
		switch (info.response)
		{
			case EChatRoomEnterResponseSuccess:
				[_chatMessageEntryTextField setEnabled:YES];
				break;
			case EChatRoomEnterResponseBanned:
				[[[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:@"You may not join the %@ chat room as you have been banned.", _clan.name] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
				break;
			case EChatRoomEnterResponseDoesntExist:
			case EChatRoomEnterResponseCommunityBan:
			case EChatRoomEnterResponseClanDisabled:
			case EChatRoomEnterResponseLimited:
			case EChatRoomEnterResponseError:
			case EChatRoomEnterResponseNotAllowed:
			case EChatRoomEnterResponseFull:
			default:
				[[[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"Unable to join chat room - Error %d", info.response] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
				break;
		}
	}
}

- (void) chatRoomDidUpdateMembers:(NSNotification *)notification
{
	NSDictionary * info = [notification steamInfo];
	if (info[SKChatRoomKey] == _chatRoom)
	{
		SKSteamFriend * friend = info[SKChatRoomChatterActedOnKey];
		SKSteamFriend * actedBy = info[SKChatRoomChaterActedByKey];
		EChatMemberStateChange stateChange = [info[SKChatRoomChatterStateChangeKey] intValue];
		
		NSString * stateMessage = nil;
		
		if (friend.steamId == _context.steamId)
		{
			switch (stateChange)
			{
				case EChatMemberStateChangeKicked:
					stateMessage = [NSString stringWithFormat:@"You have been kicked by %@", actedBy.personaName];
					break;
				case EChatMemberStateChangeBanned:
					stateMessage = [NSString stringWithFormat:@"You have been banned by %@", actedBy.personaName];
					break;
				
				default: break;
			}
			
			if (stateMessage != nil)
			{
				[[[UIAlertView alloc] initWithTitle:nil message:stateMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
				[self.chatMessageEntryTextField setEnabled:NO];
				return;
			}
		}
		
		
		switch (stateChange)
		{
			case EChatMemberStateChangeBanned:
				stateMessage = [NSString stringWithFormat:@"was banned by %@.", actedBy.personaName];
				break;
			case EChatMemberStateChangeDisconnected:
				stateMessage = @"disconnected.";
				break;
			case EChatMemberStateChangeEntered:
				stateMessage = @"entered chat.";
				break;
			case EChatMemberStateChangeKicked:
				stateMessage = [NSString stringWithFormat:@"was kicked by %@.", actedBy.personaName];
				break;
			case EChatMemberStateChangeLeft:
				stateMessage = @"left chat.";
				break;
			case EChatMemberStateChangeMax:
				stateMessage = @"broke Steam.";
				break;
		}
		
		if (friend != nil && stateMessage != nil)
		{
			NSString * message = [NSString stringWithFormat:@"%@ %@", friend.personaName, stateMessage];
			
			NSString * functionCall = [NSString stringWithFormat:@"%@(\"%@\");", @"window.steam_addStateChangeLine", [message stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			[self.webView stringByEvaluatingJavaScriptFromString:functionCall];
		}
	}
}

- (IBAction)leaveChatRoom:(id)sender {
	[_context leaveChatRoom:_chatRoom];
	[self dismissViewControllerAnimated:YES completion:^{}];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([[segue identifier] isEqualToString:@"SCShowChatRoomMembers"])
	{
		SCChatMembersViewController * vc = segue.destinationViewController;
		vc.room = _chatRoom;
	}
}

@end
