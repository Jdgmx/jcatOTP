# Introduction

jcatOTP is a simple tool that I wrote for myself to solve a particular problem.
In my job I constantly need to log into applications that use two factor authentication with one time passwords (OTPs). As everybody else, I was using a password manager to store and generate the OTP. But at a certain point it became very bothersome, every time I had to log in, to switch from my app to the password manager, search for the code, copy it, return to my app, and paste it back.
There should be a better solution to do that.

The solution that occurred to me was to use macOS Services, in other words, I should just need right-click on the text field for the OTP, and select the code.
A few weekends later and some free time spent, and I had a tool that just did exactly that. It was just a simple list of accounts, a check-button to relate them to a fixed list of services, and that’s it.
But, after some comments from someone else, I decided to release it for free to anyone that could find it useful.

A few more weekends later and jcatOTP was born.

# How It Works

The idea is very simple. First you create accounts by providing a names and the OTP codes. The list of the services is fixed, so you have to flag which accounts will map to which services. Then you enable each account for the Services menu in System Preferences.
Then, next time you have to enter an OTP code you can right-click/or go to the Services menu, select the corresponding account index and it will be automatically pasted in the selected text field.

jcatOTP uses your system’s keychain to store a key to encrypt and decrypt the file where the codes are stored. Every time it’s launched it will ask you for your computer credentials to access the keychain. If you somehow delete the keychain entry, or don’t provide the correct password, it will no longer be able to read your accounts (everything will be lost).

The first thing you will see is the list of accounts.

IMAGE_1

Start by creating a new account by clicking on the *New +* symbol in the toolbar of by pressing ⌘N.

IMAGE_2

Enter the name of the OTP account and the secret key. In general you don’t need to worry about the rest of the parameters, but if you do then you’ll know what to do.
As expected, you can delete an account by selecting it on the table and clicking on the *Delete −* symbol in the toolbar, or by pressing the *Delete ⌦* key.

You can reorder the accounts in the table by dragging them up or down, this will be important when associating them to the System Services.

## Using System Services

Select the accounts that will be available in the Services menu by clicking on the checkbox in the In Services column. You can check up top 5 accounts.

Open System Preferences and go to Keyboard → Shortcuts → Services → Text.
The titles of the Services menu are fixed. *“__n__ jcatOTP”* corresponds to the *__n__-th* row of the table where the service is checked. For example:

IMAGE_3

*0 jcatOTP* correspond to *Favorite Account*.
*1 jcatOTP* correspond to *My social media*.
*2 jcatOTP* correspond to *Super secret stuff*.

In order to have the services available to other applications don’t forget to also check the *“n jcatOTP”* item in System Preferences.

Not all text fields accept input from the Services menu, but for the ones that do you can enter quickly the OTP code by two possible ways.

First select the text field by clicking on it (the cursor should be on it). Then:

1. Go to your application menu and select Services.
1. On the Text section you should see the *“n jcatOTP”* entries that you previously checked in System Preferences.
1. Select the item that correspond to the account that you want.
1. Pasted!

IMAGE_4

Alternatively, sometimes the Services menu is available in the context menu of the text field.

1. Select the text field.
1. Right-click (or option-click) on it, the context menu should appear.
1. Select the item that correspond to the account that you want.
1. Pasted!

IMAGE_5

## Using Copy/Paste

There are three ways you can copy and paste an OTP code.
The first two ways work by selecting the desire item in the list of accounts. They can be customized in the Preferences window by pressing ⌘,

* *Press return to copy OTP*. The code will copy if you press the Return key on the selected item or if you double-click on it.
* *Copy OTP on selection change*. The code will copy every time the selection changes.

The third method consist on opening a floating window with the code in it. The window floats because it will be over every other standard window in your desktop.

IMAGE_6

First select the desire item in the list of accounts, then click on the *Detach ＞* symbol in the toolbar, or press  ⌘D. A new window will open with the selected code and a progress bar indicating the time left for the next code. The code can be copied by double-clicking on its numbers.

# Important Notes

Unfortunately I haven’t been able to find a way to customize the name of the items in the Services menu. It would be nice to have the name of your account instead of just an index number. If someone knows how to do this some feedback will be appreciated.

**Don’t use jcatOTP to permanently store the OTP secret keys.** For that use a proper password manager.
This tool uses a cryptographic key generated at runtime to encode and decode the file where the OTPs information is stored. The key is stored in your system’s keychain, if for any reason the keychain couldn’t be read then your codes will be lost forever. **There is no backup or synching mechanism.**
