@echo off
setlocal
echo Preparando para eliminar archivos antiguos de Google Cloud Storage...

:: Nombre del bucket de Google Storage
set "BUCKET=gs://nombrebucket"

:: Ruta del archivo de log
set "LOG_FILE=C:\delete_log.txt"

:: Capturar la fecha actual y calcular la fecha de corte (hace 30 días)
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set FECHA_ACTUAL=%%I
set "FECHA_CORTE=%FECHA_ACTUAL:~0,8%"
powershell -Command "Get-Date -Format 'yyyyMMdd' ((Get-Date).AddDays(-30))" > "%TEMP%\fecha_corte.txt"
set /p FECHA_CORTE=<"%TEMP%\fecha_corte.txt"

:: Capturar la fecha y hora de inicio
set "START_TIME=%DATE% %TIME%"

:: Crear el archivo de log
echo. > "%LOG_FILE%"
echo --- Inicio de la eliminación: %START_TIME% --- >> "%LOG_FILE%"

:: Obtener lista de archivos en el bucket con detalles de fecha
echo Obteniendo lista de archivos en el bucket...
gsutil ls -l -r "%BUCKET%/**" > "%TEMP%\bucket_files.txt" 2>> "%LOG_FILE%"
if %errorlevel% neq 0 (
    echo Error al obtener la lista de archivos del bucket. >> "%LOG_FILE%"
    exit /b 1
)

:: Eliminar archivos más antiguos que la fecha de corte
echo Verificando y eliminando archivos antiguos...
echo --- Archivos eliminados --- >> "%LOG_FILE%"
for /f "tokens=1,2,*" %%A in ('findstr /R "^[0-9][0-9]*" "%TEMP%\bucket_files.txt"') do (
    set "FILE_DATE=%%A"
    set "FILE_PATH=%%C"
    setlocal enabledelayedexpansion
    set "FILE_DATE=!FILE_DATE:~0,8!"
    if !FILE_DATE! lss %FECHA_CORTE% (
        echo Eliminando archivo: !FILE_PATH! >> "%LOG_FILE%"
        gsutil rm "!FILE_PATH!" >> "%LOG_FILE%" 2>&1
        if !errorlevel! neq 0 (
            echo Error al eliminar el archivo: !FILE_PATH! >> "%LOG_FILE%"
        ) else (
            echo Archivo eliminado correctamente: !FILE_PATH! >> "%LOG_FILE%"
        )
    )
    endlocal
)

:: Obtener lista de archivos restantes en el bucket
echo Obteniendo lista de archivos restantes en el bucket...
gsutil ls -r "%BUCKET%/**" > "%TEMP%\remaining_files.txt" 2>> "%LOG_FILE%"
if %errorlevel% neq 0 (
    echo Error al obtener la lista de archivos restantes del bucket. >> "%LOG_FILE%"
    exit /b 1
)

:: Escribir lista de archivos restantes en el log
echo --- Archivos restantes --- >> "%LOG_FILE%"
type "%TEMP%\remaining_files.txt" >> "%LOG_FILE%"

:: Capturar la fecha y hora de finalización
set "END_TIME=%DATE% %TIME%"

:: Escribir el log
echo Fecha de inicio: %START_TIME% >> "%LOG_FILE%"
echo Fecha de finalización: %END_TIME% >> "%LOG_FILE%"
echo Proceso de eliminación completado. >> "%LOG_FILE%"

echo Archivos antiguos eliminados correctamente.
echo Log generado en %LOG_FILE%.
pause
endlocal
