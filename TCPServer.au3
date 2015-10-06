#include-once

#cs
	TCPServer UDF
	Written by Jefrey <jefrey[at]jefrey.ml>
#ce
TCPStartup()
OnAutoItExitRegister("__TCPServer_OnExit")
Global $_TCPServer_OnConnectCallback, $_TCPServer_OnDisconnectCallback, $_TCPServer_OnReceiveCallback
Global $_TCPServer_MaxClients = 255
Global $_TCPServer_DebugMode = False
Global $_TCPServer_AutoTrim = True
Global $__TCPServer_MainSocket = -1
Global $__TCPServer_Sockets[255], $__TCPServer_SocketCache[255]
Global $__TCPServer_Consoles[255], $__TCPServer_Pars[255]

Func _TCPServer_Start($iPort, $sInterface = '0.0.0.0')
	If _TCPServer_IsServerActive() Then Return SetError(2, 0, False)
	$__TCPServer_MainSocket = TCPListen($sInterface, $iPort)
	If @error Then Return SetError(@error, @extended, False)
	If $_TCPServer_DebugMode Then __TCPServer_Log("Started listening at " & $sInterface & ":" & $iPort)
	AdlibRegister("__TCPServer_Accept")
	AdlibRegister("__TCPServer_Recv")
	AdlibRegister("__TCPServer_Sendstd")
EndFunc   ;==>_TCPServer_Start

Func _TCPServer_Stop()
	If Not _TCPServer_IsServerActive() Then Return
	AdlibUnRegister("__TCPServer_Accept")
	AdlibUnRegister("__TCPServer_Recv")
	AdlibUnRegister("__TCPServer_Sendstd")
	For $i = 1 To $_TCPServer_MaxClients
		If $__TCPServer_Sockets[$i] <> 0 Then
			TCPCloseSocket($__TCPServer_Sockets[$i])
			$__TCPServer_Sockets[$i] = 0
			$__TCPServer_SocketCache[$i][0] = 0
			$__TCPServer_SocketCache[$i][1] = 0
			$__TCPServer_Consoles[$i] = 0
			$__TCPServer_Pars[$i] = 0
		EndIf
	Next
	If $_TCPServer_DebugMode Then __TCPServer_Log("Stopping server")
	TCPCloseSocket($__TCPServer_MainSocket)
	$__TCPServer_MainSocket = -1
EndFunc   ;==>_TCPServer_Stop

Func _TCPServer_IsServerActive()
	Return $__TCPServer_MainSocket <> -1
EndFunc

Func _TCPServer_ListClients()
	;Dim $return[$__TCPServer_Sockets[0] + 1]
	Dim $return[$_TCPServer_MaxClients + 1]
	$return[0] = $__TCPServer_Sockets[0]
	For $i = 1 To $_TCPServer_MaxClients
		If $__TCPServer_Sockets[$i] <> 0 Then
			$return[$i] = $__TCPServer_Sockets[$i]
		EndIf
		; falta testar
	Next

	Return $return
EndFunc

Func _TCPServer_Close($iSocket)
	$conn = _TCPServer_SocketToConnID($iSocket)
	__TCPServer_KillConnection($conn)
EndFunc

Func _TCPServer_OnConnect($sFunction)
	$_TCPServer_OnConnectCallback = $sFunction
EndFunc   ;==>_TCPServer_OnConnect

Func _TCPServer_SetMaxClients($iMax)
	$_TCPServer_MaxClients = $iMax
	ReDim $__TCPServer_Sockets[$iMax + 1]
	ReDim $__TCPServer_SocketCache[$iMax + 1][2]
	ReDim $__TCPServer_Consoles[$iMax + 1]
	ReDim $__TCPServer_Pars[$iMax + 1]
	For $i = 0 To $iMax
		$__TCPServer_Sockets[$i] = 0
		$__TCPServer_SocketCache[$i][0] = 0
		$__TCPServer_SocketCache[$i][1] = 0
		$__TCPServer_Consoles[$i] = 0
		$__TCPServer_Pars[$i] = 0
	Next
	$__TCPServer_Sockets[0] = 0
EndFunc   ;==>_TCPServer_SetMaxClients

Func _TCPServer_GetMaxClients()
	Return $_TCPServer_MaxClients
EndFunc

Func _TCPServer_DebugMode($bMode = True)
	$_TCPServer_DebugMode = $bMode
EndFunc   ;==>_TCPServer_DebugMode

Func _TCPServer_AutoTrim($bMode = True)
	$_TCPServer_AutoTrim = $bMode
EndFunc

Func _TCPServer_OnDisconnect($sFunction)
	$_TCPServer_OnDisconnectCallback = $sFunction
EndFunc   ;==>_TCPServer_OnDisconnect

Func _TCPServer_OnReceive($sFunction)
	$_TCPServer_OnReceiveCallback = $sFunction
EndFunc   ;==>_TCPServer_OnReceive

Func _TCPServer_Broadcast($sData, $iExceptSocket = 0)
	If $iExceptSocket Then $iExceptSocket = _TCPServer_SocketToConnID($iExceptSocket)
	For $i = 1 To $__TCPServer_Sockets[0]
		If $__TCPServer_Sockets[$i] <> 0 And $i <> $iExceptSocket Then
			TCPSend($__TCPServer_Sockets[$i], $sData)
			If $_TCPServer_DebugMode Then __TCPServer_Log("Sent " & $sData & " to socket " & $__TCPServer_Sockets[$i] & "(" & _TCPServer_SocketToIP($__TCPServer_Sockets[$i]) & ")")
		EndIf
	Next
EndFunc   ;==>_TCPServer_Broadcast

Func _TCPServer_Send($iSocket, $sData)
	If $_TCPServer_DebugMode Then __TCPServer_Log("Sent " & $sData & " to socket " & $iSocket & "(" & _TCPServer_SocketToIP($iSocket) & ")")
	Return TCPSend($iSocket, $sData)
EndFunc   ;==>_TCPServer_Send

Func _TCPServer_SetParam($iSocket, $sPar)
	$conn = _TCPServer_SocketToConnID($iSocket)
	$__TCPServer_Pars[$conn] = $sPar
EndFunc

Func _TCPServer_SocketToIP($iSocket) ; taken from the helpfile
	Local $sockaddr, $aRet
	$sockaddr = DllStructCreate("short;ushort;uint;char[8]")
	$aRet = DllCall("Ws2_32.dll", "int", "getpeername", "int", $iSocket, _
			"ptr", DllStructGetPtr($sockaddr), "int*", DllStructGetSize($sockaddr))
	If Not @error And $aRet[0] = 0 Then
		$aRet = DllCall("Ws2_32.dll", "str", "inet_ntoa", "int", DllStructGetData($sockaddr, 3))
		If Not @error Then $aRet = $aRet[0]
	Else
		$aRet = 0
	EndIf
	$sockaddr = 0
	Return $aRet
EndFunc   ;==>_TCPServer_SocketToIP

Func _TCPServer_BindAppToSocket($iSocket, $sCommand, $sWorkingdir = @WorkingDir)
	$PID = Run($sCommand, $sWorkingdir, @SW_HIDE, BitOR(0x1,0x2,0x4)) ; $STDIN_CHILD + STDOUT_CHILD + STDERR_CHILD
	$conn = _TCPServer_SocketToConnID($iSocket)
	$__TCPServer_Consoles[$conn] = $PID
	If $_TCPServer_DebugMode Then __TCPServer_Log("Opened process " & $PID & " for socket " & $iSocket)
EndFunc

Func _TCPServer_SendToBound($iSocket, $sData)
	$conn = _TCPServer_SocketToConnID($iSocket)
	$PID = $__TCPServer_Consoles[$conn]
	StdinWrite($PID, $sData & @CRLF)
	If $_TCPServer_DebugMode Then __TCPServer_Log("Sent command " & $sData & " to process " & $PID & " for socket " & $iSocket)
EndFunc

Func _TCPServer_UnBindAppToSocket($iSocket)
	$iSocket = _TCPServer_SocketToConnID($iSocket)
	$PID = $__TCPServer_Consoles[$iSocket]
	$__TCPServer_Consoles[$iSocket] = 0
	Sleep(300)
	ProcessClose($PID)
EndFunc

Func _TCPServer_SocketToConnID($iSocket)
	For $i = 1 To $_TCPServer_MaxClients
		If $__TCPServer_Sockets[$i] = $iSocket Then
			Return $i
		EndIf
	Next
	Return False
EndFunc

Func _TCPServer_ConnIDToSocket($iConn)
	Return $__TCPServer_Sockets[$iConn]
EndFunc

; Internal use ============================================================
Func __TCPServer_OnExit()
	TCPShutdown()
EndFunc   ;==>__TCPServer_OnExit

Func __TCPServer_Sendstd()
	For $i = 1 To $_TCPServer_MaxClients
		If $__TCPServer_Consoles[$i] <> 0 Then
			$PID = $__TCPServer_Consoles[$i]
			$line = StdoutRead($PID)
			If $line <> "" Then
				TCPSend($__TCPServer_Sockets[$i], $line)
			EndIf
		EndIf
	Next
EndFunc

Func __TCPServer_Accept()
	If $__TCPServer_Sockets[0] >= $_TCPServer_MaxClients Then
		Return
	EndIf
	$accept = TCPAccept($__TCPServer_MainSocket)
	If $accept = -1 Then Return
	For $i = 1 To $_TCPServer_MaxClients
		If $__TCPServer_Sockets[$i] = 0 Then ; socket is empty
			$__TCPServer_Sockets[$i] = $accept
			$__TCPServer_Sockets[0] += 1
			$__TCPServer_SocketCache[$i][0] = $accept
			$__TCPServer_SocketCache[$i][1] = _TCPServer_SocketToIP($accept)
			If $_TCPServer_DebugMode Then __TCPServer_Log("Client " & _TCPServer_SocketToIP($accept) & " connected to socket " & $accept)
			Call($_TCPServer_OnConnectCallback, $__TCPServer_Sockets[$i], _TCPServer_SocketToIP($__TCPServer_Sockets[$i]))
			Return 0
		EndIf
	Next
EndFunc   ;==>__TCPServer_Accept

Func __TCPServer_KillConnection($iConn)
	$iSocket = _TCPServer_ConnIDToSocket($iConn)
	If $_TCPServer_DebugMode Then __TCPServer_Log("Closing socket " & $iSocket)
	TCPCloseSocket($iSocket)
	$__TCPServer_Sockets[$iConn] = 0
	$__TCPServer_Sockets[0] -= 1
	Call($_TCPServer_OnDisconnectCallback, $__TCPServer_SocketCache[$iConn][0], $__TCPServer_SocketCache[$iConn][1])
	$__TCPServer_SocketCache[$iConn][0] = 0
	$__TCPServer_SocketCache[$iConn][1] = 0
	If $__TCPServer_Consoles[$iConn] <> 0 Then
		ProcessClose($__TCPServer_Consoles[$iConn])
	EndIf
	$__TCPServer_Consoles[$iConn] = 0
	$__TCPServer_Pars[$iConn] = 0
EndFunc

Func __TCPServer_Recv()
	For $i = 1 To $_TCPServer_MaxClients
		Dim $sData
		$recv = TCPRecv($__TCPServer_Sockets[$i], 1000000)
		If @error = 10054 Then ; Disconnected by user
			__TCPServer_KillConnection($i)
			ContinueLoop
		EndIf

		If $recv Then
			$sData = $recv
			Do
				$recv = TCPRecv($__TCPServer_Sockets[$i], 1000000)
				$sData &= $recv
			Until $recv = ""
			If $_TCPServer_AutoTrim Then
				$sData = StringStripWS($sData, 1+2)
			EndIf
			If $_TCPServer_DebugMode Then __TCPServer_Log("Client " & _TCPServer_SocketToIP($__TCPServer_Sockets[$i]) & " sent " & $sData)
			Call($_TCPServer_OnReceiveCallback, $__TCPServer_Sockets[$i], _TCPServer_SocketToIP($__TCPServer_Sockets[$i]), $sData, $__TCPServer_Pars[$i])
		EndIf
	Next
EndFunc   ;==>__TCPServer_Recv

Func __TCPServer_Log($sMsg)
	ConsoleWrite(@CRLF & @MIN & ":" & @SEC & " > " & $sMsg)
EndFunc   ;==>__TCPServer_Log