// Genera design/SafePlace-Motion.figcraft con figcraft-cli run
// Uso: node design/build-motion.mjs [--keep]
import { writeFileSync } from "node:fs";
import { spawnSync } from "node:child_process";

const CLI = "C:\\Program Files\\ArtCraft\\FigCraft\\figcraft-cli.exe";
const OUT = "design/SafePlace-Motion.figcraft";
const SCRIPT = "design/.motion-script.json";

// ─────────────────────────────────────────────── tokens (espejo de DesignSystem.swift)
const C = {
  canvas: "#FAF8F4",
  soft: "#F3EFE8",
  card: "#FFFFFF",
  strong: "#ECE7DF",
  ink: "#2A2622",
  ink2: "#6B625A",
  muted: "#6E6862",
  hair: "#2A26221A",
  ink08: "#2A26221A",
  bright: "#FEC89A",
  brightDeep: "#E8A85F",
  calm: "#D8E2DC",
  hopeful: "#FEC5BB",
  mixed: "#FFD7BA",
  heavy: "#A9BCD0",
  peach: "#FFB084",
  teal: "#1A3A3A",
};
const SERIF = "Source Serif 4";
const SANS = "Source Sans 3";
const W = 393;
const H = 852;
const PAD = 20;
const INNER = W - PAD * 2;

// springs: response/dampingFraction → mass/stiffness/damping
const SPRING = {
  gentle: { mass: 1, stiffness: 322, damping: 28, ms: 350 },
  quick: { mass: 1, stiffness: 503, damping: 37, ms: 280 },
  bouncy: { mass: 1, stiffness: 224, damping: 20, ms: 420 },
};

// ─────────────────────────────────────────────── emisor
const cmds = [];
let nextId = 2; // la página es 1
const reserve = () => nextId++;
function push(command, params, id) {
  cmds.push({ command, params });
  return id;
}

function frame({ name, x = 0, y = 0, w, h, parent, props = {} }) {
  const id = reserve();
  push("frame.create", { name, x, y, width: w, height: h, parent, props });
  return id;
}
function rect({ name, x = 0, y = 0, w, h, parent, fill = "none", radius = 0, stroke, strokeWeight = 1, opacity, clip = false }) {
  return frame({
    name, x, y, w, h, parent,
    props: {
      layout: "none",
      fill,
      ...(radius ? { cornerRadius: radius } : {}),
      ...(stroke ? { stroke, strokeWeight, strokeAlign: "inside" } : {}),
      ...(opacity !== undefined ? { opacity } : {}),
      ...(clip ? { clip: true } : {}),
    },
  });
}
function text({ name, text, x = 0, y = 0, w, parent, props = {} }) {
  const id = reserve();
  push("text.create", { text, x, y, width: w, parent, name, props });
  return id;
}
function t(name, str, { size = 13, weight = "Regular", design = SANS, color = C.ink, x = 0, y = 0, w = INNER, parent, align = "left", tracking, lineHeight, fill = true }) {
  return text({
    name, text: str, x, y, w, parent,
    props: {
      fontFamily: design,
      fontStyle: weight,
      fontSize: size,
      ...(tracking ? { letterSpacing: tracking } : {}),
      ...(lineHeight ? { lineHeight } : {}),
      textAlign: align,
      textAutoResize: "height",
      sizingH: fill ? "fill" : "fixed",
      fill: color,
    },
  });
}
function set(id, props) {
  push("node.set", { id, ...props });
  return id;
}

// ─────────────────────────────────────────────── formas
function fadeIn(id, v) {
  if (v !== 1) push("node.set", { id, opacity: v });
  return id;
}

const circle = ({ name, d, x = 0, y = 0, parent, fill, stroke, strokeWeight = 1 }) =>
  rect({ name, x, y, w: d, h: d, parent, fill, radius: d / 2, stroke, strokeWeight, clip: true });

/** réplica de DumplingShape (SwiftUI) */
function dumplingPath(w, h, roundness = 0.62) {
  const r = Math.max(0, Math.min(roundness, 1));
  const pt = (x, y) => [x * w, y * h];
  const bellyX = 0.02 + 0.03 * (1 - r);
  const n = (v) => v.toFixed(2);
  const P = (p) => `${n(p[0])} ${n(p[1])}`;
  const start = pt(0.5, 0.04);
  return [
    `M ${P(start)}`,
    `C ${P(pt(0.66, 0.03))} ${P(pt(0.99, 0.26))} ${P(pt(0.98, 0.56))}`,
    `C ${P(pt(0.99, 0.82))} ${P(pt(0.8, 0.99))} ${P(pt(0.5, 0.99))}`,
    `C ${P(pt(0.2, 0.99))} ${P(pt(bellyX, 0.82))} ${P(pt(bellyX, 0.56))}`,
    `C ${P(pt(bellyX, 0.26))} ${P(pt(0.34, 0.03))} ${P(start)} Z`,
  ].join(" ");
}

// ─────────────────────────────────────────────── iconos: trazo, 20×20
const ICON = {
  search: "M9 1.8 A7.2 7.2 0 1 0 9 16.2 A7.2 7.2 0 1 0 9 1.8 Z M14.4 14.4 L18.6 18.6",
  sun: "M10 5.9 A4.1 4.1 0 1 0 10 14.1 A4.1 4.1 0 1 0 10 5.9 Z M10 1.2 L10 2.7 M10 17.3 L10 18.8 M1.2 10 L2.7 10 M17.3 10 L18.8 10 M3.8 3.8 L4.9 4.9 M15.1 15.1 L16.2 16.2 M16.2 3.8 L15.1 4.9 M4.9 15.1 L3.8 16.2",
  leaf: "M3.6 18.4 C3.6 9.2 8.8 4 18.4 3.6 C18 13.2 12.8 18.4 3.6 18.4 Z M3.6 18.4 L11.4 10.6",
  macro: "M10 5.6 C6.9 5.6 4.4 8.1 4.4 11.2 C4.4 14.3 6.9 16.8 10 16.8 C13.1 16.8 15.6 14.3 15.6 11.2 C15.6 8.1 13.1 5.6 10 5.6 Z M10 8.9 C8.7 8.9 7.7 9.9 7.7 11.2 C7.7 12.5 8.7 13.5 10 13.5 C11.3 13.5 12.3 12.5 12.3 11.2 C12.3 9.9 11.3 8.9 10 8.9 Z M10 1.2 L10 3.2 M2.9 4.7 L4.3 6.1 M17.1 4.7 L15.7 6.1",
  cloudSun: "M7.2 15.6 C4.8 15.6 2.9 13.7 2.9 11.3 C2.9 8.9 4.7 7 7.1 6.8 C7.9 4.6 10 3 12.4 3 C15.5 3 18 5.4 18.3 8.4 C19.6 9.2 20.4 10.6 20.4 12.1 C20.4 14 18.9 15.6 17 15.6 Z",
  cloudRain: "M7.2 12.8 C5 12.8 3.2 11 3.2 8.8 C3.2 6.6 4.9 4.8 7.1 4.7 C7.9 2.7 9.9 1.2 12.2 1.2 C15.2 1.2 17.6 3.5 17.9 6.4 C19.1 7.2 19.9 8.5 19.9 9.9 C19.9 11.6 18.5 12.8 16.9 12.8 Z M7.4 15.4 L6.7 18 M11 15.4 L10.3 18 M14.6 15.4 L13.9 18",
  flame: "M10 19.2 C6.1 19.2 3.4 16.5 3.4 12.8 C3.4 9.5 5.8 7 7.5 4.9 C8.6 3.6 9.4 2.4 9.6 1.1 C12.4 2.9 14 5.2 14.2 7.5 C15.1 6.8 15.6 5.8 15.8 4.8 C17.2 6.8 17.1 9.2 16.3 11 C16.8 11.5 17.2 12.4 17.2 13.5 C17.2 16.7 14.1 19.2 10 19.2 Z",
  sparkles: "M8 1.6 L9.6 6.2 L14.2 7.8 L9.6 9.4 L8 14 L6.4 9.4 L1.8 7.8 L6.4 6.2 Z M15.6 12.2 L16.5 14.9 L19.2 15.8 L16.5 16.7 L15.6 19.4 L14.7 16.7 L12 15.8 L14.7 14.9 Z",
  arrowRight: "M3.2 10 L16.8 10 M11.6 4.8 L16.8 10 L11.6 15.2",
  chevron: "M7.4 3.4 L13 10 L7.4 16.6",
  house: "M3.4 9.6 L10 3.2 L16.6 9.6 L16.6 16.8 L3.4 16.8 Z M7.6 16.8 L7.6 12.4 L12.4 12.4 L12.4 16.8",
  book: "M4.2 3.4 C4.2 2.8 4.7 2.4 5.3 2.4 L16 2.4 L16 16.6 L5.3 16.6 C4.7 16.6 4.2 17 4.2 17.6 Z M4.2 17.6 C4.2 18.2 4.7 18.6 5.3 18.6 L16 18.6",
  mind: "M5.2 5.6 A2.2 2.2 0 1 0 5.2 10 A2.2 2.2 0 1 0 5.2 5.6 Z M14.8 2.8 A2.2 2.2 0 1 0 14.8 7.2 A2.2 2.2 0 1 0 14.8 2.8 Z M13.8 13.2 A2.2 2.2 0 1 0 13.8 17.6 A2.2 2.2 0 1 0 13.8 13.2 Z M7.2 7.1 L12.7 5.6 M7.1 9.2 L11.8 13.4",
  bookmark: "M5.6 2.8 L14.4 2.8 C14.9 2.8 15.2 3.2 15.2 3.6 L15.2 17.8 L10 13.8 L4.8 17.8 L4.8 3.6 C4.8 3.2 5.1 2.8 5.6 2.8 Z",
  plus: "M10 3.6 L10 16.4 M3.6 10 L16.4 10",
  check: "M10 1.8 A8.2 8.2 0 1 0 10 18.2 A8.2 8.2 0 1 0 10 1.8 Z M6.4 10.2 L9 12.8 L13.8 7.6",
  person: "M10 11.4 C7.6 11.4 5.9 9.7 5.9 7.3 C5.9 4.9 7.6 3.2 10 3.2 C12.4 3.2 14.1 4.9 14.1 7.3 C14.1 9.7 12.4 11.4 10 11.4 Z M3.4 18 C3.4 14.6 6.3 12.6 10 12.6 C13.7 12.6 16.6 14.6 16.6 18",
};

// vector de trazo: el nodo ES el vector
function glyph({ name, path, d, x = 0, y = 0, parent, color = C.ink, weight = 1.7, filled = false }) {
  const s = d / 20;
  const id = reserve();
  push("node.create", {
    type: "vector", name, x, y, width: d, height: d, parent,
    props: filled
      ? { path, fill: color }
      : { path, stroke: color, strokeWeight: Math.max(1, weight * s), strokeCap: "round", strokeJoin: "round", fill: "none" },
  });
  return id;
}

// nodo vector crudo (para la mascota, que necesita tamaño propio)
function vector({ name, x = 0, y = 0, w, h, parent, props = {} }) {
  const id = reserve();
  push("node.create", { type: "vector", name, x, y, width: w, height: h, parent, props });
  return id;
}

/** escala un path sin comandos de arco (los números son coordenadas) */
function scalePath(path, s) {
  return path.replace(/-?\d+(\.\d+)?/g, (m) => (parseFloat(m) * s).toFixed(2));
}

// ─────────────────────────────────────────────── página 1
push("page.rename", { name: "Motion" });
push("page.setBackground", { color: C.canvas });

// ═══════════════════════════════════════════════ HOME
function buildHome({ name, x, y, calm, stage = 2, tabActive = "home", stats, categories, feelings, streak, recent }) {
  const vis = (s) => (stage >= s ? 1 : 0);
  const root = frame({
    name, x, y, w: W, h: H,
    props: { fill: C.canvas, layout: "vertical", gap: 15, padding: [14, PAD, 0, PAD], clip: true },
  });

  // ── header
  const header = frame({ name: "Header", w: INNER, h: 44, parent: root, props: { layout: "none", fill: "none" } });
  fadeIn(header, vis(1));
  t("Wordmark", "SafePlace", { size: 22, weight: "Semibold", design: SERIF, w: INNER, y: 8, parent: header, align: "center", fill: false });
  const avatar = circle({ name: "Avatar", d: 42, x: 0, y: 1, parent: header, fill: calm ? C.calm : C.bright });
  glyph({ name: "AvatarGlyph", path: ICON.person, d: 21, x: 10.5, y: 10.5, parent: avatar, color: "#FFFFFFCC", weight: 1.8 });
  const search = circle({ name: "Search", d: 44, x: INNER - 44, y: 0, parent: header, fill: C.card, stroke: C.hair });
  glyph({ name: "SearchGlyph", path: ICON.search, d: 19, x: 12.5, y: 12.5, parent: search, color: C.ink, weight: 1.7 });

  // ── mascota
  const mascot = frame({ name: "Mascot", w: INNER, h: 126, parent: root, props: { layout: "none", fill: "none" } });
  fadeIn(mascot, vis(1));
  const mw = 132, mh = 110, mx = (INNER - mw) / 2;
  rect({ name: "MascotShadow", x: mx + 22, y: 112, w: 88, h: 10, radius: 5, parent: mascot, fill: calm ? "#D8E2DC59" : "#FEC89A59" });
  reserve();
  push("node.create", {
    type: "vector", name: "MascotBody", x: mx, y: 2, width: mw, height: mh, parent: mascot,
    props: { path: dumplingPath(mw, mh), fill: calm ? "#D8E2DCF2" : "#FEC89AF2", stroke: "#FFFFFF59", strokeWeight: 1.2 },
  });
  rect({ name: "MascotGloss", x: mx + mw * 0.17, y: 2 + mh * 0.17, w: mw * 0.36, h: mh * 0.09, radius: 100, parent: mascot, fill: "#FFFFFF3D" });
  t("MascotCaption", "I'm here with you.", { size: 13, weight: "Medium", w: INNER, y: 112, parent: mascot, align: "center", color: C.muted, fill: false });

  // ── hoy
  const today = frame({ name: "Today", w: INNER, parent: root, props: { layout: "vertical", gap: 14, fill: "none", sizingH: "fill", sizingV: "hug" } });
  fadeIn(today, vis(1));
  t("Prompt", "How are you feeling?", { size: 30, weight: "Semibold", design: SERIF, w: INNER, parent: today, lineHeight: 34 });

  const moods = frame({ name: "MoodRow", w: INNER, parent: today, props: { layout: "horizontal", gap: 8, fill: "none", sizingH: "fill", sizingV: "hug", crossAlign: "min" } });
  const MOODS = [
    { id: "bright", label: "Bright", color: C.bright, icon: ICON.sun },
    { id: "calm", label: "Calm", color: C.calm, icon: ICON.leaf },
    { id: "hopeful", label: "Hopeful", color: C.hopeful, icon: ICON.macro },
    { id: "mixed", label: "Mixed", color: C.mixed, icon: ICON.cloudSun },
    { id: "heavy", label: "Heavy", color: C.heavy, icon: ICON.cloudRain },
  ];
  const cellW = (INNER - 32) / 5;
  const moodCells = {};
  for (const m of MOODS) {
    const on = calm && m.id === "calm";
    const item = frame({ name: `Mood-${m.id}`, w: cellW, parent: moods, props: { layout: "vertical", gap: 7, fill: "none", sizingH: "fill", sizingV: "hug", crossAlign: "center" } });
    moodCells[m.id] = item;
    const d = on ? 56 : 52;
    const disc = circle({ name: `MoodDisc-${m.id}`, d, parent: item, fill: m.color, stroke: on ? C.ink : C.ink08, strokeWeight: on ? 2 : 1 });
    glyph({ name: `MoodGlyph-${m.id}`, path: m.icon, d: 21, x: (d - 21) / 2, y: (d - 21) / 2, parent: disc, color: C.ink, weight: 1.7 });
    t(`MoodLabel-${m.id}`, m.label, { size: 10, weight: "Semibold", w: cellW, parent: item, align: "center", color: C.ink2 });
  }

  if (calm) {
    const saved = frame({ name: "SavedLine", w: INNER, parent: today, props: { layout: "horizontal", gap: 6, fill: "none", sizingH: "fill", sizingV: "hug", crossAlign: "center" } });
    glyph({ name: "SavedGlyph", path: ICON.check, d: 15, y: 2, parent: saved, color: C.brightDeep, weight: 1.8 });
    t("SavedText", "Saved. Nice check-in.", { size: 13, weight: "Medium", w: 300, parent: saved, color: C.brightDeep });
  } else {
    const row = frame({ name: "StreakRow", w: INNER, parent: today, props: { layout: "horizontal", gap: 8, fill: "none", sizingH: "fill", sizingV: "hug", crossAlign: "center" } });
    const badge = circle({ name: "StreakBadge", d: 22, parent: row, fill: streak.active ? C.bright : C.strong });
    glyph({ name: "StreakGlyph", path: ICON.flame, d: 12, x: 5, y: 5, parent: badge, color: streak.active ? C.ink : C.muted, weight: 1.6, filled: true });
    t("StreakText", streak.text, { size: 13, weight: "Medium", w: INNER - 30, parent: row, color: C.muted });
  }

  // ── stats
  const statsWrap = frame({ name: "Stats", w: INNER, parent: root, props: { layout: "vertical", gap: 18, fill: "none", sizingH: "fill", sizingV: "hug" } });
  fadeIn(statsWrap, vis(2));
  const top = frame({ name: "StatNumbers", w: INNER, parent: statsWrap, props: { layout: "horizontal", gap: 14, fill: "none", sizingH: "fill", sizingV: "hug" } });
  for (const s of stats) {
    const box = frame({ name: `Stat-${s.key}`, w: INNER / 2, parent: top, props: { layout: "vertical", gap: 2, fill: "none", sizingH: "fill", sizingV: "hug" } });
    t(`StatNumber-${s.key}`, s.value, { size: 32, weight: "Semibold", design: SERIF, w: INNER / 2, parent: box });
    t(`StatLabel-${s.key}`, s.label, { size: 10, weight: "Medium", w: INNER / 2, parent: box, tracking: 1.2, color: C.muted });
  }

  const catSection = frame({ name: "CategorySection", w: INNER, parent: statsWrap, props: { layout: "vertical", gap: 10, fill: "none", sizingH: "fill", sizingV: "hug" } });
  t("SectionTitleCategory", "BY CATEGORY", { size: 11, weight: "Medium", w: INNER, parent: catSection, tracking: 1, color: C.muted });
  const rows = frame({ name: "CategoryRows", w: INNER, parent: catSection, props: { layout: "vertical", gap: 8, fill: "none", sizingH: "fill", sizingV: "hug" } });
  const trackW = INNER - 92 - 24 - 24;
  for (const c of categories) {
    const row = frame({ name: `Category-${c.key}`, w: INNER, parent: rows, props: { layout: "horizontal", gap: 12, fill: "none", sizingH: "fill", sizingV: "hug", crossAlign: "center" } });
    t(`CategoryName-${c.key}`, c.name, { size: 12, weight: "Medium", w: 92, parent: row, color: C.ink2 });
    const track = rect({ name: `CategoryTrack-${c.key}`, w: trackW, h: 8, parent: row, fill: C.strong, radius: 4, clip: true });
    rect({ name: `CategoryBar-${c.key}`, w: Math.max(6, trackW * (c.count / 12)), h: 8, parent: track, fill: C.brightDeep, radius: 4 });
    t(`CategoryCount-${c.key}`, String(c.count), { size: 12, weight: "Medium", w: 24, parent: row, align: "right", color: C.muted });
  }

  const feelSection = frame({ name: "FeelingsSection", w: INNER, parent: statsWrap, props: { layout: "vertical", gap: 10, fill: "none", sizingH: "fill", sizingV: "hug" } });
  t("SectionTitleFeelings", "FEELINGS", { size: 11, weight: "Medium", w: INNER, parent: feelSection, tracking: 1, color: C.muted });
  const pills = frame({ name: "FeelingPills", w: INNER, parent: feelSection, props: { layout: "horizontal", gap: 7, fill: "none", sizingH: "fill", sizingV: "hug", wrap: true, crossGap: 7 } });
  for (const f of feelings) {
    const pill = frame({ name: `Feel-${f.key}`, parent: pills, props: { layout: "horizontal", gap: 5, padding: [6, 11, 6, 11], fill: f.color, cornerRadius: 100, sizingH: "hug", sizingV: "hug", crossAlign: "center" } });
    glyph({ name: `FeelGlyph-${f.key}`, path: f.icon, d: 13, y: 1, parent: pill, color: C.ink, weight: 1.6 });
    t(`FeelCount-${f.key}`, String(f.count), { size: 12, weight: "Semibold", w: 14, parent: pill, color: C.ink });
  }

  // ── recientes
  const recentWrap = frame({ name: "Recent", w: INNER, parent: root, props: { layout: "vertical", gap: 4, fill: "none", sizingH: "fill", sizingV: "hug" } });
  fadeIn(recentWrap, vis(3));
  const rhead = frame({ name: "RecentHeader", w: INNER, parent: recentWrap, props: { layout: "horizontal", fill: "none", sizingH: "fill", sizingV: "hug", crossAlign: "center", mainAlign: "spaceBetween" } });
  t("RecentTitle", "Recent", { size: 22, weight: "Semibold", design: SERIF, w: 140, parent: rhead });
  const seeAll = frame({ name: "SeeAll", parent: rhead, props: { layout: "horizontal", gap: 4, fill: "none", sizingH: "hug", sizingV: "hug", crossAlign: "center" } });
  t("SeeAllText", "See all", { size: 13, weight: "Medium", w: 46, parent: seeAll, color: C.brightDeep, fill: false });
  glyph({ name: "SeeAllArrow", path: ICON.arrowRight, d: 12, parent: seeAll, color: C.brightDeep, weight: 1.6 });

  for (let i = 0; i < recent.length; i++) {
    const r = recent[i];
    const row = frame({ name: `Note-${r.key}`, w: INNER, parent: recentWrap, props: { layout: "horizontal", gap: 12, padding: [7, 0, 7, 0], fill: "none", sizingH: "fill", sizingV: "hug", crossAlign: "center" } });
    rect({ name: `NoteSpine-${r.key}`, w: 3, h: 30, parent: row, fill: r.color, radius: 2 });
    const col = frame({ name: `NoteText-${r.key}`, w: INNER - 60, parent: row, props: { layout: "vertical", gap: 1, fill: "none", sizingH: "fill", sizingV: "hug" } });
    t(`NoteTitle-${r.key}`, r.title, { size: 15, weight: "Medium", w: INNER - 60, parent: col });
    t(`NoteDate-${r.key}`, r.date, { size: 11, weight: "Medium", w: INNER - 60, parent: col, color: C.muted });
    glyph({ name: `NoteChevron-${r.key}`, path: ICON.chevron, d: 11, parent: row, color: C.muted, weight: 1.8 });
  }

  // ── tab bar flotante: hermana a nivel de página, para poder anclarla al pie
  const tabH = 64;
  const tab = frame({
    name: "TabBar", x, y: y + H - tabH - 20, w: INNER, h: tabH,
    props: {
      layout: "horizontal", fill: C.card, cornerRadius: 32, clip: true, stroke: C.hair, strokeWeight: 1,
      mainAlign: "spaceEvenly", crossAlign: "center",
      sizingH: "fixed", sizingV: "fixed",
    },
  });
  fadeIn(tab, vis(2));
  const TABS = [
    { key: "home", path: ICON.house, on: tabActive === "home" },
    { key: "journal", path: ICON.book, on: tabActive === "journal" },
    { key: "mind", path: ICON.mind, on: tabActive === "mind" },
    { key: "saved", path: ICON.bookmark, on: tabActive === "saved" },
  ];
  const tabIds = {};
  for (const tb of TABS) {
    const cell = frame({ name: `Tab-${tb.key}`, w: 44, h: 44, parent: tab, props: { layout: "none", fill: "none", sizingH: "fixed", sizingV: "fixed" } });
    glyph({ name: `TabIcon-${tb.key}`, path: tb.path, d: 22, x: 11, y: 11, parent: cell, color: tb.on ? C.ink : C.muted, weight: tb.on ? 2 : 1.6 });
    tabIds[tb.key] = cell;
  }

  return { root, header, mascot, today, statsWrap, recentWrap, tab, tabIds, moodCells };
}

// ── estados de Home
const DATA = {
  stats: [
    { key: "notes", value: "12", label: "THINGS SAVED" },
    { key: "cats", value: "4", label: "CATEGORIES" },
  ],
  categories: [
    { key: "music", name: "Music", count: 5 },
    { key: "people", name: "People", count: 3 },
    { key: "places", name: "Places", count: 2 },
    { key: "habits", name: "Habits", count: 2 },
  ],
  feelings: [
    { key: "bright", icon: ICON.sun, count: 4, color: C.bright },
    { key: "calm", icon: ICON.leaf, count: 3, color: C.calm },
    { key: "hopeful", icon: ICON.macro, count: 3, color: C.hopeful },
    { key: "mixed", icon: ICON.cloudSun, count: 1, color: C.mixed },
    { key: "heavy", icon: ICON.cloudRain, count: 1, color: C.heavy },
  ],
  streak: { active: true, text: "Streak of 3 days · record 5 days" },
  recent: [
    { key: "a", title: "Canciones para el martes", date: "Hoy · Música", color: C.teal },
  ],
};

const HOME = buildHome({ name: "Home · En reposo", x: 0, y: 0, calm: false, stage: 3, ...DATA });

// estado de entrada, por etapas
const IN0 = buildHome({ name: "Entrada · 0%", x: W + 80, y: 0, calm: false, stage: 0, ...DATA });
const IN1 = buildHome({ name: "Entrada · 1", x: W * 2 + 160, y: 0, calm: false, stage: 1, ...DATA });
const IN2 = buildHome({ name: "Entrada · 2", x: W * 3 + 240, y: 0, calm: false, stage: 2, ...DATA });

const CHECK = buildHome({
  name: "Home · Check-in de calma",
  x: W * 4 + 320, y: 0,
  calm: true, stage: 3,
  stats: [{ key: "notes", value: "13", label: "THINGS SAVED" }, { key: "cats", value: "4", label: "CATEGORIES" }],
  categories: [
    { key: "music", name: "Music", count: 5 },
    { key: "people", name: "People", count: 3 },
    { key: "places", name: "Places", count: 2 },
    { key: "habits", name: "Habits", count: 3 },
  ],
  feelings: [
    { key: "bright", icon: ICON.sun, count: 4, color: C.bright },
    { key: "calm", icon: ICON.leaf, count: 4, color: C.calm },
    { key: "hopeful", icon: ICON.macro, count: 3, color: C.hopeful },
    { key: "mixed", icon: ICON.cloudSun, count: 1, color: C.mixed },
    { key: "heavy", icon: ICON.cloudRain, count: 1, color: C.heavy },
  ],
  streak: { active: true, text: "Streak of 4 days · record 5 days" },
  recent: [
    { key: "a", title: "Feeling calm", date: "Ahora · Check-in", color: C.calm },
  ],
});

// estado del tab activo (cambio de icono)
const JOURNAL = buildHome({ name: "Home · Tab Journal", x: W * 5 + 400, y: 0, calm: false, stage: 3, tabActive: "journal", ...DATA });

// ─────────────────────────────────────────────── interacciones
function nav(from, to, opts = {}) {
  const {
    trigger = { type: "onClick" },
    transition = "smartAnimate",
    spring,
    ms,
    bezier,
    delay,
  } = opts;
  const easing = spring
    ? { customSpring: { mass: SPRING[spring].mass, stiffness: SPRING[spring].stiffness, damping: SPRING[spring].damping } }
    : bezier
    ? { customBezier: bezier }
    : undefined;
  push("proto.interaction.add", {
    id: from,
    trigger,
    action: { type: "navigate", dest: to },
    dest: to,
    transition: { type: transition },
    durationMs: ms ?? (spring ? SPRING[spring].ms : 300),
    ...(easing ? { easing } : {}),
    ...(delay ? { delayMs: delay } : {}),
  });
}

// easeInOut de CSS: cubic-bezier(0.42, 0, 0.58, 1)
const EASE_IN_OUT = { x1: 0.42, y1: 0, x2: 0.58, y2: 1 };

// ── splash: el tinte entra, el wordmark se teclea, y se funde al Home
const SPLASH_TINT = C.bright; // theme.tint con el mood por defecto
const SPLASH_INK = "#2B2320";
function buildSplash({ name, x, y, typed }) {
  const root = frame({ name, x, y, w: W, h: H, props: { fill: SPLASH_TINT, layout: "vertical", mainAlign: "center", crossAlign: "center", padding: [0, PAD, 0, PAD] } });
  if (typed) glyph({ name: "SplashGlyph", path: ICON.sparkles, d: 26, parent: root, color: SPLASH_INK, weight: 1.4 });
  t("SplashWord", typed, { size: 46, weight: "Semibold", design: SERIF, w: INNER, parent: root, align: "center", color: SPLASH_INK, tracking: 2 });
  return { root };
}

const SPL0 = buildSplash({ name: "Splash · 0", x: 0, y: 1000, typed: "" });
const SPL1 = buildSplash({ name: "Splash · 1", x: 473, y: 1000, typed: "SafeP" });
const SPL2 = buildSplash({ name: "Splash · 2", x: 946, y: 1000, typed: "SafePlace" });

// ── racha: el loop de la llama (easeInOut 1.15 s, sin spring)
function buildFlame({ name, x, y, d, phase, active, label }) {
  const box = frame({ name, x, y, w: 393, h: 393, props: { fill: C.soft, layout: "vertical", gap: 24, padding: [40, 40, 40, 40], mainAlign: "center", crossAlign: "center", cornerRadius: 24 } });
  const peak = phase === "peak";
  const size = d;
  const disc = circle({ name: "StreakBadge", d: size, parent: box, fill: active ? C.bright : C.strong });
  // la llama escala 0.92↔1.08 anclada abajo y su opacidad va 0.86↔1; el disco no cambia
  const base = size * 0.55;
  const gd = peak ? base * 1.08 : base * 0.92;
  const glyphId = vector({
    name: "StreakGlyph",
    x: (size - gd) / 2,
    y: size / 2 + base / 2 - gd,
    w: gd, h: gd,
    parent: disc,
    props: { path: scalePath(ICON.flame, gd / 20), fill: active ? C.ink : C.muted },
  });
  if (!peak) push("node.set", { id: glyphId, opacity: 0.86 });
  t("FlameLabel", label, { size: 14, weight: "Medium", w: 300, parent: box, align: "center", color: C.ink2, fill: false });
  return { root: box, disc, glyph: glyphId };
}

const FLAME_A = buildFlame({ name: "Racha · reposo", x: 1419, y: 1000, d: 120, phase: "rest", active: true, label: "escala 0.92 · opacidad 0.86" });
const FLAME_B = buildFlame({ name: "Racha · pico", x: 1862, y: 1000, d: 120, phase: "peak", active: true, label: "escala 1.08 · opacidad 1" });
const FLAME_C = buildFlame({ name: "Racha · apagada", x: 2305, y: 1000, d: 120, phase: "rest", active: false, label: "sin racha: sin loop" });

// ── mascota: flotación + respiración
function buildMascotState({ name, x, y, lift, roundness, label }) {
  const box = frame({ name, x, y, w: 393, h: 420, props: { fill: C.soft, layout: "vertical", mainAlign: "center", crossAlign: "center", cornerRadius: 24, padding: [32, 32, 32, 32], gap: 12 } });
  const holder = frame({ name: "MascotHolder", w: 300, h: 230, parent: box, props: { layout: "none", fill: "none", sizingH: "fixed", sizingV: "fixed" } });
  vector({
    name: "MascotBody", x: 54, y: 12 + lift, width: 200, height: 168, parent: holder,
    props: { path: dumplingPath(200, 168, roundness), fill: "#FEC89AF2", stroke: "#FFFFFF59", strokeWeight: 1.2 },
  });
  rect({ name: "MascotGloss", x: 54 + 200 * 0.17, y: 12 + lift + 168 * 0.17, w: 200 * 0.36, h: 168 * 0.09, radius: 100, parent: holder, fill: "#FFFFFF3D" });
  t("MascotLabel", label, { size: 14, weight: "Medium", w: 300, parent: box, align: "center", color: C.ink2, fill: false });
  return { root: box };
}

const MASC_A = buildMascotState({ name: "Mascota · flota", x: 2748, y: 1000, lift: -6, roundness: 0.62, label: "flota 4.2 s · y ±6" });
const MASC_B = buildMascotState({ name: "Mascota · exhala", x: 3191, y: 1000, lift: 6, roundness: 0.62, label: "respira 3.4 s · anclada abajo" });

push("proto.flow.add", { start: SPL0.root, name: "Arranque" });
push("proto.flow.add", { start: IN0.root, name: "Entrada" });
push("proto.flow.add", { start: HOME.root, name: "Home" });
push("proto.flow.add", { start: FLAME_A.root, name: "Racha" });
push("proto.flow.add", { start: MASC_A.root, name: "Mascota" });

// arranque: tinte → tecleo → palabra completa → cascada → Home
nav(SPL0.root, SPL1.root, { trigger: { type: "afterDelay", ms: 700 }, transition: "dissolve", ms: 180, bezier: { x1: 0.33, y1: 0, x2: 0.67, y2: 1 } });
nav(SPL1.root, SPL2.root, { trigger: { type: "afterDelay", ms: 750 }, transition: "dissolve", ms: 180, bezier: { x1: 0.33, y1: 0, x2: 0.67, y2: 1 } });
nav(SPL2.root, IN0.root, { trigger: { type: "afterDelay", ms: 550 }, transition: "dissolve", ms: 550 });
nav(IN0.root, IN1.root, { trigger: { type: "afterDelay", ms: 900 }, spring: "gentle", delay: 120 });
nav(IN1.root, IN2.root, { trigger: { type: "afterDelay", ms: 420 }, spring: "gentle" });
nav(IN2.root, HOME.root, { trigger: { type: "afterDelay", ms: 420 }, spring: "gentle" });
nav(CHECK.root, HOME.root, { trigger: { type: "afterDelay", ms: 3200 }, transition: "dissolve", spring: "quick" });

// interacción principal: elegir el mood de calma
nav(HOME.moodCells.calm, CHECK.root, { spring: "bouncy" });
nav(CHECK.moodCells.calm, HOME.root, { spring: "bouncy" });

// iconos: cambio de tab
nav(HOME.tabIds.journal, JOURNAL.root, { spring: "quick" });
nav(JOURNAL.tabIds.home, HOME.root, { spring: "quick" });

// loops: llama 1.15 s, mascota 4.2 s
nav(FLAME_A.root, FLAME_B.root, { trigger: { type: "afterDelay", ms: 1150 }, ms: 1150, bezier: EASE_IN_OUT });
nav(FLAME_B.root, FLAME_A.root, { trigger: { type: "afterDelay", ms: 1150 }, ms: 1150, bezier: EASE_IN_OUT });
nav(MASC_A.root, MASC_B.root, { trigger: { type: "afterDelay", ms: 4200 }, ms: 4200, bezier: EASE_IN_OUT });
nav(MASC_B.root, MASC_A.root, { trigger: { type: "afterDelay", ms: 4200 }, ms: 4200, bezier: EASE_IN_OUT });


// ─────────────────────────────────────────────── página 2: iconos y springs
reserve(); // page.add consume un id del mismo espacio que los nodos
push("page.add", { name: "Iconos" });
push("page.setBackground", { color: C.canvas });

const sheet = frame({ name: "Iconos · estados", x: 0, y: 0, w: 720, h: 900, props: { fill: C.canvas, layout: "vertical", gap: 14, padding: [32, 32, 32, 32] } });
t("SheetTitle", "Icon set · rest / active", { size: 28, weight: "Semibold", design: SERIF, w: 656, parent: sheet, fill: false });
t("SheetNote", "Trazo 1.6 en reposo · 2.0 en activo · caja 20 escalada al tamaño final. La app usa SF Symbols; estas siluetas fijan el estado, el peso y el punto de anclaje de la animación.", { size: 13, weight: "Regular", w: 656, parent: sheet, color: C.muted, lineHeight: 19, fill: false });

const SET = [
  { name: "Home", rest: ICON.house, active: ICON.house },
  { name: "Journal", rest: ICON.book, active: ICON.book },
  { name: "Mind", rest: ICON.mind, active: ICON.mind },
  { name: "Saved", rest: ICON.bookmark, active: ICON.bookmark },
  { name: "Search", rest: ICON.search, active: ICON.search },
  { name: "Streak", rest: ICON.flame, active: ICON.flame },
  { name: "Bright", rest: ICON.sun, active: ICON.sun },
  { name: "Calm", rest: ICON.leaf, active: ICON.leaf },
  { name: "Hopeful", rest: ICON.macro, active: ICON.macro },
  { name: "Mixed", rest: ICON.cloudSun, active: ICON.cloudSun },
  { name: "Heavy", rest: ICON.cloudRain, active: ICON.cloudRain },
];
for (const s of SET) {
  const row = frame({ name: `Row-${s.name}`, w: 656, h: 48, parent: sheet, props: { layout: "horizontal", gap: 24, fill: "none", crossAlign: "center", sizingH: "fill", sizingV: "hug" } });
  t(`RowName-${s.name}`, s.name, { size: 13, weight: "Medium", w: 96, parent: row, color: C.ink2, fill: false });
  const restBox = circle({ name: `Rest-${s.name}`, d: 40, parent: row, fill: C.soft });
  glyph({ name: `RestGlyph-${s.name}`, path: s.rest, d: 20, x: 10, y: 10, parent: restBox, color: C.muted, weight: 1.6 });
  const actBox = circle({ name: `Active-${s.name}`, d: 40, parent: row, fill: C.card, stroke: C.hair });
  glyph({ name: `ActiveGlyph-${s.name}`, path: s.active, d: 20, x: 10, y: 10, parent: actBox, color: C.ink, weight: 2 });
  t(`RowScale-${s.name}`, "20 · 22 · 34", { size: 11, weight: "Regular", w: 120, parent: row, color: C.muted, fill: false });
}

// springs
const springs = frame({ name: "Springs", x: 760, y: 0, w: 520, h: 330, props: { fill: C.canvas, layout: "vertical", gap: 14, padding: [32, 32, 32, 32] } });
t("SpringsTitle", "Springs", { size: 28, weight: "Semibold", design: SERIF, w: 456, parent: springs, fill: false });
t("SpringsNote", "Los mismos valores que SafeDesign.spring / springSnappy / springBouncy.", { size: 13, weight: "Regular", w: 456, parent: springs, color: C.muted, fill: false, lineHeight: 19 });
for (const [key, v] of Object.entries(SPRING)) {
  const row = frame({ name: `Spring-${key}`, w: 456, parent: springs, props: { layout: "horizontal", gap: 12, fill: "none", crossAlign: "center", sizingH: "fill", sizingV: "hug" } });
  t(`SpringName-${key}`, key, { size: 15, weight: "Semibold", design: SERIF, w: 110, parent: row });
  t(`SpringVals-${key}`, `mass ${v.mass} · stiffness ${v.stiffness} · damping ${v.damping}`, { size: 12, weight: "Regular", w: 220, parent: row, color: C.ink2, fill: false });
  t(`SpringMs-${key}`, `${v.ms} ms`, { size: 12, weight: "Medium", w: 90, parent: row, color: C.muted, align: "right", fill: false });
}

// ─────────────────────────────────────────────── página 3: Reduce Motion
reserve();
push("page.add", { name: "Reduce Motion" });
push("page.setBackground", { color: C.canvas });

const rm = frame({ name: "Reduce Motion", x: 0, y: 0, w: 760, h: 620, props: { fill: C.canvas, layout: "vertical", gap: 16, padding: [40, 40, 40, 40] } });
t("RmTitle", "Reduce Motion", { size: 28, weight: "Semibold", design: SERIF, w: 680, parent: rm, fill: false });
t("RmNote", "El movimiento nunca es opcional para quien lo desactiva. Cada fila deja un estado legible sin animación, y ningún cambio de estado depende solo del movimiento.", { size: 13, weight: "Regular", w: 680, parent: rm, color: C.muted, fill: false, lineHeight: 19 });

const RM_ROWS = [
  ["Cascada de entrada", "los bloques aparecen, sin desplazamiento ni stagger"],
  ["Llama de racha", "pose de reposo, sin bucle"],
  ["Mascota", "quieta, sin flotar ni respirar"],
  ["Splash", "wordmark completo desde el primer frame"],
  ["Cambio de mood", "cross-fade de opacidad, sin escala ni anillo animado"],
  ["Cambio de tab", "el icono cambia de estado, sin spring"],
  ["Transición a check-in", "cross-fade 200 ms"],
];
for (const [what, how] of RM_ROWS) {
  const row = frame({ name: `Rm-${what}`, w: 680, parent: rm, props: { layout: "horizontal", gap: 16, padding: [10, 0, 10, 0], fill: "none", sizingH: "fill", sizingV: "hug", crossAlign: "min" } });
  t(`RmName-${what}`, what, { size: 14, weight: "Semibold", design: SERIF, w: 240, parent: row, fill: false });
  t(`RmHow-${what}`, how, { size: 13, weight: "Regular", w: 420, parent: row, color: C.ink2, fill: false });
}

// ─────────────────────────────────────────────── guardar
const json = JSON.stringify(cmds, null, 1).replace(/[\u007f-\uffff]/g, (ch) => "\\u" + ch.charCodeAt(0).toString(16).padStart(4, "0"));
writeFileSync(SCRIPT, json, "utf8");

const res = spawnSync(CLI, ["run", SCRIPT, "--automation-write-root", "design", "--out", OUT], { encoding: "utf8" });
const lines = (res.stdout || "").trim().split("\n").filter(Boolean);
const parsed = lines.map((l) => { try { return JSON.parse(l); } catch { return { ok: false, step: -1, command: "parse", error: l }; } });
const bad = parsed.filter((r) => !r.ok);
if (bad.length) {
  console.error("FALLOS:\n" + bad.map((b) => `  step ${b.step} ${b.command}: ${JSON.stringify(b.error || b.result)}`).join("\n"));
}
console.log((res.stderr || "").trim());
console.log(`${cmds.length} comandos, ${parsed.length - bad.length} ok, ${bad.length} fallos → ${OUT}`);
if (bad.length) process.exitCode = 1;
