Este repositorio contiene scripts diseñados para automatizar la subida de archivos desde un directorio local a un bucket de Google Cloud Storage y para eliminar archivos antiguos del bucket, manteniendo un registro detallado de ambas operaciones.

## Descripción de los Scripts

Los scripts automatizan la gestión de archivos en Google Cloud Storage, incluyendo la subida de backups y la eliminación de archivos antiguos.

### `upload_to_gcs.bat`

Este script automatiza la subida de archivos desde un directorio local a un bucket de Google Cloud Storage, manteniendo un registro detallado de la operación.

#### Explicación del Código

1. **Preparación inicial**
   ```batch
   @echo off
   setlocal
   echo Preparando para subir archivos a Google Cloud Storage...
   ```
   - `@echo off`: Evita que los comandos se muestren en la consola mientras se ejecutan.
   - `setlocal`: Inicia un entorno local para las variables, evitando que afecten al entorno global.
   - `echo Preparando para subir archivos a Google Cloud Storage...`: Muestra un mensaje indicando el inicio del proceso.

2. **Definición de variables**
   ```batch
   set "RUTA_LOCAL=C:\TuCarpetaLocal"
   set "BUCKET=gs://NombreBucket"
   set "LOG_FILE=C:\upload_log.txt"
   ```
   - `set "RUTA_LOCAL=C:\TuCarpetaLocal"`: Define la ruta local de los archivos que deseas subir.
   - `set "BUCKET=gs://NombreBucket"`: Define el nombre del bucket de Google Storage.
   - `set "LOG_FILE=C:\upload_log.txt"`: Define la ruta del archivo de log donde se registrarán las operaciones.

3. **Generación de nombre de carpeta con la fecha actual**
   ```batch
   for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set FECHA=%%I
   set "CARPETA_FECHA=%FECHA:~0,8%"
   ```
   - Captura la fecha actual y crea un nombre de carpeta con formato `YYYYMMDD` para organizar los archivos en el bucket.

4. **Captura del tiempo de inicio y creación del archivo de log**
   ```batch
   set "START_TIME=%DATE% %TIME%"
   echo. > "%LOG_FILE%"
   echo --- Inicio de la subida: %START_TIME% --- >> "%LOG_FILE%"
   ```
   - Captura la fecha y hora de inicio del proceso y crea el archivo de log.

5. **Subida de archivos**
   ```batch
   echo Subiendo archivos...
   gsutil -m cp -r "%RUTA_LOCAL%\*" "%BUCKET%/%CARPETA_FECHA%/" >> "%LOG_FILE%" 2>&1
   ```
   - Utiliza `gsutil` con la opción multithreaded (`-m`) para subir los archivos al bucket, redirigiendo la salida y los errores al archivo de log.

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
   - Verifica si la subida fue exitosa basándose en el código de salida (`%errorlevel%`) y actualiza el estado en el log.

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
   - Obtiene las listas de archivos subidos y locales y compara ambas para verificar que todos los archivos locales fueron subidos correctamente.

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
   - La subrutina `:CheckFile` compara cada archivo local con la lista de archivos subidos y registra cualquier archivo faltante en el log.

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
   - Registra el estado final de la subida, el espacio utilizado y la fecha de finalización en el log, y muestra un mensaje de finalización.

### `delete_old_files_gcs.bat`

Este script elimina los archivos en un bucket de Google Cloud Storage que tengan más de un mes de antigüedad, según la fecha.

#### Explicación del Código

1. **Preparación inicial y configuración de variables**:
   ```batch
   @echo off
   setlocal
   echo Preparando para eliminar archivos antiguos de Google Cloud Storage...
   set "BUCKET=gs://NombreBucket"
   set "LOG_FILE=C:\delete_log.txt"
   ```
   - `@echo off`: Evita que los comandos se muestren en la consola mientras se ejecutan.
   - `setlocal`: Inicia un entorno local para las variables.
   - `echo Preparando para eliminar archivos antiguos de Google Cloud Storage...`: Muestra un mensaje indicando el inicio del proceso.
   - `set "BUCKET=gs://NombreBucket"`: Define el nombre del bucket de Google Storage.
   - `set "LOG_FILE=C:\delete_log.txt"`: Define la ruta del archivo de log.

2. **Captura de la fecha actual y cálculo de la fecha de corte (hace 30 días)**:
   ```batch
   for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set FECHA_ACTUAL=%%I
   set "FECHA_CORTE=%FECHA_ACTUAL:~0,8%"
   powershell -Command "Get-Date -Format 'yyyyMMdd' ((Get-Date).AddDays(-30))" > "%TEMP%\fecha_corte.txt"
   set /p FECHA_CORTE=<"%TEMP%\fecha_corte.txt"
   ```
   - Captura la fecha actual y calcula la fecha de corte (hace 30 días) usando PowerShell para manipular la fecha.

3. **Captura de la fecha y hora de inicio**:
   ```batch
   set "START_TIME=%DATE% %TIME%"
   echo. > "%LOG_FILE%"
   echo --- Inicio de la eliminación: %START_TIME% --- >> "%LOG_FILE%"
   ```
   - Captura la fecha y hora de inicio del proceso y crea el archivo de log.

4. **Obtención de la lista de archivos en el bucket con detalles de fecha**:
   ```batch
   echo Obteniendo lista de archivos en el bucket...
   gsutil ls -l -r "%BUCKET%/**" > "%TEMP%\bucket_files.txt" 2>> "%LOG_FILE%"
   if %errorlevel% neq 0 (
       echo Error al obtener la lista de archivos del bucket. >> "%LOG_FILE%"
       exit /b 1
   )
   ```
   - Usa `gsutil ls -l -r` para obtener una lista detallada de archivos en el bucket, incluyendo sus fechas. Si hay un error, lo registra en el log y termina el script.

5. **Eliminación de archivos más antiguos que la fecha de corte**:
   ```batch
   echo Verificando y eliminando archivos antiguos...
   echo --- Archivos eliminados --- >> "%LOG_FILE%"
   for /f "tokens=1,2,*" %%A in ('findstr /R "^[0-9][0-9]*" "%TEMP%\bucket_files.txt"') do (
       set

 "FILE_DATE=%%A"
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
   ```
   - Recorre la lista de archivos y elimina aquellos cuya fecha es anterior a la fecha de corte (hace más de 30 días). Registra cada eliminación y cualquier error en el log.

6. **Obtención de la lista de archivos restantes en el bucket**:
   ```batch
   echo Obteniendo lista de archivos restantes en el bucket...
   gsutil ls -r "%BUCKET%/**" > "%TEMP%\remaining_files.txt" 2>> "%LOG_FILE%"
   if %errorlevel% neq 0 (
       echo Error al obtener la lista de archivos restantes del bucket. >> "%LOG_FILE%"
       exit /b 1
   )
   ```
   - Usa `gsutil ls -r` para obtener una lista de los archivos que quedan en el bucket después de la eliminación y guarda la lista en un archivo temporal.

7. **Escritura de la lista de archivos restantes en el log**:
   ```batch
   echo --- Archivos restantes --- >> "%LOG_FILE%"
   type "%TEMP%\remaining_files.txt" >> "%LOG_FILE%"
   ```
   - Escribe la lista de archivos restantes en el log.

8. **Captura de la fecha y hora de finalización**:
   ```batch
   set "END_TIME=%DATE% %TIME%"
   echo Fecha de inicio: %START_TIME% >> "%LOG_FILE%"
   echo Fecha de finalización: %END_TIME% >> "%LOG_FILE%"
   echo Proceso de eliminación completado. >> "%LOG_FILE%"
   echo Archivos antiguos eliminados correctamente.
   echo Log generado en %LOG_FILE%.
   pause
   endlocal
   ```
   - Registra la fecha de inicio, la fecha de finalización y el estado final del proceso en el log. Muestra un mensaje de finalización y pausa la ejecución para que el usuario pueda ver los resultados.

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
