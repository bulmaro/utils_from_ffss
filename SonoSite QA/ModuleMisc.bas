Attribute VB_Name = "ModuleMisc"
'''''''''''''' Misc '''''''''''''''''

' Check if a string exists in an array of strings
Function IsInArray(test, strings)
    found = False
    ' Traverse 'strings' and stop if 'test' is found
    For i = LBound(strings) To UBound(strings)
        If strings(i) = test Then
            found = True
            Exit For
        End If
    Next
    ' Just return what we found
    IsInArray = found
End Function

' Get the first name of current user
Function CurrentUser()
    firstName = Split(Environ("USERNAME"), ".")(0)
    CurrentUser = StrConv(firstName, vbProperCase)
End Function

' Are we at header row
Function IsAtHeader()
    IsAtHeader = (ActiveCell.Row = 1)
End Function

' Map a column number to a letter
Function colLetter(colNumber)
    colLetter = Chr(Asc("A") + colNumber)
End Function

' Now
Function RightNow()
    RightNow = Format(Now, "MM/dd/yyyy hh:mm:ss")
End Function
