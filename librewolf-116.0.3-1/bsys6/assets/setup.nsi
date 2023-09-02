!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "Sections.nsh"
!addplugindir .
!addplugindir x86-ansi

!define APPNAME "LibreWolf"
!define PROGNAME "librewolf"
!define EXECUTABLE "${PROGNAME}.exe"
!define PROG_VERSION "pkg_version"
!define COMPANYNAME "LibreWolf"
!define ESTIMATED_SIZE 190000
!define MUI_ICON "librewolf.ico"
!define MUI_WELCOMEFINISHPAGE_BITMAP "banner.bmp"

Name "${APPNAME}"
OutFile "${PROGNAME}-${PROG_VERSION}.en-US.win64-setup.exe"
InstallDirRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "InstallLocation"
InstallDir $PROGRAMFILES64\${APPNAME}
RequestExecutionLevel admin

# Pages

!define MUI_ABORTWARNING

!define MUI_WELCOMEPAGE_TITLE "Welcome to the LibreWolf Setup"
!define MUI_WELCOMEPAGE_TEXT "This setup will guide you through the installation of LibreWolf.$\r$\n$\r$\n\
If you don't have it installed already, this will also install the latest Visual C++ Redistributable.$\r$\n$\r$\n\
Click Next to continue."

!define MUI_COMPONENTSPAGE_SMALLDESC

!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_TEXT "Create desktop shortcut"
!define MUI_FINISHPAGE_RUN_FUNCTION "CreateDesktopShortcut"
!define MUI_FINISHPAGE_RUN_NOTCHECKED

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

Section "LibreWolf Browser" main
  SectionIn RO

	# Make sure LibreWolf is closed before the installation
	nsProcess::_FindProcess "${EXECUTABLE}"
	Pop $R0
	${If} $R0 = 0
		IfSilent 0 +4
		DetailPrint "${APPNAME} is still running, aborting because of silent install."
		SetErrorlevel 2
		Abort

		DetailPrint "${APPNAME} is still running"
		MessageBox MB_OKCANCEL "LibreWolf is still running and has to be closed for the setup to continue." IDOK continue IDCANCEL break
break:
		SetErrorlevel 1
		Abort
continue:
		DetailPrint "Closing ${APPNAME} gracefully..."
		nsProcess::_CloseProcess "${EXECUTABLE}"
		Pop $R0
		Sleep 2000
		nsProcess::_FindProcess "${EXECUTABLE}"
		Pop $R0
		${If} $R0 = 0
			DetailPrint "Failed to close ${APPNAME}, killing it..."
			nsProcess::_KillProcess "${EXECUTABLE}"
			Sleep 2000
			nsProcess::_FindProcess "${EXECUTABLE}"
			Pop $R0
			${If} $R0 = 0
				DetailPrint "Failed to kill ${APPNAME}, aborting"
				MessageBox MB_ICONSTOP "LibreWolf is still running and can't be closed by the installer. Please close it manually and try again."
				SetErrorlevel 2
				Abort
			${EndIf}
		${EndIf}
	${EndIf}

	# Install Visual C++ Redistributable (only if not silent)
	IfSilent +4 0
	InitPluginsDir
	File /oname=$PLUGINSDIR\vc_redist.x64.exe vc_redist.x64.exe
	ExecWait "$PLUGINSDIR\vc_redist.x64.exe /install /quiet /norestart"

	# Copy files
	SetOutPath $INSTDIR
	File /r LibreWolf\*.*

	# Start Menu
	RMDir /r "$SMPROGRAMS\${COMPANYNAME}" ; Previously those files were stored for the user, we don't want double entries
	SetShellVarContext all
	CreateDirectory "$SMPROGRAMS\${COMPANYNAME}"
	CreateShortCut "$SMPROGRAMS\${COMPANYNAME}\${APPNAME}.lnk" "$INSTDIR\${PROGNAME}.exe" "" "$INSTDIR\${MUI_ICON}"
	CreateShortCut "$SMPROGRAMS\${COMPANYNAME}\Uninstall.lnk" "$INSTDIR\uninstall.exe" "" ""

	# Uninstaller 
	writeUninstaller "$INSTDIR\uninstall.exe"

	# Registry information for add/remove programs
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "DisplayName" "${APPNAME}"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "QuietUninstallString" "$\"$INSTDIR\uninstall.exe$\" /S"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "InstallLocation" "$\"$INSTDIR$\""
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "DisplayIcon" "$\"$INSTDIR\${MUI_ICON}$\""
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "Publisher" "${COMPANYNAME}"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "DisplayVersion" "${PROG_VERSION}"
	# There is no option for modifying or repairing the install
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "NoModify" 1
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "NoRepair" 1
	# Set the INSTALLSIZE constant (!defined at the top of this script) so Add/Remove Programs can accurately report the size
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "EstimatedSize" ${ESTIMATED_SIZE}


	#
	# Registry information to let Windows pick us up in the list of available browsers
	#
	
	WriteRegStr HKLM "Software\Clients\StartMenuInternet\LibreWolf" "" "LibreWolf"	

	WriteRegStr HKLM "Software\Clients\StartMenuInternet\LibreWolf\Capabilities" "ApplicationDescription" "LibreWolf"
	WriteRegStr HKLM "Software\Clients\StartMenuInternet\LibreWolf\Capabilities" "ApplicationIcon" "$INSTDIR\librewolf.exe,0"
	WriteRegStr HKLM "Software\Clients\StartMenuInternet\LibreWolf\Capabilities" "ApplicationName" "LibreWolf"
	WriteRegStr HKLM "Software\Clients\StartMenuInternet\LibreWolf\Capabilities\FileAssociations" ".htm" "LibreWolfHTM"
	WriteRegStr HKLM "Software\Clients\StartMenuInternet\LibreWolf\Capabilities\FileAssociations" ".html" "LibreWolfHTM"
	WriteRegStr HKLM "Software\Clients\StartMenuInternet\LibreWolf\Capabilities\FileAssociations" ".pdf" "LibreWolfHTM"
	WriteRegStr HKLM "Software\Clients\StartMenuInternet\LibreWolf\Capabilities\Startmenu" "StartMenuInternet" "LibreWolf"
	WriteRegStr HKLM "Software\Clients\StartMenuInternet\LibreWolf\Capabilities\URLAssociations" "http" "LibreWolfHTM"
	WriteRegStr HKLM "Software\Clients\StartMenuInternet\LibreWolf\Capabilities\URLAssociations" "https" "LibreWolfHTM"

	WriteRegStr HKLM "Software\Clients\StartMenuInternet\LibreWolf\DefaultIcon" "" "$INSTDIR\librewolf.exe,0"
	WriteRegStr HKLM "Software\Clients\StartMenuInternet\LibreWolf\shell\open\command" "" "$INSTDIR\librewolf.exe"
	
	WriteRegStr HKLM "Software\RegisteredApplications" "LibreWolf" "Software\Clients\StartMenuInternet\LibreWolf\Capabilities"
	
	WriteRegStr HKLM "Software\Classes\LibreWolfHTM" "" "LibreWolf Handler"
	WriteRegStr HKLM "Software\Classes\LibreWolfHTM" "AppUserModelId" "LibreWolf"
	WriteRegStr HKLM "Software\Classes\LibreWolfHTM\Application" "AppUserModelId" "LibreWolf"
	WriteRegStr HKLM "Software\Classes\LibreWolfHTM\Application" "ApplicationIcon" "$INSTDIR\librewolf.exe,0"
	WriteRegStr HKLM "Software\Classes\LibreWolfHTM\Application" "ApplicationName" "LibreWolf"
	WriteRegStr HKLM "Software\Classes\LibreWolfHTM\Application" "ApplicationDescription" "Start the LibreWolf Browser"
	WriteRegStr HKLM "Software\Classes\LibreWolfHTM\Application" "ApplicationCompany" "LibreWolf Community"
	WriteRegStr HKLM "Software\Classes\LibreWolfHTM\DefaultIcon" "" "$INSTDIR\librewolf.exe,0"
	WriteRegStr HKLM "Software\Classes\LibreWolfHTM\shell\open\command" "" "$\"$INSTDIR\librewolf.exe$\" -osint -url $\"%1$\""

	DetailPrint "Removing potentially broken WinUpdater Scheduled Task"
	nsExec::ExecToLog 'schtasks.exe /delete /tn "LibreWolf WinUpdater" /f'

	DetailPrint "Removing potentially broken WinUpdater start menu entry"
	SetShellVarContext current
	RmDir /r "$SMPROGRAMS\LibreWolf"
	SetShellVarContext all
SectionEnd

Section /o "LibreWolf WinUpdater" winupdater
	File LibreWolf-WinUpdater.exe
	File ScheduledTask-Create.ps1
	File ScheduledTask-Remove.ps1
	CreateShortCut "$SMPROGRAMS\${COMPANYNAME}\LibreWolf WinUpdater.lnk" "$INSTDIR\LibreWolf-WinUpdater.exe" "" "$INSTDIR\LibreWolf-WinUpdater.exe"
SectionEnd

# Uninstaller
section "Uninstall"

	# Kill LibreWolf if it is still running
	nsProcess::_FindProcess "${EXECUTABLE}"
	Pop $R0
	${If} $R0 = 0
		DetailPrint "${APPNAME} is still running, killing it..."
		nsProcess::_KillProcess "${EXECUTABLE}"
		Sleep 2000
	${EndIf}
	
	SetShellVarContext all

	# Remove the Start Menu folder
	RmDir /r "$SMPROGRAMS\LibreWolf"
 
	# Remove files
	RmDir /r $INSTDIR

	# Remove uninstaller information from the registry
	DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}"
	
	#
	# Windows default browser integration
	#
	
	DeleteRegKey HKLM "Software\Clients\StartMenuInternet\LibreWolf"
	DeleteRegKey HKLM "Software\RegisteredApplications"
	DeleteRegKey HKLM "Software\Classes\LibreWolfHTM"


	DetailPrint "Removing WinUpdater"

	SetShellVarContext current
	FindFirst $0 $1 $PROFILE\..\*
	loop:
		StrCmp $1 "" done

		RmDir /r "$PROFILE\..\$1\AppData\Roaming\LibreWolf\WinUpdater"

		FindNext $0 $1
		Goto loop
	done:
	FindClose $0
	SetShellVarContext all


	DetailPrint "Removing WinUpdater Scheduled Task(s)"
	nsExec::ExecToLog `powershell -Command "Get-ScheduledTask 'LibreWolf*' | Unregister-ScheduledTask -Confirm:$$false"`

sectionEnd

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${main} "Install the browser for all users"
  !insertmacro MUI_DESCRIPTION_TEXT ${winupdater} "A companion tool to update LibreWolf with a single click"
!insertmacro MUI_FUNCTION_DESCRIPTION_END


Function .onInit
	Var /GLOBAL DEFAULT_INSTDIR
	Var /GLOBAL INSTALL_TYPE
	StrCpy $DEFAULT_INSTDIR $INSTDIR
	StrCpy $INSTALL_TYPE "normal"
	SetShellVarContext current
	IfFileExists "$SMPROGRAMS\${COMPANYNAME}\LibreWolf WinUpdater.lnk" +3 +1
	SetShellVarContext all
	IfFileExists "$INSTDIR\LibreWolf-WinUpdater.exe" +1 +2
	SectionSetFlags ${winupdater} ${SF_SELECTED}
	SetShellVarContext all
FunctionEnd


Function "CreateDesktopShortcut"
	SetShellVarContext all
	CreateShortCut "$DESKTOP\LibreWolf.lnk" "$INSTDIR\librewolf.exe" "" "$INSTDIR\librewolf.exe" 0
FunctionEnd
