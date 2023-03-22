Attribute VB_Name = "ModuleAnalyze"
'''''''''''''''' Analyze Results '''''''''''''''

Public Const defaultReason As String = "Jira URL, Jira ID or an explanation"

' Just go to next result
Sub GoNext()
    Do
        ActiveCell.Offset(1, 0).Activate
    Loop Until Not (ActiveCell.EntireRow.RowHeight = 0)
End Sub

' Just go to previous results
Sub GoBack()
    If IsAtHeader Then
        Exit Sub
    End If
    Do
        ActiveCell.Offset(-1, 0).Activate
    Loop Until Not (ActiveCell.EntireRow.RowHeight = 0)
End Sub

' Analyze this result
Sub AnalyzeThisResult()
Attribute AnalyzeThisResult.VB_ProcData.VB_Invoke_Func = "a\n14"
    GrabWorksheet
    ' Read the row
    Set currentRow = Sheet2.Rows(ActiveCell.Row)
    ' Extract relevant fields
    owner = currentRow.Cells(1, colOwner)
    job = currentRow.Cells(1, colJob)
    Script = currentRow.Cells(1, colScript)
    time_stamp = currentRow.Cells(1, colTimestamp)
    result = currentRow.Cells(1, colResult)
    reasons = currentRow.Cells(1, colReasons)
    analyzed_on = currentRow.Cells(1, colAnalyzedOn)
    ' Now to analyze it
    If owner = "" Or job = "" Or Script = "" Then
        ShareMessage "No data to analyze", , , True
        Exit Sub
    End If
    If IsAtHeader Then
        ShareMessage "Skipping Header."
        'GoNext
        GoAsFarAsPossible
        Exit Sub
    End If
    If IsResultAnalyzed Then
        ShareMessage "Already Analyzed, skipping it."
        'GoNext
        GoAsFarAsPossible
        Exit Sub
    End If
    If IsResultPass Then
        currentRow.Cells(1, colAnalyzedOn) = RightNow
        currentRow.Cells(1, colJiraBugLink) = "Auto analyzed"
        currentRow.Cells(1, colAnalyzedBy) = "Auto analyzed"
        ColorizeThisResultForRibbon
        ShareMessage "Auto Analyzed as Passing."
'        GoNext
        GoAsFarAsPossible
        Exit Sub
    End If
    If IsClonable Then
        wantToClone = MsgBox("This Result has the same result as the one above." & vbCrLf & _
                             "Do you want to clone it?", _
                             vbQuestion + vbYesNo + vbDefaultButton2, "Clone it?")
        If wantToClone = vbYes Then
            AnalizeAsAbove
            Exit Sub
        End If
    End If
    ' Needs analysis... let's engage the user
    
    ' Prompt for a 'reason', hopefully a Jira reference
    testContext = _
        "Owner:" & vbTab & owner & "" & vbCrLf & _
        "Job:" & vbTab & job & "" & vbCrLf & _
        "Script:" & vbTab & Script & "" & vbCrLf & _
        "Msg:" & vbTab & reasons & "" & vbCrLf & _
        "On:" & vbTab & time_stamp & "" & vbCrLf & vbCrLf & _
        "Please provide a reason..."
    myReason = Trim(InputBox(testContext, "Analyzing this failed test...", defaultReason))
    
    ' First try to determine if it's a Jira reference
    Set regex = CreateObject("VBScript.RegExp")
    regex.Pattern = "^http:\/\/jira\.sonosite\.com:8080\/browse\/[a-z]{2,}-\d{2,}$"
    IsValidJiraURL = regex.test(LCase(myReason))
    regex.Pattern = "^[a-z]{2,}-\d{2,}$"
    isValidJiraTicket = regex.test(LCase(myReason))
    ' Get a Jira URL is possible
    If IsValidJiraURL Then
        jiraURL = LCase(myReason)
        jiraID = Split(jiraURL, "/")(UBound(Split(jiraURL, "/")))
    ElseIf isValidJiraTicket Then
        jiraID = UCase(myReason)
        jiraURL = "http://jira.sonosite.com:8080/browse/" & jiraID
    Else
        jiraURL = Empty
    End If
    
    ' Act depending on what we found
    If jiraURL <> "" Then
        currentRow.Cells(1, colAnalyzedOn) = RightNow
        currentRow.Cells(1, colAnalyzedBy) = CurrentUser
        ' Set Jira bug link
        Set jiraCell = currentRow.Cells(1, colJiraBugLink)
        jiraCell.Hyperlinks.Add Anchor:=jiraCell, Address:=jiraURL, TextToDisplay:=jiraID
        ColorizeThisResultForRibbon
        ShareMessage "Marked it as Jira issue (" & jiraID & ")."
        'GoNext
        GoAsFarAsPossible
    ElseIf (myReason <> "") And (myReason <> defaultReason) Then
        currentRow.Cells(1, colAnalyzedOn) = RightNow
        currentRow.Cells(1, colAnalyzedBy) = CurrentUser
        ' Set reason
        currentRow.Cells(1, colJiraBugLink) = myReason
        ColorizeThisResultForRibbon
        ShareMessage "Marked it with your explanation."
        'GoNext
        GoAsFarAsPossible
    Else
        ShareMessage "Please provide a valid reason: ( Jira URL | Jira ID | explanation ).", _
            vbExclamation, _
            "Analyzing this failed test...", True
    End If
End Sub

Sub GoAsFarAsPossible()
    Do
        GoNext
    Loop Until Not IsResultAnalyzed
End Sub

' Copy analisys from above if possible
Sub AnalizeAsAbove()
    If IsAtHeader Then
        Beep
        Exit Sub
    End If
    
    If IsClonable Then
        ' Get current row
        currentRow = ActiveCell.Row
        Set currentRowRange = ActiveSheet.Range("A" & currentRow & ":" & _
                                                 ActiveSheet.Cells(currentRow, ActiveSheet.Columns.Count).End(xlToLeft).Address)
        ' Extract relevant fields
        thisScript = currentRowRange.Cells(1, colScript)
        thisResult = currentRowRange.Cells(1, colResult)
        thisReasons = currentRowRange.Cells(1, colReasons)
        thisAnalyzed_on = currentRowRange.Cells(1, colAnalyzedOn)
        thisAnalyzed_by = currentRowRange.Cells(1, colAnalyzedBy)
        ' Get the prev row
        Set prevRowRange = ActiveSheet.Range("A" & currentRow - 1 & ":" & _
                                                 ActiveSheet.Cells(currentRow - 1, ActiveSheet.Columns.Count).End(xlToLeft).Address)
        ' Extract relevant fields
        prevScript = prevRowRange.Cells(1, colScript)
        prevResult = prevRowRange.Cells(1, colResult)
        prevReasons = prevRowRange.Cells(1, colReasons)
        prevAnalyzed_on = prevRowRange.Cells(1, colAnalyzedOn)
        prevJiraBugLink = prevRowRange.Cells(1, colJiraBugLink)
        prevAnalyzed_by = prevRowRange.Cells(1, colAnalyzedBy)
        ' Set 'analyzed timestamp' to now
        currentRowRange.Cells(1, colAnalyzedOn).Value = RightNow
        ' Copy 'analyzed by'
        currentRowRange.Cells(1, colAnalyzedBy).Value = prevAnalyzed_by
        ' Set reason
        CopyValueAndHyperlink prevRowRange.Cells(1, colJiraBugLink), currentRowRange.Cells(1, colJiraBugLink)
        ColorizeThisResultForRibbon
        ShareMessage "Cloned analysis from previous result."
        GoNext
    Else
        Beep
    End If
End Sub

Function IsClonable()
    ' Get current row
    currentRow = ActiveCell.Row
    ' Get the current row
    Set currentRowRange = ActiveSheet.Range("A" & currentRow & ":" & _
                                             ActiveSheet.Cells(currentRow, ActiveSheet.Columns.Count).End(xlToLeft).Address)
    ' Extract relevant fields
    thisScript = currentRowRange.Cells(1, colScript)
    thisResult = currentRowRange.Cells(1, colResult)
    thisReasons = currentRowRange.Cells(1, colReasons)
    thisAnalyzed_on = currentRowRange.Cells(1, colAnalyzedOn)
    ' Get the prev row
    Set prevRowRange = ActiveSheet.Range("A" & currentRow - 1 & ":" & _
                                             ActiveSheet.Cells(currentRow - 1, ActiveSheet.Columns.Count).End(xlToLeft).Address)
    ' Extract relevant fields
    prevScript = prevRowRange.Cells(1, colScript)
    prevResult = prevRowRange.Cells(1, colResult)
    prevReasons = prevRowRange.Cells(1, colReasons)
    prevAnalyzed_on = prevRowRange.Cells(1, colAnalyzedOn)
'    prevJiraBugLink = prevRowRange.Cells(1, colJiraBugLink)
    
    IsClonable = (thisScript = prevScript) And (thisReasons = prevReasons) And _
        (thisResult = prevResult) And (thisResult = "fail") And _
        (prevAnalyzed_on <> "" And prevAnalyzed_on <> "TBD")
End Function

Sub AccountForPass()
    GrabWorksheet
    ' Go through all the rows
    totResultsAnalyzed = 0
    For RowIndex = firstDataRow To lastDataRow
        Set currentRow = Sheet2.Rows(RowIndex)
        result = currentRow.Cells(1, colResult)
        analyzed_on = currentRow.Cells(1, colAnalyzedOn)
        If IsPass(result) And Not IsAnalyzed(analyzed_on) Then
            currentRow.Cells(1, colAnalyzedOn) = RightNow
            currentRow.Cells(1, colJiraBugLink) = "Auto analyzed"
            currentRow.Cells(1, colAnalyzedBy) = "Auto analyzed"
            totResultsAnalyzed = totResultsAnalyzed + 1
        End If
    Next
    msg = IIf(totResultsAnalyzed = 0, _
        "I found no results to auto analyze.", _
        "Analyzed " & totResultsAnalyzed & " passing results.")
    ShareMessage msg, vbInformation, appName & " - " & "Auto Analyzed!"
End Sub

Sub CopyValueAndHyperlink(cellFrom As Range, cellTo As Range)
    ' Check if cellFrom has a hyperlink
    If cellFrom.Hyperlinks.Count > 0 Then
        ' Copy the value and hyperlink from cellFrom to cellTo
        cellTo.Value = cellFrom.Value
        cellTo.Hyperlinks.Add Anchor:=cellTo, Address:= _
            cellFrom.Hyperlinks(1).Address, TextToDisplay:= _
            cellFrom.Hyperlinks(1).TextToDisplay
    Else
        ' If cellFrom does not have a hyperlink, just copy the value
        cellTo.Value = cellFrom.Value
    End If
End Sub

' Check if current result is a pass
Function IsResultPass()
    IsResultPass = IsPass(Sheet2.Cells(ActiveCell.Row, colResult))
End Function

' Check if current results is analyzed
Function IsResultAnalyzed()
    IsResultAnalyzed = IsAnalyzed(Sheet2.Cells(ActiveCell.Row, colAnalyzedOn))
End Function

