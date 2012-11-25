//
// This file is subject to the software licence as defined in
// the file 'LICENCE.txt' included in this source code package.
//

#import "SCLoginViewController.h"
#import "SCSteamContext.h"
#import <SKSteamKit/SteamLanguage.h>
#import <SKSteamKit/Steammessages_clientserver.pb.h>
#import "SCClanTableViewController.h"

@interface SCLoginViewController ()

@end

@implementation SCLoginViewController
{
	NSString * _lastSteamGuardDomainName;
}

- (IBAction)logIn:(id)sender {
	SCSteamContext * context = [[SCSteamContext alloc] init];
	NSString * username = self.usernameTextField.text;
	NSString * password = self.passwordTextField.text;
	
	CRPromise * loginPromise = [context logInWithUsername:username password:password];
	[self handleLoginPromise:loginPromise forContext:context];
}

- (IBAction)logInWithSteamGuardCode:(NSString *)steamGuardCode sender:(id)sender
{
	SCSteamContext * context = [[SCSteamContext alloc] init];
	NSString * username = self.usernameTextField.text;
	NSString * password = self.passwordTextField.text;
	
	CRPromise * loginPromise = [context logInWithUsername:username password:password steamGuardCode:steamGuardCode];
	[self handleLoginPromise:loginPromise forContext:context];
}

- (void) handleLoginPromise:(CRPromise *)promise forContext:(SCSteamContext *)context
{
	[[promise addSuccessHandler:^(id data) {
		[context setAsGlobalContext];
		_context = context;
		[self dismissViewControllerAnimated:YES completion:^{}];
		
	}]
	addFailureHandler:^(NSError *error) {
		
		UIAlertView * alert = [[UIAlertView alloc] init];
		alert.title = @"Failed";
		BOOL showAlert = YES;
		
		CMsgClientLogonResponse * response = error.userInfo[@"Response"];
		if (response == nil)
		{
			alert.message = error.description;
		} else {
			EResult eresult = response.eresult;
			switch (eresult)
			{
				case EResultPasswordNotSet:
					alert.message = @"Password Not Set";
					break;
					
				case EResultAccountLogonDenied:
					[self requestSteamGuardCodeThatWasSentToDomain:response.emailDomain];
					showAlert = NO;
					break;
					
				case EResultInvalidLoginAuthCode:
					[self requestCorrectSteamGuardCodeThatWasSentToDomain:response.emailDomain];
					showAlert = NO;
					break;
					
				case EResultAccountLocked:
					alert.message = @"Account Locked";
					break;
					
				case EResultAccountNotFound:
					alert.message = @"Account Not Found";
					break;
					
				case EResultInvalidPassword:
					alert.message = @"Invalid Password";
					break;
					
				// U: gaben@valvesoftware.com P: MoolyFTW
				case EResultAccountLogonDeniedNoMailSent:
					alert.message = @"Account Logon Denied No Mail Sent. IPT?";
					break;
					
				default:
					alert.message = [NSString stringWithFormat:@"Unknown result: %u", eresult];
			}
		}
		
		if (showAlert)
		{
			[alert addButtonWithTitle:@"Oh bugger"];
			alert.cancelButtonIndex = 0;
			[alert show];
		}
	}];
}

- (void) requestSteamGuardCodeThatWasSentToDomain:(NSString *)domain
{
	_lastSteamGuardDomainName = domain;
	
	UIAlertView * alertView = [[UIAlertView alloc] init];
	alertView.title = @"Steam Guard Code required";
	alertView.message = [NSString stringWithFormat:@"Please enter the Steam Guard Code, sent to your %@ email address", domain];
	[alertView addButtonWithTitle:@"Cancel"];
	[alertView addButtonWithTitle:@"OK"];
	alertView.delegate = self;
	alertView.cancelButtonIndex = 0;
	alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
	
	[alertView show];
}

- (void) requestCorrectSteamGuardCodeThatWasSentToDomain:(NSString *)domain
{
	if (domain == nil || domain.length == 0)
	{
		domain = _lastSteamGuardDomainName;
	}
	
	UIAlertView * alertView = [[UIAlertView alloc] init];
	alertView.title = @"Invalid Steam Guard Code";
	alertView.message = [NSString stringWithFormat:@"Please enter the Steam Guard Code, sent to your %@ email address", domain];
	[alertView addButtonWithTitle:@"Cancel"];
	[alertView addButtonWithTitle:@"OK"];
	alertView.delegate = self;
	alertView.cancelButtonIndex = 0;
	alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
	
	[alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == alertView.cancelButtonIndex)
	{
		[self alertViewCancel:alertView];
		return;
	}
	
	NSString * code = [alertView textFieldAtIndex:0].text;
	[self logInWithSteamGuardCode:code sender:self];
}

- (void) alertViewCancel:(UIAlertView *)alertView
{
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
}

@end
