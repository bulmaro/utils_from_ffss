Attribute VB_Name = "ModuleGlobal"
'''''''''''''''''''' Global Variables ''''''''''''''''''''

' General constants
Public Const appName As String = "SonoSite QA"

Public ForceDialog As Boolean

Sub ShareMessage(msg, Optional Buttons As VbMsgBoxStyle = vbInformation, Optional Title As String = appName, Optional ForceThisTime As Boolean = False)
    Application.StatusBar = Replace(msg, vbCrLf, " ")
    If ForceDialog Or ForceThisTime Then
        MsgBox msg, Buttons, Title
    End If
End Sub

Function InDebuggingMode()
    Debugging = False
    InDebuggingMode = (CurrentUser = "Bulmaro") Or Debugging
End Function
