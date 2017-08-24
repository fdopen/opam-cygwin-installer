!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "nsDialogs.nsh"
!include "winmessages.nsh"
!include "FileFunc.nsh"

Unicode true

!addplugindir StdUtils/Plugins/Release_Unicode
!addincludedir StdUtils/Include
!include "StdUtils.nsh"

!if "${FDOPENBITS}" == "64"
!define CYGWIN_URL "https://cygwin.com/setup-x86_64.exe"
!else
!define CYGWIN_URL "https://cygwin.com/setup-x86.exe"
!endif

!define CYGWIN_PACKAGES_COMMON "bc,dash,diffutils,dos2unix,file,findutils,gawk,make,mintty,ncurses,patch,rlwrap,sed,tar,unzip,wget,which,xz,zsh,rsync,git,perl,m4,curl,wget,time"
!if "${FDOPENBITS}" == "64"
!define CYGWIN_PACKAGES "${CYGWIN_PACKAGES_COMMON},mingw64-x86_64-gcc-core"
!else
!define CYGWIN_PACKAGES "${CYGWIN_PACKAGES_COMMON},mingw64-i686-gcc-core"
!endif

!define ADMIN_WARNING "You are running the installer as administrator (elevated \
mode). This is not recommended! $\n$\n\
It is better to run this installer as normal user, so you can later install additional mingw-w64 related packages as normal user with 'opam depext ...' (e.g. pcre,gmp,zarith, or gtk2). Just \
abort the setup and restart the installer without choosing \
'Run as Administrator'. $\n$\n\
Continue anyway?"

!define MUI_WELCOMEPAGE_TITLE "Welcome to fdopen's OCaml Installer for Windows."

!define MUI_WELCOMEPAGE_TEXT "This wizard will install OCaml and related tools \
(flexdll, opam, aspcud) - and it will create a customized cygwin environment.$\n$\n\
Cygwin is a Unix-like environment and command-line interface for Microsoft Windows. \
Cygwin based programs are necessary for opam, ocamlbuild, and in order to compile OCaml sources to native code.$\n$\n\
This wizard will later start cygwin's setup tool. You only have to select a mirror near you, everything else is already configured for you. Just follow the dialogs!"

!define MUI_LICENSEPAGE_TEXT_TOP "There are different licenses for each included package."

!define MUI_LICENSEPAGE_TEXT_BOTTOM "Read and accept the terms of the license agreement to proceed with the installation."

!define MUI_FINISHPAGE_TITLE "Cygwin and Opam are now installed!"
!define MUI_FINISHPAGE_TEXT "Start a cygwin shell to install additional libraries ..."

; MUI Settings / Icons
!define MUI_ICON "orange\Icons\orange-install.ico"
!define MUI_UNICON "orange\Icons\orange-uninstall.ico"
 
; MUI Settings / Header
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_RIGHT
!define MUI_HEADERIMAGE_BITMAP "orange\Header\orange-r.bmp"
!define MUI_HEADERIMAGE_UNBITMAP "orange\Header\orange-uninstall-r.bmp"
 
; MUI Settings / Wizard
!define MUI_WELCOMEFINISHPAGE_BITMAP "orange\Wizard\orange.bmp"
!define MUI_UNWELCOMEFINISHPAGE_BITMAP "orange\Wizard\orange-uninstall.bmp"

!define MUI_BUTTONTEXT_FINISH "&Finish"

Name "OCaml${FDOPENBITS}"
OutFile "OCaml${FDOPENBITS}.exe"
InstallDir "C:\OCaml${FDOPENBITS}"
RequestExecutionLevel user
DirText "Please choose a directory to which you'd like to install this application. The name of the directory should contain only alphanumeric ASCII-letters and no whitespace characters!"

SetCompressor /SOLID lzma
SetCompressorDictSize 64
SetDatablockOptimize ON

BrandingText " "
; The name of the installer

Var CygwinCreated
Var AdminType
Var AdminAndUac

Function CheckForSpaces
 Exch $R0
 Push $R1
 Push $R2
 Push $R3
 StrCpy $R1 -1
 StrCpy $R3 $R0
 StrCpy $R0 0
 loop:
   StrCpy $R2 $R3 1 $R1
   IntOp $R1 $R1 - 1
   StrCmp $R2 "" done
   StrCmp $R2 " " 0 loop
   IntOp $R0 $R0 + 1
 Goto loop
 done:
 Pop $R3
 Pop $R2
 Pop $R1
 Exch $R0
FunctionEnd

Function .onInit
 Strcpy $AdminAndUac "false"
 StrCpy $CygwinCreated "unknown"
 UserInfo::GetAccountType
 pop $0

 ${If} $0 != "admin" ;Require admin rights on NT4+
         ; MessageBox mb_iconstop "Administrator rights required!"
         ; SetErrorLevel 740 ;ERROR_ELEVATION_REQUIRED
         ; Quit
         StrCpy $AdminType "no_admin"
 ${Else}
    StrCpy $AdminType "admin"
 ${EndIf}

 ${If} "$AdminType" == "admin"
   ClearErrors
   ReadRegDWORD $0 HKLM Software\Microsoft\Windows\CurrentVersion\Policies\System EnableLUA
   IfErrors fun_end
   IntCmpU $0 1 +1 fun_end fun_end

   ClearErrors
   ReadRegDWORD $0 HKLM Software\Microsoft\Windows\CurrentVersion\Policies\System ConsentPromptBehaviorAdmin
   IfErrors fun_end
   IntCmpU $0 0 fun_end +1 +1

   Strcpy $AdminAndUac "true"
   MessageBox MB_YESNO|MB_ICONQUESTION "${ADMIN_WARNING}" IDYES fun_end
   Abort
 ${Endif}
  fun_end:
FunctionEnd


Function CheckDirectory
 Push $INSTDIR
 Call CheckForSpaces
 Pop $R0

 StrCmp $R0 0 no_spaces

 MessageBox MB_OK "The installation directory contains a space character. This is \
     is not supported.$\n\
     Please choose another directory!"
 Abort

  no_spaces:
  StrCpy $CygwinCreated "created"
  IfFileExists "$INSTDIR" check_empty 0

  ClearErrors
  CreateDirectory "$INSTDIR"
  IfErrors retry
  # Delete it, so cygwin's setup will create it again with it's own access rights
  Rmdir "$INSTDIR"
  goto end

  retry:
    MessageBox MB_OK "I can't create the installation directory.$\nPlease choose a location where you have write access to."
    Abort

  check_empty:
    ${DirState} "$INSTDIR" $R0
    ${If} $R0 == 0
      StrCpy $CygwinCreated "empty"
      goto end
    ${Endif}
    StrCpy $CygwinCreated "non_empty"
    MessageBox MB_YESNO|MB_ICONQUESTION "$INSTDIR already exists. If you continue, files may be overwritten. Continue anyway?" IDYES +2
    Abort

    ClearErrors
    CreateDirectory "$INSTDIR\xyzd"
    IfErrors retry2
    RMDir "$INSTDIR\xyzd"
    goto end

  retry2:
   MessageBox MB_OK "Please choose a location where you have write access to."
   Abort

  end:
FunctionEnd

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "license.txt"
!define MUI_PAGE_CUSTOMFUNCTION_LEAVE "CheckDirectory"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES

;--------------------------------

Section "Choose a path" ChoosePath
SetOutPath $INSTDIR
SectionEnd

; Page Custom createShortCuts createShortCutsLeave

var MYTEMPDIR
Section "Cygwin" InstallCygwin
  GetTempFileName $0
  Delete $0
  CreateDirectory $0
  StrCpy $MYTEMPDIR $0
  NSISdl::download /TIMEOUT=30000 ${CYGWIN_URL} "$MYTEMPDIR\cygwin-dl.exe"
  Pop $0
  StrCmp $0 "success" ok
    MessageBox MB_OK "Couldn't download cygwin's setup.exe: $0"
    SetErrors
    DetailPrint "$0"
  ok:
  ClearErrors

  SetDetailsPrint both
  DetailPrint "Cygwin is being installed. Just follow the instructions!"
  SetDetailsPrint listonly

  ${If} "$AdminType" == "admin"
    ExecWait "$MYTEMPDIR\cygwin-dl.exe --quiet-mode --root $INSTDIR \
        --local-package-dir=$TEMP\cygwin\ \
        -g --wait --packages=${CYGWIN_PACKAGES} \
        >NUL 2>&1" $0
    ;;--no-admin
    IfErrors 0 no_error
  ${Else}
    ExecWait "$MYTEMPDIR\cygwin-dl.exe --quiet-mode --root $INSTDIR \
        --no-admin --local-package-dir=$TEMP\cygwin\ \
        -g --wait --packages=${CYGWIN_PACKAGES} \
	>NUL 2>&1" $0
    IfErrors 0 no_error
  ${Endif}

  RMDir /r $MYTEMPDIR
  DetailPrint "Cygwin installation failed"  
  MessageBox MB_OK "The installation of cygwin failed. OCaml/opam can't be installed. $\n\
      Try the manual installation."
  Abort "Installation Failed"

  no_error:
  RMDir /r $MYTEMPDIR
  IfFileExists "$INSTDIR\bin\bash.exe"  +1 setup_aborted
  IfFileExists "$INSTDIR\bin\bc.exe"  +1 setup_aborted
  IfFileExists "$INSTDIR\bin\bzip2.exe"  +1 setup_aborted
  IfFileExists "$INSTDIR\bin\cat.exe"  +1 setup_aborted
  IfFileExists "$INSTDIR\bin\chmod.exe"  +1 setup_aborted
  IfFileExists "$INSTDIR\bin\chown.exe"  +1 setup_aborted
  IfFileExists "$INSTDIR\bin\cmp.exe"  +1 setup_aborted
  IfFileExists "$INSTDIR\bin\cp.exe"  +1 setup_aborted
  IfFileExists "$INSTDIR\bin\curl.exe"  +1 setup_aborted
  IfFileExists "$INSTDIR\bin\cygpath.exe"  +1 setup_aborted
  IfFileExists "$INSTDIR\bin\dash.exe"  +1 setup_aborted
  IfFileExists "$INSTDIR\bin\diff.exe"  +1 setup_aborted
  IfFileExists "$INSTDIR\bin\dirname.exe"  +1 setup_aborted
  IfFileExists "$INSTDIR\bin\dos2unix.exe"  +1 setup_aborted
  IfFileExists "$INSTDIR\bin\file.exe"  +1 setup_aborted
  IfFileExists "$INSTDIR\bin\find.exe"  +1 setup_aborted
  IfFileExists "$INSTDIR\bin\gawk.exe"  +1 setup_aborted
  IfFileExists "$INSTDIR\bin\git.exe"  +1 setup_aborted
  IfFileExists "$INSTDIR\bin\grep.exe"  +1 setup_aborted
  IfFileExists "$INSTDIR\bin\gzip.exe"  +1 setup_aborted
  IfFileExists "$INSTDIR\bin\head.exe"  +1 setup_aborted
  IfFileExists "$INSTDIR\bin\m4.exe"  +1 setup_aborted
  IfFileExists "$INSTDIR\bin\make.exe"  +1 setup_aborted
  IfFileExists "$INSTDIR\bin\mintty.exe"  +1 setup_aborted
  IfFileExists "$INSTDIR\bin\mkdir.exe"  +1 setup_aborted
  IfFileExists "$INSTDIR\bin\mount.exe" +1 setup_aborted
  IfFileExists "$INSTDIR\bin\mv.exe"  +1 setup_aborted
  IfFileExists "$INSTDIR\bin\patch.exe" +1 setup_aborted
  IfFileExists "$INSTDIR\bin\perl.exe" +1 setup_aborted
  IfFileExists "$INSTDIR\bin\printf.exe"  +1 setup_aborted
  IfFileExists "$INSTDIR\bin\readlink.exe"  +1 setup_aborted
  IfFileExists "$INSTDIR\bin\rlwrap.exe"  +1 setup_aborted
  IfFileExists "$INSTDIR\bin\rsync.exe"  +1 setup_aborted
  IfFileExists "$INSTDIR\bin\sed.exe"  +1 setup_aborted
  IfFileExists "$INSTDIR\bin\sort.exe"  +1 setup_aborted
  IfFileExists "$INSTDIR\bin\tar.exe"  +1 setup_aborted
  IfFileExists "$INSTDIR\bin\unzip.exe"  +1 setup_aborted
  IfFileExists "$INSTDIR\bin\wget.exe"  +1 setup_aborted
  IfFileExists "$INSTDIR\bin\which.exe"  +1 setup_aborted
  IfFileExists "$INSTDIR\bin\xz.exe"  +1 setup_aborted
  ; the exit status doesn't indicate, if the user aborted the installation.
  ; But zsh get's installed last, at least at the moment. It's a good indicator, if
  ; the installation has been finished regularly.
  IfFileExists "$INSTDIR\bin\zsh.exe"  +1 setup_aborted
!if "${FDOPENBITS}" == "64"
  IfFileExists "$INSTDIR\bin\x86_64-w64-mingw32-gcc.exe" endp setup_aborted
!else
  IfFileExists "$INSTDIR\bin\i686-w64-mingw32-gcc.exe" endp setup_aborted
!endif
  goto endp

  setup_aborted:
    DetailPrint "Cygwin installation incomplete!"
    MessageBox MB_OK "The installation of cygwin is incomplete. OCaml/opam can't be installed. $\n\
        Try the manual installation."
    Abort "Installation Aborted"

 endp:
SectionEnd ; end the section

Section "Opam" InstallOpam
  SetDetailsPrint both
  DetailPrint "Testing cygwin ..."
  SetDetailsPrint listonly
  nsExec::ExecToLog '"$INSTDIR\bin\dash.exe" -lc "echo test"'
  Pop $R1
  ${If} $R1 != "0"
    goto error
  ${Endif}

  RMDir /r "$INSTDIR\tmp\OCaml${FDOPENBITS}"

  SetOutPath "$INSTDIR\tmp"
  DetailPrint "Extracting packages ..."
  SetDetailsPrint listonly
  File /r "OCaml${FDOPENBITS}"

  SetDetailsPrint both
  DetailPrint "Installing opam, flexdll and aspcud  ..."
  SetDetailsPrint listonly
  nsExec::ExecToLog '"$INSTDIR\bin\dash.exe" -l /tmp/OCaml${FDOPENBITS}/install.sh'
  Pop $R1
  ${If} $R1 != "0"
    goto error
  ${Endif}
  SetDetailsPrint both
  DetailPrint "Creating a customized passwd file ..."
  SetDetailsPrint listonly
  nsExec::ExecToLog '"$INSTDIR\bin\bash.exe" --login /tmp/OCaml${FDOPENBITS}/mkpasswd/mmkpasswd.sh'
  Pop $R1
  ${If} $R1 != "0"
    goto error
  ${Endif}

  ${If} "$AdminAndUac" != "true"
    SetDetailsPrint both
    DetailPrint "Installing the OCaml compiler  ..."
    SetDetailsPrint listonly
    nsExec::ExecToLog '"$INSTDIR\bin\bash.exe" --login /tmp/OCaml${FDOPENBITS}/ocaml${FDOPENBITS}.sh'
    Pop $R1
    ${If} $R1 == "4"
      goto error2
    ${ElseIf} $R1 != "0"
      goto error
    ${Endif}
  ${Else}
    SetDetailsPrint both
    DetailPrint "Installing the default compiler - please don't close the new window!"
    SetDetailsPrint listonly
    ${StdUtils.ExecShellAsUser} $0 '$INSTDIR\bin\mintty.exe' "open" '-h always -t "Don$\'t close this window until the installation is finished" -e $INSTDIR\bin\bash.exe -l /tmp/OCaml${FDOPENBITS}/ocaml${FDOPENBITS}.sh'
    DetailPrint "Result: $0"
  ${Endif}

  goto end

  error:
    DetailPrint "opam/OCaml installation failed"
    MessageBox MB_OK "There was a problem installing OCaml. A cygwin command failed. $\n\
        Try the manual installation."
    Abort "installation failed"
    goto end
  error2:
    DetailPrint "cygwin installation incomplete"
    MessageBox MB_OK "There was a problem installing cygwin. At least one cygwin tool is not installed properly. $\n\
        Try the manual installation."
    Abort "installation failed"
  end:
SectionEnd

!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_LANGUAGE "English"
