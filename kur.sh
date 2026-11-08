#!/bin/zsh
# Mac baslangici: bu dosya acik depoda durur, icinde kullanici ve depo adindan baskasi yok.
# Calistirma (boru ile degil: giris adimlari klavyeyi okur):
#   zsh -c "$(curl -fsSL https://raw.githubusercontent.com/mulvib-ship-it/claude-setup-basla/main/kur.sh)"
# Tekrar calistirilabilir: olani atlar, yerel degisiklige dokunmaz.

KULLANICI=mulvib-ship-it
DEPO=claude-setup
HEDEF="$HOME/MyTools/$DEPO"

dur() {
  print -r -- "HATA: $1"
  exit 1
}

[[ "$(uname)" == Darwin ]] || dur "Bu betik yalniz Mac icindir."

if ! command -v brew >/dev/null; then
  print -r -- "Homebrew kuruluyor; sifreniz istenebilir."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
    || dur "Homebrew kurulamadi."
fi
for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  [[ -x "$b" ]] && eval "$("$b" shellenv)"
done
command -v brew >/dev/null || dur "Homebrew bulunamadi."

for paket in git gh python; do
  brew list --formula "$paket" >/dev/null 2>&1 || brew install "$paket" || dur "$paket kurulamadi."
done

if ! gh auth status >/dev/null 2>&1; then
  print -r -- "GitHub girisi: tarayicida onaylayin."
  gh auth login --hostname github.com --git-protocol https --web || dur "GitHub girisi olmadi."
fi
gh auth setup-git || dur "Git, GitHub girisine baglanamadi."

if [[ -d "$HEDEF/.git" ]]; then
  git -C "$HEDEF" pull --ff-only || print -r -- "Uyari: depo guncellenemedi, eldeki surumle devam."
else
  mkdir -p "${HEDEF:h}" || dur "$HEDEF acilamadi."
  git clone "https://github.com/$KULLANICI/$DEPO.git" "$HEDEF" || dur "Depo alinamadi."
  YENI_KLON=1
fi

python3 "$HEDEF/kurucu/kur.py" --uygula

# Yeni ev bilgisayari: eski evin kendi degisikliklerini `ev` dalindan geri al.
# kur.py'den sonra: git kimligi ancak o zaman ayarli. Gelenler icin kur.py bir daha.
if [[ -n "$YENI_KLON" ]]; then
  if python3 "$HEDEF/kurucu/esitle.py" ev-al; then
    python3 "$HEDEF/kurucu/kur.py" --uygula
  else
    print -r -- "Uyari: ev dali alinamadi; yukaridaki sonuca bakin."
  fi
fi
