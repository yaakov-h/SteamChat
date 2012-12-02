//
// This file is subject to the software licence as defined in
// the file 'LICENCE.txt' included in this source code package.
//

#import "SCChatMembersViewController.h"
#import "SCSteamContext.h"
#import <SKSteamKit/SKSteamChatRoom.h>
#import <SKSteamKit/SKSteamFriend.h>
#import <SKSteamKit/SKEnterChatRoomInfo.h>
#import <SKSteamKit/SKNSNotificationExtensions.h>
#import <SKSteamKit/SteamLanguage.h>

@interface SCChatMembersViewController ()

@end

@implementation SCChatMembersViewController
{
	SCSteamContext * _context;
	NSArray * _membersCache;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	_context = [SCSteamContext globalContext];
	
	NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
	[center addObserver:self selector:@selector(didEnterChatRoom:) name:SKEnterChatRoomInfoNotification object:nil];
	[center addObserver:self selector:@selector(chatRoomDidUpdateMembers:) name:SKSteamChatRoomMembersChangedNotification object:nil];
}

- (void) viewWillAppear:(BOOL)animated
{
	[self reload];
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return _membersCache.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SCChatMemberCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    SKSteamFriend * member = _membersCache[[indexPath row]];
	cell.textLabel.text = member.personaName;
	
	EClanPermission permission = [_room permissionsForMemberSteamID:member.steamId];
	
	if ((permission & EClanPermissionOfficer) > 0)
	{
		cell.textLabel.text = [NSString stringWithFormat:@"🌟 %@", member.personaName];
	}
	else if ((permission & EClanPermissionModerator) > 0)
	{
		cell.textLabel.text = [NSString stringWithFormat:@"⭐ %@", member.personaName];
	}
	
    return cell;
}

- (void) didEnterChatRoom:(NSNotification *)notification
{
	SKEnterChatRoomInfo * info = [notification steamInfo];
	if (info.chatRoom == _room)
	{
		[self reload];
	}
}

- (void) reload
{	
	_membersCache = [_room.members sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		return [[obj1 personaName] compare:[obj2 personaName]];
	}];
	
	[self.tableView reloadData];
	
	self.navigationItem.title = [NSString stringWithFormat:@"Members (%u)", _membersCache.count];
}

- (void) chatRoomDidUpdateMembers:(NSNotification *)notification
{
	NSDictionary * info = [notification steamInfo];
	if (info[SKChatRoomKey] == _room)
	{
		[self reload];
	}
}

@end
