//
// This file is subject to the software licence as defined in
// the file 'LICENCE.txt' included in this source code package.
//

#import <UIKit/UIKit.h>

@class SCSteamContext;

@interface SCLoginViewController : UITableViewController <UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (nonatomic, readonly) SCSteamContext * context;
- (IBAction)logIn:(id)sender;

@end
