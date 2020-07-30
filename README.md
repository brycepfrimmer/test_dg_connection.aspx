Web programming is hard. There are _lots_ of things that can go wrong. 

### External things go wrong 

* Security configurations
* Intermittent hardware failures
* Network configurations
* Product licensing issues 
* Looking at the wrong results (ie, a file override lurks somewhere that you missed which leads you to examine the wrong file for results)
* Network endpoints are incorrect (ie, you're testing on a dev server but thought you were testing on a production server)

### Swallowing errors

There is nearly an endless number of ways a programmer can cause a bug. Which is OK, we all do that. But more nefarious than causing a bug is hiding one. For example, consider the code below: 

    Try 
        Connect pgmDB 
        Open MyFile 
    Catch 
    EndTry 

If an error occurred connecting to the database object or opening the file, no error would be reported. The program would fail silently--possibly making the programmer think DataGate failed. On the IBM i a little digging into job logs would probably shine some light, but not quickly and obviously.

This kind of problem can very pervasive in .NET because the error might not be swallowed immediately, but perhaps in the caller that called the offending routine. It's often very challenging to root out these areas where errors are swallowed.

How does code like that above get written? Sometimes the coder that is good defensive code, sometimes the coder was in a hurry and meant to get back to that code to finish up (you know that goes). No matter how it happens, it doess occasionally, even to the best programmers. 

### Complexity bites you 

Another challenge with Web apps is their inherent complexity. In ASNA tech support, we often see _very_ complex apps with more layers than a wedding cake. This complexity often gets in the way of reproducing the problem -- and also being able to prove the problem has been reproduced (ie, we need to create a cupcake out of your wedding cake to show R&D the reproduced issue.)

### It works here but not there

You're all familiar with this problem. The challenge is that the Web app works from your desktop to the test server, but when deployed to a production server it fails. Making small incremental changes means a full redeploy--and that is often a complex, manual process. If only you test a little fragment quickly and easily. 

## Find the culprit quickly

Because of all of these complexities, ASNA Tech Support often spends _lots_ of time looking at an issue only to find out that the issue isn't DataGate-related, but rather the error caused by some other extenuating circumstance unrelated to ASNA products. 

When you report a problem with DataGate with your Web app we need to be able to quickly determine if DataGate is working. Quickly knowing DataGate's state:

* Helps you know to look further at elements under your control (eg, networking and security issues) 
* Helps us to know quickly that DataGate is, or is not, working as expected. 

If you report a problem and we can then determine that DataGate is working, we can then try to zero in on the problem area. However, please remember that Tech Support can't spend much time helping you debug your application nor are we networking experts. If your debugging needs exceed the scope of tech support, we may need to hook you up with an ASNA Services contract to further investigate the problem for you. 

## Quickly finding the culprit 

This article introduces a single-page ASPX page, `test_gt_connection.aspx` that quickly determines the status of DataGate in a Web environment. The full ASPX file is about 200 lines long, but the only parts of the code you care about are the first 20 or so lines of code, shown below. 

    DclDB pgmDB DBName("*PUBLIC/DG Net Local")

    DclDiskFile  InputFile +
          Type( *Input  ) +
          Org( *Indexed ) +
          File( "Examples/CMastNewL2" ) +
          DB( pgmDB ) +
          ImpOpen( *No )

    BegSr WriteFieldValue 
        /*
         | Put field name to display here.
         |                V
         */
        Response.Write(CMName) 
    EndSr

    BegSr Overrides
        // Add overrides as needed. Here are some examples. Remember, too, 
        // that the test page offers a few overrides as well.
        //pgmDB.Server = '123.123.123.123'
        //pgmDB.Port = 4567
        //pgmDB.User = 'Neil'
        //pgmDB.Password = 'y#dePL%wmcQr'
        //InputFile.FilePath = '*Libl/CMastNewL1'
    EndSr

> You can download the `test_dg_connect.aspx` from [this ASNA GitHub page.](https://github.com/ASNA/test_dg_connection.aspx) or you can [download a zipped copy of it here](http://asna.com/media/packages/test_dg_connection.aspx-1.zip). If you're reading this article on ASNA.com you can also download the file with the "Download" button at the top of this page.

Before you deploy the file you need to make a few changes to it. The changes you need to make to the code are isolated to four specific areas: 

1. Change the Database Name to your Database Name.
2. Change the DclDiskFile's `File` keyword to point to your library and file.
3. Change the field name referenced in the `WriteFieldValue` subroutine to a valid field name in your file.
4. Optionally, you may want to override values in the Database Name or the disk file. Do this in the Overrides subroutine. Some commented example overrides are provided. 

Note that you can also override the Database Name, the disk file path (what library and file it's using), the user profile, and user password at runtime in the test page. Page-level overrides override those made in the Override subroutine (ie, page-level overrides override the Override subroutine, got that?)

After tailoring the page to your specs, to deploy the page just drop it into your Web site's root directory and launch it from your browser. Nothing else is required. You can also open the page with Notepad on your server and make changes to the ASPX file. Resubmitting the page after an edit causes ASP.NET to automatically recompile it for you. 

When the page loads, if all went well, the page displays like this:

![](https://asna.com/media/images/noerror-1.png)

<small>Figure 1a. No errors!</small>

If you have licensing problem, the page displays like this:

![](https://asna.com/media/images/nolicense-1.png)

<small>Figure 1b. A licensing error occurred.</small>

Note that while the ASNA DataGate Monitor can test a DataGate connection, because the DataGate Monitor is a fat client app, it doesn't test that you have a valid WebPak license registered. Use the `test_dg_connection.aspx` for that. 

If any other type of error occurs the page displays like this (varying the top level error message to reflect the specific error that occurred):

![](https://asna.com/media/images/error-1.png)

<small>Figure 1c. Some other error occurred. (in this case to cause an error I disconnected a VPN connection)</small>

### Using the page-level overrides

After the page displays, you can override any combination of:

* The Database Name
* The file path
* The user profile name
* The user password 

Fill in the fields you want override and press click the "Submit test again" button to see the test results with your overridden values. If you need more granularity over values to override, use the `Overrides` subroutine mentioned 
above. 

Note the password entered is fully visible--by design. This is because:

* We assume the developers know the password and in the isolated environment where you'll you use this page eyeball security isn't paramount.
* Seeing the password as you type it may help eliminate typing errors. 

### About the code

The code in `test_db_connection.aspx` is mostly self-explanatory. The only things particularly interesting are:

* The AVR code is inside a `<script runat="server">` tag. This eliminates the need for a code-behind file and makes the test page easy to install. Generally embedding server-side code in your ASPX is a bad idea--but it's just perfect for this use case.

* Check out the `PingServer` and `CheckPort` subroutines for how to programmatically ping a server and check that a port is open. 

>A warning about single-page ASPX pages: Don't use global variables with a single page file like this. Keep all your variables local to subroutines and functions. This may be a bug and we are investigating that. 

### Bend it, shape it, any way you want to

The concept of a single-page test app is very powerful and can be extended many ways. You can add some special subroutines to test other special cases or IO idioms. Bend it and tweak it, that's what it's for! 

We strongly recommend you use `test_dg_connection.aspx` anytime you spin up a new server, change a license key, or get ready to deploy a new app. It will save you time and grief. 


