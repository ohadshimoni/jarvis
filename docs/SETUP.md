# הקמת Jarvis — מדריך מהיר (Windows)

> הסטאק: **Android → OpenMausBot → Jarvis bot → Hermes (ACP) → כלים + מודל**
>
> כל הפקודות כאן נבדקו מול הקוד והתיעוד של OpenMausBot ו-Hermes (30.09.2026). מה שלא מאומת מסומן ⚠️.
> זמן משוער לשלבים 0–3: כ-45 דקות.

---

## שלב 0 · Baseline — Hermes עובד בטקסט

### 0.1 קבע את תיקיית הבית של Hermes (חשוב, פעם אחת)
ב-Windows, Hermes שומר כברירת מחדל ב-`%LOCALAPPDATA%\hermes`, אבל OpenMausBot מחפש את ההגדרות שלו ב-`~/.hermes`.
כדי ששניהם יסתכלו על אותה תיקייה (וכדי שהמעבר ל-Mac mini יהיה זהה), פתח **PowerShell רגיל (לא Admin)** והרץ:

```powershell
[Environment]::SetEnvironmentVariable("HERMES_HOME", "$env:USERPROFILE\.hermes", "User")
```

**סגור את PowerShell ופתח חלון חדש** (כדי שהמשתנה ייטען).

### 0.2 התקנת Hermes (native, בלי WSL)
```powershell
iex (irm https://hermes-agent.nousresearch.com/install.ps1)
```
סגור ופתח PowerShell חדש, ובדוק:
```powershell
hermes acp --check
```

### 0.3 חיבור מודל (provider)
```powershell
hermes model
```
בחר אחד:

| אפשרות | מתי | הערה |
|---|---|---|
| **ChatGPT or Codex Subscription** | יש לך ChatGPT Plus/Pro | התחברות ב-device code לחשבון ChatGPT. ⚠️ איך זה נספר מול מכסת המנוי לא מתועד. |
| **OpenRouter** | רוצה גישה לכל המודלים, תשלום לפי שימוש | מפתח `OPENROUTER_API_KEY` נשמר ב-`~/.hermes/.env`. |
| **Anthropic (API key)** | רוצה Claude בתשלום לפי שימוש | `ANTHROPIC_API_KEY`. |
| **Anthropic OAuth** | יש Claude Max | עובד **רק** עם קרדיטים של extra usage — לא מהמכסה הבסיסית של Max. Claude Pro לא נתמך. |

> ⚠️ מפתחות API שמים **רק** ב-`~/.hermes\.env` (או דרך `hermes model`) — לא כמשתני סביבה של Windows. OpenMausBot מוחק `OPENAI_API_KEY`/`OPENROUTER_API_KEY` מהסביבה כשהוא מפעיל את Hermes.

### 0.4 הזהות של Jarvis במנוע
העתק את [`jarvis/SOUL.md`](../jarvis/SOUL.md) מהריפו אל `~/.hermes\SOUL.md` (מחליף את הזהות ברירת-המחדל "Hermes"):
```powershell
notepad "$env:USERPROFILE\.hermes\SOUL.md"
```
(הדבק את התוכן ושמור.)

### 0.5 בדיקה
```powershell
hermes
```
נסה: `מה התאריך היום? ותראה לי אילו קבצים יש בתיקיית Documents שלי`
✅ **הצלחה:** מקבל תשובה בעברית, והוא מריץ כלי (terminal/files) כדי לענות.

---

## שלב 1 · OpenMausBot — Jarvis מופיע ב-UI

### 1.1 התקנה
1. הורד: <https://github.com/milind-soni/OpenMausBot/releases/latest/download/OpenMausBot-setup.exe>
2. הרץ. ההתקנה per-user, בלי Admin.
3. ה-installer עדיין לא חתום, אז SmartScreen יציג "unknown publisher" → **More info → Run anyway**.

### 1.2 וידוא שהמנוע Hermes מזוהה
**Settings → Engines** → ודא ש-**Hermes** מופיע ומזוהה.
אם לא: לחץ **Set CLI…** והדבק את הנתיב שמחזירה הפקודה:
```powershell
(Get-Command hermes).Source
```
> OpenMausBot מפעיל בעצמו `hermes acp` — תהליך חי אחד לכל שיחה.

### 1.3 יצירת הבוט Jarvis
**New bot**:
- **Name:** `Jarvis`
- **Model / Engine:** `Hermes` → `hermes-default` (משתמש במודל שהגדרת ב-`hermes model`)
- **Soul / Instructions:** הדבק את התוכן של [`jarvis/SOUL.md`](../jarvis/SOUL.md)
- **Approval:** `Ask for approval` (ב-Hermes זמינים רק Ask ו-Auto; Auto מתנהג כמו Ask)
- **Working folder:** צור תיקייה ייעודית, למשל `C:\Users\<you>\Jarvis`, ובחר אותה — זו "גישה מינימלית לתיקיות".

✅ **הצלחה:** Jarvis מופיע בצד, עונה בצ'אט, ולפני פקודה רגישה מופיע **Approval card**.

> ⚠️ **באג ידוע (PR #1875, פתוח):** בבוט על Hermes, הכלים הפנימיים של OpenMausBot (`list_bots`, `memory_update` וכו') נכשלים מההודעה השנייה בשיחה. הצ'אט עצמו, הכלים של Hermes וה-MCP שמוגדרים ב-Hermes לא מושפעים. לכן את האפליקציות (Calendar, Gmail…) נחבר **ישירות ב-Hermes** — ראה [INTEGRATIONS.md](INTEGRATIONS.md).

---

## שלב 2 · Tools — Jarvis מבצע

- **Terminal / Files / Browser / Web:** מובנים ב-Hermes. ב-Windows ה-terminal רץ דרך **Git Bash** (ה-installer מתקין Git אם חסר).
- **אפליקציות (Google Calendar, Gmail, Drive, Todoist, Notion, Zapier…):** ראה [INTEGRATIONS.md](INTEGRATIONS.md).
- **מדיניות אישורים:** מוגדרת ב-`jarvis/SOUL.md` (מתי לבצע לבד ומתי לשאול) + Approval cards ב-OpenMausBot + `approvals` ב-Hermes.

---

## שלב 3 · Phone — משימות מכל מקום

### 3.1 אפליקציית Android
הורד את ה-APK מדף ה-Releases של OpenMausBot — חפש את הגרסה **Android 1.5.0** והקובץ `OpenMausBot-1.5.0.apk`:
<https://github.com/milind-soni/OpenMausBot/releases>
(גרסת Google Play עדיין בתהליך — PR #1531.) התקן (תצטרך לאשר "התקנה ממקור לא ידוע").

### 3.2 חיבור הטלפון למחשב
במחשב: **Settings → Remote access** → הפעל → מופיע **QR** (תקף ל-2 דקות, חד-פעמי). סרוק מהאפליקציה.

איך הטלפון מגיע למחשב — בחר אחד:

| דרך | מתי | אבטחה |
|---|---|---|
| **אותו Wi-Fi** | בבית | HTTP לא מוצפן — רק ברשת ביתית אמינה |
| **Tailscale** (מומלץ) | מכל מקום | מוצפן (WireGuard). התקן Tailscale במחשב ובטלפון, והשתמש בשם ה-`*.ts.net` של המחשב |
| **Hosted HTTPS** | מכל מקום בלי Tailscale | התחברות במייל במחשב, מקבל כתובת `*.openmausbot.com` דרך Cloudflare tunnel. ⚠️ עלות/מכסות לא נבדקו |

### 3.3 התראות
ב-Android הפעל את מצב **Always on** באפליקציה (foreground service) — כך התראות מגיעות גם כשהאפליקציה סגורה.
> אין push מהענן (אין FCM) — המחשב חייב להיות דלוק עם OpenMausBot פתוח.

✅ **הצלחה:** שולח משימה מהטלפון מחוץ לבית, ומקבל תשובה + התראה.

---

## שלב 4 · Voice (בהמשך)
- **במחשב:** Hermes תומך ב-wake word מקומי. ב-`config.yaml`: `wake_word.enabled: true`, `phrase: "hey jarvis"` (ל-Porcupine, מילת ברירת המחדל כבר `jarvis`). פרטים מלאים יגיעו בשלב 4.
- **בטלפון:** בינתיים dictation בכפתור המיקרופון באפליקציה. "Hey Jarvis" כשהטלפון נעול = שכבה שנבנה (Android wake bridge).

## שלבים 5–6
- **Multi-agent:** `hermes profile create <name>` לכל סוכן (Research / Coder / Admin), כל אחד עם `SOUL.md`, זיכרון והרשאות משלו.
- **Mac mini:** גיבוי `~/.openmausbot` + `~/.hermes` → התקנה מחדש על Mac → שחזור.

---

## גיבוי
- OpenMausBot: **Settings → Backups → Export full backup** (קובץ `.ombbackup` מוצפן, בלי credentials). או: סגור את האפליקציה והעתק את כל `~/.openmausbot`.
- Hermes: העתק את כל `~/.hermes` (כולל `.env` — שמור אותו במקום מאובטח, לא ב-Git).
