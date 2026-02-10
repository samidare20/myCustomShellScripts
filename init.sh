
set -euo pipefail

# 1. zsh 설치 확인
if ! command -v zsh >/dev/null 2>&1; then
  echo "❌ zsh가 설치되어 있지 않습니다."
  echo "Windows Git Bash에 zsh를 설치하려면 다음 단계를 따르세요:"
  echo "  1. https://packages.msys2.org/package/zsh?repo=msys&variant=x86_64 에서 최신버전 .tar.zst 다운로드"
  echo "  2. 해당 파일의 압축을 풀어 Git 설치 경로(C:\Program Files\Git)에 덮어쓰기"
  echo "  (압축 해제 시 usr 폴더가 겹치도록 하면 됩니다.)"
  exit 1
fi

# 2. Oh My Zsh 설치 확인 및 자동 설치
if [ ! -d "${HOME}/.oh-my-zsh" ]; then
  echo "⏳ Oh My Zsh가 없습니다. 설치를 시작합니다..."
  # --unattended: 설치 후 자동으로 zsh를 실행하지 않음
  # --keep-zshrc: 기존 .zshrc를 덮어쓰지 않음
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  echo "✅ Oh My Zsh 설치 완료!"
fi

# 3. bash 실행 시 zsh로 자동 전환 설정
BASHRC="${HOME}/.bashrc"
ZSH_SWITCH_CODE='if [ -t 0 ] && command -v zsh >/dev/null 2>&1; then
  exec zsh
fi'

if [ ! -f "$BASHRC" ] || ! grep -q "exec zsh" "$BASHRC"; then
  printf "\n# Auto-switch to zsh\n%s\n" "$ZSH_SWITCH_CODE" >> "$BASHRC"
  echo "✅ ${BASHRC}에 zsh 자동 전환 설정 추가됨"
fi

ZSHRC="${HOME}/.zshrc"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 4. Powerlevel10k 설정
# 테마 클론 (이미 있으면 스킵)
if [ ! -d "${HOME}/powerlevel10k" ]; then
  echo "⏳ Powerlevel10k 다운로드 중..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${HOME}/powerlevel10k"
fi

# p10k 설정 파일 복사
if [ -f "${SCRIPT_DIR}/.p10k.zsh" ]; then
  cp "${SCRIPT_DIR}/.p10k.zsh" "${HOME}/.p10k.zsh"
  echo "✅ .p10k.zsh 설정 파일 복사 완료"
  
  # .zshrc 상단에 p10k 설정 로드 추가 (없을 때만)
  P10K_INST="[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh"
  if ! grep -q "p10k.zsh" "$ZSHRC"; then
    # 파일 맨 앞에 추가하기 위해 임시 파일 사용
    echo "$P10K_INST" | cat - "$ZSHRC" > "${ZSHRC}.tmp" && mv "${ZSHRC}.tmp" "$ZSHRC"
  fi
fi

# .zshrc에 테마 적용 (ZSH_THEME 설정이 있으면 변경, 없으면 추가)
if grep -q "^ZSH_THEME=" "$ZSHRC"; then
  sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"
else
  # ZSH_THEME 설정이 아예 없으면 source 방식으로 추가 (이미 init.sh 하단에 있는 로직과 겹치지 않게 주의)
  if ! grep -q "powerlevel10k.zsh-theme" "$ZSHRC"; then
    echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >> "$ZSHRC"
  fi
fi

TARGET="${SCRIPT_DIR}/main.sh"

# 이전 버전들 정리를 위한 패턴들
SUBPATH="${TARGET#${HOME}}"
OLD_PATTERNS=(
  "[ -f \"${TARGET}\" ] && source \"${TARGET}\""
  "[ -f \"\\$HOME${SUBPATH}\" ] && source \"\\$HOME${SUBPATH}\""
  '[ -f "./main.sh" ] && source "./main.sh"'
)

# 현재 디렉토리 기준으로 절대 경로 결정
CURRENT_PWD="$(pwd -P)"
if [[ -f "${CURRENT_PWD}/main.sh" ]]; then
  FINAL_TARGET="${CURRENT_PWD}/main.sh"
else
  FINAL_TARGET="${TARGET}"
fi

LINE_TO_ADD="[ -f \"${FINAL_TARGET}\" ] && source \"${FINAL_TARGET}\""

# ~/.zshrc 파일 존재 확인
touch "${ZSHRC}"

# 기존 항목들 제거
temp_file="${ZSHRC}.tmp"
cp "${ZSHRC}" "${temp_file}"

for pattern in "${OLD_PATTERNS[@]}"; do
  grep -Fvx "${pattern}" "${temp_file}" > "${temp_file}.new" || true
  mv "${temp_file}.new" "${temp_file}"
done

mv "${temp_file}" "${ZSHRC}"

# 새 항목 추가 (중복 확인)
if ! grep -Fqx "${LINE_TO_ADD}" "${ZSHRC}"; then
  printf '\n%s\n' "${LINE_TO_ADD}" >> "${ZSHRC}"
  echo "✅ ${ZSHRC}에 추가됨: ${LINE_TO_ADD}"
else
  echo "✅ 이미 ${ZSHRC}에 존재함"
fi

# zsh 환경에서 즉시 적용
if [ -n "${ZSH_VERSION-}" ]; then
  source "${ZSHRC}"
  echo "설정이 현재 세션에 적용되었습니다"
else
  echo "zsh를 시작하고 'source \"${ZSHRC}\"'를 실행하여 변경사항을 적용하세요"
fi