Set shell = CreateObject("WScript.Shell")
basePath = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)
exePath = basePath & "\zapret2_kontrol_merkezi.exe"
scriptPath = basePath & "\zapret2-roblox-ui.ps1"
If CreateObject("Scripting.FileSystemObject").FileExists(exePath) Then
  shell.Run """" & exePath & """", 0, False
Else
  shell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & scriptPath & """", 0, False
End If
