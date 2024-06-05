@echo off
setlocal
echo Preparando para subir archivos a Google Cloud Storage...

:: Ruta del directorio que contiene los archivos que deseas subir
set "RUTA_LOCAL=(RUTA DE CARPETA A RESPALDAR)"

:: Nombre del bucket de Google Storage
set "BUCKET=(NOMBRE DE BUKET)"

:: Ruta del archivo de log
set "LOG_FILE=C:\upload_log.txt"

:: Generar un nombre de carpeta con la fecha actual en formato YYYYMMDD
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set FECHA=%%I
set "CARPETA_FECHA=%FECHA:~0,8%"

:: Capturar la fecha y hora de inicio
set "START_TIME=%DATE% %TIME%"

:: Crear el archivo de log
echo. > "%LOG_FILE%"
echo --- Inicio de la subida: %START_TIME% --- >> "%LOG_FILE%"

:: Comando para subir los archivos con opción multithreaded
echo Subiendo archivos...
gsutil -m cp -r "%RUTA_LOCAL%\*" "%BUCKET%/%CARPETA_FECHA%/" >> "%LOG_FILE%" 2>&1

:: Verificar si la subida fue exitosa
if %errorlevel% equ 0 (
    set "STATUS=Éxito"
    echo Subida completada correctamente. >> "%LOG_FILE%"
) else (
    set "STATUS=Fallo"
    echo Error durante la subida. >> "%LOG_FILE%"
)

:: Obtener lista de archivos subidos
echo Obteniendo lista de archivos subidos...
gsutil ls -r "%BUCKET%/%CARPETA_FECHA%/**" > "%TEMP%\uploaded_files.txt" 2>> "%LOG_FILE%"
if %errorlevel% neq 0 (
    echo Error al obtener la lista de archivos subidos. >> "%LOG_FILE%"
    set "STATUS=Fallo"
)

:: Obtener lista de archivos locales
echo Obteniendo lista de archivos locales...
dir /B /S "%RUTA_LOCAL%" > "%TEMP%\local_files.txt"

:: Comparar listas de archivos
echo Verificando archivos subidos...
set "MISSING_FILES=0"
for /f "tokens=*" %%A in (%TEMP%\local_files.txt) do (
    set "LOCAL_FILE=%%A"
    set "LOCAL_FILE_RELATIVE=%%A:%RUTA_LOCAL%\=%BUCKET%/%CARPETA_FECHA%/%"
    call :CheckFile "%LOCAL_FILE_RELATIVE%"
)

:: Subrutina para comparar archivos
:CheckFile
set "FILE_TO_CHECK=%~1"
findstr /C:"%FILE_TO_CHECK%" "%TEMP%\uploaded_files.txt" >nul
if %errorlevel% neq 0 (
    echo Archivo faltante: %FILE_TO_CHECK% >> "%LOG_FILE%"
    set /a MISSING_FILES+=1
)
goto :EOF

:: Verificar resultados de la comparación
if %MISSING_FILES% equ 0 (
    echo Todos los archivos se subieron correctamente. >> "%LOG_FILE%"
) else (
    echo %MISSING_FILES% archivos faltantes. >> "%LOG_FILE%"
    set "STATUS=Fallo"
)

:: Calcular el espacio utilizado en el directorio
for /f "usebackq tokens=3" %%A in (`dir /a /s "%RUTA_LOCAL%" ^| find "bytes"`) do set "SPACE_USED=%%A"

:: Capturar la fecha y hora de finalización
set "END_TIME=%DATE% %TIME%"

:: Escribir el log
echo Fecha de subida: %START_TIME% >> "%LOG_FILE%"
echo Fecha de finalización: %END_TIME% >> "%LOG_FILE%"
echo Estado de la subida: %STATUS% >> "%LOG_FILE%"
echo Espacio utilizado: %SPACE_USED% bytes >> "%LOG_FILE%"

echo Archivos subidos correctamente.
echo Log generado en %LOG_FILE%.
pause
endlocal
