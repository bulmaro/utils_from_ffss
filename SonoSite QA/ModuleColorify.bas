Attribute VB_Name = "ModuleColorify"
'''''''''''''''' Colorify ''''''''''''''''''''

'
Sub ColorizeAllResults()
    GrabWorksheet
    ' Go through all the rows in 'dataWorksheet'
    For RowIndex = firstDataRow To lastDataRow
        ColorizeByRow (RowIndex)
    Next
    ShareMessage "Applied colors based on Result (pass or failed) and on Analyzed", , appName & " - " & "Auto Colorize"
End Sub

Sub ColorizeByRow(rowNumber)
    result = Sheet2.Rows(rowNumber).Cells(1, colResult)
    analyzed_on = Sheet2.Rows(rowNumber).Cells(1, colAnalyzedOn)
    Sheet2.Rows(rowNumber).Interior.Color = ChooseColor(result, analyzed_on, True)
End Sub

' Colorize the current result without parameter so it can be used as macro for ribbon
Sub ColorizeThisResultForRibbon()
    GrabWorksheet
    ' Go down if we are in the header
    If IsAtHeader Then
        SendKeys "{DOWN}"
        Exit Sub
    End If
    ColorizeByRow (ActiveCell.Row)
    ShareMessage "Colorized current Result"
End Sub

' Decide the color based on the result data
Function ChooseColor(result, analyzed_on, applyColor)
    If applyColor Then
        If IsPass(result) Then
            thisColor = vbGreen
            If IsAnalyzed(analyzed_on) Then
                thisColor = RGB(200, 255, 200) ' greenish
            Else
                thisColor = vbGreen ' bright green
            End If
        Else ' failed or something
            If IsAnalyzed(analyzed_on) Then
                thisColor = RGB(255, 200, 200) ' pinkish
            Else
                thisColor = vbRed ' bright red
            End If
        End If
    Else
        thisColor = vbWhite
    End If
    ChooseColor = thisColor
End Function
