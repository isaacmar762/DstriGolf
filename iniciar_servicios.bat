@echo off
title DistriGolf - Iniciar Servicios
cd /d "%~dp0"

:MENU
cls
echo ============================================
echo      DISTRIGOLF - INICIAR SERVICIOS
echo ============================================
echo.
echo  1. Iniciar app Flutter (modo debug)
echo  2. Ejecutar pruebas Flutter
echo  3. Importar datos Excel a Supabase
echo  4. Ejecutar scripts de prueba Python
echo  5. Asignar zonas a vendedor (si no ve clientes)
echo  6. Construir APK de release
echo  7. Salir
echo.
set /p opcion="Seleccione una opcion (1-7): "

if "%opcion%"=="1" goto FLUTTER_RUN
if "%opcion%"=="2" goto FLUTTER_TEST
if "%opcion%"=="3" goto PYTHON_IMPORT
if "%opcion%"=="4" goto PYTHON_TEST
if "%opcion%"=="5" goto FIX_ZONAS
if "%opcion%"=="6" goto FLUTTER_BUILD
if "%opcion%"=="7" goto SALIR
goto MENU

:FLUTTER_RUN
cls
echo ============================================
echo   Iniciando app Flutter en el navegador...
echo ============================================
echo   Se abrira Chrome automaticamente al compilar.
echo   Cierre esta ventana para detener la app.
echo ============================================
cd /d "distrigolf_app"
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: Flutter no encontrado en PATH
    pause
    goto MENU
)
flutter run -d chrome
pause
goto MENU

:FLUTTER_TEST
cls
echo ============================================
echo   Ejecutando pruebas Flutter...
echo ============================================
cd /d "distrigolf_app"
flutter test
if %errorlevel% equ 0 (
    echo.
    echo Pruebas exitosas.
) else (
    echo.
    echo Algunas pruebas fallaron.
)
pause
goto MENU

:PYTHON_IMPORT
cls
echo ============================================
echo   Importando datos Excel a Supabase...
echo ============================================
cd /d "scripts"
python import_excel_to_supabase.py
if %errorlevel% equ 0 (
    echo.
    echo Importacion completada.
) else (
    echo.
    echo Error en la importacion.
)
pause
goto MENU

:PYTHON_TEST
cls
echo ============================================
echo   Ejecutando scripts de prueba Python...
echo ============================================
echo.
echo  1. Probar login
echo  2. Probar clientes
echo  3. Diagnosticar Supabase
echo  4. Volver al menu
echo.
set /p subop="Seleccione (1-4): "
cd /d "scripts"
if "%subop%"=="1" python test_login.py
if "%subop%"=="2" python test_clients.py
if "%subop%"=="3" python diagnose.py
if "%subop%"=="4" goto MENU
pause
goto PYTHON_TEST

:FIX_ZONAS
cls
echo ============================================
echo   Asignando zonas a vendedores sin acceso...
echo ============================================
cd /d "scripts"
python fix_tat_clients.py
if %errorlevel% equ 0 (
    echo.
    echo Asignacion completada.
) else (
    echo.
    echo Error en la asignacion.
)
pause
goto MENU

:FLUTTER_BUILD
cls
echo ============================================
echo   Construyendo APK de release...
echo ============================================
cd /d "distrigolf_app"
flutter build apk --release
if %errorlevel% equ 0 (
    echo.
    echo APK generado en: build\app\outputs\flutter-apk\
) else (
    echo.
    echo Error en la construccion.
)
pause
goto MENU

:SALIR
cls
echo Saliendo...
timeout /t 1 >nul
