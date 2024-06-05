Claro, aquí tienes la descripción completa del repositorio, incluyendo la sección sobre cómo automatizar el script desde las Tareas Programadas de Windows:

---

# GCS-FileUploader

Este repositorio contiene un script diseñado para automatizar la subida de archivos desde un directorio local a un bucket de Google Cloud Storage, manteniendo un registro detallado de la operación.

## Descripción del Script

El script facilita la gestión de backups automáticos y la verificación de la correcta subida de los archivos. A continuación, se detalla el funcionamiento de cada parte del código:

### Código del Script

```batch
@echo off
setlocal
echo Preparando para subir archivos a Google Cloud Storage...

:: Ruta del directorio que contiene los archivos que deseas subir
set "RUTA_LOCAL=(RUTA A RESPALDAR "C:/tucarpeta")"

:: Nombre del bucket de Google Storage
set "BUCKET=(Nombre del buket "gs://tubuket")"

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

### Explicación del Código

1. **Preparación inicial**
   ```batch
   @echo off
   setlocal
   echo Preparando para subir archivos a Google Cloud Storage...
   ```
   - `@echo off`: Evita que los comandos se muestren en la consola mientras se ejecutan.
   - `setlocal`: Inicia un entorno local para las variables, evitando que afecten al entorno global.

2. **Definición de variables**
   ```batch
   set "RUTA_LOCAL=(RUTA A RESPALDAR "C:/tucarpeta")"
   set "BUCKET=(Nombre del buket "gs://tubuket")"
   set "LOG_FILE=C:\upload_log.txt"
   ```
   - Define la ruta local de los archivos, el bucket de Google Storage y la ruta del archivo de log.

3. **Generación de nombre de carpeta con la fecha actual**
   ```batch
   for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set FECHA=%%I
   set "CARPETA_FECHA=%FECHA:~0,8%"
   ```
   - Obtiene la fecha actual y crea un nombre de carpeta con formato `YYYYMMDD`.

4. **Captura del tiempo de inicio y creación del archivo de log**
   ```batch
   set "START_TIME=%DATE% %TIME%"
   echo. > "%LOG_FILE%"
   echo --- Inicio de la subida: %START_TIME% --- >> "%LOG_FILE%"
   ```
   - Registra la fecha y hora de inicio y crea el archivo de log.

5. **Subida de archivos**
   ```batch
   echo Subiendo archivos...
   gsutil -m cp -r "%RUTA_LOCAL%\*" "%BUCKET%/%CARPETA_FECHA%/" >> "%LOG_FILE%" 2>&1
   ```
   - Utiliza `gsutil` para subir los archivos al bucket, con opción multithreaded (`-m`).

6. **Verificación del éxito de la subida**
   ```batch
   if %errorlevel% equ 0 (
       set "STATUS=Éxito"
       echo Subida completada correctamente. >> "%LOG_FILE%"
   ) else (
       set "STATUS=Fallo"
       echo Error durante la subida. >> "%LOG_FILE%"
   )
   ```
   - Verifica si la subida fue exitosa y registra el estado en el log.

7. **Obtención y comparación de listas de archivos**
   ```batch
   echo Obteniendo lista de archivos subidos...
   gsutil ls -r "%BUCKET%/%CARPETA_FECHA%/**" > "%TEMP%\uploaded_files.txt" 2>> "%LOG_FILE%"
   echo Obteniendo lista de archivos locales...
   dir /B /S "%RUTA_LOCAL%" > "%TEMP%\local_files.txt"
   echo Verificando archivos subidos...
   set "MISSING_FILES=0"
   for /f "tokens=*" %%A in (%TEMP%\local_files.txt) do (
       set "LOCAL_FILE=%%A"
       set "LOCAL_FILE_RELATIVE=%%A:%RUTA_LOCAL%\=%BUCKET%/%CARPETA_FECHA%/%"
       call :CheckFile "%LOCAL_FILE_RELATIVE%"
   )
   ```
   - Obtiene y compara las listas de archivos locales y subidos, verificando si hay archivos faltantes.

8. **Subrutina para comparación de archivos**
   ```batch
   :CheckFile
   set "FILE_TO_CHECK=%~1"
   findstr /C:"%FILE_TO_CHECK%" "%TEMP%\uploaded_files.txt" >nul
   if %errorlevel% neq 0 (
       echo Archivo faltante: %FILE_TO_CHECK% >> "%LOG_FILE%"
       set /a MISSING_FILES+=1
   )
   goto :EOF
   ```
   - Compara cada archivo local con la lista de archivos subidos y registra cualquier archivo faltante.

9. **Registro de resultados y finalización**
   ```batch
   if %MISSING_FILES% equ 0 (
       echo Todos los archivos se subieron correctamente. >> "%LOG_FILE%"
   ) else (
       echo %MISSING_FILES% archivos faltantes. >> "%LOG_FILE%"
       set "STATUS=Fallo"
   )
   for /f "usebackq tokens=3" %%A in (`dir /a /s "%RUTA_LOCAL%" ^| find "bytes"`) do set "SPACE_USED=%%A"
   set "END_TIME=%DATE% %TIME%"
   echo Fecha de subida: %START_TIME% >> "%LOG_FILE%"
   echo Fecha de finalización: %END_TIME% >> "%LOG_FILE%"
   echo Estado de la subida: %STATUS% >> "%LOG_FILE%"
   echo Espacio utilizado: %SPACE_USED% bytes >> "%LOG_FILE%"
   echo Archivos subidos correctamente.
   echo Log generado en %LOG_FILE%.
   pause
   endlocal
   ```
   - Registra el estado final de la subida, el espacio utilizado y genera el log final.

### Uso del Script

Para automatizar la ejecución de este script utilizando las Tareas Programadas de Windows, sigue estos pasos:

1. **Abrir el Programador de

 Tareas**:
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

Ahora, el script se ejecutará automáticamente según la programación establecida, subiendo los archivos al bucket de Google Cloud Storage y generando un log con los detalles de cada operación.

## Contribuciones

Las contribuciones son bienvenidas. Si tienes ideas, mejoras o nuevos scripts que podrían beneficiar a otros, no dudes en hacer un fork del repositorio y enviar un pull request.

## Licencia

Este proyecto está licenciado bajo la [MIT License](LICENSE).
