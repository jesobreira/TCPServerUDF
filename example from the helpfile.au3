#include "TCPServer.au3"

_TCPServer_OnConnect("connected")
_TCPServer_OnDisconnect("disconnect")
_TCPServer_OnReceive("received")

_TCPServer_DebugMode(True)
_TCPServer_SetMaxClients(10)

_TCPServer_Start(8081)

Func connected($iSocket, $sIP)
	_TCPServer_Send($iSocket, "Hello, how are you?")
EndFunc

Func received($iSocket, $sIP, $sData, $sPar)
	_TCPServer_Send($iSocket, "Ok, I understood.")
EndFunc

Func disconnect($iSocket, $sIP)
	MsgBox(0, "", "I miss him.")
EndFunc

While 1
	Sleep(100)
WEnd