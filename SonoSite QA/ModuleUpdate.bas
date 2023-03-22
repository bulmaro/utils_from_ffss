Attribute VB_Name = "ModuleUpdate"
''''''''''''''' Update '''''''''''''''''

Public Const challenge As String = "WiPeOuT!"
Public Const firstDataRowInCSV = 2

' Import CSV
Sub ImportCSVAndUpdateDataRange()
    ' Grab worksheet
    RemoveFilters
    GrabWorksheet
    ' Specify which columns we'll filter on
    colNames = Array("script_name", "time_stamp")
    colNumbers = Array(colScript, colTimestamp)
    ' Get the dataRanges containing the columns we want
    ReDim dataRanges(UBound(colNames)) As Range
    For rangeIndex = 0 To UBound(colNames)
        Set dataRanges(rangeIndex) = Sheet2.Range(colLetter(colNumbers(rangeIndex)) & firstDataRow)
    Next
    ' Build the array of strings that we'll use to decide if we want to import data
    ReDim dataExisting(totalRows) As String
    For RowIndex = 0 To totalRows
        dataLine = ""
        For rangeIndex = LBound(dataRanges) To UBound(dataRanges)
            dataLine = dataLine & dataRanges(rangeIndex).Cells(RowIndex + firstDataRow - 1, 0)
        Next
        dataExisting(RowIndex) = dataLine
    Next
    
    ' Prompt user to select CSV file ...
    csvFullFilename = Application.GetOpenFilename("CSV Files (*.csv), *.csv")
    If csvFullFilename = False Then Exit Sub
    
    ' Read CSV data temporarily into a workbook
    Set tempWorkbook = Workbooks.Open(csvFullFilename)
    csvData = tempWorkbook.Sheets(1).UsedRange.Value
    tempWorkbook.Close False
    csvDataTotalRows = UBound(csvData, 1) - 1
    
    ' Loop through CSV data and add new records to existing 'data range'
    rowsAddedTotal = 0
    rowNumber = lastDataRow + 1 ' start adding at 'dataLastRow'
    For RowIndex = firstDataRowInCSV To UBound(csvData)
        ' Create a concatenated 'searchValue' from all cell values in the row
        searchValue = ""
        For colNamesIndex = LBound(colNames) To UBound(colNames)
            cellValue = csvData(RowIndex, colNumbers(colNamesIndex))
            searchValue = searchValue & cellValue
        Next
        ' will add the current row from CSV data if it's not already in 'dataExisting'
        If Not IsInArray(searchValue, dataExisting) Then
            Sheet2.Cells(rowNumber, 1).Resize(1, UBound(csvData, 2)).Value = _
                Application.Index(csvData, RowIndex, 0)
            rowNumber = rowNumber + 1
            rowsAddedTotal = rowsAddedTotal + 1
        End If
    Next

    ' Display message box with results
    justFileName = Left(Right(csvFullFilename, Len(csvFullFilename) - InStrRev(csvFullFilename, "\")), InStrRev(Right(csvFullFilename, Len(csvFullFilename) - InStrRev(csvFullFilename, "\")), ".") - 1)
    msg = _
        "Imported CSV file '" & justFileName & "': " & vbCrLf & _
        IIf(rowsAddedTotal = 0, _
            csvDataTotalRows & " records read but no new ones were imported.", _
            csvDataTotalRows & " records read and " & rowsAddedTotal & " new ones imported.")
    ShareMessage msg, , , True
    
    wantToSmartStart = MsgBox("You can engage the wizard 'Smart Start'." & vbCrLf & vbCrLf & _
                              "It will format & filter all Results..." & vbCrLf & vbCrLf & _
                              "Do you want to?", vbQuestion + vbYesNo + vbDefaultButton2, appName & " - " & Title)
    If wantToSmartStart = vbYes Then
        SetMeUp
    End If
End Sub

' Wipeout
Sub WipeOut()
    Title = "Clear ALL data!"
    
    isSure = MsgBox("Because it is executed by 'macro', this action cannot be undone." & vbCrLf & vbCrLf & _
                    "Are you sure?", vbCritical + vbYesNo + vbDefaultButton2, appName & " - " & Title)
    If isSure = vbYes Then
        If (Not InDebuggingMode) Then
            confirm = InputBox("If you are really-really sure, type '" & challenge & "'", "About to clear ALL data!", Title)
        End If
        If InDebuggingMode Or (confirm = challenge) Then
            RemoveFilters
            GrabWorksheet
            Application.ScreenUpdating = False
            ' Traverse all results
            For RowIndex = firstDataRow To lastDataRow
                Set Row = Sheet2.Cells(RowIndex, 1)
                Row.EntireRow.Hidden = False
                Row.EntireRow.ClearContents
                Row.EntireRow.Style = "Normal"
            Next RowIndex
            Application.ScreenUpdating = True
            ActiveSheet.UsedRange.Columns.AutoFit
            goHome
            ShareMessage "All filters, data and colors have been cleared.", , appName & " - " & "Show All"
            filteredByUser = ""
        Else
            ShareMessage "Didn't think so."
        End If
    Else
        ShareMessage "Better safe than sorry..."
    End If
End Sub


