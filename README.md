Este repositorio contiene scripts diseñados para automatizar la subida de archivos desde un directorio local a un bucket de Google Cloud Storage y para eliminar archivos antiguos del bucket, manteniendo un registro detallado de ambas operaciones.

## Descripción de los Scripts

Los scripts facilitan la gestión de backups automáticos y la eliminación de archivos antiguos en Google Cloud Storage.

### `upload_to_gcs.bat`

Este script automatiza la subida de archivos desde un directorio local a un bucket de Google Cloud Storage, manteniendo un registro detallado de la operación.

#### Código del Script

```batch
@echo off
setlocal
echo Preparando para subir archivos a Google Cloud Storage...

:: Ruta del directorio que contiene los archivos que deseas subir
set "RUTA_LOCAL=C:\TuCarpeta"

:: Nombre del bucket de Google Storage
set "BUCKET=gs://nombrebucket"

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
```

### `delete_old_files_gcs.bat`

Este script elimina los archivos en un bucket de Google Cloud Storage que tengan más de un mes de antigüedad, según la fecha.

#### Código del Script

```batch
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
```

## Uso de los Scripts

### Subida de Archivos

Para subir archivos, ejecuta `upload_to_gcs.bat`. Configura las variables `RUTA_LOCAL` y `BUCKET` según tus necesidades.

### Eliminación de Archivos Antiguos

Para eliminar archivos antiguos, ejecuta `delete_old_files_gcs.bat`. Configura la variable `BUCKET` según tus necesidades.

## Automatización con Tareas Programadas de Windows

### Configuración de una Tarea Programada

1. **Abrir el Programador de Tareas**:
   - Busca "Programador de tareas" en el menú de inicio y ábrelo.

2. **Crear una Tarea Básica**:
   - Haz clic en "Crear tarea básica..." en el panel derecho.

3. **Configurar la Tarea**:
   - **Nombre**: Ingresa un nombre descriptivo para la tarea (por ejemplo, "Backup Google Cloud Storage").
   - **Descripción**: Opcionalmente, ingresa una descripción (por ejemplo, "Sube archivos automáticamente a Google Cloud Storage cada día").

4. **Configurar el Desencadenador**:
   - Elige cuándo deseas que se ejecute la tarea (por ejemplo, diariamente).
   - Configura la hora y la frecuencia según tus necesidades.

5. **Configurar la Acción**:
   - Elige "Iniciar un programa".
   - En "Programa o script", busca el archivo del script batch (`.bat`) que contiene el código proporcionado.

6. **Finalizar la Configuración**:
   - Revisa la configuración y haz clic en "Finalizar".

Ahora, los scripts se ejecutarán automáticamente según la programación establecida, subiendo los archivos al bucket de Google Cloud Storage y eliminando los archivos antiguos, mientras generan un log con los detalles de cada operación.

## Contribuciones

Las contribuciones son bienvenidas. Si tienes ideas, mejoras o nuevos scripts que podrían beneficiar a otros, no dudes en hacer un fork del repositorio y enviar un pull request.

## Licencia

Este proyecto está licenciado bajo la [MIT License](LICENSE).
