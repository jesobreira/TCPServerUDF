#cs
	Download netcat at https://eternallybored.org/misc/netcat/
	Execute this script
	Run in CMD:
	nc -vv 127.0.0.1 8081
#ce

#include "TCPServer.au3"

Global $sPassword = "12345" ; input server password here

_TCPServer_OnConnect("connected")
_TCPServer_OnDisconnect("disconnect")
_TCPServer_OnReceive("received")

_TCPServer_DebugMode(True)
_TCPServer_SetMaxClients(10)

_TCPServer_Start(8081)

Func connected($iSocket, $sIP)
	_TCPServer_Send($iSocket, "Welcome! Please input password: ")
	_TCPServer_SetParam($iSocket, 'login')
EndFunc   ;==>connected

Func disconnect($iSocket, $sIP)
	MsgBox(0, "Client disconnected", "Client " & $sIP & " disconnected from socket " & $iSocket)
EndFunc   ;==>disconnect

Func received($iSocket, $sIP, $sData, $sParam)
	If $sParam = "login" Then
		If $sData <> $sPassword Then
			_TCPServer_Send($iSocket, "Wrong password. Try again: ")
			Return
		Else
			_TCPServer_SetParam($iSocket, 'command')
			_TCPServer_BindAppToSocket($iSocket, 'cmd.exe')
		EndIf
	ElseIf $sParam = "command" Then
		_TCPServer_SendToBound($iSocket, $sData)
	EndIf

EndFunc   ;==>received

While 1
	Sleep(100)
WEnd
