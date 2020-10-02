<%@ Page Language="AVR" %>
<%@ Import Namespace="System.Net.Sockets" %>
<%@ Import Namespace="System.Net.NetworkInformation" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">

<script runat="server">
    DclDB pgmDB DBName("*Public/DG Net iSeries")

    DclDiskFile InputFile +
          Type (*Input) +
          Org (*Indexed) +
          File ("ACSFILES/PACSGUI") +
          DB (pgmDB) +
          ImpOpen (*No)

    BegSr WriteFieldValues
        Response.Write("Product: " + GUIPRD + " - Non-Annual Member: " + GUIMBN + " - Annual Member: " + GUIMBA)
    EndSr

    BegSr Overrides
        //gonna stick with DBName for the generic 'Overrides' function
        //each customer/division will have a different IP/DNS name where their iSeries resides
        //allow that to be specified within the page overrides
        //pgmDB.Server = '123.123.123.123'

        pgmDB.DBName = "*Public/DG Net iSeries"
        pgmDB.Port = 5042 //the default - so this isn't really necessary
        pgmDB.User = 'TESTUSER'
        pgmDB.Password = 'y#dePL%wmcQr' //this isn't the actual password...
    EndSr

    // ---------------------------------------------------------------------------

    BegSr Page_Load Access(*Private) Event(*This.Load)
        DclSrParm sender Type(*Object)
        DclSrParm e Type(System.EventArgs)

        DclFld DBName Type(*String)
        Dclfld DBServer Type(*String)
        Dclfld DBPort Type(*Integer4)
        //DclFld FilePath Type(*String)
        DclFld User Type(*String)
        DclFld Password Type(*String)

        Overrides()

        //probably don't ever want to specify a dbname AND a dbserver...

        If Request['dbname'] AND NOT String.IsNullOrWhiteSpace(Request['dbname'].ToString())
            DBName = Request['dbname'].ToString().Trim()
            pgmDB.DBName = DBName
        EndIf

        If Request['dbserver'] AND NOT String.IsNullOrWhiteSpace(Request['dbserver'].ToString())
            DBServer = Request['dbserver'].ToString().Trim()
            pgmDB.Server = DBServer
        Endif

        If Request['dbport'] AND NOT String.IsNullOrWhiteSpace(Request['dbport'].ToString())
            Try
                DBPort = Convert.ToInt32(Request['dbport'].ToString())
                pgmDB.Port = DBPort
            Catch ex Type(Exception)
                Response.Write("SPECIFIED INVALID OVERRIDE PORT")
            EndTry
        Endif

//        If Request['filepath'] AND NOT String.IsNullOrWhiteSpace(Request['filepath'].ToString())
//            FilePath = Request['FilePath'].ToString().Trim()
//            InputFile.FilePath = FilePath
//        EndIf

        If Request['user'] AND NOT String.IsNullOrWhiteSpace(Request['user'].ToString())
            User = Request['user'].ToString().Trim()
            pgmDB.User = User 
        EndIf

        If Request['password'] AND NOT String.IsNullOrEmpty(Request['password'].ToString())
            Password = Request['password'].ToString()
            pgmDB.Password = Password
        EndIf

        Response.Write('<h1>ASNA DataGate connection test</h1>')

        Try
            Connect pgmDB
            Response.Write(String.Format('<h3>Database: <span class="highlight">{0}</span> connected successfully.</h3>', pgmDB.DBName + " - " + pgmDB.Server + " - " + pgmDB.Port))

            Open InputFile
            Read InputFile

            Response.Write('<h2 class="success">Read record succeeded</h2>')
            Response.Write(String.Format('<span class="sm-text">File path used: <span class="highlight">{0}</span>', InputFile.FilePath))
            Response.Write('<br><br><span>Field value(s): </span><span class="highlight">')

            WriteFieldValues()

            Response.Write('</span>')
            Response.Write(String.Format('<br><br><span>User profile is: </span><span class="highlight">{0}</span>', pgmDB.User))

            Close *All
            Disconnect pgmDB
        Catch ex Type(Exception)
            Response.Write('<h2 class="failure">Something is wrong</h2>')
            Response.Write(String.Format('<br><br class="sm-text">DBName is: <span class="highlight">{0}</span>', pgmDB.DBName))
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
    <title>CIMS Connect Test ASNA DataGate</title>
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
        <hr />
        <h3>Provide test overrides below</h3>

        <br />
        <label for "dbname">Override DB Name:</label>
        <br />
        <input type="text" name="dbname" />
        <br />

        <br />
        <label for "dbserver">Override DB Server:</label>
        <br />
        <input type="text" name="dbserver" />
        <br />

        <br />
        <label for "dbport">Override DB Port:</label>
        <br />
        <input type="text" name="dbport" />
        <br />
        <span class="sm-text">Port specified MUST BE an integer</span>
        <br />

        <!-- <br />
        <label for "filepath">Override file path:</label>
        <br />
        <input type="text" name="filepath" />
        <br />
        <span class="sm-text">Enter file path in the form "LibraryFile"</span>
        <br /> -->

        <br />
        <br />
        <label for "user">Override user profile:</label>
        <br />
        <input type="text" name="user" />
        <br />

        <br />
        <label for "password">Override password:</label>
        <br />
        <input type="text" name="password" autocomplete="off" />
        <br />
        <br />

        <button type="submit">Submit test again</button>
    </div>
    </form>
</body>
</html>
