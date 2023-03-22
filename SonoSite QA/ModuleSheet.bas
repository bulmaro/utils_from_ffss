Attribute VB_Name = "ModuleSheet"
''''''''''''''' Worksheet ''''''''''''''

Public Const dataRangeName As String = "Data Center"

' Columns
' owner,job_name,script_name,prod_type,bom,version,time_stamp,result,reasons,link,analyzed_on,jira_bug_link
Public Const colOwner = 1
Public Const colJob = 2
Public Const colScript As Integer = 3
Public Const colProdType As Integer = 4
Public Const colBOM As Integer = 5
Public Const colVersion As Integer = 6
Public Const colTimestamp As Integer = 7
Public Const colResult As Integer = 8
Public Const colReasons As Integer = 9
Public Const colLink As Integer = 10
Public Const colAnalyzedOn As Integer = 11
Public Const colJiraBugLink As Integer = 12
Public Const colAnalyzedBy As Integer = 13

Public totalColumns As Integer

Public Const firstDataRow As Integer = 2

Public lastDataRow As Integer
Public totalRows As Integer

' Load the worksheet
Sub GrabWorksheet()
    lastDataRow = Sheet2.Cells(Sheet2.Rows.Count, "A").End(xlUp).Row
    totalRows = lastDataRow - firstDataRow + 1
    totalColumns = Sheet2.Cells(1, 1).End(xlToRight).Column
End Sub

' Go to the first data row
Sub goHome()
    ' Top, right-most of the non-frozen pane
    SendKeys "^{HOME}"
    ' And to the result field
    SendKeys "{RIGHT}"
    SendKeys "{RIGHT}"
    SendKeys "{RIGHT}"
    SendKeys "{RIGHT}"
End Sub
