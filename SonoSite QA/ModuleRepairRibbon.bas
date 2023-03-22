Attribute VB_Name = "ModuleRepairRibbon"
Sub QueryRibbon()
'    Dim path As String
'    Set path = Application.Run("RemoveFilters")
'    MsgBox path

'    Dim button As CommandBarButton
'    Dim macroName As String
    
'    Set button = Application.CommandBars("Help").Controls("QueryRibbon")
'    macroName = button.ControlFormat.OnAction

'    Dim myTab As CommandBar
'    Dim tabName As String
'    tabName = "SonoSiteQA"
    
'    Set myTab = Application.CommandBars.FindControl(Type:=msoControlPopup, ID:=0, _
'        Tag:=tabName, Visible:=True)
        
'    If Not myTab Is Nothing Then
'        ' The custom tab was found, and myTab is now a reference to its CommandBar object.
'    Else
'        ' The custom tab was not found.
'    End If

Dim cb As CommandBar

For Each cb In Application.CommandBars
    If cb.Type = msoBarTypeMenuBar Or cb.Type = msoBarTypePopup Then
        Name = cb.Name
        If Left(Name, 1) = "S" Or cb.Type = msoBarTypePopup Then
          Debug.Print cb.Name
        End If
    End If
Next cb

End Sub
