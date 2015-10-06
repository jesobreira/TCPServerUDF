#cs
	Download netcat at https://eternallybored.org/misc/netcat/
	Execute this script
	Run in CMD:
	nc -vv 127.0.0.1 8081
#ce

#include "TCPServer.au3"

; First we set the callback functions for the three events (none of them is mandatory)
_TCPServer_OnConnect("connected")
_TCPServer_OnDisconnect("disconnect")
_TCPServer_OnReceive("received")

; And some parameters
_TCPServer_DebugMode(True)
_TCPServer_SetMaxClients(10)

; Finally we start the server at port 8081 at any interface
_TCPServer_Start(8081)

Func connected($iSocket, $sIP)
	MsgBox(0, "Client connected", "Client " & $sIP & " connected!")
	_TCPServer_Broadcast('new client connected guys', $iSocket)
	_TCPServer_Send($iSocket, "Hey! Write something ;)" & @CRLF)
	_TCPServer_SetParam($iSocket, "will write")
EndFunc   ;==>connected

Func disconnect($iSocket, $sIP)
	MsgBox(0, "Client disconnected", "Client " & $sIP & " disconnected from socket " & $iSocket)
EndFunc   ;==>disconnect

Func received($iSocket, $sIP, $sData, $sPar)
	MsgBox(0, "Data received from " & $sIP, $sData & @CRLF & "Parameter: " & $sPar)
	_TCPServer_Send($iSocket, "You wrote: " & $sData)
	_TCPServer_SetParam($iSocket, 'will write again')
EndFunc   ;==>received

While 1
	Sleep(100)
WEnd
