Attribute VB_Name = "ModulePretty"
'''''''''''' Prettify ''''''''''''''

'
Sub FitAllColumns()
    GrabWorksheet
    ReDim maxWidths(1 To totalColumns) As Integer
    For rowNum = 1 To lastDataRow ' not firstDataRow, to also consider the headers
        If Not Sheet2.Cells(rowNum, 1).EntireRow.Hidden Then
            Sheet2.Cells(rowNum, 1).EntireRow.Columns.AutoFit
            For colNum = 1 To totalColumns
                thisWidth = Sheet2.Cells(rowNum, colNum).ColumnWidth
                If thisWidth > maxWidths(colNum) Then
                    maxWidths(colNum) = thisWidth
                End If
            Next colNum
        End If
    Next rowNum
    For colNum = 1 To totalColumns
        colWidth = maxWidths(colNum)
        Columns(colNum).ColumnWidth = colWidth
    Next colNum
    If filteredByUser <> "" Then
        Columns(colOwner).Hidden = True
    End If
    ShareMessage "Auto adjusted all columns widths", , appName & " - " & "Auto Width"
End Sub

'
Sub URLsToLinks()
    ' Load worksheet
    GrabWorksheet
    ' Prepare our URL checker
    Set regex = CreateObject("VBScript.RegExp")
    regex.Pattern = "^(https?://)([\w-]+\.)+[\w-]+(/[\w- ./?%&=]*)?$"
    ' Go through all the rows in 'dataWorksheet'
    For RowIndex = firstDataRow To lastDataRow
        ' Change each column we want
        For colIndex = 1 To totalColumns
            Set cell = Sheet2.Cells(RowIndex, colIndex)
            dataVal = cell.Value
            If regex.test(dataVal) Then ' is a hyperlink?
                jiraID = Split(dataVal, "/")(UBound(Split(dataVal, "/")))
                cell.Hyperlinks.Add Anchor:=cell, Address:=dataVal, TextToDisplay:=jiraID
            End If
        Next
    Next
    ShareMessage "Simplified all URLs as true links with value with last token.", , appName & " - " & "Linkify All"
End Sub
