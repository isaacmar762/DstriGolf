# Paso a Paso: Publicar APK de DistriGolf para pruebas

## Opcion 1: Rapida (APK local + Google Drive)

### 1. Generar el APK
Ejecuta el `iniciar_servicios.bat` y selecciona la opcion **6 (Construir APK de release)**, o ejecuta directamente:

```
cd distrigolf_app
flutter build apk --release
```

### 2. Ubicar el APK generado
El APK se genera en:
```
distrigolf_app\build\app\outputs\flutter-apk\app-release.apk
```

### 3. Subir a Google Drive
1. Entra a https://drive.google.com
2. Sube el archivo `app-release.apk`
3. Haz clic derecho sobre el archivo subido
4. Selecciona **Compartir > General > Cualquier persona con el enlace**
5. Cambia el permiso a **Lector**
6. Copia el enlace

### 4. Descargar e instalar en el movil
1. Abre el enlace de Google Drive en el navegador del movil
2. Descarga el APK
3. Android puede pedirte activar **"Instalar apps de origenes desconocidos"**
4. Acepta e instala

---

## Opcion 2: Profesional (GitHub + Actions + Releases)
Recomendada para tener control de versiones y builds automaticos.

### 1. Crear cuenta en GitHub
1. Entra a https://github.com/signup
2. Crea una cuenta gratis con tu correo
3. Confirma el correo electronico

### 2. Crear repositorio y subir el codigo
1. En GitHub, haz clic en **"+" > "New repository"**
2. Nombre: `DistriGolf` (o el que quieras)
3. Deja publico y sin marcar nada mas
4. Clic en **"Create repository"**
5. Te mostrara comandos. En tu PC, abre PowerShell en la carpeta del proyecto y ejecuta:

```powershell
git init
git add .
git commit -m "Primer commit - DistriGolf"
git branch -M main
git remote add origin https://github.com/TU_USUARIO/DistriGolf.git
git push -u origin main
```

> Si no tienes Git instalado: https://git-scm.com/download/win

### 3. Agregar el workflow de GitHub Actions
Crea la carpeta y archivo:

`.github/workflows/build_apk.yml`

```
E:\IsaacMartinez\2026\DistriGolf\distrigolf_app\.github\workflows\build_apk.yml
```

Pega este contenido:

```yaml
name: Build APK

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: distrigolf_app

    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          channel: stable

      - run: flutter pub get

      - run: flutter build apk --release

      - uses: actions/upload-artifact@v4
        with:
          name: app-release-apk
          path: distrigolf_app/build/app/outputs/flutter-apk/app-release.apk
```

### 4. Subir el workflow a GitHub
```powershell
git add .
git commit -m "Agrega workflow de build APK"
git push
```

Esto activara el build automatico. Ve a la pestana **Actions** de tu repositorio para ver el progreso.

### 5. Descargar el APK desde GitHub
Cuando el workflow termine (unos 5-10 min):
1. Ve a tu repositorio en GitHub
2. Clic en **Actions** > clic en el workflow completado
3. Baja hasta **Artifacts**
4. Descarga `app-release-apk.zip`
5. Extrae el zip: dentro esta `app-release.apk`
6. Pasalo a tu movil (USB, Google Drive, WhatsApp, etc.)

### 6. Subir APK como Release (opcional pero recomendado)
Cada vez que quieras publicar una version para descargar facil:

Agrega esto al final del archivo `build_apk.yml` (dentro de `jobs.build.steps`):

```yaml
      - name: Create Release
        uses: softprops/action-gh-release@v2
        if: startsWith(github.ref, 'refs/tags/')
        with:
          files: distrigolf_app/build/app/outputs/flutter-apk/app-release.apk
```

Luego, cuando quieras publicar una version:
1. Ve a tu repositorio > **Releases** > **Create a new release**
2. Ponle un tag como `v1.0.0`
3. El workflow se activara y subira el APK como adjunto a la Release
4. Compartes el link de la Release para que cualquiera descargue

---

## Opcion 3: Hosting web gratis (Netlify)
Para tener una pagina web desde donde descargar el APK.

### 1. Crear carpeta web
Crea una carpeta `web_host` en el proyecto con un archivo `index.html`:

```html
<!DOCTYPE html>
<html>
<head>
  <title>DistriGolf - Descargar APK</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    body { font-family: Arial, sans-serif; text-align: center; padding: 40px; background: #1a1a2e; color: white; }
    a { display: inline-block; padding: 15px 30px; background: #4CAF50; color: white; text-decoration: none; border-radius: 8px; font-size: 18px; margin-top: 20px; }
    .paso { background: #16213e; padding: 15px; border-radius: 8px; margin: 15px 0; }
  </style>
</head>
<body>
  <h1>DistriGolf</h1>
  <p>App de preventa para vendedores</p>
  <a href="app-release.apk">Descargar APK</a>
  <div class="paso">
    <h3>Instrucciones:</h3>
    <p>1. Descarga el APK</p>
    <p>2. Abrelo en tu celular</p>
    <p>3. Permite instalar de origenes desconocidos</p>
    <p>4. Listo!</p>
  </div>
</body>
</html>
```

### 2. Subir a Netlify
1. Entra a https://app.netlify.com (registro gratis con Google o GitHub)
2. Arrastra la carpeta `web_host` al area de "drag and drop"
3. Netlify te dara una URL como `https://nombre-aleatorio.netlify.app`
4. Copia el APK dentro de `web_host/app-release.apk` y vuelve a arrastrar

O mejor: conecta con GitHub:
1. En Netlify, clic en **"Add new site" > "Import an existing project"**
2. Conecta con GitHub y selecciona tu repositorio `DistriGolf`
3. Configura:
   - **Base directory:** `web_host`
   - **Build command:** (dejar vacio)
   - **Publish directory:** `web_host`
4. Clic en **"Deploy site"**

### 3. Actualizar APK cuando haya cambios
Cada vez que construyas un nuevo APK:
1. Copia `app-release.apk` a la carpeta `web_host`
2. Haz push a GitHub (si conectaste Netlify con GitHub, se actualiza solo)
3. O vuelve a arrastrar la carpeta a Netlify

---

## Resumen de URLs que obtendras

| Servicio | URL | Proposito |
|---|---|---|
| Google Drive | Link compartido | Descargar APK directo |
| GitHub Actions | github.com/TU_USUARIO/DistriGolf/actions | Build automatico |
| Netlify | nombre.netlify.app | Pagina web con descarga |

Cualquier duda me avisas!
