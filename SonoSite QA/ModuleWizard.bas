Attribute VB_Name = "ModuleWizard"
''''''''''''''''' Wizard '''''''''''''''''''''

Sub SetMeUp()
    ForceDialog = True
    WizardTitle = "Data Wizard"
    MsgBox _
        "This Data Wizard will help you to:" & vbCrLf & vbCrLf & _
        "1) Format the data," & vbCrLf & _
        "2) Sort it," & vbCrLf & _
        "3) Mark all results passing as auto-analyzed," & vbCrLf & _
        "4) Time stamp as of right now," & vbCrLf & _
        "5) Colorize the results according to their status," & vbCrLf & _
        "6) Filter out results for scripts" & vbCrLf & _
        "   which are consitently passing or" & vbCrLf & _
        "   have been analyzed and accounted for." & vbCrLf & _
        "7) Filter all scripts by owner," & vbCrLf & _
        "8) Auto adjust the columns width," & vbCrLf & vbCrLf & _
        "It takes only 1 minute.", vbOKOnly + vbInformation, appName & " - " & WizardTitle
    goHome
    RemoveFilters
    URLsToLinks
    Application.Dialogs(xlDialogSort).Show
    AccountForPass
    ColorizeAllResults
    FilterByUser
    FilterMyInterestingScripts
    FitAllColumns
    MsgBox "All done! You are next..." & vbCrLf & vbCrLf & _
           "To continue, I suggest you use the 'Smart' & 'Clone' analyze buttons.", _
           vbOKOnly + vbInformation, appName & " - " & WizardTitle
    CourtesyOfBulmaro
    goHome
    ForceDialog = False
End Sub
