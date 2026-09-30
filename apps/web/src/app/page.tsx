const stages = [
  { n: "0", name: "Baseline", goal: "Hermes עובד בטקסט על Windows" },
  { n: "1", name: "OpenMausBot", goal: "Jarvis מופיע ב-UI ומדבר דרך Hermes ACP" },
  { n: "2", name: "Tools", goal: "Jarvis לא רק מדבר — הוא מבצע משימות" },
  { n: "3", name: "Phone", goal: "אפשר לתת משימות מכל מקום" },
  { n: "4", name: "Voice", goal: "״Hey Jarvis״ → משימה → תשובה קולית" },
  { n: "5", name: "Multi-agent", goal: "עבודה מקבילית לפי תפקידים" },
  { n: "6", name: "Mac mini", goal: "Jarvis רץ 24/7 על Mac mini" },
];

export default function Home() {
  return (
    <main className="relative min-h-dvh overflow-hidden bg-[#03060b] text-slate-100">
      <div aria-hidden className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_at_50%_35%,rgba(56,189,248,0.18),transparent_60%)]" />
      <div aria-hidden className="pointer-events-none absolute inset-0 opacity-[0.07] [background-image:linear-gradient(rgba(125,211,252,.6)_1px,transparent_1px),linear-gradient(90deg,rgba(125,211,252,.6)_1px,transparent_1px)] [background-size:48px_48px]" />
      <section className="relative mx-auto flex max-w-3xl flex-col items-center px-4 pt-24 pb-16 text-center">
        <div aria-hidden className="relative mb-10 size-40">
          <div className="absolute inset-0 animate-spin rounded-full border border-sky-400/40 border-t-sky-300 [animation-duration:6s]" />
          <div className="absolute inset-4 animate-spin rounded-full border border-cyan-300/30 border-b-cyan-200 [animation-direction:reverse] [animation-duration:9s]" />
          <div className="absolute inset-10 rounded-full bg-sky-300/80 blur-md" />
          <div className="absolute inset-[3.25rem] rounded-full bg-white shadow-[0_0_60px_20px_rgba(125,211,252,.6)]" />
        </div>
        <p dir="ltr" className="font-mono text-xs tracking-[0.4em] text-sky-300/80">SYSTEM ONLINE · V1</p>
        <h1 dir="ltr" className="mt-4 text-5xl font-black tracking-[0.25em] sm:text-7xl">J.A.R.V.I.S</h1>
        <p className="mt-6 text-lg text-slate-300 sm:text-xl">
          ה-HQ של Jarvis בבנייה. <bdi>OpenMausBot</bdi> הוא ה-UI, <bdi>Hermes</bdi> הוא המנוע, והחיבור ביניהם דרך <bdi>ACP</bdi>.
        </p>
        <p dir="ltr" className="mt-4 rounded-full border border-sky-400/20 bg-sky-400/5 px-4 py-2 font-mono text-xs text-sky-200/90 sm:text-sm">
          Android → OpenMausBot → Jarvis bot → Hermes via ACP → tools + model
        </p>
        <ol className="mt-12 grid w-full gap-3 text-start sm:grid-cols-2">
          {stages.map((s) => (
            <li key={s.n} className="rounded-xl border border-white/10 bg-white/[0.03] p-4 backdrop-blur">
              <div className="flex items-baseline gap-3">
                <span className="font-mono text-sky-300">{s.n}</span>
                <span dir="ltr" className="font-semibold">{s.name}</span>
              </div>
              <p className="mt-1 text-sm text-slate-400">{s.goal}</p>
            </li>
          ))}
        </ol>
        <p className="mt-12 text-sm text-slate-500">העיצוב המלא בדרך — הסוכנים עובדים עליו עכשיו.</p>
      </section>
    </main>
  );
}
