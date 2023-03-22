Attribute VB_Name = "ModuleFunny"
'''''''''''''''' Funny ''''''''''''''''''''''

' Brought to you...
Sub CourtesyOfBulmaro()
    ShareMessage _
        vbTab & "Brought to you by" & vbTab & vbTab & vbCrLf & vbCrLf & _
        vbTab & "'Bulmaro Herrera'" & vbTab & vbTab & vbCrLf & vbCrLf & _
        "", vbOKOnly + vbInformation, appName & " - " & "Author", True
'        vbTab & "(and the letter 'Y')", , appName & " - " & "Author", True
End Sub

' Show how to contact me
Sub ContactBulmaro()
    ShareMessage "Sending email", , appName & " - " & "eMail"
    ' Create an instance of the Outlook application
    Set olApp = CreateObject("Outlook.Application")
    ' Create a new mail item
    Set olMail = olApp.CreateItem(0)
    ' Set the fields
    olMail.To = "Bulmaro Herrera <bulmaro.herrera.contractor@fujifilm.com>"
    olMail.CC = "Bulmaro Herrera <bulmaro.herrera@gmail.com>"
    olMail.Subject = "About '" & appName & "'..."
    olMail.Body = _
        "Hi Bulmaro, " & vbCrLf & vbCrLf & _
        "About this cool tool 'SonoSite QA'..." & vbCrLf & vbCrLf & _
        "Thanks," & vbCrLf & vbCrLf & _
        CurrentUser
    ' Display the new mail item
    olMail.Display
    ShareMessage "Sent!", , appName & " - " & "eMail"
End Sub

' The documentation
Sub OpenDoc()
    ShareMessage "Opening Confluence", , appName & " - " & "Wiki"
    If MsgBox("Want to go to Confluence", vbYesNo, appName & " Documentation") = vbYes Then
        ActiveWorkbook.FollowHyperlink "http://engconfl.sonosite.com:8090/display/SEW/SonoSite+QA+-+Analyze+Test+Results?flashId=1435570794"
        ShareMessage "Gone to Confluence", , appName & " - " & "Wiki"
    End If
End Sub

' Maybe a few bitcoins?
Sub AskForDonation()
    ShareMessage "Just kidding!!! It's included with your FFSS QA membership.", vbInformation, appName, True
'    MsgBox "Just kidding!!! It's included with your FFSS QA membership.", vbInformation, appName
End Sub

