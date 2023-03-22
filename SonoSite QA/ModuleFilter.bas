Attribute VB_Name = "ModuleFilter"
''''''''''''''' Filter '''''''''''''''

Public Const notAnalyzed As String = "TBD"
Public Const pass As String = "pass"
Public Const filterByUserTitle = "Filter by User"
Public Const filterByFocusTitle = "Filter for Need Analysis"

Public filteredByUser As String

' Show all
Sub RemoveFilters()
    ActiveSheet.Rows.EntireRow.Hidden = False
    Columns(1).Hidden = False
    filteredByUser = ""
    GrabWorksheet
    goHome
    ShareMessage "Removed all filters. Showing " & totalRows & " Results.", , appName & " - " & "Show All"
End Sub

' Remove any filters by user if needed, then filter
Sub FilterByUser()
    GrabWorksheet

    If filteredByUser <> "" Then
        Columns(colOwner).Hidden = False
        RemoveFilters
    End If
    
    If totalRows = 0 Then
        ShareMessage "Nothing to filter"
        Exit Sub
    End If

    userFilter = InputBox("Enter 'owner' to filter by", appName & " - " & filterByUserTitle, CurrentUser)
    
    totRowsHidden = 0
    For RowIndex = firstDataRow To lastDataRow
        Set cell = Sheet2.Cells(RowIndex, colOwner)
        dataVal = cell.Value
        If dataVal <> userFilter Then
            cell.EntireRow.Hidden = True
            totRowsHidden = totRowsHidden + 1
        End If
    Next
    
    filteredByUser = userFilter
    Columns(colOwner).Hidden = True

    msg = IIf(totRowsHidden = 0, _
        "I found no Results to hide for owner '" & userFilter & "'.", _
        "Hidding " & totRowsHidden & " Results not owned by '" & userFilter & "'.")
    ShareMessage msg, vbInformation, appName & " - " & filterByUserTitle

    goHome
End Sub

' Show only scripts that I care about
Sub FilterMyInterestingScripts()
    GrabWorksheet
    If totalRows = 0 Then
        ShareMessage "Nothing to filter"
        Exit Sub
    End If
    ' Refresh worksheet data
    GrabWorksheet
    ' Get all unique script names
    scriptNames = GetUniqueScriptNames
    ' We're going to count how many we hide
    totScriptsHidden = 0
    totResultsHidden = 0
    ' Check for each of the scripts
    For i = 0 To UBound(scriptNames)
        scriptName = scriptNames(i)
        ' Lets check if all results of the script are passing or analyzed
        allPassingOrAnalyzed = True
        ' Check all rows
        For RowIndex = firstDataRow To lastDataRow
            Set Row = Sheet2.Cells(RowIndex, 1)
            script_name = Row.Cells(0, colScript)
            result = Row.Cells(0, colResult)
            analyzed_on = Row.Cells(0, colAnalyzedOn)
            If script_name = scriptName Then
                allPassingOrAnalyzed = allPassingOrAnalyzed And (IsPass(result) Or IsAnalyzed(analyzed_on))
            End If
        Next
        ' at this moment, the variable 'allPassingOrAnalyzed' is true
        ' if every result for the 'scriptName' was either passing or analyzed
        If allPassingOrAnalyzed Then
            totScriptsHidden = totScriptsHidden + 1
            ' Hide all occurrences
            For RowIndex = firstDataRow To lastDataRow
                Set cell = Sheet2.Cells(RowIndex, colScript)
                If cell.Value = scriptName Then
                    totResultsHidden = totResultsHidden + 1
                    cell.EntireRow.Hidden = True
                End If
            Next
        End If
    Next
    goHome
    ' Share the news
    msg = IIf(totResultsHidden = 0, _
        "I found no results to hide.", _
        "Hidding " & totResultsHidden & " results for " & totScriptsHidden & " scripts, not needing Analysis")
    ShareMessage msg, vbInformation, appName & " - " & filterByFocusTitle
End Sub

' Show all analyzed
Sub ShowOnlyFullyAnalyzed()
    GrabWorksheet
    ShareMessage "NOT Implemented." & vbCrLf & "This button will show only scripts for which all results are analyzed.", vbInformation, appName & " - Fully Analyzed", True
End Sub

Function GetUniqueScriptNames()
    Dim uniqueArray() As String
    If totalRows > 0 Then
        ' Get a range object for the column
        col = colLetter(colScript - 1)
        Set colRange = Sheet2.Range(col & firstDataRow & ":" & col & lastDataRow)
        
        Set dict = CreateObject("Scripting.Dictionary")
        
        'Loop through the range and add unique values to the dictionary
        For Each cell In colRange
            If Not dict.exists(cell.Value) Then
                dict.Add cell.Value, i
                i = i + 1
            End If
        Next cell
        'Copy the unique values to an array
        ReDim uniqueArray(0 To dict.Count - 1) As String
        For i = 0 To dict.Count - 1
            uniqueArray(i) = dict.keys()(i)
        Next i
    End If
    GetUniqueScriptNames = uniqueArray
End Function


'''''''''''''' State of Result ''''''''''''''''
' Check if string is pass
Function IsPass(test)
    IsPass = (test = pass)
End Function

' Check if string is analyzed
Function IsAnalyzed(test)
    IsAnalyzed = test <> "" And test <> notAnalyzed
End Function

