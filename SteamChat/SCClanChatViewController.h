//
// This file is subject to the software licence as defined in
// the file 'LICENCE.txt' included in this source code package.
//

#import <UIKit/UIKit.h>
#import <SKSteamKit/SKSteamClan.h>

@interface SCClanChatViewController : UIViewController <UIWebViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) SKSteamClan * clan;
@property (nonatomic, weak) IBOutlet UIWebView * webView;
@property (weak, nonatomic) IBOutlet UITextField *chatMessageEntryTextField;
- (IBAction)leaveChatRoom:(id)sender;

@end
