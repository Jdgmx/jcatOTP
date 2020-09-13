# jcatOTP
jCat One Time Password Manager

I wrote jcatOTP mainly to solve a particular problem that I was having.

I've been trying to find a solution to the problem of gaving to login repetedly to
to an app using two factor authentication and one time passwords. In other words,
I got tired of switching to the authenticator app, looking up the correct code,
copying the code, going back to the app and paste back the code.

This application is a proposed solution to this inconvenience.

The idea is to generate the OTP code on the fly and paste it into the correct text
field using macOS services. That way I would only need to right-click over the
place where I want to paste the OTP and select the correct item. No switching apps
or copy/pasting anything.

It's as simple as a list of OTPs. You can copy the item's code either by selecting
it in the table, or pressing return or double-clicking on it. Also, you can have
up to 5 items in the services menu. Each item has the title "n jCatOTP" with
correspond, in order, to the n-th element of the table with the services check
turned on.
