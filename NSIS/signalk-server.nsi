;======================================================
;Init
  Unicode True
  SetCompressor /solid /final lzma ; zlib|bzip2|lzma
;======================================================
;Include tools
  !include "tools.nsh"
  !include x64.nsh
;======================================================
;Include Modern UI
  !include "MUI2.nsh"
;======================================================
;General
  !define INST_VERSION "0.4.3"
  BrandingText "Signal K from http://signalk.org/"
  Name "Signal K installer ${INST_VERSION}"
  OutFile "..\output\signalk-server-setup-${INST_VERSION}.exe"
  InstallDir "c:\signalk"
  RequestExecutionLevel admin ; user | admin 
  !define MUI_ICON "..\target\tools\signalk.ico"
;======================================================
;Pages
  !insertmacro MUI_PAGE_WELCOME
  !insertmacro MUI_PAGE_DIRECTORY
;  !insertmacro MUI_PAGE_LICENSE "${NSISDIR}\Docs\Modern UI\License.txt"
  !insertmacro MUI_PAGE_COMPONENTS
  !insertmacro MUI_PAGE_INSTFILES

;======================================================
; Languages
  !insertmacro MUI_LANGUAGE "English"
;======================================================
;Interface Settings
  !define MUI_ABORTWARNING
;======================================================
; GLOBAL vars
  Var /GLOBAL USERPROFILE
  Var /GLOBAL NODE_PATH
  Var /GLOBAL NODE_MODULES_PATH
  Var /GLOBAL OPENSSL_PATH
  Var /GLOBAL OPENSSL_BIN_PATH
  Var /GLOBAL OPENSSL_CONF
  Var /GLOBAL TOOLS_PATH
  Var /GLOBAL INSTALL_DRIVE
  Var /GLOBAL NODE64_URL
  Var /GLOBAL NODE64_ORG_DIR
  Var /GLOBAL NODE86_URL
  Var /GLOBAL NODE86_ORG_DIR

  Function SetGlobalVars
    StrCpy $USERPROFILE $INSTDIR\signalkhome
    StrCpy $NODE_PATH '$INSTDIR\nodejs'
    StrCpy $NODE_MODULES_PATH '$INSTDIR\nodejs\node_modules'
    StrCpy $OPENSSL_PATH '$INSTDIR\openssl'
    StrCpy $OPENSSL_BIN_PATH '$INSTDIR\openssl\bin'
    StrCpy $OPENSSL_CONF '$INSTDIR\openssl\openssl.cnf'
    StrCpy $TOOLS_PATH '$INSTDIR\tools'
    StrCpy $NODE64_URL 'https://nodejs.org/dist/v10.23.0/node-v10.23.0-win-x64.zip'
    StrCpy $NODE86_URL 'https://nodejs.org/dist/v10.23.0/node-v10.23.0-win-x86.zip'
    StrCpy $NODE64_ORG_DIR 'node-v10.23.0-win-x64'
    StrCpy $NODE86_ORG_DIR 'node-v10.23.0-win-x86'
  FunctionEnd

  !macro CreateInternetShortcutWithIcon FILEPATH URL ICONPATH ICONINDEX
    WriteINIStr "${FILEPATH}" "InternetShortcut" "URL" "${URL}"
    WriteINIStr "${FILEPATH}" "InternetShortcut" "IconIndex" "${ICONINDEX}"
    WriteINIStr "${FILEPATH}" "InternetShortcut" "IconFile" "${ICONPATH}"
    WriteINIStr "${FILEPATH}" "InternetShortcut" "HotKey" "0"
    WriteINIStr "${FILEPATH}" "InternetShortcut" "IDList" ""
    WriteINIStr "${FILEPATH}" "{000214A0-0000-0000-C000-000000000046}" "Prop3" "19,2"
  !macroend

;======================================================
  Function .onInit
    SetOutPath $INSTDIR
    LogSet on
    SetDetailsView show
    LogText "Signal K installer version: ${INST_VERSION}"
    LogSet off
  FunctionEnd
;======================================================
  Function GenToolsFiles
    StrCpy $0 "$INSTDIR"
    StrCpy $0 $0 1 ; Get drive letter
    StrCpy $INSTALL_DRIVE "$0:"

    DetailPrint "Create $TOOLS_PATH\signalk-server-cli.cmd"
    FileOpen  $9  $TOOLS_PATH\signalk-server-cli.cmd w
    FileWrite $9 '@ECHO OFF$\r$\n'
    FileWrite $9 '$INSTALL_DRIVE$\r$\n'
    FileWrite $9 'set USERPROFILE=$USERPROFILE$\r$\n'
    FileWrite $9 'set NODE_PATH=$NODE_PATH$\r$\n'
    FileWrite $9 'set PATH=%NODE_PATH%;$OPENSSL_BIN_PATH;%PATH%$\r$\n'
    FileWrite $9 'set SIGNALK_NODE_CONFIG_DIR=%USERPROFILE%\.signalk$\r$\n'
    FileWrite $9 'set SIGNALK_SERVER_IS_UPDATABLE=1$\r$\n'
    FileWrite $9 'set OPENSSL_CONF=$OPENSSL_CONF$\r$\n'
    FileWrite $9 'cd %USERPROFILE%$\r$\n'
    FileWrite $9 'node.exe -p -e "$\'Your environment has been set up for using Node.js $\' + process.versions.node + $\' ($\' + process.arch + $\')$\'"%$\r$\n'
    FileWrite $9 'echo Welcome in signal K$\r$\n'
    FileWrite $9 'echo "enter signalk-server.cmd to start server"$\r$\n'
    FileWrite $9 '$\r$\n'
    FileClose $9

    DetailPrint "Create $USERPROFILE\.npmrc"
    FileOpen  $9  $USERPROFILE\.npmrc w
    FileWrite $9 'cache=$USERPROFILE\npm-cache$\r$\n'
    FileWrite $9 'tmp=$USERPROFILE\tmp$\r$\n'
    FileWrite $9 'prefix=$NODE_PATH$\r$\n'
    FileWrite $9 '$\r$\n'
    FileClose $9

    DetailPrint "Create $TOOLS_PATH\signalk-server-services.js"
    FileOpen  $9  $TOOLS_PATH\signalk-server-services.js w
    FileWrite $9 'process.env.SIGNALK_NODE_CONFIG_DIR = process.env.USERPROFILE + "\\.signalk"$\r$\n'
    FileWrite $9 'process.env.SIGNALK_SERVER_IS_UPDATABLE = "1"$\r$\n'
    FileWrite $9 '//process.env.DEBUG = ""$\r$\n'
      Push $NODE_MODULES_PATH
      Call ConvertBStoDBS 
      Pop $R0
    FileWrite $9 'var Server = require("$R0\\signalk-server");$\r$\n'
    FileWrite $9 'var server = new Server();$\r$\n'
    FileWrite $9 'server.start().catch(err => {console.log(err);process.exit(-1)})$\r$\n'
    FileWrite $9 '$\r$\n'
    FileClose $9

    DetailPrint "Create $TOOLS_PATH\install-signalk-server-services.js"
    FileOpen $9  $TOOLS_PATH\install-signalk-server-services.js w
      Push $NODE_PATH
      Call ConvertBStoDBS 
      Pop $R0
    FileWrite $9 'process.env.NODE_PATH = "$R0"$\r$\n'
      Push $USERPROFILE
      Call ConvertBStoDBS 
      Pop $R0
    FileWrite $9 'process.env.USERPROFILE = "$R0"$\r$\n'
      Push $OPENSSL_BIN_PATH
      Call ConvertBStoDBS 
      Pop $R0
    FileWrite $9 'process.env.Path = process.env.NODE_PATH + ";$R0;" + process.env.Path$\r$\n'
      Push $OPENSSL_CONF
      Call ConvertBStoDBS 
      Pop $R0
    FileWrite $9 'process.env.OPENSSL_CONF = "$R0"$\r$\n'
      Push $NODE_MODULES_PATH
      Call ConvertBStoDBS 
      Pop $R0
    FileWrite $9 'var Service = require("$R0\\node-windows").Service;$\r$\n'
    FileWrite $9 'var elevate = require("$R0\\node-windows").elevate;$\r$\n'
    FileWrite $9 'var svc = new Service({$\r$\n'
    FileWrite $9 '  name:"signalk-server-node",$\r$\n'
    FileWrite $9 '  description: "Signal K server node",$\r$\n'
      Push "$TOOLS_PATH\signalk-server-services.js"
      Call ConvertBStoDBS 
      Pop $R0
    FileWrite $9 '  script: "$R0",$\r$\n'
    FileWrite $9 '  env: ['
    FileWrite $9 '{name: "HOME",value: process.env["USERPROFILE"]},'
    FileWrite $9 '{name: "NODE_PATH",value: process.env.NODE_PATH},'
    FileWrite $9 '{name: "Path",value: process.env.Path},'
    FileWrite $9 '{name: "USERPROFILE",value: process.env.USERPROFILE},'
    FileWrite $9 '{name: "OPENSSL_CONF",value: process.env.OPENSSL_CONF}'
    FileWrite $9 ']'
    FileWrite $9 '});$\r$\n'
    FileWrite $9 'svc.on("install",function(){$\r$\n'
    FileWrite $9 '//  svc.start();$\r$\n'
    FileWrite $9 '  elevate($\'sc config "signalkservernode.exe" Start=Demand$\');$\r$\n'
    FileWrite $9 '});$\r$\n'
    FileWrite $9 'svc.install();$\r$\n'
    FileWrite $9 '$\r$\n'
    FileClose $9

    DetailPrint "Create $TOOLS_PATH\remove-signalk-server-services.cmd"
    FileOpen  $9  $TOOLS_PATH\remove-signalk-server-services.cmd w
    FileWrite $9 '@ECHO OFF$\r$\n'
    FileWrite $9 'echo "Remove signalk as service in progress..."$\r$\n'
    FileWrite $9 'SC DELETE "signalkservernode.exe"$\r$\n'
    FileWrite $9 'if %ERRORLEVEL% neq 0 goto :ERROR$\r$\n'
    FileWrite $9 'pause$\r$\n'
    FileWrite $9 'exit 0$\r$\n'
    FileWrite $9 ':ERROR$\r$\n'
    FileWrite $9 'echo "An ERROR has occurred."$\r$\n'
    FileWrite $9 'pause$\r$\n'
    FileWrite $9 'exit 1$\r$\n'
    FileWrite $9 '$\r$\n'
    FileClose $9

    DetailPrint "Create $TOOLS_PATH\create-signalk-server-services.cmd"
    FileOpen  $9  $TOOLS_PATH\create-signalk-server-services.cmd w
    FileWrite $9 '@ECHO OFF$\r$\n'
    FileWrite $9 '$INSTALL_DRIVE$\r$\n'
    FileWrite $9 'echo Install signalk as service in progress...$\r$\n'
    FileWrite $9 'set NODE_PATH=$NODE_PATH$\r$\n'
    FileWrite $9 'set "PATH=%NODE_PATH%;%PATH%"$\r$\n'
    FileWrite $9 'cd $TOOLS_PATH$\r$\n'
    FileWrite $9 'node .\install-signalk-server-services.js$\r$\n'
    FileWrite $9 'if %ERRORLEVEL% neq 0 goto :ERROR$\r$\n'
    FileWrite $9 'exit 0$\r$\n'
    FileWrite $9 ':ERROR$\r$\n'
    FileWrite $9 'echo An ERROR has occurred.$\r$\n'
    FileWrite $9 'pause$\r$\n'
    FileWrite $9 'exit 1$\r$\n'
    FileWrite $9 '$\r$\n'
    FileClose $9

    DetailPrint "Create $TOOLS_PATH\stop-signalk-server-services.cmd"
    FileOpen  $9  $TOOLS_PATH\stop-signalk-server-services.cmd w
    FileWrite $9 '@ECHO OFF$\r$\n'
    FileWrite $9 'echo Stop Signal K service...$\r$\n'
    FileWrite $9 'net stop "signalkservernode.exe"$\r$\n'
    FileWrite $9 'if %ERRORLEVEL% neq 0 goto :ERROR$\r$\n'
    FileWrite $9 'exit 0$\r$\n'
    FileWrite $9 ':ERROR$\r$\n'
    FileWrite $9 'echo An ERROR has occurred.$\r$\n'
    FileWrite $9 'pause$\r$\n'
    FileWrite $9 'exit 1$\r$\n'
    FileWrite $9 '$\r$\n'
    FileClose $9

    DetailPrint "Create $TOOLS_PATH\start-signalk-server-services.cmd"
    FileOpen  $9  $TOOLS_PATH\start-signalk-server-services.cmd w
    FileWrite $9 '@ECHO OFF$\r$\n'
    FileWrite $9 'echo Start Signal K service...$\r$\n'
    FileWrite $9 'openfiles >NUL 2>&1$\r$\n'
    FileWrite $9 'if %ERRORLEVEL% neq 0 goto :ERROR_ADMIN$\r$\n'
    FileWrite $9 'goto :STOP_SERVICE$\r$\n'
    FileWrite $9 ':ERROR_ADMIN$\r$\n'
    FileWrite $9 'echo ERROR: This command must be "Run as Administrator"$\r$\n'
    FileWrite $9 'pause$\r$\n'
    FileWrite $9 'exit 1$\r$\n'
    FileWrite $9 ':STOP_SERVICE$\r$\n'
    FileWrite $9 'net stop "signalkservernode.exe" >nul 2>&1$\r$\n'
    FileWrite $9 'net start "signalkservernode.exe"$\r$\n'
    FileWrite $9 'if %ERRORLEVEL% neq 0 goto :ERROR_START$\r$\n'
    FileWrite $9 'exit 0$\r$\n'
    FileWrite $9 ':ERROR_START$\r$\n'
    FileWrite $9 'echo An ERROR has occurred.$\r$\n'
    FileWrite $9 'pause$\r$\n'
    FileWrite $9 'exit 1$\r$\n'
    FileWrite $9 '$\r$\n'
    FileClose $9

    DetailPrint "Create $TOOLS_PATH\npm-install-node-windows.cmd"
    FileOpen  $9  $TOOLS_PATH\npm-install-node-windows.cmd w
    FileWrite $9 '@ECHO OFF$\r$\n'
    FileWrite $9 '$INSTALL_DRIVE$\r$\n'
    FileWrite $9 'echo Install node-windows package in progress...$\r$\n'
    FileWrite $9 'set USERPROFILE=$USERPROFILE$\r$\n'
    FileWrite $9 'set NODE_PATH=$NODE_PATH$\r$\n'
    FileWrite $9 'set "Path=%NODE_PATH%;%Path%"$\r$\n'
    FileWrite $9 'set OPENSSL_CONF=$OPENSSL_CONF$\r$\n'
    FileWrite $9 'cd $NODE_PATH$\r$\n'
    FileWrite $9 'npm install -g --unsafe-perm  node-windows@1.0.0-beta.5$\r$\n'
    FileWrite $9 'if %ERRORLEVEL% neq 0 goto :ERROR$\r$\n'
    FileWrite $9 'exit 0$\r$\n'
    FileWrite $9 ':ERROR$\r$\n'
    FileWrite $9 'echo An ERROR has occurred.$\r$\n'
    FileWrite $9 'pause$\r$\n'
    FileWrite $9 'exit 1$\r$\n'
    FileWrite $9 '$\r$\n'
    FileClose $9

    DetailPrint "Create $TOOLS_PATH\npm-install-signalk-server.cmd"
    FileOpen  $9  $TOOLS_PATH\npm-install-signalk-server.cmd w
    FileWrite $9 '@ECHO OFF$\r$\n'
    FileWrite $9 '$INSTALL_DRIVE$\r$\n'
    FileWrite $9 'echo Install signalk-server package in progress...$\r$\n'
    FileWrite $9 'set USERPROFILE=$USERPROFILE$\r$\n'
    FileWrite $9 'set NODE_PATH=$NODE_PATH$\r$\n'
    FileWrite $9 'set "Path=%NODE_PATH%;%Path%"$\r$\n'
    FileWrite $9 'set OPENSSL_CONF=$OPENSSL_CONF$\r$\n'
    FileWrite $9 'cd $NODE_PATH$\r$\n'
    FileWrite $9 'npm install -g --unsafe-perm  signalk-server$\r$\n'
    FileWrite $9 'if %ERRORLEVEL% neq 0 goto :ERROR$\r$\n'
    FileWrite $9 'exit 0$\r$\n'
    FileWrite $9 ':ERROR$\r$\n'
    FileWrite $9 'echo An ERROR has occurred.$\r$\n'
    FileWrite $9 'pause$\r$\n'
    FileWrite $9 'exit 1$\r$\n'
    FileWrite $9 '$\r$\n'
    FileClose $9

    DetailPrint "Create $TOOLS_PATH\SignalK-CLI.lnk"
    CreateShortCut "$TOOLS_PATH\SignalK-CLI.lnk" "cmd" \
      "/k $TOOLS_PATH\signalk-server-cli.cmd" "$TOOLS_PATH\signalk.ico" 0 SW_SHOWNORMAL \
      "" "Signal K CLI"

    DetailPrint "Create $TOOLS_PATH\SignalK GUI shortcut"
    !insertmacro CreateInternetShortcutWithIcon "$TOOLS_PATH\SignalK GUI.URL" "http://localhost:3000" "$TOOLS_PATH\signalk.ico" 0
  FunctionEnd
;======================================================
  Section "Extract nodejs" SecExtractJS
    LogSet on
;    SectionIn RO
    SetDetailsView show
    Call SetGlobalVars
    SetOutPath $INSTDIR
    File /r ..\target\wget.exe
    LogText "Extract wget.exe to $INSTDIR"
    ClearErrors
    ${If} ${RunningX64}
      DetailPrint "Download nodejs 64-bits"
      LogText "Download nodejs 64-bits from $NODE64_URL"
      ExecWait '"$INSTDIR\wget.exe" "--output-document=$INSTDIR\nodejs.zip" "$NODE64_URL"' $0
    ${Else}
      DetailPrint "Download nodejs 32-bits"
      LogText "Download nodejs 32-bits from $NODE86_URL"
      ExecWait '"$INSTDIR\wget.exe" "--output-document=$INSTDIR\nodejs.zip" "$NODE86_URL"' $0
    ${EndIf}  
    ${If} ${Errors}
      MessageBox MB_OK "Download nodejs failed with code: $0"
      LogText "Download nodejs failed whith code: $0"
      Quit
    ${EndIf}
    DetailPrint "Extract nodejs"
    LogText "Extract nodejs from $INSTDIR\nodejs.zip to $INSTDIR"
    nsisunz::Unzip "$INSTDIR\nodejs.zip" "$INSTDIR"
    Pop $0
    DetailPrint "Extract nodejs: $0"
    StrCmp $0 "success" unzipOk
      MessageBox MB_OK "Extract nodejs failed"
      Quit
    unzipOk:
    ${If} ${RunningX64}
      Rename $INSTDIR\$NODE64_ORG_DIR $INSTDIR\nodejs
    ${Else}
      Rename $INSTDIR\$NODE86_ORG_DIR $INSTDIR\nodejs
    ${EndIf}  
    Delete "$INSTDIR\nodejs.zip"
    Delete "$INSTDIR\wget.exe"
  SectionEnd

  Section "Extract openssl" SecExtractSSL
    LogSet on
;    SectionIn RO
    Call SetGlobalVars
    SetOutPath $OPENSSL_PATH
    ${If} ${RunningX64}
      DetailPrint "Extract openssl 64-bits"
      File /r "..\target\openssl-x64\*.*"
    ${Else}
      DetailPrint "Extract openssl 32-bits"
      File /r "..\target\openssl-x86\*.*"
    ${EndIf}  
  SectionEnd

  Section "Generate tools" SecTools
    LogSet on
;    SectionIn RO
    Call SetGlobalVars
    DetailPrint "Install tools files"
    SetOutPath $INSTDIR\signalkhome
    File /nonfatal /r "..\target\signalkhome\*.*"
    SetOutPath $INSTDIR\tools
    File /nonfatal /r "..\target\tools\*.*"
    SetOutPath $INSTDIR\screenshots
    File /nonfatal /r "..\screenshots\*.png"
    SetOutPath $INSTDIR
    File /nonfatal /r "..\target\readme.html"
    Call GenToolsFiles
    ExecWait '"$TOOLS_PATH\npm-install-node-windows.cmd"' $0
    DetailPrint "npm install -g --unsafe-perm  node-windows returned $0"
  SectionEnd

  Section "install signalk-server" SecSkInstall
    LogSet on
    Call SetGlobalVars
    ExecWait '"$TOOLS_PATH\npm-install-signalk-server.cmd"' $0
    DetailPrint "npm install -g --unsafe-perm  signalk-server returned $0"
  SectionEnd

  Section "Signal K as services" SecSkService
    LogSet on
    Call SetGlobalVars
    ExecWait '"$TOOLS_PATH\create-signalk-server-services.cmd"' $0
    DetailPrint "Install Signal K as windows services returned $0"
  SectionEnd

  SectionGroup /e "Desktop shortcut" SecShortcuts
    Section "Start service" SecStartService
      LogSet on
      Call SetGlobalVars
      DetailPrint "Create desktop shortcut 'Start Signal K Service'"
      CreateShortCut "$DESKTOP\Start Signal K Service.lnk" "$TOOLS_PATH\start-signalk-server-services.cmd" \
        "" "$TOOLS_PATH\signalk.ico" 0 SW_SHOWNORMAL \
        "" "Start Signal K Service"
    SectionEnd
    Section "Signal Web GUI" SecSignalkWebGUI
      LogSet on
      Call SetGlobalVars
      DetailPrint "Create desktop shortcut 'SignalK-GUI'"
      !insertmacro CreateInternetShortcutWithIcon "$DESKTOP\SignalK-GUI.URL" "http://localhost:3000" "$TOOLS_PATH\signalk.ico" 0
    SectionEnd

    Section /o "Signal K CLI" SecSignalkCli
      LogSet on
      Call SetGlobalVars
      DetailPrint "Create desktop shortcut 'Signal K CLI'"
      CreateShortCut "$DESKTOP\Signal K CLI.lnk" "cmd" \
        "/k $TOOLS_PATH\signalk-server-cli.cmd" "$TOOLS_PATH\signalk.ico" 0 SW_SHOWNORMAL \
        "" "Signal K CLI"
    SectionEnd
SectionGroupEnd

;======================================================
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SecExtractJS}    "Download and extract node js binary and library, mandatory for running Signal K (Internet access required)"
  !insertmacro MUI_DESCRIPTION_TEXT ${SecExtractSSL}   "Extract OpenSSL binary and library (mandatory for running Signal K with https)"
  !insertmacro MUI_DESCRIPTION_TEXT ${SecTools}        "Generate startup scripts, home dir and tools for running Signal K on Windows OS (mandatory for running Signal K)"
  !insertmacro MUI_DESCRIPTION_TEXT ${SecSkInstall}    "Install the lastest version of Signal K server node from npm repository (Internet access required)"
  !insertmacro MUI_DESCRIPTION_TEXT ${SecSkService}    "Install Signal as Windows service (Internet access required)"
  !insertmacro MUI_DESCRIPTION_TEXT ${SecShortcuts}    "Create desktop shortcut"
  !insertmacro MUI_DESCRIPTION_TEXT ${SecStartService} "Desktop shortcut to start Signal K service.$\n'Signal K as services' must be selected"
  !insertmacro MUI_DESCRIPTION_TEXT ${SecSignalkCli}   "Desktop shortcut to open nodejs console for run Signal K as standalone server.$\nOnly for advanced users"
  !insertmacro MUI_DESCRIPTION_TEXT ${SecSignalkWebGUI}   "Desktop shortcut to open the web GUI of Signal K server"
!insertmacro MUI_FUNCTION_DESCRIPTION_END
;======================================================

Function .onSelChange
  ${If} $0 != ${SecSkService}
    Return
  ${EndIf}
  SectionGetFlags ${SecSkService} $0
  IntOp $0 $0 & ${SF_SELECTED}
  IntCmp $0 ${SF_SELECTED} enableShortCut disableShortCut
  enableShortCut:
  SectionSetFlags ${SecStartService} ${SF_SELECTED}
  goto end
  disableShortCut:
  SectionSetFlags ${SecStartService} ${SF_RO}
  end:
FunctionEnd
