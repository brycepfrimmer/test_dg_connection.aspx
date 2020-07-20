<%@ Page Language="AVR" %>
<%@ Import Namespace="System.Net.Sockets" %>
<%@ Import Namespace="System.Net.NetworkInformation" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">

<script runat="server">
    /*
     | Set pgmDB DBName 'keyword' and DclDiskFile File 'keyword'
     | correctly for your environment. 
     |
     | In the WriteFieldValue subroutine, specify a field name 
     | from your file.        
     | 
     | Specify any overrides in the Overrides subroutine. 
     */

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
         |               V
         */
        Response.Write(CMName) 
    EndSr

    BegSr Overrides
        //pgmDB.Server = '123.123.123.123'
        //pgmDB.Port = 4567
        //pgmDB.User = 'Neil'
        //pgmDB.Password = 'y#dePL%wmcQr'
    EndSr

    // ---------------------------------------------------------------------------
         
    BegSr Page_Load Access(*Private) Event(*This.Load)
        DclSrParm sender Type(*Object)
        DclSrParm e Type(System.EventArgs)

        DclFld DBName Type(*String) 
        DclFld FilePath Type(*String) 
        DclFld User Type(*String) 
        DclFld Password Type(*String) 

        Overrides()

        If Request['dbname'] AND NOT String.IsNullOrEmpty(Request['dbname'].ToString()) 
            DBName = Request['dbname'] 
            pgmDB.DBName = DBName
        EndIf 

        If Request['filepath'] AND NOT String.IsNullOrEmpty(Request['filepath'].ToString()) 
            FilePath = Request['FilePath'].ToString()
            InputFile.FilePath = FilePath 
        EndIf 

        If Request['user'] AND NOT String.IsNullOrEmpty(Request['user'].ToString()) 
            User = Request['user'].ToString()
            pgmDB.User = User 
        EndIf 

        If Request['password'] AND NOT String.IsNullOrEmpty(Request['password'].ToString()) 
            FilePath = Request['password'].ToString()
            pgmDB.Password = Password
        EndIf 
       
        Response.Write('<h1>ASNA DataGate connection test</h1>')

        Try 
            Connect pgmDB 
            Response.Write(String.Format('<h3>Database name: <span class="highlight">{0}</span> connected successfully.</h3>', pgmDB.DBName)) 
    
            Open InputFile
            Read InputFile

            Response.Write('<h2 class="success">Read record succeeded</h2>')
            Response.Write(String.Format('<span class="sm-text">File path used: <span class="highlight">{0}</span>', InputFile.FilePath)) 
            Response.Write('<br><br><span>Field value is: </span><span class="highlight">')

            WriteFieldValue()

            Response.Write('</span>')
            Response.Write(String.Format('<br><br><span>User profile is: </span><span class="highlight">{0}</span>', pgmDB.User))
                        
            Close *All 
            Disconnect pgmDB 
        Catch ex Type(Exception) 
            Response.Write('<h2 class="failure">Something is wrong</h2>')
            Response.Write(String.Format('<br><br class="sm-text">Server is: <span class="highlight">{0}</span>', pgmDB.Server)) 
            Response.Write(String.Format('<br><br class="sm-text">Port is: <span class="highlight">{0}</span>', pgmDB.Port)) 
            Response.Write(String.Format('<br><br class="sm-text">User is: <span class="highlight">{0}</span>', pgmDB.User)) 
            Response.Write(String.Format('<br><br class="sm-text">File path is: <span class="highlight">{0}</span>', InputFile.FilePath)) 
            Response.Write(String.Format('<br><br>Top level error message: <span class="highlight">{0}</span>', ex.Message)) 
            Response.Write('<br>')
            PingServer()
            CheckPort()
        EndTry 
    EndSr 

    BegSr PingServer
        DclFld Server Type(*String)
        DclFld MyPing Type(Ping) New()
        DclFld Reply Type(PingReply)              

        Server = pgmDB.Server

        Try 
            Reply = myPing.Send(Server, 1000)
        
            If Reply.Status = IPStatus.Success
                Response.Write(String.Format('<br>Ping to {0} succeeded.', Server))
            Else 
                Response.Write(String.Format('<br>Ping to {0} failed', Server))
            EndIf 
        Catch ex Type(Exception) 
            Response.Write('<br>Attempt to ping server failed.')
            Response.Write(String.Format('<br><span class="sm-text">Exception that occurred pinging server {0}: {1}</span>', Server, ex.Message))                 
        EndTry 
    EndSr

    BegSr CheckPort 
        DclFld Port Type(*Integer4) 
        DclFld Server Type(*String)

        Server = pgmDB.Server
        Port = pgmDB.Port

        BegUsing tcpc Type(TcpClient) Value(*New TcpClient()) 
            Try 
                tcpc.Connect(Server, Port)      
                Response.Write(String.Format('<br>Port {0} appears to be open', Port))
            Catch ex Type(Exception) 
                Response.Write(String.Format('<br>Port {0} does not appear to be open', Port)) 
                Response.Write(String.Format('<br><span class="sm-text">Exception that occurred checking port {0}: {1}</span>', Port, ex.Message))                 
            EndTry 
        EndUsing 
    EndSr
</script>

<html xmlns="http://www.w3.org/1999/xhtml" >
<head runat="server">
    <title>Test ASNA DataGate</title>
    <style>
        body {
            font-family: sans-serif;
        }
        .failure {
            color: red;
        }
        .success {
            color: green;
        }
        .highlight {
            background-color: darkgrey;
            padding: .5em;
        }
        .sm-text {
            font-size: 75%;
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
    <div>
        <br />
        <hr>
        <h3>Provide test overrides below</h3>

        <br />
        <label for "dbname">Override DB Name:</label>
        <br />  
        <input type="text" name="dbname"/>
        <br />  

        <br />
        <label for "filepath">Override file path:</label>
        <br />  
        <input type="text" name="filepath"/>
        <br /> 
        <span class="sm-text">Enter file path in the form "LibraryFile"</span>

        <br />
        <br />
        <label for "user">Override user profile:</label>
        <br />  
        <input type="text" name="user"/>
        <br />  

        <br />
        <label for "password">Override password:</label>
        <br />  
        <input type="text" name="password"/>
        <br />  
        <br />

        <button type="submit">Submit test again</button>
    </div>
    </form>
</body>
</html>
