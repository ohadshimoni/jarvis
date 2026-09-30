# Jarvis אישי: OpenMausBot + Hermes — V1 Architecture

> מחשב Windows עכשיו, מעבר ל-Mac mini בהמשך. זיכרון, קול, שליטה מהטלפון, כלים וסוכנים — בלי OpenClaw.
>
> מקור: `Jarvis_Architecture_OpenMausBot_Hermes.pdf` · גרסה 1.0 · 30.09.2026

## העיקרון

**OpenMausBot** הוא מעטפת השליטה וה-UI. **Hermes** הוא מנוע הסוכן. החיבור ביניהם נעשה דרך **ACP**.

```
טלפון Android ──► OpenMausBot ◄──► Hermes Agent ──► מודל + כלים
 Companion         Jarvis Bot +       hermes acp        Provider שמוגדר ב-Hermes
                   Harness
```

| רכיב | תפקיד | יכולות |
|---|---|---|
| **טלפון Android** — OpenMausBot Companion | צ'אט / Push-to-talk / התראות | Remote UI · Mic · Notifications |
| **OpenMausBot** — Jarvis Bot + Harness | שיחות, הרשאות, מחשב, אפליקציות, תורים, רוטינות | Rooms · Approvals · Memory UI · Computer |
| **Hermes Agent** — `hermes acp` | תכנון, כלים, skills, זיכרון, `delegate_task`, subagents | Skills · Memory · Delegate · MCP |
| **מודל + כלים** — Provider שמוגדר ב-Hermes | Browser, Terminal, Files, MCP, APIs, VMs | LLM · Web · Shell · Apps |

- **HOST NOW:** Windows PC
- **HOST LATER:** Mac mini — אותה ארכיטקטורה
- **DESIGN RULE:** `Jarvis = agent identity` — לא תלוי במחשב.

### אבולוציה

| גרסה | מה זה |
|---|---|
| **V1 — סוכן יחיד** | Bot אחד בשם Jarvis שמפעיל Hermes. Hermes יכול לפצל עבודה פנימית באמצעות subagents. |
| **V2 — צוות סוכנים** | Research, Coding, Admin, Shopping וכו' — כולם Hermes, כל אחד עם הוראות, תיקייה והרשאות שונות. |
| **V3 — מנועים נוספים** | בהמשך אפשר להוסיף Claude Code ו-Codex כ-engines נפרדים ב-OpenMausBot, בלי לשנות את Jarvis הבסיסי. |

---

## זרימת בקשה: מה קורה כשאתה אומר ל-Jarvis לעשות משהו

| # | שלב | מה קורה |
|---|---|---|
| 1 | **קלט** | טקסט או קול מהטלפון / מהמחשב. |
| 2 | **Wake / STT** | במצב קול: מילת הפעלה + תמלול מקומי. |
| 3 | **OpenMausBot** | מנתב את ההודעה ל-Jarvis ושומר את השיחה. |
| 4 | **ACP** | OpenMausBot מחזיק תהליך Hermes חי לשיחה ומעביר events והרשאות. |
| 5 | **Hermes** | מתכנן, משתמש בזיכרון / skills, ויכול להאציל תתי-משימות. |
| 6 | **פעולה** | Browser, terminal, files, MCP, אפליקציות או מחשב מבודד. |
| 7 | **תשובה** | טקסט + TTS + התראה לטלפון. |

### מה נשאר ב-OpenMausBot
- ממשק שיחה נוח במחשב ובטלפון.
- ניהול bots, rooms והרשאות.
- בחירת מחשב / VM וכלי עבודה לכל bot.
- Approval cards לפני פעולות רגישות.
- חיבור engines דרך ACP, כולל Hermes.

### מה נשאר ב-Hermes
- ה-agent loop עצמו: reasoning, planning, execution.
- זיכרון, skills וחיפוש בשיחות עבר.
- `delegate_task` וסוכנים מקבילים.
- MCP / browser / terminal / code execution.
- Voice pipeline ו-wake word על desktop / CLI.

### נקודה חשובה: ChatGPT Pro ו-Claude Max
ב-V1, שבו Hermes הוא המנוע, המודל של Hermes מוגדר בנפרד לפי ה-providers שהוא תומך בהם. **אין להניח** שמנוי ChatGPT Pro או Claude Max מזין אוטומטית את Hermes.

**הדרך הנקייה להשתמש במנויים בהמשך:** OpenMausBot יודע להריץ גם Claude CLI וגם Codex CLI עם ה-login הקיים שלהם. לכן אפשר להוסיף אותם כ-engines נפרדים ליד Hermes — ולא לנסות "לדחוף" אותם לתוך Hermes.

### למה הארכיטקטורה הזו טובה
ה-UI, הזהות של Jarvis וה-history לא תלויים במודל מסוים. אפשר להחליף engine בעתיד בלי לבנות מחדש את כל המערכת.

---

## קול ומילת הפעלה: מה אפשר עכשיו ומה צריך לבנות לטלפון

### מחשב — אפשר כבר עכשיו
Hermes תומך ב-wake word מקומי על CLI / TUI / Desktop. אפשר להגדיר phrase כמו **"Hey Jarvis"**, ואז:
- ה-listener מאזין מקומית רק למילת ההפעלה.
- אחרי זיהוי נפתח session קולי.
- STT יכול להיות local Whisper.
- TTS יכול להיות מקומי, למשל Piper / NeuTTS.

`openWakeWord` · `Whisper` · `Piper` · `Hermes Voice`

### טלפון נעול — לא נניח שזה קיים אוטומטית
OpenMausBot מציע companion ל-Android / iOS, אבל תיעוד ה-wake word של Hermes מתייחס ל-CLI / TUI / Desktop. לכן "Hey Jarvis" כשהטלפון נעול הוא **שכבה נוספת שאנחנו צריכים לבנות**.
ב-Android זה אפשרי: foreground service מקומי שמריץ wake-word detector, פותח מיקרופון רק אחרי trigger, ושולח את הפקודה ל-host.

### ארכיטקטורת Voice מומלצת

```
Android Listener ──► Audio Capture ──► Jarvis Host ──► Voice Reply
openWakeWord /       VAD + STT         OpenMausBot →     TTS → phone speaker
Porcupine            local preferred   Hermes ACP        stream / notification
on-device                              Windows / Mac mini
```

- **Privacy:** Wake-word detection נשארת על המכשיר. רק אחרי trigger מעבירים אודיו / טקסט ל-Jarvis.
- **Battery:** Android foreground service דורש אופטימיזציה וסוללה. נשתמש ב-detector קל ולא ב-Whisper רציף.
- **Fallback:** עד שנבנה listener — OpenMausBot mobile app + push-to-talk נותן שליטה מלאה מהטלפון.

---

## תוכנית בנייה: Windows עכשיו, Mac mini בהמשך

### ברירת מחדל בטוחה
- Approval לפעולות רגישות.
- גישה מינימלית לתיקיות.
- Secrets לא בתוך prompts.
- VM למשימות לא אמינות.

### אחסון וגיבוי
- OpenMausBot data — `~/.openmausbot`
- Hermes config / memory — `~/.hermes`
- Backup לפני migration.
- Git עבור skills / config מותאם (הריפו הזה).

### יעד סופי
- Host תמיד דולק.
- טלפון = remote + voice.
- Jarvis = orchestrator אישי.
- סוכנים מקבילים עם הרשאות נפרדות.

### החלטה ארכיטקטונית לקבע כבר עכשיו
**אל נבנה את Jarvis כ-script ענק.** נבנה אותו כ-identity / config בתוך OpenMausBot, כאשר Hermes הוא engine. כך המעבר מ-Windows ל-Mac mini והוספת Claude / Codex בעתיד יהיו שינויים בתשתית — ולא rewrite.

### Roadmap

| שלב | מה מתקינים | מה בונים | מטרה / תוצאה |
|---|---|---|---|
| **0 · Baseline** | Hermes + provider | Hermes עובד בטקסט על Windows | פקודה אחת ב-Hermes מחזירה תשובה ומשתמשת בכלים. |
| **1 · OpenMausBot** | Install OpenMausBot | ליצור bot בשם Jarvis, לבחור Hermes engine | Jarvis מופיע ב-UI ומדבר דרך Hermes ACP. |
| **2 · Tools** | Browser, terminal, files, MCP | Working folder, approval policy | Jarvis לא רק מדבר — הוא מבצע משימות. |
| **3 · Phone** | Pair Android companion | Remote access, notifications מאובטח | אפשר לתת משימות מכל מקום. |
| **4 · Voice** | Wake word + local STT/TTS על ה-host | אחר כך Android wake bridge | "Hey Jarvis" → משימה → תשובה קולית. |
| **5 · Multi-agent** | Research / Coder / Admin bots | או Hermes delegates | עבודה מקבילית לפי תפקידים. |
| **6 · Mac mini migration** | Reinstall stack | להעביר config / memory / skills אחרי גיבוי ובדיקת compatibility | Jarvis רץ 24/7 על Mac mini; ה-Windows כבר לא host. |

---

## מה מאומת כרגע בתיעוד

**OpenMausBot**
- Hermes מופיע כ-engine מובנה עם ACP integration.
- יש Windows build וגם Android / iOS companion.
- ה-desktop harness מקומי ושומר נתונים תחת `~/.openmausbot`.
- ACP sessions נשמרים כתהליך חי לכל conversation thread.

**Hermes**
- Hermes מפעיל ACP server כ-`hermes acp`.
- Wake word קיים ב-CLI / TUI / Desktop והזיהוי יכול להיות מקומי.
- Voice mode תומך STT / TTS, כולל אפשרויות מקומיות.
- Hermes כולל memory, skills, MCP ו-delegation.

### מה עדיין דורש פיתוח שלנו
- Always-on wake word על Android כשהטלפון נעול.
- UX של שיחת קול רציפה בטלפון בסגנון Siri / Jarvis.
- Policy מדויק: מתי Jarvis מבצע לבד ומתי מבקש אישור.
- הגדרת ה-model provider של Hermes בהתאם לעלות / למנויים שלך.

### מקורות טכניים שנבדקו (30.09.2026)
- OpenMausBot Docs — Agent engines / Configuration / Download.
- Hermes Agent Docs — ACP Host Integration / Programmatic Integration.
- Hermes Agent Docs — Wake Word / Voice Mode / TTS.

---

## הסטאק הסופי של V1

```
Android phone → OpenMausBot → Jarvis bot → Hermes via ACP → tools + model provider
```

עם voice / wake מקומי על ה-host עכשיו, ו-Android wake bridge בשלב הבא.
