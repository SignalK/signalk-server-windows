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
  !define INST_VERSION "0.1.0"
  BrandingText "Signal K from http://signalk.org/"
  Name "Signal K installer ${INST_VERSION}"
  OutFile "..\output\signalk-server-setup.exe"
  InstallDir "c:\signalk"
  RequestExecutionLevel user ; user | admin 
  !define MUI_ICON "..\src\tools\signalk.ico"
;======================================================
;Pages
  !insertmacro MUI_PAGE_WELCOME
  !insertmacro MUI_PAGE_DIRECTORY
;  !insertmacro MUI_PAGE_LICENSE "${NSISDIR}\Docs\Modern UI\License.txt"
  !insertmacro MUI_PAGE_COMPONENTS
  !insertmacro MUI_PAGE_INSTFILES
  !insertmacro MUI_PAGE_FINISH

;  !insertmacro MUI_UNPAGE_WELCOME
;  !insertmacro MUI_UNPAGE_CONFIRM
;  !insertmacro MUI_UNPAGE_INSTFILES
;  !insertmacro MUI_UNPAGE_FINISH
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
  Var /GLOBAL TOOLS_PATH
  Var /GLOBAL INSTALL_DRIVE

  Function SetGlobalVars
    StrCpy $USERPROFILE $INSTDIR\signalkhome
    StrCpy $NODE_PATH '$INSTDIR\nodejs'
    StrCpy $NODE_MODULES_PATH '$INSTDIR\nodejs\node_modules'
    StrCpy $OPENSSL_PATH '$INSTDIR\openssl'
    StrCpy $OPENSSL_BIN_PATH '$INSTDIR\openssl\bin'
    StrCpy $TOOLS_PATH '$INSTDIR\tools'
  FunctionEnd
;======================================================
  Function .onInit
    SetDetailsView show
    Call SetGlobalVars
;    System::Call 'Kernel32::SetEnvironmentVariableA(t, t) i("USERPROFILE", "$USERPROFILE").r2'
;    DetailPrint "Set USERPROFILE=$USERPROFILE"

;    System::Call 'Kernel32::SetEnvironmentVariableA(t, t) i("NODE_PATH", "$NODE_PATH").r0'
;    DetailPrint "Set NODE_PATH=$NODE_PATH"

  FunctionEnd
;======================================================
  Function GenToolsFiles
    StrCpy $0 "$INSTDIR"
    StrCpy $0 $0 1 ; Get drive letter
    StrCpy $INSTALL_DRIVE "$0:"

    DetailPrint "create $TOOLS_PATH\signalk-server-cli.cmd"
    FileOpen  $9  $TOOLS_PATH\signalk-server-cli.cmd w
    FileWrite $9 '@ECHO OFF$\r$\n'
    FileWrite $9 '$INSTALL_DRIVE$\r$\n'
    FileWrite $9 'set USERPROFILE=$USERPROFILE$\r$\n'
    FileWrite $9 'set NODE_PATH=$NODE_PATH$\r$\n'
    FileWrite $9 'set PATH=%NODE_PATH%;$OPENSSL_BIN_PATH;%~dp0;%PATH%$\r$\n'
    FileWrite $9 'set SIGNALK_NODE_CONFIG_DIR=%USERPROFILE%\.signalk$\r$\n'
    FileWrite $9 'set SIGNALK_SERVER_IS_UPDATABLE=1$\r$\n'
    FileWrite $9 'cd %USERPROFILE%$\r$\n'
    FileWrite $9 'node.exe -p -e "$\'Your environment has been set up for using Node.js $\' + process.versions.node + $\' ($\' + process.arch + $\')$\'"%$\r$\n'
    FileWrite $9 'echo Welcome in signal K$\r$\n'
    FileWrite $9 'echo "enter signalk-server.cmd to start server"$\r$\n'
    FileClose $9

    DetailPrint "create $USERPROFILE\.npmrc"
    FileOpen  $9  $USERPROFILE\.npmrc w
    FileWrite $9 'cache=$USERPROFILE\npm-cache$\r$\n'
    FileWrite $9 'tmp=$USERPROFILE\tmp$\r$\n'
    FileWrite $9 'prefix=$NODE_PATH$\r$\n'
    FileClose $9

    DetailPrint "create $TOOLS_PATH\signalk-server-services.js"
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
    FileClose $9

    DetailPrint "create $TOOLS_PATH\install-signalk-server-services.js"
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
    FileWrite $9 '{name: "USERPROFILE",value: process.env.USERPROFILE}'
    FileWrite $9 ']'
    FileWrite $9 '});$\r$\n'
    FileWrite $9 'svc.on("install",function(){$\r$\n'
    FileWrite $9 '//  svc.start();$\r$\n'
    FileWrite $9 '  elevate($\'sc config "signalkservernode.exe" Start=Demand$\');$\r$\n'
    FileWrite $9 '});$\r$\n'
    FileWrite $9 'svc.install();$\r$\n'
    FileClose $9

    DetailPrint "create $TOOLS_PATH\remove-signalk-server-services.cmd"
    FileOpen  $9  $TOOLS_PATH\remove-signalk-server-services.cmd w
    FileWrite $9 'SC DELETE "signalkservernode.exe"$\r$\n'
    FileWrite $9 'pause$\r$\n'
    FileWrite $9 '$\r$\n'
    FileClose $9

    DetailPrint "create $TOOLS_PATH\create-signalk-server-services.cmd"
    FileOpen  $9  $TOOLS_PATH\create-signalk-server-services.cmd w
    FileWrite $9 '@ECHO OFF$\r$\n'
    FileWrite $9 '$INSTALL_DRIVE$\r$\n'
    FileWrite $9 'echo "Install signalk as service in progress..."$\r$\n'
    FileWrite $9 'set NODE_PATH=$NODE_PATH$\r$\n'
    FileWrite $9 'set "PATH=%NODE_PATH%;%~dp0;%PATH%"$\r$\n'
    FileWrite $9 'cd $TOOLS_PATH$\r$\n'
    FileWrite $9 'node .\install-signalk-server-services.js$\r$\n'
    FileWrite $9 'pause$\r$\n'
    FileWrite $9 '$\r$\n'
    FileClose $9

    DetailPrint "create $TOOLS_PATH\stop-signalk-server-services.cmd"
    FileOpen  $9  $TOOLS_PATH\stop-signalk-server-services.cmd w
    FileWrite $9 '@ECHO OFF$\r$\n'
    FileWrite $9 'echo "Stop Signal K service..."$\r$\n'
    FileWrite $9 'net stop "signalkservernode.exe"$\r$\n'
    FileWrite $9 'pause$\r$\n'
    FileClose $9

    DetailPrint "create $TOOLS_PATH\start-signalk-server-services.cmd"
    FileOpen  $9  $TOOLS_PATH\start-signalk-server-services.cmd w
    FileWrite $9 '@ECHO OFF$\r$\n'
    FileWrite $9 'echo "Start Signal K service..."$\r$\n'
    FileWrite $9 'net start "signalkservernode.exe"$\r$\n'
    FileWrite $9 'pause$\r$\n'
    FileClose $9

    DetailPrint "create $TOOLS_PATH\npm-install-node-windows.cmd"
    FileOpen  $9  $TOOLS_PATH\npm-install-node-windows.cmd w
    FileWrite $9 '@ECHO OFF$\r$\n'
    FileWrite $9 '$INSTALL_DRIVE$\r$\n'
    FileWrite $9 'echo "Install node-windows package in progress..."$\r$\n'
    FileWrite $9 'set USERPROFILE=$USERPROFILE$\r$\n'
    FileWrite $9 'set NODE_PATH=$NODE_PATH$\r$\n'
    FileWrite $9 'set "Path=%NODE_PATH%;%~dp0;%Path%"$\r$\n'
    FileWrite $9 'cd $NODE_PATH$\r$\n'
    FileWrite $9 'npm install -g --unsafe-perm  node-windows$\r$\n'
    FileWrite $9 'pause$\r$\n'
    FileClose $9

    DetailPrint "create $TOOLS_PATH\npm-install-signalk-server.cmd"
    FileOpen  $9  $TOOLS_PATH\npm-install-signalk-server.cmd w
    FileWrite $9 '@ECHO OFF$\r$\n'
    FileWrite $9 '$INSTALL_DRIVE$\r$\n'
    FileWrite $9 'echo "Install signalk-server package in progress..."$\r$\n'
    FileWrite $9 'set USERPROFILE=$USERPROFILE$\r$\n'
    FileWrite $9 'set NODE_PATH=$NODE_PATH$\r$\n'
    FileWrite $9 'set "Path=%NODE_PATH%;%~dp0;%Path%"$\r$\n'
    FileWrite $9 'cd $NODE_PATH$\r$\n'
    FileWrite $9 'npm install -g --unsafe-perm  signalk-server$\r$\n'
    FileWrite $9 'pause$\r$\n'
    FileClose $9

    DetailPrint "create $TOOLS_PATH\SignalK-CLI.lnk"
    CreateShortCut "$TOOLS_PATH\SignalK-CLI.lnk" "cmd" \
      "/k $TOOLS_PATH\signalk-server-cli.cmd" "$TOOLS_PATH\signalk.ico" 0 SW_SHOWNORMAL \
      "" "Signal K CLI"
  FunctionEnd
;======================================================
  Section "Extract nodejs" SecExtractJS
;    SectionIn RO
    SetOutPath $NODE_PATH
    ${If} ${RunningX64}
      DetailPrint "extract nodejs 64-bits"
      File /r "..\src\node-v10.19.0-win-x64\*.*"
    ${Else}
      DetailPrint "extract nodejs 32-bits"
      File /r "..\src\node-v10.19.0-win-x86\*.*"
    ${EndIf}  
  SectionEnd

  Section "Extract openssl" SecExtractSSL
;    SectionIn RO
    SetOutPath $OPENSSL_PATH
    ${If} ${RunningX64}
      DetailPrint "extract openssl 64-bits"
      File /r "..\src\openssl-x64\*.*"
    ${Else}
      DetailPrint "extract openssl 32-bits"
      File /r "..\src\openssl-x86\*.*"
    ${EndIf}  
  SectionEnd

  Section "Generate tools" SecTools
;    SectionIn RO
    SetOutPath $INSTDIR\signalkhome
    File /nonfatal /r "..\src\signalkhome\*.*"
    SetOutPath $INSTDIR\tools
    File /nonfatal /r "..\src\tools\*.*"
    Call GenToolsFiles
  SectionEnd

  Section "install signalk-server" SecSkInstall
    ExecWait '"$TOOLS_PATH\npm-install-signalk-server.cmd"' $0
    DetailPrint "npm install -g --unsafe-perm  signalk-server returned $0"
  SectionEnd

  Section /o "Signal K as services" SecSkService
    ExecWait '"$TOOLS_PATH\npm-install-node-windows.cmd"' $0
    DetailPrint "npm install -g --unsafe-perm  node-windows returned $0"

    ExecWait '"$TOOLS_PATH\create-signalk-server-services.cmd"' $0
    DetailPrint "Install Signal K as windows services returned $0"
  SectionEnd

  SectionGroup /e "Desktop shortcut" SecShortcuts
    Section /o "Start service" SecStartService
      CreateShortCut "$DESKTOP\Start Signal K Service.lnk" "$TOOLS_PATH\start-signalk-server-services.cmd" \
        "" "$TOOLS_PATH\signalk.ico" 0 SW_SHOWNORMAL \
        "" "Start Signal K Service"
    SectionEnd
    Section /o "Signal K CLI" SecSignalkCli
      CreateShortCut "$DESKTOP\Signal K CLI.lnk" "cmd" \
        "/k $TOOLS_PATH\signalk-server-cli.cmd" "$TOOLS_PATH\signalk.ico" 0 SW_SHOWNORMAL \
        "" "Signal K CLI"
    SectionEnd
SectionGroupEnd

;======================================================
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SecExtractJS}    "Extract node js binary and library"
  !insertmacro MUI_DESCRIPTION_TEXT ${SecExtractSSL}   "Extract OpenSSL binary and library"
  !insertmacro MUI_DESCRIPTION_TEXT ${SecTools}        "Generate startup scripts, home dir and tools for running Signal K on Windows OS"
  !insertmacro MUI_DESCRIPTION_TEXT ${SecSkInstall}    "Install the lastest version of Signal K server node from npm repository (Internet access required)"
  !insertmacro MUI_DESCRIPTION_TEXT ${SecSkService}    "Install Signal as Windows service (Internet access required)"
  !insertmacro MUI_DESCRIPTION_TEXT ${SecShortcuts}    "Create desktop shortcut"
  !insertmacro MUI_DESCRIPTION_TEXT ${SecStartService} "Desktop shortcut to start Signal K service"
  !insertmacro MUI_DESCRIPTION_TEXT ${SecSignalkCli}   "Desktop shortcut to open nodejs console for run Signal K server"
!insertmacro MUI_FUNCTION_DESCRIPTION_END
;======================================================
