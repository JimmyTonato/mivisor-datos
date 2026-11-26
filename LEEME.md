# MiVisor · Biblioteca publicada

Rama generada automáticamente por MiVisor Gold. Tiene un solo commit que se reemplaza en cada publicación.

* `manifest.json`: revisión, fecha, `cambios_desde`, parámetros del cifrado y totales. Sin cifrar.
* `biblioteca.enc`: la Biblioteca completa (solo IDs en uso), cifrada. Los IDs de cada canal van en orden; los que llevan
  `"lista": "reserva"` funcionan pero no son los mejores: van al final, como opciones extra si los primeros fallan.
* `cambios.enc`: los cambios de las revisiones posteriores a `cambios_desde`, cifrado.

Cifrado: `MVB1` + sal (16 bytes) + nonce (12 bytes) + AES-256-GCM; clave = PBKDF2-HMAC-SHA256(contraseña, sal,
iteraciones del manifest, 32 bytes). Lo descifrado es JSON Lines comprimido con gzip (esquema `mivisor.biblioteca/2`).
