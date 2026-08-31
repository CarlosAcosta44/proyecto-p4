# Proyecto 4 (P4): Asistencia con Verificación Biométrica

Este proyecto implementa un sistema de control de asistencia para aprendices del SENA usando validación biométrica (huella/Face ID) y geocercas (GPS).

## 🚀 Tecnologías

* **Backend:** Node.js, Express, Prisma ORM, PostgreSQL (NeonDB)
* **Frontend:** Flutter, Riverpod (Gestor de Estado), Dio (Networking)
* **Seguridad:** JWT (Access & Refresh tokens en `flutter_secure_storage`), `local_auth` para biometría.

---

## 🛠️ Cómo arrancar el proyecto en Local (Modo Pruebas)

### 1. Iniciar el Backend (API)
El servidor valida las coordenadas, los horarios y procesa la autenticación.
```bash
cd api
npm install
node src/index.js # o npm run dev
```
*El servidor correrá en `http://localhost:3000` (o la IP local de tu PC).*

### 2. Iniciar la App Flutter (Celular)
Asegúrate de que tu celular esté conectado a la **misma red Wi-Fi** que la computadora, con la depuración USB activada.
```bash
cd app
flutter run
```

---

## 👥 Usuarios de Prueba

La base de datos cuenta con los siguientes usuarios pre-creados para probar la aplicación:

| Email | Contraseña | Rol | Ficha |
| :--- | :--- | :--- | :--- |
| `aprendiz@ceet.edu.co` | `ceet2025` | Aprendiz | Ficha 2977225 |
| `carlos@gmail.com` | `carlos123` | Aprendiz | Ficha 327641 |

---

## 📍 ¿Cómo funciona la Validación GPS (Geocerca)?

Cuando un usuario presiona el botón de huella para marcar su entrada o salida, la app envía sus coordenadas GPS actuales al servidor.
El servidor busca la **Ficha** a la que pertenece el usuario y calcula la distancia usando la fórmula de Haversine. Si el usuario está fuera del `radio_m` configurado, la asistencia es rechazada.

### Cómo actualizar o cambiar las coordenadas de tu Ficha
Si necesitas hacer pruebas desde tu casa o desde otra sede del SENA, puedes actualizar el centro del área permitida fácilmente.

1. Abre [Google Maps](https://www.google.com/maps).
2. Mantén presionado el punto exacto donde estás actualmente.
3. Copia las coordenadas que aparecen (ejemplo: `4.6536, -74.1013` o `4°35'45.7"N 74°06'43.5"W`).
4. Si las coordenadas están en formato **Grados, Minutos, Segundos (DMS)** (ej: `4°35'45.7"N 74°06'43.5"W`), conviértelas a decimales así:
   * **Latitud (N):** `Grados + (Minutos/60) + (Segundos/3600)`
     * Ej: `4 + (35/60) + (45.7/3600) = 4.596027`
   * **Longitud (W):** `-(Grados + (Minutos/60) + (Segundos/3600))` *(Lleva signo negativo)*
     * Ej: `-(74 + (6/60) + (43.5/3600)) = -74.112083`
5. Abre el archivo `api/src/actualizar_ficha.js` y modifica las variables `latitud`, `longitud` y `radio_m` según necesites.
6. Ejecuta el script para actualizar la base de datos:
   ```bash
   cd api
   node src/actualizar_ficha.js
   ```

---

## 📱 ¿Qué pasa si el sensor de huella de mi celular está dañado?
La aplicación es inteligente. Si detecta que tu celular tiene el sensor de huella averiado o no tienes huellas registradas, **automáticamente te pedirá el PIN o Patrón de desbloqueo** del dispositivo como método de respaldo para validar que eres tú.
