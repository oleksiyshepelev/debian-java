# Instalación de Java 21 Temurin en Debian

Este directorio contiene el script `install-java.sh`, el cual automatiza la instalación de Java 21 (Temurin) y algunos paquetes básicos en sistemas Debian y derivados.

## ¿Qué hace el script?

- Actualiza los repositorios del sistema.
- Instala utilidades y herramientas básicas recomendadas para administración.
- Añade el repositorio oficial de Adoptium para Java Temurin.
- Instala Java 21 Temurin (`temurin-21-jdk`).
- Configura la variable de entorno `JAVA_HOME` para todos los usuarios.
- Realiza limpieza de paquetes y verifica la instalación.

## Requisitos

- Debian 11/12 o derivado (Ubuntu, etc.)
- Acceso root (el script debe ejecutarse como root)
- Conexión a Internet

## Uso

1. Da permisos de ejecución al script:

   ```bash
   chmod +x install-java.sh
   ```

2. Ejecútalo como root:

   ```bash
   sudo ./install-java.sh
   ```

## Notas

- Si la variable `JAVA_HOME` no aparece en tu entorno tras la instalación, ejecuta:

  ```bash
  source /etc/profile.d/java.sh
  ```

  o reinicia la sesión.
- El script instala también herramientas útiles como `curl`, `git`, `vim`, `ufw`, `fail2ban`, entre otros.
- El repositorio de Adoptium se configura automáticamente según la versión de tu sistema.

## Verificación

Al finalizar, el script mostrará la versión de Java instalada y la ruta de `JAVA_HOME`.

## Autor

- Basado en scripts de automatización para servidores Debian.
