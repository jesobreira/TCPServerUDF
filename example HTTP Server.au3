#cs
	Run this script
	Point your browser to http://localhost:8081/
#ce

#include "TCPServer.au3"

_TCPServer_OnReceive("received")

_TCPServer_DebugMode(True)
_TCPServer_SetMaxClients(10)

_TCPServer_Start(8081)


Func received($iSocket, $sIP, $sData, $sParam)

	_TCPServer_Send($iSocket, "HTTP/1.0 200 OK" & @CRLF & _
					"Content-Type: text/html" & @CRLF & @CRLF & _
					"<h1>It works!</h1>" & @CRLF & _
					"<p>This is the default web page for this server.</p>" & @CRLF & _
					"<p>However this server is just a 26-lines example.</p>")
	_TCPServer_Close($iSocket)

EndFunc   ;==>received

While 1
	Sleep(100)
WEnd
