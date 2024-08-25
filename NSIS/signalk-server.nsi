;======================================================
;Init
  Unicode True
  SetCompressor /solid /final lzma ; zlib|bzip2|lzma
;======================================================
;Include tools
  !include "tools.nsh"
  !include x64.nsh
  !include WinVer.nsh
  !include nsDialogs.nsh
;======================================================
;Include Modern UI
  !include "MUI2.nsh"
;======================================================
;General
  !define INST_VERSION "1.2.0"
  BrandingText "Signal K from http://signalk.org/"
  Name "Signal K installer ${INST_VERSION}"
  OutFile "..\output\signalk-server-setup-${INST_VERSION}.exe"
  InstallDir "c:\signalk"
  RequestExecutionLevel admin ; user | admin 
  !define MUI_ICON "..\target\tools\signalk.ico"
;  !define MUI_HEADERIMAGE
;  !define MUI_HEADERIMAGE_BITMAP "signal-k-logo-image.bmp" ; 150x57 pixels
;  !define MUI_HEADERIMAGE_BITMAP_NOSTRETCH
;  !define MUI_HEADERIMAGE_RIGHT
;  !define MUI_WELCOMEFINISHPAGE_BITMAP "xxx.bmp" ; 164x314 pixels
;  !define MUI_WELCOMEFINISHPAGE_BITMAP_NOSTRETCH
;======================================================
;Pages
;internal_page_type [pre_function] [show_function] [leave_function] [/ENABLECANCEL]
  !insertmacro MUI_PAGE_WELCOME
;  !define MUI_PAGE_CUSTOMFUNCTION_PRE wel_pre
;  !define MUI_PAGE_CUSTOMFUNCTION_SHOW wel_show
  !insertmacro MUI_PAGE_DIRECTORY
;  !insertmacro MUI_PAGE_LICENSE "${NSISDIR}\Docs\Modern UI\License.txt"
  Page custom nodejsAlertPre
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
  Var /GLOBAL LOG_FILE
  Var /GLOBAL NODE_INSTALLED
  Var /GLOBAL NODE_INSTALL
  Var /GLOBAL NODE_UPGRADE
  Var /GLOBAL NODE_SHORT_VERSION
  Var /GLOBAL NODE_VERSION
  Var /GLOBAL SIGNALK_NODE_CONFIG_DIR

  Function SetGlobalVars
    LogSet on
    StrCpy $USERPROFILE $INSTDIR\signalkhome
    StrCpy $NODE_PATH '$INSTDIR\nodejs'
    StrCpy $NODE_MODULES_PATH '$INSTDIR\nodejs\node_modules'
    StrCpy $OPENSSL_PATH '$INSTDIR\openssl'
    StrCpy $OPENSSL_BIN_PATH '$INSTDIR\openssl\bin'
    StrCpy $OPENSSL_CONF '$INSTDIR\openssl\openssl.cnf'
    StrCpy $TOOLS_PATH '$INSTDIR\tools'
    StrCpy $SIGNALK_NODE_CONFIG_DIR '$USERPROFILE\.signalk'

    ${If} ${AtLeastWin10}
      StrCpy $NODE64_URL 'https://nodejs.org/dist/v18.17.1/node-v18.17.1-win-x64.zip'
      StrCpy $NODE86_URL 'https://nodejs.org/dist/v18.17.1/node-v18.17.1-win-x86.zip'
      StrCpy $NODE64_ORG_DIR 'node-v18.17.1-win-x64'
      StrCpy $NODE86_ORG_DIR 'node-v18.17.1-win-x86'
      StrCpy $NODE_VERSION 'v18.17.1'
      StrCpy $NODE_SHORT_VERSION 'v18'
    ${EndIf}
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
  Function GenToolsFiles
    StrCpy $0 "$INSTDIR"
    StrCpy $0 $0 1 ; Get drive letter
    StrCpy $INSTALL_DRIVE "$0:"

    DetailPrint "Create $TOOLS_PATH\signalk-server-cli.cmd"
    FileOpen  $9  $TOOLS_PATH\signalk-server-cli.cmd w
    FileWrite $9 '@ECHO OFF$\r$\n'
    FileWrite $9 '$INSTALL_DRIVE$\r$\n'
    FileWrite $9 'set USERPROFILE=$USERPROFILE$\r$\n'
    FileWrite $9 'set NODE_PATH=$NODE_MODULES_PATH$\r$\n'
    FileWrite $9 'set PATH=$NODE_PATH;$OPENSSL_BIN_PATH;%PATH%$\r$\n'
    FileWrite $9 'set SIGNALK_NODE_CONFIG_DIR=$SIGNALK_NODE_CONFIG_DIR$\r$\n'
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
    FileWrite $9 'prefix=$NODE_PATH$\r$\n'
    FileWrite $9 '$\r$\n'
    FileClose $9

    DetailPrint "Create $TOOLS_PATH\signalk-server-services.js"
    FileOpen  $9  $TOOLS_PATH\signalk-server-services.js w
      Push $SIGNALK_NODE_CONFIG_DIR
      Call ConvertBStoDBS 
      Pop $R0
    FileWrite $9 'process.env.SIGNALK_NODE_CONFIG_DIR = "$R0"$\r$\n'
    FileWrite $9 'process.env.SIGNALK_SERVER_IS_UPDATABLE = "1"$\r$\n'
    FileWrite $9 '//process.env.DEBUG = ""$\r$\n'
      Push $OPENSSL_BIN_PATH
      Call ConvertBStoDBS 
      Pop $R0
      Push $NODE_PATH
      Call ConvertBStoDBS 
      Pop $R1
    FileWrite $9 'process.env.Path = "$R1;$R0;" + process.env.Path$\r$\n'  
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
    FileWrite $9 'net stop "signalkservernode.exe"$\r$\n'
    FileWrite $9 'SC DELETE "signalkservernode.exe"$\r$\n'
    FileWrite $9 'if %ERRORLEVEL% neq 0 goto :ERROR$\r$\n'
    FileWrite $9 'pause$\r$\n'
    FileWrite $9 'exit /b 0$\r$\n'
    FileWrite $9 ':ERROR$\r$\n'
    FileWrite $9 'echo "An ERROR has occurred."$\r$\n'
    FileWrite $9 'pause$\r$\n'
    FileWrite $9 'exit /b 1$\r$\n'
    FileWrite $9 '$\r$\n'
    FileClose $9

    DetailPrint "Create $TOOLS_PATH\create-signalk-server-services.cmd"
    FileOpen  $9  $TOOLS_PATH\create-signalk-server-services.cmd w
    FileWrite $9 '@ECHO OFF$\r$\n'
    FileWrite $9 '$INSTALL_DRIVE$\r$\n'
    FileWrite $9 'echo Install signalk as service in progress...$\r$\n'
    FileWrite $9 'set NODE_PATH=$NODE_MODULES_PATH$\r$\n'
    FileWrite $9 'set "PATH=$NODE_PATH;%PATH%"$\r$\n'
    FileWrite $9 'cd $TOOLS_PATH$\r$\n'
    FileWrite $9 'node .\install-signalk-server-services.js$\r$\n'
    FileWrite $9 'if %ERRORLEVEL% neq 0 goto :ERROR$\r$\n'
    FileWrite $9 'exit /b 0$\r$\n'
    FileWrite $9 ':ERROR$\r$\n'
    FileWrite $9 'echo An ERROR has occurred.$\r$\n'
    FileWrite $9 'pause$\r$\n'
    FileWrite $9 'exit /b 1$\r$\n'
    FileWrite $9 '$\r$\n'
    FileClose $9

    DetailPrint "Create $TOOLS_PATH\stop-signalk-server-services.cmd"
    FileOpen  $9  $TOOLS_PATH\stop-signalk-server-services.cmd w
    FileWrite $9 '@ECHO OFF$\r$\n'
    FileWrite $9 'echo Stop Signal K service...$\r$\n'
    FileWrite $9 'net stop "signalkservernode.exe"$\r$\n'
    FileWrite $9 'if %ERRORLEVEL% neq 0 goto :ERROR$\r$\n'
    FileWrite $9 'exit /b 0$\r$\n'
    FileWrite $9 ':ERROR$\r$\n'
    FileWrite $9 'echo An ERROR has occurred.$\r$\n'
    FileWrite $9 'pause$\r$\n'
    FileWrite $9 'exit /b 1$\r$\n'
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
    FileWrite $9 'exit /b 1$\r$\n'
    FileWrite $9 ':STOP_SERVICE$\r$\n'
    FileWrite $9 'net stop "signalkservernode.exe" >nul 2>&1$\r$\n'
    FileWrite $9 'net start "signalkservernode.exe"$\r$\n'
    FileWrite $9 'if %ERRORLEVEL% neq 0 goto :ERROR_START$\r$\n'
    FileWrite $9 'exit /b 0$\r$\n'
    FileWrite $9 ':ERROR_START$\r$\n'
    FileWrite $9 'echo An ERROR has occurred.$\r$\n'
    FileWrite $9 'pause$\r$\n'
    FileWrite $9 'exit /b 1$\r$\n'
    FileWrite $9 '$\r$\n'
    FileClose $9

    DetailPrint "Create $TOOLS_PATH\npm-install-node-windows.cmd"
    StrCpy $LOG_FILE "npm-inst-node-windows.log"
    FileOpen  $9  $TOOLS_PATH\npm-install-node-windows.cmd w
    FileWrite $9 '@ECHO OFF$\r$\n'
    FileWrite $9 '$INSTALL_DRIVE$\r$\n'
    FileWrite $9 'echo Install node-windows service package in progress...$\r$\n'
    FileWrite $9 'echo Install log saved in $INSTDIR\$LOG_FILE file$\r$\n'
    FileWrite $9 'echo Please wait ...$\r$\n'
    FileWrite $9 'set USERPROFILE=$USERPROFILE$\r$\n'
    FileWrite $9 'set NODE_PATH=$NODE_MODULES_PATH$\r$\n'
    FileWrite $9 'set "Path=$NODE_PATH;%Path%"$\r$\n'
    FileWrite $9 'set OPENSSL_CONF=$OPENSSL_CONF$\r$\n'
    FileWrite $9 'cd $NODE_PATH$\r$\n'
    FileWrite $9 'echo "start: npm install -g --unsafe-perm  node-windows@1.0.0-beta.5" 1>>$INSTDIR\$LOG_FILE 2>&1$\r$\n'
    FileWrite $9 'call npm install -g --unsafe-perm  node-windows@1.0.0-beta.5 1>>$INSTDIR\$LOG_FILE 2>&1$\r$\n'
    FileWrite $9 'if %ERRORLEVEL% neq 0 goto :ERROR$\r$\n'
    FileWrite $9 'exit /b 0$\r$\n'
    FileWrite $9 ':ERROR$\r$\n'
    FileWrite $9 'echo An ERROR has occurred.$\r$\n'
    FileWrite $9 'echo See the $INSTDIR\$LOG_FILE file$\r$\n'
    FileWrite $9 'pause$\r$\n'
    FileWrite $9 'exit /b 1$\r$\n'
    FileWrite $9 '$\r$\n'
    FileClose $9

    DetailPrint "Create $TOOLS_PATH\npm-install-signalk-server.cmd"
    StrCpy $LOG_FILE "npm-inst-signalk-server.log"
    FileOpen  $9  $TOOLS_PATH\npm-install-signalk-server.cmd w
    FileWrite $9 '@ECHO OFF$\r$\n'
    FileWrite $9 '$INSTALL_DRIVE$\r$\n'
    FileWrite $9 'echo Install signalk-server package in progress...$\r$\n'
    FileWrite $9 'echo Install log saved in $INSTDIR\$LOG_FILE file$\r$\n'
    FileWrite $9 'echo Please wait this may take some time ...$\r$\n'
    FileWrite $9 'set USERPROFILE=$USERPROFILE$\r$\n'
    FileWrite $9 'set NODE_PATH=$NODE_MODULES_PATH$\r$\n'
    FileWrite $9 'set "Path=$NODE_PATH;%Path%"$\r$\n'
    FileWrite $9 'set OPENSSL_CONF=$OPENSSL_CONF$\r$\n'
    FileWrite $9 'cd $NODE_PATH$\r$\n'
    FileWrite $9 'echo "start: npm install -g --unsafe-perm  signalk-server" 1>>$INSTDIR\$LOG_FILE 2>&1$\r$\n'
    FileWrite $9 'call npm install -g --unsafe-perm  signalk-server 1>>$INSTDIR\$LOG_FILE 2>&1$\r$\n'
    FileWrite $9 'if %ERRORLEVEL% neq 0 goto :ERROR$\r$\n'
    FileWrite $9 'exit /b 0$\r$\n'
    FileWrite $9 ':ERROR$\r$\n'
    FileWrite $9 'echo An ERROR has occurred.$\r$\n'
    FileWrite $9 'echo See the $INSTDIR\$LOG_FILE file$\r$\n'
    FileWrite $9 'pause$\r$\n'
    FileWrite $9 'exit /b 1$\r$\n'
    FileWrite $9 '$\r$\n'
    FileClose $9

    DetailPrint "Create $TOOLS_PATH\generate-certificate.cmd"
    StrCpy $LOG_FILE "generate-certificate.log"
    FileOpen  $9  $TOOLS_PATH\generate-certificate.cmd w
    FileWrite $9 '@ECHO OFF$\r$\n'
    FileWrite $9 '$INSTALL_DRIVE$\r$\n'
    FileWrite $9 'echo log saved in $INSTDIR\$LOG_FILE file$\r$\n'
    FileWrite $9 'echo Check if certificate already exist$\r$\n'
    FileWrite $9 'if exist "$SIGNALK_NODE_CONFIG_DIR\ssl-cert.pem" goto :NOGENCERT$\r$\n'
    FileWrite $9 'if exist "$SIGNALK_NODE_CONFIG_DIR\ssl-key.pem" goto :NOGENCERT$\r$\n'
    FileWrite $9 'goto :GENCERT$\r$\n'
    FileWrite $9 ':NOGENCERT$\r$\n'
    FileWrite $9 'echo Certificate already exist in directory $SIGNALK_NODE_CONFIG_DIR$\r$\n'
    FileWrite $9 'echo Certificate already exist in directory $SIGNALK_NODE_CONFIG_DIR >>$INSTDIR\$LOG_FILE$\r$\n'
    FileWrite $9 'echo Delete the ssl-cert.pem and ssl-key.pem files to generate a new certificate.$\r$\n'
    FileWrite $9 'echo Delete the ssl-cert.pem and ssl-key.pem files to generate a new certificate. >>$INSTDIR\$LOG_FILE$\r$\n'
    FileWrite $9 'exit /b 0$\r$\n'
    FileWrite $9 ':GENCERT$\r$\n'
    FileWrite $9 'echo Generate certificate in progress...$\r$\n'
    FileWrite $9 'echo Generatecertificate in progress... >>$INSTDIR\$LOG_FILE$\r$\n'
    FileWrite $9 'set PATH=$NODE_PATH;$OPENSSL_BIN_PATH;%PATH%$\r$\n'
    FileWrite $9 'set "Path=$NODE_PATH;%Path%"$\r$\n'
    FileWrite $9 'set OPENSSL_CONF=$OPENSSL_CONF$\r$\n'
    FileWrite $9 'cd $SIGNALK_NODE_CONFIG_DIR\$\r$\n'
    FileWrite $9 'echo "openssl req -newkey rsa:2048 -nodes -keyout ssl-key.pem -x509 -out ssl-cert.pem -days 3650 -config $TOOLS_PATH\certificate-authority-self-signing.conf"  >>$INSTDIR\$LOG_FILE$\r$\n'
    FileWrite $9 'openssl req -newkey rsa:2048 -nodes -keyout ssl-key.pem -x509 -out ssl-cert.pem -days 3650 -config "$TOOLS_PATH\certificate-authority-self-signing.conf" 1>>$INSTDIR\$LOG_FILE 2>&1$\r$\n'
    FileWrite $9 'if %ERRORLEVEL% neq 0 goto :ERROR$\r$\n'
    FileWrite $9 'exit /b 0$\r$\n'
    FileWrite $9 ':ERROR$\r$\n'
    FileWrite $9 'echo An ERROR has occurred.$\r$\n'
    FileWrite $9 'echo See the $INSTDIR\$LOG_FILE file$\r$\n'
    FileWrite $9 'pause$\r$\n'
    FileWrite $9 'exit /b 1$\r$\n'
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
  Section "Visual C++ Runtime" SecVCruntime64
;    SectionIn RO
    LogSet on
    SetDetailsView show
    SetOutPath $INSTDIR
    File /r ..\target\wget.exe
    DetailPrint "Extract wget.exe to $INSTDIR"
    ClearErrors
    DetailPrint "Download VC_redist.x64.exe from https://aka.ms/vs/17/release/vc_redist.x64.exe"
    ExecWait '"$INSTDIR\wget.exe" "--output-document=$INSTDIR\vc_redist.x64.exe" "https://aka.ms/vs/17/release/vc_redist.x64.exe"' $0
    ${If} ${FileExists} "$INSTDIR\vc_redist.x64.exe"
      ExecWait "$INSTDIR\vc_redist.x64.exe" $0
      ClearErrors
      Delete "$INSTDIR\vc_redist.x64.exe"
      ClearErrors
    ${EndIf}
    Delete "$INSTDIR\wget.exe"
  SectionEnd

  Section "Extract nodejs" SecExtractJS
    LogSet on
    SetDetailsView show
    SetOutPath $INSTDIR
    File /r ..\target\wget.exe
    DetailPrint "Extract wget.exe to $INSTDIR"
    ClearErrors
    ${If} ${RunningX64}
      DetailPrint "Download nodejs 64-bits from $NODE64_URL"
      ExecWait '"$INSTDIR\wget.exe" "--output-document=$INSTDIR\nodejs.zip" "$NODE64_URL"' $0
    ${Else}
      DetailPrint "Download nodejs 32-bits from $NODE86_URL"
      ExecWait '"$INSTDIR\wget.exe" "--output-document=$INSTDIR\nodejs.zip" "$NODE86_URL"' $0
    ${EndIf}
    ${If} ${Errors}
      MessageBox MB_ICONSTOP|MB_OK "Download nodejs failed with code: $0"
      DetailPrint "Download nodejs failed whith code: $0"
      Quit
    ${EndIf}
    DetailPrint "Extract nodejs from $INSTDIR\nodejs.zip to $INSTDIR"
    nsisunz::Unzip "$INSTDIR\nodejs.zip" "$INSTDIR"
    Pop $0
    DetailPrint "Extract nodejs: $0"
    StrCmp $0 "success" unzipOk
    MessageBox MB_ICONSTOP|MB_OK "Extract nodejs failed"
    DetailPrint "Extract nodejs failed: $0"
    SetAutoClose false
    Quit
    unzipOk:
    StrCmp $NODE_UPGRADE '0' renamenode
    DetailPrint "Upgrade NodeJS to $NODE_VERSION in progress..."
    ${If} ${RunningX64}
      CopyFiles /SILENT $INSTDIR\$NODE64_ORG_DIR\* $INSTDIR\nodejs
    ${Else}
      CopyFiles /SILENT $INSTDIR\$NODE86_ORG_DIR\* $INSTDIR\nodejs
    ${EndIf}
    DetailPrint "Upgrade NodeJS to $NODE_VERSION completed"
    Goto endcopynode
    renamenode:
    DetailPrint "Install NodeJS $NODE_VERSION in progress..."
    ${If} ${RunningX64}
      Rename $INSTDIR\$NODE64_ORG_DIR $INSTDIR\nodejs
    ${Else}
      Rename $INSTDIR\$NODE86_ORG_DIR $INSTDIR\nodejs
    ${EndIf}
    DetailPrint "Install NodeJS $NODE_VERSION completed"
    endcopynode:
    DetailPrint "Cleaning up temporary files..."
    Delete "$INSTDIR\nodejs.zip"
    Delete "$INSTDIR\wget.exe"
    ${If} ${RunningX64}
      DetailPrint 'RMDir /r "$INSTDIR\$NODE64_ORG_DIR"'
      RMDir /r "$INSTDIR\$NODE64_ORG_DIR"
    ${Else}
      DetailPrint 'RMDir /r "$INSTDIR\$NODE86_ORG_DIR"'
      RMDir /r "$INSTDIR\$NODE86_ORG_DIR"
    ${EndIf}
    DetailPrint "Cleaning up temporary files completed"
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
    ExecWait '"$TOOLS_PATH\npm-install-signalk-server.cmd"' $0
    DetailPrint "npm install -g --unsafe-perm  signalk-server returned $0"
    ExecWait '"$TOOLS_PATH\generate-certificate.cmd"' $0
    DetailPrint "generate-certificate returned $0"
  SectionEnd

  Section "Signal K as services" SecSkService
    LogSet on
;    Call SetGlobalVars
    ExecWait '"$TOOLS_PATH\create-signalk-server-services.cmd"' $0
    DetailPrint "Install Signal K as windows services returned $0"
  SectionEnd

  SectionGroup /e "Desktop shortcut" SecShortcuts
    Section "Start service" SecStartService
      LogSet on
      DetailPrint "Create desktop shortcut 'Start Signal K Service'"
      CreateShortCut "$DESKTOP\Start Signal K Service.lnk" "$TOOLS_PATH\start-signalk-server-services.cmd" \
        "" "$TOOLS_PATH\signalk.ico" 0 SW_SHOWNORMAL \
        "" "Start Signal K Service"
    SectionEnd
    Section "Signal Web GUI" SecSignalkWebGUI
      LogSet on
      DetailPrint "Create desktop shortcut 'SignalK-GUI'"
      !insertmacro CreateInternetShortcutWithIcon "$DESKTOP\SignalK-GUI.URL" "http://localhost:3000" "$TOOLS_PATH\signalk.ico" 0
    SectionEnd

    Section "Signal K CLI" SecSignalkCli
      LogSet on
      DetailPrint "Create desktop shortcut 'Signal K CLI'"
      CreateShortCut "$DESKTOP\Signal K CLI.lnk" "cmd" \
        "/k $TOOLS_PATH\signalk-server-cli.cmd" "$TOOLS_PATH\signalk.ico" 0 SW_SHOWNORMAL \
        "" "Signal K CLI"
    SectionEnd
SectionGroupEnd

;======================================================
  !insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${SecVCruntime64}  "Install Microsoft redistributable VC++ runtime files (required for OpenSSL)"
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
  ${If} $0 == ${SecVCruntime64}
    SectionSetFlags ${SecVCruntime64} ${SF_SELECTED}
    Return
  ${EndIf}
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

Function nodejsAlertPre
  LogSet on
  SetDetailsView show
  Call SetGlobalVars
  ${If} ${FileExists} "$NODE_PATH\node.exe"
    StrCpy $NODE_INSTALL '1'
    StrCpy $NODE_UPGRADE '1'
    nsExec::ExecToStack '"$NODE_PATH\node.exe" -v'
    Pop $0 # return value/error/timeout
    Pop $1 # printed text, up to ${NSIS_MAX_STRLEN}
    StrCpy $NODE_INSTALLED $1
    DetailPrint 'nodejs detected: "$NODE_PATH\node.exe" in version: $NODE_INSTALLED'
    LogText "Return code: $0"
    ${StrContains} $0 "$NODE_SHORT_VERSION" $NODE_INSTALLED
    StrCmp $0 "" noinstall
    StrCpy $NODE_INSTALL '1'
    StrCpy $NODE_UPGRADE '1'
    Goto done
    noinstall:
    StrCpy $NODE_INSTALL '0'
    StrCpy $NODE_UPGRADE '0'
    SectionSetFlags ${SecExtractJS} ${SF_RO}
    LogText "A different major version of NodeJs is detected: $NODE_INSTALLED in $INSTDIR and cannot be updated to $NODE_VERSION"
    SetOutPath $INSTDIR
    ExecShell "open" "https://github.com/SignalK/signalk-server-windows/blob/v${INST_VERSION}/readme.md"
    System::Call "User32::SetWindowPos(i $HWNDPARENT, i -1, i 0, i 0, i 0, i 0, i 3) i." ; Keep focus
    !insertmacro MUI_HEADER_TEXT "Node JS version" "Checking the Node JS version"
    nsDialogs::Create 1018
    Pop $0
    ${If} $0 == error
      Abort
    ${EndIf}
    ${NSD_CreateLabel} 0 26u 100% 10u "A different major version of NodeJs is detected: $NODE_INSTALLED"
    Pop $0
    ${NSD_CreateLabel} 0 36u 100% 10u "in $INSTDIR"
    Pop $0
    ${NSD_CreateLabel} 0 46u 100% 10u "and cannot be updated to $NODE_VERSION."
    Pop $0
    ${NSD_CreateLabel} 0 60u 100% 10u "Please see upgrade section in readme.md page that has just opened."
    Pop $0
    ${NSD_CreateLabel} 0 74u 100% 10u "Or continue to upgrade only Signal K (not recommended)."
    Pop $0
    nsDialogs::Show
  ${Else}
    StrCpy $NODE_INSTALL '1'
    StrCpy $NODE_UPGRADE '0'
  ${EndIf}
  done:
  LogText "NODE_INSTALL: '$NODE_INSTALL' NODE_UPGRADE: '$NODE_UPGRADE'"
FunctionEnd
;======================================================
  Function .onInit
    SetOutPath $INSTDIR
    LogSet on
    SetDetailsView show
    LogText "Signal K installer version: ${INST_VERSION}"
    ${IfNot} ${AtLeastWin10}
      MessageBox MB_ICONEXCLAMATION|MB_OK "Your current version of Windows is lower than Windows 10,$\nOperating System version prior to Windows 10 are no longer supported with recent versions of Signal K server. "
      LogText "Windows version < 10 detected, installation cancelled "
      Abort
    ${EndIf}
    ${If} ${RunningX64}
      ReadRegStr $0 HKLM "SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\X64" "Major"
      ReadRegStr $1 HKLM "SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\X64" "Version"
      ${If} $0 == 14
        LogText "Visual Studio Runtime $1 already installed"
        SectionSetText ${SecVCruntime64} ""
        !insertmacro UnSelectSection ${SecVCruntime64}
      ${Else}
        LogText "Visual Studio Runtime 14 Not found, install now selected"
        SectionSetFlags ${SecVCruntime64} ${SF_SELECTED}
      ${EndIf}
    ${EndIf}
    LogSet off
  FunctionEnd
