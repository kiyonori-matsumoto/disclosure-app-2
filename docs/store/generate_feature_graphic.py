import base64

with open("icons/icon_console.png", "rb") as f:
    icon_b64 = base64.b64encode(f.read()).decode("utf-8")

with open("docs/store/screenshots/01_timeline_tdnet.png", "rb") as f:
    ss_b64 = base64.b64encode(f.read()).decode("utf-8")

svg_content = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 500" width="1024" height="500">
  <defs>
    <!-- Background Gradients -->
    <linearGradient id="bgGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#0a1128" />
      <stop offset="50%" stop-color="#001f54" />
      <stop offset="100%" stop-color="#034078" />
    </linearGradient>
    <radialGradient id="glowTopRight" cx="85%" cy="20%" r="65%">
      <stop offset="0%" stop-color="#00b4d8" stop-opacity="0.3" />
      <stop offset="100%" stop-color="#00b4d8" stop-opacity="0" />
    </radialGradient>
    <radialGradient id="glowBottomLeft" cx="15%" cy="85%" r="55%">
      <stop offset="0%" stop-color="#1282a2" stop-opacity="0.25" />
      <stop offset="100%" stop-color="#1282a2" stop-opacity="0" />
    </radialGradient>

    <filter id="dropShadow" x="-15%" y="-15%" width="130%" height="130%">
      <feDropShadow dx="0" dy="16" stdDeviation="24" flood-color="#000000" flood-opacity="0.6" />
    </filter>
    <filter id="iconShadow" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="8" stdDeviation="12" flood-color="#000000" flood-opacity="0.4" />
    </filter>

    <clipPath id="phoneClip">
      <rect x="0" y="0" width="270" height="580" rx="36" />
    </clipPath>
    <clipPath id="iconClip">
      <rect x="0" y="0" width="76" height="76" rx="18" />
    </clipPath>
  </defs>

  <!-- Background -->
  <rect width="1024" height="500" fill="url(#bgGrad)" />
  <rect width="1024" height="500" fill="url(#glowTopRight)" />
  <rect width="1024" height="500" fill="url(#glowBottomLeft)" />

  <!-- Subtle grid lines -->
  <g stroke="#ffffff" stroke-opacity="0.04" stroke-width="1">
    <line x1="0" y1="125" x2="1024" y2="125" />
    <line x1="0" y1="250" x2="1024" y2="250" />
    <line x1="0" y1="375" x2="1024" y2="375" />
    <line x1="256" y1="0" x2="256" y2="500" />
    <line x1="512" y1="0" x2="512" y2="500" />
    <line x1="768" y1="0" x2="768" y2="500" />
  </g>

  <!-- Left Content (Text & Branding) -->
  <g transform="translate(64, 72)">
    <!-- App Header & Official Console Icon -->
    <g filter="url(#iconShadow)">
      <g clip-path="url(#iconClip)">
        <image href="data:image/png;base64,{icon_b64}" width="76" height="76" />
      </g>
    </g>
    <text x="96" y="32" font-family="'Noto Sans JP', -apple-system, sans-serif" font-weight="700" font-size="28" fill="#ffffff" letter-spacing="0.5">適時開示 Notifier</text>
    <text x="96" y="60" font-family="'Noto Sans JP', -apple-system, sans-serif" font-weight="600" font-size="15" fill="#90e0ef" letter-spacing="1">TDNET &amp; EDINET NOTIFIER</text>

    <!-- Main Catchphrase -->
    <text x="0" y="160" font-family="'Noto Sans JP', -apple-system, sans-serif" font-weight="800" font-size="44" fill="#ffffff">
      適時開示 &amp; EDINETを
    </text>
    <text x="0" y="215" font-family="'Noto Sans JP', -apple-system, sans-serif" font-weight="900" font-size="44" fill="#48cae4">
      最速プッシュ通知。
    </text>

    <!-- Sub Copy -->
    <text x="0" y="270" font-family="'Noto Sans JP', -apple-system, sans-serif" font-weight="500" font-size="20" fill="#cbd5e1">
      保有銘柄の開示・決算発表を逃さない
    </text>

    <!-- Feature Badges with Vector Icons -->
    <g transform="translate(0, 318)">
      <!-- Badge 1: リアルタイム -->
      <g>
        <rect width="144" height="38" rx="19" fill="#ffffff" fill-opacity="0.12" stroke="#48cae4" stroke-opacity="0.5" stroke-width="1.5" />
        <path d="M11 10.5 L3 19.5 L9 19.5 L6 27.5 L16 17.5 L10 17.5 Z" transform="translate(14, 0)" fill="#48cae4" />
        <text x="42" y="24" font-family="'Noto Sans JP', sans-serif" font-weight="600" font-size="14" fill="#ffffff">最速リアルタイム</text>
      </g>
      <!-- Badge 2: PDF即時閲覧 -->
      <g transform="translate(156, 0)">
        <rect width="144" height="38" rx="19" fill="#ffffff" fill-opacity="0.12" stroke="#48cae4" stroke-opacity="0.5" stroke-width="1.5" />
        <rect x="16" y="11" width="13" height="16" rx="2.5" fill="none" stroke="#48cae4" stroke-width="1.6" />
        <line x1="19.5" y1="16.5" x2="25.5" y2="16.5" stroke="#48cae4" stroke-width="1.4" stroke-linecap="round" />
        <line x1="19.5" y1="20.5" x2="25.5" y2="20.5" stroke="#48cae4" stroke-width="1.4" stroke-linecap="round" />
        <text x="40" y="24" font-family="'Noto Sans JP', sans-serif" font-weight="600" font-size="14" fill="#ffffff">原文PDF即時閲覧</text>
      </g>
      <!-- Badge 3: 決算カレンダー -->
      <g transform="translate(312, 0)">
        <rect width="134" height="38" rx="19" fill="#ffffff" fill-opacity="0.12" stroke="#48cae4" stroke-opacity="0.5" stroke-width="1.5" />
        <rect x="15.5" y="13" width="15" height="14" rx="2.5" fill="none" stroke="#48cae4" stroke-width="1.6" />
        <line x1="15.5" y1="17.5" x2="30.5" y2="17.5" stroke="#48cae4" stroke-width="1.4" />
        <line x1="19.5" y1="11" x2="19.5" y2="14" stroke="#48cae4" stroke-width="1.5" stroke-linecap="round" />
        <line x1="26.5" y1="11" x2="26.5" y2="14" stroke="#48cae4" stroke-width="1.5" stroke-linecap="round" />
        <circle cx="23" cy="21" r="1.3" fill="#48cae4" />
        <text x="40" y="24" font-family="'Noto Sans JP', sans-serif" font-weight="600" font-size="14" fill="#ffffff">決算カレンダー</text>
      </g>
    </g>
  </g>

  <!-- Right Side (Real Smartphone Screenshot Mockup) -->
  <g transform="translate(680, 25) rotate(4)" filter="url(#dropShadow)">
    <rect x="-8" y="-8" width="286" height="596" rx="44" fill="#0f172a" stroke="#334155" stroke-width="3" />
    <g clip-path="url(#phoneClip)">
      <image href="data:image/png;base64,{ss_b64}" x="0" y="0" width="270" height="600" preserveAspectRatio="xMidYMin slice" />
    </g>
    <rect x="0" y="0" width="270" height="580" rx="36" fill="none" stroke="#ffffff" stroke-opacity="0.12" stroke-width="1.5" />
  </g>
</svg>
'''

output_path = "docs/store/feature_graphic.svg"
with open(output_path, "w", encoding="utf-8") as f:
    f.write(svg_content)

print(f"Generated {output_path} with vector icons.")
