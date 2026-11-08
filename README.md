# Rama `catalogo` · servidores del catálogo de Ace Stream

MiVisor TV convierte cada ID de Ace Stream en su descriptor preguntando a estos servidores
(`http://IP:8081/gettorrent`). Si la lista se queda vieja, los canales no encuentran pares.

- **Cuándo la lee la app:** al abrirse, como mucho cada 6 h.
- **Para aplicarla ya:** Ajustes › Motor › «Servidores del catálogo» y después «Reiniciar motor».

## Formato (`catalog-hosts.json`)

- `schema_version`: 1.
- `updated`: AAAA-MM-DD del último cambio.
- `hosts`: en orden de preferencia (el primero se prueba antes).
  - `host`: **IPv4 pública**, sin nombres de dominio.
  - `port`: normalmente 8081.
  - `note`: libre (de dónde salió).
  - `last_ok`, `fails`, `last_fail`: los escribe el verificador. La app los ignora.
  - `"enabled": false`: apuntado pero sin usar.
- Máximo 16 activos. Un fichero roto se ignora y la app sigue con la última lista buena.

## Comprobar que una IP sigue valiendo

Abrir el puerto no basta: un servidor puede responder y no resolver nada.
`tools/verificar-catalogo.sh` arranca Outpace usando **solo** ese servidor y le pide IDs reales:

```bash
OUTPACE=/ruta/outpace tools/verificar-catalogo.sh --id <ID1> --id <ID2> --id <ID3> [--actualizar] [ip:puerto …]
```

- **VALE:** ha convertido al menos uno de los IDs en su descriptor.
- **FALLA:** no ha resuelto ninguno (sale el motivo, por ejemplo `catalog connect failed`).
- **IDs de prueba:** 2 o 3 que funcionen, de canales distintos (si uno desaparece, los otros siguen sirviendo).
- **`--actualizar`:** apunta el resultado en el JSON.

`tools/comprobar-catalogo.sh` es la prueba rápida, solo de puerto, sin Outpace.

### Preparar el verificador (una vez, en Linux)

```bash
git clone https://github.com/jamezrin/outpace.git && cd outpace
git checkout --detach 7d77f410c9bde453cb5f5816ab37f5e571d6e5f0
git apply /ruta/a/esta/rama/tools/outpace-mivisor.patch
cargo build --release -p ace-engine --bin outpace     # → target/release/outpace
```

## Regla para no acumular IPs muertas

1. Una IP nueva entra **solo si da VALE**.
2. **3 comprobaciones seguidas en FALLA** (con `--actualizar` se cuenta solo): pasa a `"enabled": false` y la app deja de usarla.
3. **Más de 30 días desactivada** y sin volver a dar VALE: se borra del fichero.
4. Si vuelve a dar VALE, el verificador la reactiva solo.

## Automático (opcional)

`para-main/.github/workflows/verificar-catalogo.yml` va en la rama **main** (GitHub solo lanza los horarios desde la rama principal).

1. Cópialo a `main` en `.github/workflows/`.
2. Crea la variable del repositorio `CATALOGO_IDS` con 2 o 3 IDs separados por espacios.

Cada lunes, y a mano desde Actions:
- compila Outpace con el parche;
- verifica la rama `catalogo`;
- sube el resultado.

## Cuándo buscar IPs nuevas

- La app dice `catalog connect failed` o `catalog timeout` en Ajustes › Motor.
- Varios IDs que iban dejan de encontrar pares.
- El verificador deja menos de 2 IPs en VALE.
- Sale una versión nueva del motor oficial de Ace Stream.

Para encontrarlas, en una máquina de pruebas con el motor oficial de Ace Stream para Linux:

```bash
sudo tools/descubrir-catalogo.sh <ID_que_funcione>
```

Apunta a qué IPs se conecta por el 8081.

## Publicar un cambio a mano

```bash
git checkout catalogo
# editar catalog-hosts.json (y "updated")
python3 -m json.tool catalog-hosts.json > /dev/null
git commit -am "catalogo: …"
git push origin catalogo
```

No toca las ramas `main` (agenda), `banners` ni `providers`.
