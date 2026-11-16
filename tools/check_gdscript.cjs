/**
 * Statischer GDScript-Checker für BWL Slayer.
 *
 * Der Godot-Editor ist in jeder CI verfügbar, aber nicht zwingend lokal.
 * Dieser Checker fängt die häufigsten Syntax- und Strukturfehler ab, damit
 * Fehler schon vor dem CI-Lauf sichtbar werden.
 *
 * Prüft:
 *   - Tabulator/Einrückungs-Mischungen
 *   - unausgeglichene Klammern
 *   - nicht geschlossene Strings
 *   - fehlende `class_name`-Deklarationen für referenzierte Klassen
 *   - doppelte `class_name`-Deklarationen
 *   - Autoload-Referenzen gegen project.godot prüfen
 *   - Dateien, die von class_name abhängen, aber nicht existieren
 *
 * Aufruf:  node tools/check_gdscript.cjs
 */

const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const godotRoot = path.join(root, 'godot');

let errors = 0;
let warnings = 0;

function fail(file, line, message) {
  errors++;
  console.log(`ERROR ${path.relative(root, file)}:${line}  ${message}`);
}

function warn(file, line, message) {
  warnings++;
  console.log(`WARN  ${path.relative(root, file)}:${line}  ${message}`);
}

/** Alle .gd-Dateien rekursiv sammeln. */
function collect(dir, out = []) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (entry.name === '.godot' || entry.name === 'build') continue;
      collect(full, out);
    } else if (entry.name.endsWith('.gd')) {
      out.push(full);
    }
  }
  return out;
}

const files = collect(godotRoot);

/* ------------------------------------------------------------------
 * 0. Autoloads aus project.godot lesen (vor der Typprüfung nötig)
 * ------------------------------------------------------------------ */
const projectText = fs.readFileSync(path.join(godotRoot, 'project.godot'), 'utf8');
const AUTOLOADS = new Set();
const autoloadSection = projectText.match(/\[autoload\]([\s\S]*?)\n\[/);
if (autoloadSection) {
  for (const line of autoloadSection[1].split('\n')) {
    const m = line.match(/^([A-Za-z_][A-Za-z0-9_]*)\s*=/);
    if (m) AUTOLOADS.add(m[1]);
  }
}


/* ------------------------------------------------------------------
 * 1. Strukturprüfungen je Datei
 * ------------------------------------------------------------------ */
const declaredClasses = new Map(); // class_name -> Datei
const classMethods = new Map();  // class_name -> Set(method names)

for (const file of files) {
  const lines = fs.readFileSync(file, 'utf8').split('\n');
  const source = lines.join('\n');

  // class_name (muss in Zeile 1 oder 2 stehen)
  const classMatch = source.match(/^\s*class_name\s+([A-Za-z_][A-Za-z0-9_]*)/m);
  if (classMatch) {
    const name = classMatch[1];
    if (declaredClasses.has(name)) {
      fail(file, 1, `class_name "${name}" ist bereits in ${path.relative(root, declaredClasses.get(name))} deklariert`);
    } else {
      declaredClasses.set(name, file);
    }
    // Ein class_name, der einem Autoload-Singleton entspricht, verhindert
    // den Projektstart: "Class \"X\" hides an autoload singleton".
    if (AUTOLOADS.has(name)) {
      fail(file, 1,
        `class_name "${name}" kollidiert mit dem Autoload-Singleton "${name}" – ` +
        'ein Autoload-Skript darf kein gleichnamiges class_name tragen');
    }
  }

  // Methoden je Klasse sammeln (für die Aufrufprüfung in Schritt 2b)
  {
    const ownClass = source.match(/^\s*class_name\s+([A-Za-z_][A-Za-z0-9_]*)/m);
    const methodNames = new Set();
    for (const m of source.matchAll(/^\s*(?:static\s+)?func\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(/gm)) {
      methodNames.add(m[1]);
    }
    for (const m of source.matchAll(/^\s*(?:const|var)\s+([A-Za-z_][A-Za-z0-9_]*)\s*[=:]/gm)) {
      methodNames.add(m[1]);
      methodNames.add(`prop:${m[1]}`);
    }
    // @export var zaehler: int = 0
    for (const m of source.matchAll(/^\s*@export\s+(?:var\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*[=:]/gm)) {
      methodNames.add(m[1]);
      methodNames.add(`prop:${m[1]}`);
    }
    const target = ownClass ? ownClass[1] : null;
    if (target) {
      if (!classMethods.has(target)) classMethods.set(target, new Set());
      for (const m of methodNames) classMethods.get(target).add(m);
    }
    // Für Dateien ohne class_name (Autoloads) den Dateinamen als Schlüssel
    const base = path.basename(file, '.gd');
    if (!target && !classMethods.has(base)) classMethods.set(base, methodNames);
    else if (!target) {
      for (const m of methodNames) classMethods.get(base).add(m);
    }
  }

  // Einrückung: keine Mischung aus Tabulator und Spaces
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (!line.trim()) continue;
    if (/^\s*\t/.test(line) && /^\t* +/.test(line.replace(/\t/g, ''))) {
      // Tabulator und Spaces gemischt
      fail(file, i + 1, 'Mischung aus Tabulator und Leerzeichen in der Einrückung');
    }
  }

  // Klammern平衡 (ohne Strings/Kommentare)
  const stripped = stripCode(source);
  const balance = { '(': 0, '[': 0, '{': 0 };
  const pairs = { ')': '(', ']': '[', '}': '{' };
  for (const ch of stripped) {
    if (ch in balance) balance[ch]++;
    else if (ch in pairs) balance[pairs[ch]]--;
  }
  for (const [open, count] of Object.entries(balance)) {
    if (count !== 0) {
      fail(file, 1, `Unausgeglichene Klammer "${open}" (Differenz ${count})`);
    }
  }

  // Nicht geschlossene Strings (grobe Heuristik: ungerade Anzahl unescaped ")
  const quotes = (stripped.match(/(^|[^\\])"/g) || []).length;
  if (quotes % 2 !== 0) {
    warn(file, 1, 'Ungerade Anzahl Anführungszeichen – möglicherweise nicht geschlossener String');
  }
}

/** Entfernt Kommentare und String-Literale für die Klammerprüfung. */
function stripCode(source) {
  let out = '';
  let inString = false;
  let inComment = false;
  for (let i = 0; i < source.length; i++) {
    const ch = source[i];
    const next = source[i + 1];
    if (inComment) {
      if (ch === '\n') { inComment = false; out += ch; }
      continue;
    }
    if (inString) {
      if (ch === '\\') { i++; continue; }
      if (ch === '"') { inString = false; continue; }
      continue;
    }
    if (ch === '"') { inString = true; continue; }
    if (ch === '#') { inComment = true; continue; }
    out += ch;
  }
  return out;
}

/* ------------------------------------------------------------------
 * 2. Referenzprüfung: referenzierte Klassen müssen existieren
 * ------------------------------------------------------------------ */
const KNOWN_BUILTINS = new Set([
  'GDScript',
  'Vector2', 'Vector2i', 'Vector3', 'Vector3i', 'Vector4', 'Rect2', 'Rect2i',
  'Color', 'String', 'StringName', 'Node', 'Node2D', 'Node3D', 'Control',
  'CanvasItem', 'RefCounted', 'Resource', 'Object', 'SceneTree', 'Viewport',
  'SubViewport', 'SubViewportContainer', 'Camera3D', 'Camera2D', 'MeshInstance3D',
  'Mesh', 'BoxMesh', 'TorusMesh', 'StandardMaterial3D', 'BaseMaterial3D',
  'DirectionalLight3D', 'WorldEnvironment', 'Environment', 'Label', 'Label3D',
  'Button', 'Panel', 'PanelContainer', 'VBoxContainer', 'HBoxContainer',
  'BoxContainer', 'ScrollContainer', 'LineEdit', 'OptionButton', 'HSeparator',
  'ColorRect', 'Control', 'StyleBoxFlat', 'Theme', 'Font', 'Array', 'Dictionary',
  'PackedStringArray', 'PackedStringArray', 'PackedFloat32Array', 'PackedInt32Array',
  'Input', 'InputEvent', 'Time', 'OS', 'FileAccess', 'DirAccess', 'JSON',
  'GridContainer', 'HSlider', 'VSlider', 'SpinBox', 'CheckBox', 'CheckButton',
  'RichTextLabel', 'TextureRect', 'TextureButton', 'ProgressBar', 'TabContainer',
  'ItemList', 'Tree', 'PopupMenu', 'PopupPanel', 'MarginContainer', 'AspectRatioContainer',
  'CenterContainer', 'ScrollBar', 'Range', 'LabeledSeparator', 'LinkButton',
  'RandomNumberGenerator', 'ProjectSettings', 'Engine', 'MeshInstance3D',
  'PlaneMesh', 'CylinderMesh', 'SphereMesh', 'QuadMesh', 'CapsuleMesh',
  'PrimitiveMesh', 'ImmediateMesh', 'SurfaceTool', 'Texture2D', 'Image',
  'WeakRef', 'Signal', 'Callable', 'Variant', 'bool', 'int', 'float', 'String',
  // Eingabe- und Tastaturklassen (Godot 4)
  'InputEventKey', 'InputEventMouse', 'InputEventAction', 'InputMap',
  'Key', 'KeyModifierMask',
]);

for (const file of files) {
  const source = fs.readFileSync(file, 'utf8');
  // Nur echte Codezeilen betrachten (Kommentare und Strings entfernen)
  const code = stripCode(source);
  // Typisierungen der Form "var x: KlassName" und "-> KlassName"
  const typeRefs = [
    ...code.matchAll(/:\s*([A-Z][A-Za-z0-9_]*)\b/g),
    ...code.matchAll(/->\s*([A-Z][A-Za-z0-9_]*)\b/g),
  ];
  for (const match of typeRefs) {
    const name = match[1];
    if (KNOWN_BUILTINS.has(name)) continue;
    if (declaredClasses.has(name)) continue;
    // Autoloads
    if (AUTOLOADS.has(name)) continue;
    // Lokale innere Klassen (class Foo:)
    if (new RegExp(`class\\s+${name}\\b`).test(code)) continue;
    // Konstanten und Enum-Werte (const CURRENT_VERSION, enum State)
    if (new RegExp(`(const|enum)\\s+${name}\\b`).test(code)) continue;
    // Godot-Builtins mit Präfix (Tasten: KEY_ESCAPE, Maustasten: MOUSE_BUTTON_LEFT)
    if (/^(KEY_|MOUSE_BUTTON_|JOY_BUTTON_|JOY_AXIS_)/.test(name)) continue;
    warn(file, 1, `Unbekannter Typ "${name}" – keine class_name-Deklaration gefunden`);
  }
}

/* ------------------------------------------------------------------
 * 2c. Variant-Inferenz aus Autoload-Aufrufen
 *
 * Ein Autoload (Simulation, Advisor, ...) ist vom Typ `Node`. Ruft man
 * darüber eine Methode auf, die eine typisierte Collection zurueckgibt
 * (z. B. `active_machines() -> Array[MachineInstance]`), ist das
 * Ergebnis fuer den Compiler ein Variant. Godot 4.7 behandelt die
 * Typinferenz aus einem Variant als FEhler ("Cannot infer the type
 * of ... because the value doesn't have a set type").
 *
 * Deshalb muss der Ergebnis-Typ immer ausdruecklich stehen:
 *
 *   var machines: Array[MachineInstance] = Simulation.active_machines()
 *
 * Diese Regel findet Stellen, an denen das Ergebnis eines
 * Autoload-Aufrufs untypisiert in einer `:=`-Zuweisung landet.
 * ------------------------------------------------------------------ */
{
  // Methoden, die eine typisierte Collection zurueckgeben.
  const TYPED_COLLECTION_METHODS = new Set([
    'active_machines',
    'all_machines',
    'completed_orders',
    'deliveries',
    'machines',
    'specs',
  ]);

  // Methoden mit skaliertem Rückgabewert (float/bool/String). Auch sie
  // liefern ueber einen Autoload ein Variant.
  const SCALAR_METHODS = new Set([
    'credit_limit',
    'debt_ratio',
    'equity_ratio',
    'financing_costs_year',
    'interest_burden',
    'material_price',
    'current_utilization',
  ]);

  for (const file of files) {
    const source = fs.readFileSync(file, 'utf8');
    const code = stripCode(source);
    const lines = source.split('\n');

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      const trimmed = line.trim();
      if (trimmed.startsWith('#')) continue;

      // Muster: var x := <Autoload>.<methode>()
      const assign = trimmed.match(
        /^var\s+([A-Za-z_][A-Za-z0-9_]*)\s*:=\s*([A-Z][A-Za-z0-9_]*)\.([A-Za-z_][A-Za-z0-9_]*)\s*\(/
      );
      if (!assign) continue;

      const [, varName, autoload, method] = assign;
      if (!AUTOLOADS.has(autoload)) continue;
      const isCollection = TYPED_COLLECTION_METHODS.has(method);
      const isScalar = SCALAR_METHODS.has(method);
      if (!isCollection && !isScalar) continue;

      // Ausnahme: die Schleifenvariable einer for-Schleife ist kein
      // Inference-Problem, solange der Typ nicht abgeleitet wird.
      // `for x in Simulation.machines()` faellt ohnehin nicht unter
      // dieses Muster.

      const typeHint = isCollection
        ? ': Array[MachineInstance] = ...'
        : ': float = ...';
      warn(
        file,
        i + 1,
        `"${varName}" erbt den Typ Variant aus "${autoload}.${method}()" – ` +
          `bitte explizit typisieren (z. B. "${typeHint}"), ` +
          `sonst bricht der Projektstart in Godot 4.7 mit "Cannot infer the type"`
      );
    }
  }
}

/* ------------------------------------------------------------------
 * 2b. Aufrufprüfung gegen eigene Klassen
 *
 * Ruft eine Variable eines eigenen Typs eine Methode auf, die es dort
 * nicht gibt, bricht der Projektstart mit "Invalid call"/"Parse Error"
 * ab. Beispiel: `store.write_slot(...)` obwohl die Klasse `write_save`
 * anbietet. Diese Prüfung findet solche Fehler vor dem CI-Lauf.
 * ------------------------------------------------------------------ */
{
  // Lokale Variablen mit bekanntem Typ ermitteln:
  //   var x: SaveStore = ...
  //   var x := SaveStore.new()
  //   var x := SaveStore.new(...)   (new() liefert den Typ der Klasse)
  const typeOfVar = new Map(); // pro Datei

  for (const file of files) {
    const source = fs.readFileSync(file, 'utf8');
    const code = stripCode(source);
    const vars = new Map();

    for (const m of code.matchAll(/\bvar\s+([A-Za-z_][A-Za-z0-9_]*)\s*:\s*([A-Z][A-Za-z0-9_]*)/g)) {
      vars.set(m[1], m[2]);
    }
    for (const m of code.matchAll(/\bvar\s+([A-Za-z_][A-Za-z0-9_]*)\s*:?=\s*([A-Z][A-Za-z0-9_]*)\.new\(/g)) {
      vars.set(m[1], m[2]);
    }

    for (const [varName, className] of vars) {
      const known = classMethods.get(className);
      if (!known) continue; // Klasse kennt der Checker nicht (z. B. Engine-Typ)
      for (const m of code.matchAll(new RegExp(`\\b${varName}\\.([A-Za-z_][A-Za-z0-9_]*)`, 'g'))) {
        const member = m[1];
        if (known.has(member)) continue;
        // Properties (ohne Klammern aufgerufen) sind ebenfalls zulaessig.
        if (known.has(`prop:${member}`)) continue;
        // Nachfolgende Klammer entscheidet: Aufruf einer Methode.
        const isCall = new RegExp(`\\b${varName}\\.${member}\\s*\\(`).test(code);
        if (isCall) {
          warn(file, 1,
            `Aufruf "${varName}.${member}()" – die Klasse "${className}" besitzt diese Methode nicht`);
        }
      }
    }
  }
}

/* ------------------------------------------------------------------
 * 2b2. Typinferenz bei Variant-liefernden Builtins
 *
 * `var x := abs(y)` schlägt beim Kompilieren fehl: abs() liefert in
 * GDScript einen Variant, dessen Typ nicht abgeleitet werden kann
 * ("Cannot infer the type of \"x\" variable"). Betroffen sind alle
 * Builtins, die auf einen Variant-Operanden arbeiten.
 * ------------------------------------------------------------------ */
{
  const VARIANT_BUILTINS = [
    'abs', 'sign', 'sqrt', 'pow', 'fmod', 'posmod', 'max', 'min',
    'clamp', 'lerp', 'round', 'floor', 'ceil', 'snapped', 'smoothstep',
    'ease', 'inverse_lerp', 'wrapf', 'pingpong', 'step_decimals',
  ];
  for (const file of files) {
    const code = stripCode(fs.readFileSync(file, 'utf8'));
    for (const m of code.matchAll(/\bvar\s+([A-Za-z_][A-Za-z0-9_]*)\s*:=\s*[^\n]*?\b([a-z_][a-z0-9_]*)\s*\(/g)) {
      const fn = m[2];
      if (!VARIANT_BUILTINS.includes(fn)) continue;
      // max/min mit zwei float-Argumenten sind in Godot 4 typisiert.
      if ((fn === 'max' || fn === 'min') && /\bfloat\s*\(/.test(m[0])) continue;
      // Hinweis: In GDScript gibt es kein powf(); pow() liefert bei
      // float-Argumenten bereits einen float. Die Empfehlung lautet
      // deshalb: explizite Typangabe statt ":= " verwenden.
      warn(file, 1,
        `Typinferenz bei "${fn}()": "var ${m[1]} := ..." ist nicht ableitbar – ` +
        `stattdessen eine explizite Typangabe verwenden (z. B. "var ${m[1]}: float = ...")`);
    }
  }
}

/* ------------------------------------------------------------------
 * 2b3. Typinferenz aus Variant-Funktionen
 *
 * Godot 4.7 behandelt die Warnung "The variable type is being
 * inferred from a Variant value" als Fehler. Betroffen ist jedes
 * "var x := f()" wobei f() einen Variant zurueckgibt. Der Checker
 * findet solche Aufrufe anhand der Rueckgabetypen der eigenen
 * Funktionen.
 * ------------------------------------------------------------------ */
{
  // Funktionen, die einen Variant zurueckgeben.
  // Es werden alle Dateien durchsucht – auch ohne class_name, denn
  // die Testsuiten sind statische Klassen ohne eigenen Namen.
  const variantFunctions = new Set();
  for (const file of files) {
    const src = stripCode(fs.readFileSync(file, 'utf8'));
    // static func / func, optionaler Rueckgabetyp
    for (const m of src.matchAll(/\bfunc\s+([A-Za-z_][A-Za-z0-9_]*)\s*\([^)]*\)\s*(?:->\s*([A-Za-z_][A-Za-z0-9_]*))?\s*:/g)) {
      if (m[2] === 'Variant') variantFunctions.add(m[1]);
    }
  }
  // Variant-liefernde Builtins
  variantFunctions.add('JSON.parse_string');
  variantFunctions.add('load');

  for (const file of files) {
    const code = stripCode(fs.readFileSync(file, 'utf8'));
    // Aufrufe koennen qualifiziert sein (Klasse.Funktion()) oder direkt.
    for (const m of code.matchAll(/\bvar\s+([A-Za-z_][A-Za-z0-9_]*)\s*:=\s*(?:[A-Za-z_][A-Za-z0-9_]*\.)?([A-Za-z_][A-Za-z0-9_]*)\s*\(/g)) {
      const fn = m[2];
      if (!variantFunctions.has(fn)) continue;
      warn(file, 1,
        `Typinferenz aus einem Variant: "var ${m[1]} := ${fn}()" – ` +
        `Godot 4.7 behandelt das als Fehler. Explizite Typangabe verwenden: ` +
        `"var ${m[1]}: Variant = ${fn}()"`);
    }
  }
}

/* ------------------------------------------------------------------
 * 2b4. get() mit zwei Argumenten auf bekannten Objekttypen
 *
 * Dictionary.get() nimmt genau einen Default-Parameter. Ein Aufruf
 * wie `objekt.get("key", [])` ist bei einem Objekt (kein
 * Dictionary) ein Parse-Fehler: "Too many arguments for get() call".
 *
 * Geprueft werden Variablen, deren Typ im selben Ausdruck deklariert
 * ist (var x: MeineKlasse = ...) sowie Schleifenvariablen ueber ein
 * typisiertes Array einer bekannten Klasse.
 * ------------------------------------------------------------------ */
{
  // Properties mit typisiertem Array, nach Klasse sortiert.
  const typedArrays = new Map(); // "Klasse.Property" -> Elementtyp
  for (const file of files) {
    const src = stripCode(fs.readFileSync(file, 'utf8'));
    const classMatch = src.match(/^\s*class_name\s+([A-Za-z_][A-Za-z0-9_]*)/m);
    if (!classMatch) continue;
    for (const m of src.matchAll(/\bvar\s+([A-Za-z_][A-Za-z0-9_]*)\s*:\s*Array\[([A-Za-z_][A-Za-z0-9_]*)\]/g)) {
      typedArrays.set(`${classMatch[1]}.${m[1]}`, m[2]);
    }
  }

  // Objekttypen des Projekts
  const objectClasses = new Set();
  for (const file of files) {
    const src = stripCode(fs.readFileSync(file, 'utf8'));
    const cn = src.match(/^\s*class_name\s+([A-Za-z_][A-Za-z0-9_]*)/m);
    const ext = src.match(/^\s*extends\s+([A-Za-z_][A-Za-z0-9_]*)/m);
    if (cn && ext && ext[1] !== 'RefCounted' && ext[1] !== 'Object') {
      objectClasses.add(cn[1]);
    }
  }

  for (const file of files) {
    const code = stripCode(fs.readFileSync(file, 'utf8'));
    const varTypes = new Map();
    for (const vm of code.matchAll(/\bvar\s+([A-Za-z_][A-Za-z0-9_]*)\s*:\s*([A-Z][A-Za-z0-9_]*)/g)) {
      varTypes.set(vm[1], vm[2]);
    }

    // for x in y.prop:   -> x ist der Elementtyp von Klassen.prop
    for (const fm of code.matchAll(/\bfor\s+([A-Za-z_][A-Za-z0-9_]*)\s+in\s+([A-Za-z_][A-Za-z0-9_]*)\.([A-Za-z_][A-Za-z0-9_]*)\s*:/g)) {
      const varName = fm[1];
      const ownerType = varTypes.get(fm[2]);
      if (!ownerType) continue;
      let elementType = null;
      for (const [key, et] of typedArrays) {
        if (key === `${ownerType}.${fm[3]}`) elementType = et;
      }
      if (!elementType || !objectClasses.has(elementType)) continue;
      const callRe = new RegExp(`\\b${varName}\\.get\\(([^()]*?,[^()]*?)\\)`, 'g');
      for (const cm of code.matchAll(callRe)) {
        warn(file, 1,
          `"${varName}.get(...)" mit zwei Argumenten – "${elementType}" ist ein Objekt, ` +
          'nicht ein Dictionary. Dictionary.get() nimmt nur einen Default-Parameter.');
      }
    }

    // var x: MeineKlasse = ...   -> x.get(a, b) ist ein Fehler
    for (const [varName, typeName] of varTypes) {
      if (!objectClasses.has(typeName)) continue;
      const callRe = new RegExp(`\\b${varName}\\.get\\(([^()]*?,[^()]*?)\\)`, 'g');
      for (const cm of code.matchAll(callRe)) {
        warn(file, 1,
          `"${varName}.get(...)" mit zwei Argumenten – "${typeName}" ist ein Objekt, ` +
          'nicht ein Dictionary. Dictionary.get() nimmt nur einen Default-Parameter.');
      }
    }
  }
}

/* ------------------------------------------------------------------
 * 2b5. Aufrufe gegen die Godot-OS-API pruefen
 *
 * Godot 4 kennt kein `OS.exit()` – der Prozess wird ueber
 * `OS.set_exit_code()` plus `quit()` beendet. Ein unbekannter
 * OS-Aufruf bricht den Projektstart mit einem Parse-Fehler ab.
 * ------------------------------------------------------------------ */
{
  const OS_METHODS = new Set([
    'alert', 'benchmark_begin', 'benchmark_end', 'benchmark_get',
    'benchmark_get_bezier_cut', 'benchmark_get_fps', 'benchmark_get_memory',
    'benchmark_get_physics_frames', 'benchmark_get_process_frames',
    'benchmark_get_render_frames', 'benchmark_get_render_total_frames',
    'benchmark_print', 'crash', 'create_process', 'delay_msec',
    'execute', 'execute_with_pipe', 'find_keycode_from_string',
    'get_cache_dir', 'get_cmdline_args', 'get_cmdline_user_args',
    'get_config_dir', 'get_connected_midi_inputs', 'get_data_dir',
    'get_distribution_name', 'get_environment', 'get_executable_path',
    'get_granted_permissions', 'get_keycode_string', 'get_locale',
    'get_locale_language', 'get_model_name', 'get_name', 'get_process_id',
    'get_processor_count', 'get_processor_name', 'get_restart_on_exit',
    'get_system_dir', 'get_system_fonts', 'get_ticks_msec',
    'get_ticks_usec', 'get_unique_id', 'get_user_data_dir', 'has_environment',
    'has_feature', 'is_debug_build', 'is_process_running',
    'kill', 'move_to_trash', 'open_dynamic_library', 'read_string_from_file',
    'request_permission', 'request_permissions', 'set_environment',
    'set_exit_code', 'set_restart_on_exit', 'set_use_threads',
    'shell_open', 'shell_show_in_file_manager', 'unset_environment',
  ]);

  for (const file of files) {
    const code = stripCode(fs.readFileSync(file, 'utf8'));
    for (const m of code.matchAll(/\bOS\.([A-Za-z_][A-Za-z0-9_]*)\s*\(/g)) {
      const name = m[1];
      if (OS_METHODS.has(name)) continue;
      warn(file, 1,
        `OS.${name}() gibt es in Godot 4 nicht – ` +
        'der Prozess wird ueber OS.set_exit_code() plus quit() beendet');
    }
  }
}

/* ------------------------------------------------------------------
 * 2c. Signalprüfung des EventBus
 *
 * `EventBus.xyz.emit(...)` funktioniert nur, wenn `xyz` auch als
 * Signal deklariert ist. Andernfalls bricht der Projektstart mit
 * "Function \"emit()\" not found in base Callable" ab.
 * ------------------------------------------------------------------ */
{
  const busFile = path.join(godotRoot, 'src/core/event_bus.gd');
  if (fs.existsSync(busFile)) {
    const busSrc = stripCode(fs.readFileSync(busFile, 'utf8'));
    const signals = new Set();
    for (const m of busSrc.matchAll(/^signal\s+([A-Za-z_][A-Za-z0-9_]*)/gm)) {
      signals.add(m[1]);
    }
    // Autoload-Singletons, die keine Signale kennen, sind zulaessig
    // (z. B. Simulation mit Methoden).
    for (const file of files) {
      if (file === busFile) continue;
      const code = stripCode(fs.readFileSync(file, 'utf8'));
      for (const m of code.matchAll(/\bEventBus\.([A-Za-z_][A-Za-z0-9_]*)\.emit\s*\(/g)) {
        const name = m[1];
        if (signals.has(name)) continue;
        fail(file, 1,
          `EventBus.${name}.emit(...) – "${name}" ist im EventBus kein Signal ` +
          `(verfügbare Signale: ${[...signals].sort().join(', ')})`);
      }
    }
  }
}

/* ------------------------------------------------------------------
 * 3. Autoload-Prüfung
 * ------------------------------------------------------------------ */
// Autoload-Skripte müssen existieren
for (const m of projectText.matchAll(/([A-Za-z_][A-Za-z0-9_]*)\s*=\s*"\*?res:\/\/([^"]+)"/g)) {
  const scriptPath = path.join(godotRoot, m[2]);
  if (!fs.existsSync(scriptPath)) {
    fail(path.join(godotRoot, 'project.godot'), 1, `Autoload "${m[1]}" verweist auf fehlende Datei ${m[2]}`);
  }
}

/* ------------------------------------------------------------------
 * 4. Inhalt: Content-Sidecar prüfen
 * ------------------------------------------------------------------ */
const contentPath = path.join(godotRoot, 'content/worlds.json');
if (!fs.existsSync(contentPath)) {
  fail(contentPath, 1, 'Content-Sidecar fehlt – bitte `node tools/export_content.cjs` ausführen');
} else {
  const content = JSON.parse(fs.readFileSync(contentPath, 'utf8'));
  if (!content.worlds || content.worlds.length !== 9) {
    fail(contentPath, 1, `Erwartet 9 Welten, gefunden ${content.worlds ? content.worlds.length : 0}`);
  }
  const labTasks = content.worlds.reduce((a, w) => a + w.lab.tasks.length, 0);
  const quiz = content.worlds.reduce(
    (a, w) => a + w.concept.items.reduce((b, i) => b + (i.questions || []).length, 0),
    0
  );
  console.log(`      Content: 9 Welten, ${labTasks} Originalaufgaben, ${quiz} Quizfragen`);
}

/* ------------------------------------------------------------------
 * 5. Version-Pinning prüfen
 * ------------------------------------------------------------------ */
const pinned = fs.readFileSync(path.join(root, '.godot-version'), 'utf8').trim();
const workflow = fs.readFileSync(path.join(root, '.github/workflows/godot-build.yml'), 'utf8');
// Single-Source-of-truth: Der Workflow muss die Version aus .godot-version
// lesen, statt sie zu hardcodieren. Ein hartkodiertes Vorkommen der
// Versionsnummer wäre ein Duplikat, das auseinanderlaufen kann.
if (!workflow.includes('.godot-version')) {
  fail(path.join(root, '.github/workflows/godot-build.yml'), 1,
    'Workflow liest die Version nicht aus .godot-version – Single-Source-of-truth verletzt');
}
const hardcoded = workflow.match(/GODOT_VERSION:\s*"?([0-9][^"\s]*)"?/);
if (hardcoded && hardcoded[1] !== pinned) {
  fail(path.join(root, '.github/workflows/godot-build.yml'), 1,
    `Workflow hardcodiert Version "${hardcoded[1]}", gepinnt ist "${pinned}"`);
}

// Godot normalisiert den Versionsstring fuer die Export-Templates:
// "4.7.2-stable" wird zu "4.7.2.stable". Wird das Verzeichnis nicht
// entsprechend benannt, findet der Exporter die Templates nicht und
// der Windows-Build schlaegt fehl.
const templateDir = pinned.replace('-stable', '.stable');
// Nur echte Pfadverwendungen pruefen, keine Kommentare.
const templatePathUsages = workflow
  .split('\n')
  .filter((line) => !line.trim().startsWith('#'))
  .filter((line) => line.includes('export_templates/'));
for (const line of templatePathUsages) {
  if (line.includes('export_templates/${GODOT_VERSION}')) {
    fail(path.join(root, '.github/workflows/godot-build.yml'), 1,
      `Export-Templates werden in "${pinned}" abgelegt – Godot erwartet "${templateDir}"`);
  }
}
if (!workflow.includes('GODOT_TEMPLATE_DIR')) {
  warn(path.join(root, '.github/workflows/godot-build.yml'), 1,
    `Workflow berechnet das Template-Verzeichnis nicht – Godot erwartet "${templateDir}"`);
}

/* ------------------------------------------------------------------
 * 6. Workflow-Syntax prüfen (YAML)
 * ------------------------------------------------------------------ */
const workflowPath = path.join(root, '.github/workflows/godot-build.yml');
if (fs.existsSync(workflowPath)) {
  const wfText = fs.readFileSync(workflowPath, 'utf8');
  // Einfache Strukturprüfung: jeder "name:"-Schritt muss einen "run:" oder
  // "uses:"-Schlüssel besitzen. Das fängt die häufigsten YAML-Fehler ab.
  const steps = wfText.split('\n');
  let inSteps = false;
  let currentName = null;
  let hasBody = false;
  const flush = () => {
    if (currentName !== null && !hasBody) {
      fail(workflowPath, 1, `Schritt "${currentName}" hat weder "run:" noch "uses:"`);
    }
    currentName = null;
    hasBody = false;
  };
  for (let i = 0; i < steps.length; i++) {
    const line = steps[i];
    if (/^\s{6}- name:/.test(line)) {
      flush();
      inSteps = true;
      currentName = line.replace(/^\s*- name:\s*/, '').trim();
      hasBody = false;
      continue;
    }
    if (inSteps && /^\s{8}(run|uses):/.test(line)) {
      hasBody = true;
    }
    if (/^\s{0,4}[a-z_]+:/.test(line) && !/^\s{6}-/.test(line)) {
      flush();
      inSteps = false;
    }
  }
  flush();

  // Job-Abhängigkeiten: export muss von test abhängen
  if (!/export:\n[\s\S]{0,400}?needs:\s*test/.test(wfText)) {
    warn(workflowPath, 1, 'Export-Job sollte vom Test-Job abhängen (needs: test)');
  }
  if (!/release:[\s\S]{0,300}?needs:\s*\[test, export\]/.test(wfText)) {
    warn(workflowPath, 1, 'Release-Job sollte von test und export abhängen');
  }
  console.log(`      Workflow: 3 Jobs, Version ${pinned}`);

  // Asset-Namen im Workflow müssen zum Versionsformat passen.
  // GODOT_VERSION endet bereits auf "-stable" – ein zusätzliches "_stable"
  // im Dateinamen würde zu einem nicht existierenden Asset führen.
  // Der Workflow interpoliert ${GODOT_VERSION}. Deshalb prüfen wir das
  // Muster, nicht den aufgelösten Namen.
  //
  // GODOT_VERSION ist der vollständige Release-Tag (z. B. "4.7.2-stable").
  // Der Asset-Name lautet "Godot_v<Tag>_linux.x86_64.zip" – ohne Zusatz.
  if (!wfText.includes('Godot_v${GODOT_VERSION}_linux.x86_64.zip')) {
    fail(workflowPath, 1,
      'Editor-Asset-Muster fehlt: "Godot_v${GODOT_VERSION}_linux.x86_64.zip"');
  }
  if (!wfText.includes('Godot_v${GODOT_VERSION}_export_templates.tpz')) {
    fail(workflowPath, 1,
      'Template-Asset-Muster fehlt: "Godot_v${GODOT_VERSION}_export_templates.tpz"');
  }
  // Doppelte "_stable"-Suffixe sind ein bekannter Fehler:
  // "${GODOT_VERSION}" endet bereits auf "-stable".
  if (wfText.includes('${GODOT_VERSION}_stable_')) {
    fail(workflowPath, 1,
      'Versionssuffix doppelt: "${GODOT_VERSION}_stable_" ist falsch, da GODOT_VERSION bereits auf "-stable" endet');
  }
  // Der gepinnte Tag muss dem Muster der geprüften Assets entsprechen.
  if (!/^\d+\.\d+(\.\d+)?-stable$/.test(pinned)) {
    fail(path.join(root, '.godot-version'), 1,
      `Ungültiger Versions-Tag "${pinned}" – erwartet z. B. "4.7.2-stable"`);
  }
}
console.log('');
console.log(`Geprüfte Dateien: ${files.length}`);
console.log(`Deklarierte Klassen: ${declaredClasses.size}`);
console.log(`Autoloads: ${[...AUTOLOADS].join(', ')}`);
console.log('');
console.log(`ERRORS: ${errors}, WARNINGS: ${warnings}`);
process.exit(errors > 0 ? 1 : 0);
