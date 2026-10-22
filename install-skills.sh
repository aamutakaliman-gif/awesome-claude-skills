#!/usr/bin/env bash
# Pasang skill dari repo andrej-karpathy-skills, rea, dan awesome-claude-skills (termasuk composio-skills) ke ~/.claude/skills,
# plus CLI langsmith-fetch dan MCP server Composio (pengganti Rube yang dihentikan sejak 16 Mei 2026).
# Pemakaian: bash install-skills.sh [folder-berisi-repo]   (default: folder saat ini; repo yang belum ada akan di-clone)
set -euo pipefail
BASE="${1:-$PWD}"
DEST="$HOME/.claude/skills"
mkdir -p "$DEST"
for r in andrej-karpathy-skills rea awesome-claude-skills; do
  [ -d "$BASE/$r" ] || git clone --depth 1 "https://github.com/aamutakaliman-gif/$r.git" "$BASE/$r"
done
n=0
while IFS= read -r f; do
  d=$(dirname "$f")
  name=$(grep -m1 -e '^name:' "$f" | sed 's/^name: *//; s/["'\'']//g')
  [ "$name" = "template-skill" ] && continue
  rm -rf -- "$DEST/$name"; cp -r -- "$d" "$DEST/$name"; n=$((n+1))
done < <(find "$BASE/andrej-karpathy-skills/skills" "$BASE/rea/.agents/skills" "$BASE/awesome-claude-skills" \
           -name SKILL.md -not -path '*/.git/*')
echo "Terpasang $n skill ke $DEST"
pip install -q langsmith-fetch && echo "langsmith-fetch terpasang"
# Sesi cloud: bundle CA proxy tidak memuat rantai sertifikat LangSmith, jadi langsmith-fetch memakai bundle certifi.
real=$(command -v langsmith-fetch)
if [ -d /root/.ccr ] && [ ! -e "$real.real" ]; then
  mv "$real" "$real.real"
  printf '#!/usr/bin/env bash\nca=$(python3 -c "import certifi;print(certifi.where())")\nREQUESTS_CA_BUNDLE=$ca SSL_CERT_FILE=$ca exec "%s.real" "$@"\n' "$real" > "$real"
  chmod +x "$real"
fi
if command -v claude >/dev/null; then
  claude mcp get composio >/dev/null 2>&1 || claude mcp add --scope user --transport http composio https://connect.composio.dev/mcp
fi
