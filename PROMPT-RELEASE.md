# Petición para el equipo de release · servidores del catálogo

> Copia todo lo de abajo, rellena las IPs y los IDs y mándalo.

---

Hola. Necesito actualizar los servidores del catálogo de Ace Stream que usa MiVisor TV. Están en el repositorio `mivisor-datos`, rama **`catalogo`**, fichero `catalog-hosts.json`. Instrucciones completas en el `README.md` de esa rama.

**IPs nuevas que he encontrado** (una por línea, `ip:puerto`):

```
<IP_1>:8081
<IP_2>:8081
```

**IDs de prueba que me funcionan ahora** (2 o 3, de canales distintos):

```
<ID_1>
<ID_2>
<ID_3>
```

**Qué tenéis que hacer:**

1. Clonar `mivisor-datos` y pasar a la rama `catalogo`. Tener a mano el verificador. Si no está preparado, seguir «Preparar el verificador» del README: Outpace en el commit indicado, con `tools/outpace-mivisor.patch` aplicado.
2. Verificar cada IP nueva **por separado**:
   `OUTPACE=/ruta/outpace tools/verificar-catalogo.sh --id <ID_1> --id <ID_2> --id <ID_3> <IP_1>:8081 <IP_2>:8081`
   - Las que den **VALE** se añaden **al principio** de `hosts`, con `"port": 8081` y en `note` la fecha y de dónde salen.
   - Las que den **FALLA** **no** se añaden. Decidme cuáles y el motivo que sale.
   - Si una ya estaba en la lista, no se duplica: se mueve arriba si da VALE.
3. Verificar **toda** la lista y apuntar el resultado:
   `OUTPACE=/ruta/outpace tools/verificar-catalogo.sh --id <ID_1> --id <ID_2> --id <ID_3> --actualizar`
4. Limpiar según la regla del README:
   - 3 fallos seguidos → `"enabled": false` (lo hace el script);
   - desactivada hace más de 30 días → borrarla;
   - máximo 16 activas;
   - tienen que quedar **al menos 2 en VALE**. Si no, avisadme antes de publicar.
5. Poner la fecha de hoy en `"updated"` y comprobar que el JSON es válido: `python3 -m json.tool catalog-hosts.json`.
6. Commit en `catalogo` («catalogo: añade <IPs> y limpia caídas (AAAA-MM-DD)») y push. **No tocar** las ramas `main`, `banners` ni `providers`.
7. Mandadme la salida del verificador (la tabla VALE/FALLA) y el JSON final.

Gracias.
