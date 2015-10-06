#include <GUIConstantsEx.au3>
#include <ListViewConstants.au3>
#include <WindowsConstants.au3>
#include <GUIListView.au3>
#include <Array.au3>
#include "TCPServer.au3"

Opt("GUIOnEventMode", 1)

#Region ### START Koda GUI section ### Form=
$frmList = GUICreate("List clients", 306, 114, -1, -1)
GUISetOnEvent($GUI_EVENT_CLOSE, "ExitFunc")
$gList = GUICtrlCreateListView("IP|Socket", 0, 0, 305, 113)
GUICtrlSendMsg(-1, $LVM_SETCOLUMNWIDTH, 0, 200)
GUICtrlSendMsg(-1, $LVM_SETCOLUMNWIDTH, 1, 100)
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

_TCPServer_OnConnect("OnConnect")
_TCPServer_OnDisconnect("OnDisconnect")

_TCPServer_DebugMode(True)
_TCPServer_SetMaxClients(10)

_TCPServer_Start(8081)

While 1
	Sleep(100)
WEnd

Func ExitFunc()
	If _TCPServer_IsServerActive() Then
		_TCPServer_Stop()
	EndIf
	Exit
EndFunc

Func OnConnect($iSocket, $sIP)
	GUICtrlCreateListViewItem($sIP & "|" & $iSocket, $gList)
EndFunc

Func OnDisconnect($iSocket, $sIP)
	; We should use $iSocket and search for it on the list view
	;  then simply remove it.
	; But we want to show how to use the whole UDF
	; So that's what we will do:

	_GUICtrlListView_DeleteAllItems($gList)
	$aActive = _TCPServer_ListClients()
	For $i = 1 To _TCPServer_GetMaxClients()
		$sIP = _TCPServer_SocketToIP($aActive[$i])
		If $sIP <> 0 Then
			GUICtrlCreateListViewItem($sIP & "|" & $aActive[$i], $gList)
		EndIf
	Next
EndFunc