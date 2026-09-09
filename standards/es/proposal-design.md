# Estándar de Diseño de Propuesta

Estándar canónico de diseño y entrega para toda propuesta comercial redactada
por el sector business-ops (`/ocf:proposal`, skill `proposal-writer`). Toda
propuesta DEBE entregarse en PDF con marca (y en HTML fuente), además de la
fuente Markdown, usando el logo y los datos de la empresa que emite la
propuesta.

Las reglas siguientes son concretas y comprobables (afirmaciones MUST con
valores medibles), no opiniones.

## 1. Salidas

1. Toda propuesta DEBE tener tres salidas derivadas de una única fuente de
   verdad (`proposal.md`):
   - `proposal.md` — la fuente Markdown (Mermaid permitido para gantt/pie).
   - `proposal.html` — renderización HTML autocontenida, lista para A4, con
     cabecera de marca.
   - `proposal.pdf` — PDF A4 generado desde `proposal.html` vía
     `scripts/proposal/pdf.sh` (Chrome headless, fallback LibreOffice).
2. El HTML/PDF DEBE generarse a partir de la plantilla de referencia
   `skills/business-ops/proposal-writer/templates/proposal.html` — los agentes
   adaptan el CONTENIDO, nunca reescriben el CSS desde cero.
3. El HTML/PDF DEBE incluir el logo y los datos de la empresa emisora en la
   cabecera (ver §3 Marca). Una propuesta generada sin marca DEBE ser una
   construcción "sin marca" explícita y confirmada por el usuario, nunca una
   omisión silenciosa.

## 2. Impresión (A4)

1. El tamaño de página DEBE ser A4. Los márgenes superior/laterales DEBEN ser
   14–16mm; el margen inferior DEBE ser ≥16mm (18mm en la plantilla de
   referencia) para alojar el pie con número de página.
2. La propuesta DEBE ser totalmente legible en blanco y negro: ninguna
   información puede depender solo del color. El énfasis de estado/precio viene
   del peso, tamaño y espaciado.
3. DEBE existir un bloque `@media print` limpio que elimine colores
   interactivos y mantenga el layout; los fondos DEBEN ser claros/ausentes al
   imprimir.
4. Las secciones y bloques `.proposal-section` DEBEN usar `break-inside: avoid`;
   `h2` DEBE usar `break-after: avoid` para que un título de sección nunca
   quede huérfano al final de página. Las tablas largas (esfuerzo/precio)
   PUEDEN romperse con `orphans: 3; widows: 3`.
5. El pie con número de página ES OBLIGATORIO
   (`@page { @bottom-right { content: counter(page) } }` o pie equivalente de
   Chrome) para que una propuesta impresa pueda referenciarse por página.
   Chrome renderiza los margin boxes CSS; el fallback LibreOffice NO los
   renderiza — el motor de respaldo avisa, y un PDF producido por LibreOffice
   DEBE revisarse manualmente (o usarse la variante de pie en el cuerpo).
6. Las fuentes DEBEN ser fuentes de sistema seguras para impresión
   (`Helvetica`, `Arial`, `sans-serif`; `Courier`/mono para códigos/ids). Las
   fuentes web remotas ESTÁN PROHIBIDAS — pueden no renderizarse headless.

## 3. Marca (empresa emisora)

1. Los assets de marca viven en `docs/assets/` del proyecto donde se invoca el
   flujo. Orden de resolución (DEBE):
   1. `<proyecto>/docs/assets/company.json` + `<proyecto>/docs/assets/logo.*`
      (marca del proyecto — preferida).
   2. `~/.config/opencode/assets/company.json` + `~/.config/opencode/assets/logo.*`
      (fallback global).
   3. Compat heredada: `docs/specs/<slug>/assets/logo.*` (copia local de spec
      del comportamiento antiguo de `spec-init.sh`). Nunca es la fuente primaria.
2. Esquema de `company.json` (todos los campos opcionales; NUNCA inventar
   valores — omita los campos desconocidos):
   ```json
   {
     "name": "Nombre legal o comercial de la empresa",
     "legal_name": "Razón social completa (opcional)",
     "document": "CNPJ/RIF/número de registro (opcional)",
     "contact": { "email": "…", "phone": "…", "website": "…" },
     "address": { "street": "…", "city": "…", "state": "…", "country": "…" }
   }
   ```
3. La cabecera del HTML/PDF DEBE renderizar, cuando exista: la imagen del logo,
   el `name` de la empresa y una línea de contacto compacta
   (email/phone/website). Los campos ausentes del `company.json` se omiten —
   nunca se sustituyen por placeholders ni datos inventados.
4. El `proposal.html` DEBE ser autocontenido: referencie el logo como data URI
   o cópielo junto a `proposal.html` y referencie la ruta relativa
   (`./logo.png`). NUNCA use una URL absoluta `file://` o remota para el logo —
   la URL `file://` se filtraría en la impresión y una URL remota puede no
   cargarse headless.
5. El atributo `<html lang>` DEBE corresponder al locale resuelto de la
   propuesta (no a un idioma fijo), para que los lectores de pantalla y las
   herramientas de traducción se comporten correctamente.
6. `scripts/proposal/brand-resolve.sh` DEBE usarse para resolver la
   disponibilidad de marca antes de redactar. Resuelve POR TIER COMPLETO
   (proyecto → global → legacy), nunca componiendo assets de tiers distintos
   (un logo de proyecto nunca se empareja con un `company.json` global).
   Contrato de salida:
   - `0` — marca encontrada (logo y/o `company.json`).
   - `1` — sin marca en ningún lugar (ni proyecto ni global).
   El script imprime las rutas absolutas resueltas (`logo=…`,
   `company_json=…`) y el tier activo (`source=…`).
7. Cuando NO exista marca, el agente DEBE preguntar al usuario (nunca asumir):
   - (a) generar SIN marca, o
   - (b) aportar datos/logo ahora (guardados en `<proyecto>/docs/assets/`),
   - (c) crear primero el estándar de marca en el proyecto (ver §5).
   Solo tras la respuesta del usuario el agente genera. Esto es un gate rígido.
8. Reglas de renderizado de la cabecera:
   - Con logo y `company.json` presentes: logo a la izquierda, nombre +
     contacto de la empresa a la derecha.
   - Con solo uno presente (logo-only / company-only): el bloque único se
     ancla a la izquierda y se elimina el lado vacío — nunca un layout
     `space-between` medio vacío.
   - En una construcción sin marca, el elemento `<header class="brand-header">`
     DEBE eliminarse por completo (una cabecera vacía deja una regla suelta en
     el documento del cliente).

## 4. Estructura de contenido de la propuesta

El orden canónico de secciones de la skill `proposal-writer` se conserva en el
HTML/PDF (§ Estructura). Todo valor de precio DEBE derivar de matemática
visible (tarifa × horas, descuentos, total) exactamente como en la fuente
Markdown — nunca un número redondeado sin derivación.

## 5. Crear un estándar de marca en un proyecto

Cuando el usuario elija (c) en la §3.7, el agente DEBE, en orden:

1. Preguntar o reunir la identidad pública de la empresa emisora (URL, archivo
   de logo o press kit) y datos factuales.
2. Ejecutar la skill `brand-to-design-md` contra la identidad pública para
   producir `<proyecto>/docs/assets/DESIGN.md` (tokens de diseño: colores,
   tipografía, espaciado, uso del logo).
3. Guardar los datos de la empresa como `<proyecto>/docs/assets/company.json`
   siguiendo el esquema de la §3.2 y el logo resuelto como
   `<proyecto>/docs/assets/logo.<ext>` (svg/png preferido).
4. Confirmar que los assets son legibles por `scripts/proposal/brand-resolve.sh`
   (exit 0) antes de continuar con la propuesta.

## 6. Lista de conformidad (ejecutar antes de generar el PDF)

- [ ] `proposal.md`, `proposal.html`, `proposal.pdf` existen y coinciden en
      contenido/valores
- [ ] El HTML parte de la plantilla de referencia (nunca CSS desde cero)
- [ ] `@page { size: A4; … }` presente; márgenes superior/laterales 14–16mm;
      inferior ≥16mm
- [ ] La cabecera muestra logo + nombre de la empresa + contacto (cuando
      exista en company.json); las construcciones de asset único y sin marca
      siguen la §3.8 (sin lado vacío/regla suelta)
- [ ] Ningún dato de empresa inventado; los campos ausentes del `company.json`
      se omiten
- [ ] Logo referenciado como data URI o copia relativa — sin logo `file://`/remoto
- [ ] Sin fuentes/redes remotas; legible en blanco y negro
- [ ] Pie con número de página presente (Chrome ≥131; salida LibreOffice
      revisada manualmente — el motor avisa)
- [ ] `<html lang>` corresponde al locale resuelto de la propuesta
- [ ] Ningún token de plantilla sin renderizar: `grep -E '\{\{' proposal.html` → 0
- [ ] Resolución de marca vía `brand-resolve.sh`; la construcción sin marca es
      explícita y confirmada por el usuario
- [ ] Matemática de precio visible e idéntica en `.md`/`.html`/`.pdf`
- [ ] Prosa correcta en el locale; identificadores de código/nombres de agentes
      ausentes del documento orientado al cliente
- [ ] `proposal.pdf` no vacío y válido (Chrome o LibreOffice con éxito)

## 7. Locale

Los originales de `proposal-design.md` viven en inglés en `standards/`. Las
versiones localizadas existen en `standards/pt/proposal-design.md` y
`standards/es/proposal-design.md`. Nunca edite los originales en inglés desde
las traducciones; la versión en inglés es la fuente de la verdad.
