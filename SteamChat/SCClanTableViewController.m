//
// This file is subject to the software licence as defined in
// the file 'LICENCE.txt' included in this source code package.
//

#import "SCClanTableViewController.h"
#import "SCSteamContext.h"
#import <SKSteamKit/SKSteamAccountInfo.h>
#import "SCClanChatViewController.h"
#import <SKSteamKit/SKSteamPersonaStateInfo.h>
#import <SKSteamKit/SKNSNotificationExtensions.h>
#import "SCLoginViewController.h"

@interface SCClanTableViewController ()

@end

@implementation SCClanTableViewController
{
	SCSteamContext * _context;
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
	[center addObserver:self selector:@selector(didRecieveAccountInfo:) name:SKSteamAccountInfoUpdateNotification object:nil];
	[center addObserver:self selector:@selector(didRecievePersonaStateChange:) name:SKSteamPersonaStateInfoNotification object:nil];
	
	self.navigationItem.title = @"Groups";// _context.localUserPersonaName;
}

- (void) viewDidAppear:(BOOL)animated
{
	if (_context == nil)
	{
		_context = [SCSteamContext globalContext];
	}
	
	if (_context == nil || !_context.isConnected)
	{
		SCLoginViewController * vc = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"SCLoginViewController"];
		vc.modalPresentationStyle = UIModalPresentationFullScreen;
		vc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;

		[self presentViewController:vc animated:NO completion:^{}];
	}
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
	return [_context.clans count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SCClanCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
	SKSteamClan * clan = [_context.clans objectAtIndex:[indexPath row]];
	cell.textLabel.text = clan.name;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

- (void) didRecieveAccountInfo:(NSNotification *)notification
{
	self.navigationItem.title = _context.localUserPersonaName;
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"SCShowClanChat"])
	{
		SKSteamClan * clan = [_context.clans objectAtIndex:[[self.tableView indexPathForSelectedRow] row]];
		SCClanChatViewController * dest = segue.destinationViewController;
		dest.clan = clan;
	}
}

- (void) didRecievePersonaStateChange:(NSNotification *)notification
{
	SKSteamPersonaStateInfo * info = [notification steamInfo];
	NSArray * clans = _context.clans;
	
	if (info.clan != nil && [clans containsObject:info.clan])
	{
//		NSUInteger row = [clans indexOfObject:info.clan];
//		NSIndexPath * reloadRow = [NSIndexPath indexPathForRow:row inSection:0];
//		[self.tableView reloadRowsAtIndexPaths:@[reloadRow] withRowAnimation:UITableViewRowAnimationNone];
		[self.tableView reloadData];
	}
}

@end
