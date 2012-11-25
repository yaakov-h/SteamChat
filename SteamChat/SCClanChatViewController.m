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

@interface SCClanChatViewController ()

@end

@implementation SCClanChatViewController
{
	SCSteamContext * _context;
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

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	_context = [SCSteamContext globalContext];
	
	NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
	[center addObserver:self selector:@selector(didRecieveChatMessage:) name:SKSteamChatMessageInfoNotification object:nil];
	[center addObserver:self selector:@selector(steamClientDidDisconnect:) name:SKSteamClientDisconnectedNotification object:nil];
	[center addObserver:self selector:@selector(steamClientDidGetLoggedOut:) name:SKSteamLoggedOffNotification object:nil];
	
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

@end
