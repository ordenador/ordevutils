@ECHO OFF

REM Obtener fecha y hora
for /f "delims=" %%a in ('date/t') do @set mydate=%%a 
for /f "delims=" %%a in ('time/t') do @set mytime=%%a 
set fvar=%mydate%%mytime% 

REM Comentario mediante argumento o dejar en blanco para mensaje por defecto
SET COMENTARIO="%*"
if %COMENTARIO%=="" (set COMENTARIO="Commit automatico (pushwindows.bat): %fvar%")

REM Comandos git
"%ProgramFiles(x86)%\Git\bin\git" add .
"%ProgramFiles(x86)%\Git\bin\git" commit -a -m %COMENTARIO%
REM push para Heroku
"%ProgramFiles(x86)%\Git\bin\git" push heroku master
REM push para GitHub ":ordenador/web"
"%ProgramFiles(x86)%\Git\bin\git" push git@github.com:ordenador/web.git
