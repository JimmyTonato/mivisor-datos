# Rama `catalogo` · servidores del catálogo de Ace Stream

MiVisor TV convierte cada ID de Ace Stream en su descriptor preguntando a estos servidores
(`GET http://IP:8081/gettorrent?...`). Si la lista se queda vieja, los canales no encuentran pares.
La app la descarga al abrirse (como mucho cada 6 h) y el motor la usa la próxima vez que arranca.

## Formato (`catalog-hosts.json`)

- `schema_version`: 1.
- `updated`: fecha del último cambio (AAAA-MM-DD). Sale en Ajustes › Motor.
- `hosts`: en orden de preferencia (el primero se prueba antes).
  - `host`: **solo IPv4 pública** (nada de nombres de dominio).
  - `port`: normalmente 8081.
  - `note`: opcional, para nosotros.
  - `"enabled": false`: lo deja apuntado sin usarlo.
- Máximo 16. Si el fichero está roto o no trae ninguno válido, la app lo ignora y sigue con la última lista buena.

## Cuándo hay que actualizarla

- **Avisos de la app:** varios IDs que antes iban dejan de encontrar pares a la vez. En Ajustes › Motor, «Último aviso del motor» dice `catalog connect failed` o `catalog timeout`.
- **Comprobación semanal:** `tools/comprobar-catalogo.sh` (abajo) dice que algún servidor ya no responde.
- **Versión nueva:** sale una versión nueva del motor oficial de Ace Stream (suele traer servidores nuevos).

## Cómo encontrar los servidores actuales

Con el motor oficial de Ace Stream para Linux en una máquina de pruebas (no en producción):

```bash
sudo tools/descubrir-catalogo.sh <ID_que_funcione>
```

Lanza la petición del ID al motor oficial y apunta a qué IPs se conecta por el puerto 8081.
Esas son las que hay que poner arriba en `hosts`. Las viejas que ya no respondan se quitan o se marcan con `"enabled": false`.

## Publicar un cambio

```bash
git checkout catalogo
# editar catalog-hosts.json (y la fecha de "updated")
python3 -m json.tool catalog-hosts.json > /dev/null   # que sea JSON válido
git commit -am "catalogo: actualiza servidores (AAAA-MM-DD)"
git push origin catalogo
```

No toca las ramas `main` (agenda), `banners` ni `providers`.
