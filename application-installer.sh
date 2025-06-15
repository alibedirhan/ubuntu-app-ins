#!/bin/bash

# Ubuntu Program Kurulum Yöneticisi - Zenity GUI Version v2.2
# Kritik hatalar, yapısal ve performans sorunları düzeltilmiş versiyon

# Hata yönetimi - sadece undefined variables için strict mode
set -u

# Temel değişkenler
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/kurulum.log"
TEMP_DIR="/tmp/ubuntu-installer-$$"  # PID ile unique temp dizin
APT_UPDATED=false  # apt update kontrolü için

# Cleanup fonksiyonu
cleanup() {
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT

# Temp dizini oluştur
mkdir -p "$TEMP_DIR"

# Paket açıklamaları - Merkezi yönetim
declare -A PACKAGE_DESCRIPTIONS=(
    ["git"]="Git Versiyon Kontrol"
    ["curl"]="URL Transfer Aracı"
    ["wget"]="Web Dosya İndirici"
    ["vim"]="Gelişmiş Metin Editörü"
    ["build-essential"]="Temel Geliştirme Araçları"
    ["python3-pip"]="Python Paket Yöneticisi"
    ["nodejs"]="Node.js JavaScript Runtime"
    ["code"]="Visual Studio Code"
    ["vlc"]="VLC Media Player"
    ["gimp"]="GIMP Görüntü Editörü"
    ["firefox"]="Firefox Web Tarayıcısı"
    ["audacity"]="Ses Düzenleme Programı"
    ["spotify"]="Spotify Müzik Uygulaması"
    ["discord"]="Discord İletişim Uygulaması"
    ["htop"]="Sistem Monitörü"
    ["neofetch"]="Sistem Bilgi Gösterici"
    ["tree"]="Dizin Ağacı Gösterici"
    ["unzip"]="ZIP Arşiv Açıcı"
    ["gparted"]="Disk Bölümleme Aracı"
    ["synaptic"]="Grafik Paket Yöneticisi"
    ["ufw"]="Güvenlik Duvarı"
    ["libreoffice"]="LibreOffice Ofis Paketi"
    ["thunderbird"]="Thunderbird E-posta İstemcisi"
    ["evince"]="PDF Görüntüleyici"
    ["flameshot"]="Ekran Görüntüsü Aracı"
    ["telegram-desktop"]="Telegram Masaüstü"
)

# Paket kurulum yöntemleri - Merkezi yönetim
declare -A PACKAGE_DEFAULT_METHODS=(
    ["git"]="apt"
    ["curl"]="apt"
    ["wget"]="apt"
    ["vim"]="apt"
    ["htop"]="apt"
    ["tree"]="apt"
    ["unzip"]="apt"
    ["gparted"]="apt"
    ["firefox"]="apt"
    ["libreoffice"]="apt"
    ["thunderbird"]="apt"
    ["evince"]="apt"
    ["flameshot"]="apt"
    ["audacity"]="apt"
    ["gimp"]="apt"
    ["build-essential"]="apt"
    ["python3-pip"]="apt"
    ["neofetch"]="apt"
    ["synaptic"]="apt"
    ["ufw"]="apt"
    ["vlc"]="apt"
    ["spotify"]="snap"
    ["discord"]="snap"
    ["telegram-desktop"]="snap"
    ["code"]="special"
    ["nodejs"]="special"
)

# Zenity kontrolü
check_zenity() {
    if ! command -v zenity >/dev/null 2>&1; then
        echo "Zenity kuruluyor..."
        sudo apt-get update >/dev/null 2>&1
        sudo apt-get install -y zenity >/dev/null 2>&1
    fi
}

# Log fonksiyonları - Geliştirilmiş
log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1" >> "$LOG_FILE"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" >> "$LOG_FILE"
}

log_success() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SUCCESS] $1" >> "$LOG_FILE"
}

# Dialog fonksiyonları
show_error() {
    zenity --error --title="Hata" --text="$1" --width=400
    log_error "$1"
}

show_info() {
    zenity --info --title="Bilgi" --text="$1" --width=400
    log_info "$1"
}

ask_confirmation() {
    zenity --question --title="Onay" --text="$1" --width=400
}

# APT update fonksiyonu - Tekrarı önler
update_apt_if_needed() {
    if [[ "$APT_UPDATED" == "false" ]]; then
        log_info "APT paket listesi güncelleniyor..."
        if sudo apt-get update >/dev/null 2>&1; then
            APT_UPDATED=true
            return 0
        else
            return 1
        fi
    fi
    return 0
}

# Güvenli sudo kontrolü
check_sudo_access() {
    if ! sudo -n true 2>/dev/null; then
        # Zenity password dialog ile 3 deneme hakkı
        local attempts=0
        while [[ $attempts -lt 3 ]]; do
            if zenity --password --title="Yönetici Şifresi Gerekli" | sudo -S true 2>/dev/null; then
                return 0
            fi
            ((attempts++))
            if [[ $attempts -lt 3 ]]; then
                zenity --error --text="Hatalı şifre. $((3-attempts)) deneme hakkınız kaldı." --width=300
            fi
        done
        return 1
    fi
    return 0
}

# Sistem kontrolü - İyileştirilmiş
check_system() {
    local check_passed=true
    
    (
        echo "10" ; echo "# Sudo yetkileri kontrol ediliyor..."
        sleep 0.5
        
        if ! check_sudo_access; then
            check_passed=false
            echo "100"
            exit 1
        fi
        
        echo "40" ; echo "# İnternet bağlantısı kontrol ediliyor..."
        sleep 0.5
        if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
            check_passed=false
            echo "100"
            exit 1
        fi
        
        echo "70" ; echo "# Paket veritabanı güncelleniyor..."
        if ! update_apt_if_needed; then
            check_passed=false
            echo "100"
            exit 1
        fi
        
        echo "100" ; echo "# Sistem kontrolü tamamlandı"
        sleep 0.5
    ) | zenity --progress \
        --title="Sistem Kontrolü" \
        --text="Başlatılıyor..." \
        --width=400 \
        --auto-close \
        --no-cancel || true
    
    if [[ $? -ne 0 ]] && [[ "$check_passed" == "false" ]]; then
        show_error "Sistem kontrolü başarısız!"
        exit 1
    fi
    
    log_info "Sistem kontrolü tamamlandı"
}

# Kurulum tercihi seçimi
select_installation_preference() {
    local preference=$(zenity --list \
        --title="Kurulum Tercihi" \
        --text="🛠️ Programlar nasıl kurulsun?" \
        --radiolist \
        --column="Seç" \
        --column="Yöntem" \
        --column="Açıklama" \
        --width=700 \
        --height=400 \
        TRUE "auto" "🤖 Otomatik (Önerilen) - Her program en uygun yöntemle kurulur" \
        FALSE "apt_only" "📦 Sadece APT - Hızlı ve güvenilir Ubuntu paketleri" \
        FALSE "prefer_snap" "🔄 Snap Öncelikli - Modern ve güncel sürümler" \
        FALSE "manual" "⚙️ Manuel Kontrol - Her program için ayrı seçim" 2>/dev/null)
    
    if [[ -z "$preference" ]]; then
        return 1
    fi
    
    case "$preference" in
        "auto")
            show_info "🤖 OTOMATİK MOD SEÇİLDİ

• Her program en uygun yöntemle kurulur
• Hızlı ve güvenilir seçenekler öncelikli
• Manuel müdahale gerekmez

Örnek:
• Git, VLC → APT (hızlı)
• Spotify, Discord → Snap (güncel)
• VS Code → Özel kurulum (en stabil)"
            ;;
        "apt_only")
            show_info "📦 SADECE APT MOD SEÇİLDİ

• Tüm programlar Ubuntu deposundan kurulur
• En hızlı kurulum
• En az disk kullanımı
• Bazen eski sürümler olabilir"
            ;;
        "prefer_snap")
            show_info "🔄 SNAP ÖNCELİKLİ MOD SEÇİLDİ

• Mümkün olan programlar Snap ile kurulur
• Her zaman güncel sürümler
• Daha fazla disk kullanımı
• İzole ve güvenli kurulum"
            ;;
        "manual")
            show_info "⚙️ MANUEL KONTROL MOD SEÇİLDİ

• Her program için kurulum yöntemi sorulacak
• Tam kontrol sizde
• Daha uzun kurulum süreci
• İleri kullanıcılar için ideal"
            ;;
    esac
    
    echo "$preference"
}

# Kurulum modu seçimi
select_installation_mode() {
    local mode=$(zenity --list \
        --title="Kurulum Modu Seçimi" \
        --text="🎯 Kategorilerdeki programlar nasıl kurulsun?" \
        --radiolist \
        --column="Seç" \
        --column="Mod" \
        --column="Açıklama" \
        --width=650 \
        --height=350 \
        TRUE "full" "⚡ Kategori Dolu - Seçilen kategorilerdeki TÜM programları kur" \
        FALSE "selective" "🔍 Seçmeli - Her kategoride hangi programları kuracağını seç" 2>/dev/null)
    
    if [[ -z "$mode" ]]; then
        return 1
    fi
    
    case "$mode" in
        "full")
            show_info "⚡ KATEGORİ DOLU MOD SEÇİLDİ

• Seçilen kategorilerdeki TÜM programlar kurulur
• En hızlı ve kolay yöntem
• Yeni kullanıcılar için ideal

📦 Kurulacak program sayısı fazla olabilir."
            ;;
        "selective")
            show_info "🔍 SEÇMELİ MOD SEÇİLDİ

• Her kategori için hangi programları kuracağınızı seçebilirsiniz
• Tam kontrol ve esneklik
• İleri kullanıcılar için ideal

⏱️ Her kategori için ayrı seçim penceresi açılacak."
            ;;
    esac
    
    echo "$mode"
}

# Kategori seçimi
select_categories() {
    local categories=$(zenity --list \
        --title="Kategori Seçimi" \
        --text="Kurmak istediğiniz kategorileri seçin:" \
        --checklist \
        --column="Seç" \
        --column="Kategori" \
        --column="Açıklama" \
        --width=600 \
        --height=400 \
        --separator="|" \
        TRUE "development" "Geliştirici Araçları (Git, VS Code, Node.js)" \
        TRUE "multimedia" "Multimedya (VLC, GIMP, Spotify)" \
        TRUE "system" "Sistem Araçları (Htop, GParted, UFW)" \
        TRUE "office" "Ofis (LibreOffice, Thunderbird, Telegram)" 2>/dev/null)
    
    if [[ -z "$categories" ]]; then
        show_info "Hiçbir kategori seçilmedi. Ana menüye dönülüyor."
        return 1
    fi
    
    log_info "Seçilen kategoriler (select_categories): $categories"
    echo "$categories"
}

# Kurulum yöntemi belirleme - İyileştirilmiş
get_install_method() {
    local package="$1"
    local preference="$2"
    
    case "$preference" in
        "auto")
            echo "${PACKAGE_DEFAULT_METHODS[$package]:-apt}"
            ;;
        "apt_only")
            if [[ "${PACKAGE_DEFAULT_METHODS[$package]}" == "special" ]]; then
                echo "special"
            else
                echo "apt"
            fi
            ;;
        "prefer_snap")
            case "${PACKAGE_DEFAULT_METHODS[$package]}" in
                "special")
                    echo "special"
                    ;;
                "apt")
                    # Bazı paketler snap'te yoktur
                    if [[ "$package" =~ ^(build-essential|python3-pip|unzip|gparted|synaptic|ufw|evince)$ ]]; then
                        echo "apt"
                    else
                        echo "snap"
                    fi
                    ;;
                *)
                    echo "snap"
                    ;;
            esac
            ;;
        "manual")
            local method=$(zenity --list \
                --title="$package Kurulum Yöntemi" \
                --text="$package nasıl kurulsun?" \
                --radiolist \
                --column="Seç" \
                --column="Yöntem" \
                --column="Açıklama" \
                --width=600 \
                --height=300 \
                TRUE "apt" "📦 APT - Hızlı ve güvenilir" \
                FALSE "snap" "🔄 Snap - Güncel ve izole" 2>/dev/null)
            
            if [[ -z "$method" ]]; then
                echo "skip"
            else
                echo "$method"
            fi
            ;;
    esac
}

# Paket kurulu mu kontrolü - İyileştirilmiş
is_package_installed() {
    local package="$1"
    local method="$2"
    
    case "$method" in
        "apt")
            dpkg -s "$package" 2>/dev/null | grep -q "Status: install ok installed"
            ;;
        "snap")
            snap list 2>/dev/null | grep -q "^$package "
            ;;
        "special")
            case "$package" in
                "nodejs")
                    command -v node >/dev/null 2>&1
                    ;;
                "code")
                    command -v code >/dev/null 2>&1
                    ;;
            esac
            ;;
    esac
}

# VS Code kurulum fonksiyonu
install_vscode() {
    local vscode_list="/etc/apt/sources.list.d/vscode.list"
    local ms_gpg="/etc/apt/trusted.gpg.d/packages.microsoft.gpg"
    
    # Microsoft GPG anahtarını indir ve yükle
    if ! wget -qO- https://packages.microsoft.com/keys/microsoft.asc | \
         gpg --dearmor > "$TEMP_DIR/packages.microsoft.gpg" 2>/dev/null; then
        return 1
    fi
    
    if ! sudo install -o root -g root -m 644 "$TEMP_DIR/packages.microsoft.gpg" "$ms_gpg" 2>/dev/null; then
        return 1
    fi
    
    # Repository ekle
    echo "deb [arch=amd64,arm64,armhf signed-by=$ms_gpg] https://packages.microsoft.com/repos/code stable main" | \
        sudo tee "$vscode_list" >/dev/null
    
    # APT güncelle ve VS Code kur
    update_apt_if_needed
    sudo apt-get install -y code >/dev/null 2>&1
}

# Node.js kurulum fonksiyonu
install_nodejs() {
    # NodeSource repository ekle
    if ! curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - >/dev/null 2>&1; then
        return 1
    fi
    
    # Node.js kur
    sudo apt-get install -y nodejs >/dev/null 2>&1
}

# Paket kurulum fonksiyonu - İyileştirilmiş
install_package() {
    local package="$1"
    local description="${PACKAGE_DESCRIPTIONS[$package]:-$package}"
    local preference="$2"
    
    local method=$(get_install_method "$package" "$preference")
    
    if [[ "$method" == "skip" ]]; then
        echo "SKIP|$package kurulumu kullanıcı tarafından iptal edildi"
        return 0
    fi
    
    # Paket kurulu mu kontrol et
    if is_package_installed "$package" "$method"; then
        echo "SKIP|$package zaten kurulu ($method)"
        return 0
    fi
    
    # Kurulum yap
    case "$method" in
        "apt")
            update_apt_if_needed
            if sudo apt-get install -y "$package" >/dev/null 2>&1; then
                echo "SUCCESS|$package kuruldu (APT)"
                log_success "$package başarıyla kuruldu (APT)"
                return 0
            else
                echo "ERROR|$package kurulumunda hata (APT)"
                log_error "$package kurulamadı (APT)"
                return 1
            fi
            ;;
        "snap")
            if ! command -v snap >/dev/null 2>&1; then
                echo "ERROR|Snap kurulu değil"
                log_error "Snap kurulu değil"
                return 1
            fi
            
            if sudo snap install "$package" >/dev/null 2>&1; then
                echo "SUCCESS|$package kuruldu (Snap)"
                log_success "$package başarıyla kuruldu (Snap)"
                return 0
            else
                echo "ERROR|$package kurulumunda hata (Snap)"
                log_error "$package kurulamadı (Snap)"
                return 1
            fi
            ;;
        "special")
            case "$package" in
                "nodejs")
                    if install_nodejs; then
                        echo "SUCCESS|Node.js kuruldu (NodeSource)"
                        log_success "Node.js başarıyla kuruldu (NodeSource)"
                        return 0
                    else
                        echo "ERROR|Node.js kurulumunda hata"
                        log_error "Node.js kurulamadı"
                        return 1
                    fi
                    ;;
                "code")
                    if install_vscode; then
                        echo "SUCCESS|VS Code kuruldu (Microsoft)"
                        log_success "VS Code başarıyla kuruldu (Microsoft)"
                        return 0
                    else
                        echo "ERROR|VS Code kurulumunda hata"
                        log_error "VS Code kurulamadı"
                        return 1
                    fi
                    ;;
            esac
            ;;
    esac
}

# Kategori paket listesi
get_category_packages() {
    local category="$1"
    
    case "$category" in
        "development") 
            echo "git
curl
wget
vim
build-essential
python3-pip
nodejs
code"
            ;;
        "multimedia") 
            echo "vlc
gimp
firefox
audacity
spotify
discord"
            ;;
        "system")
            echo "htop
neofetch
tree
unzip
gparted
synaptic
ufw"
            ;;
        "office")
            echo "libreoffice
thunderbird
evince
flameshot
telegram-desktop"
            ;;
    esac
}

# Kategori adı al
get_category_name() {
    local category="$1"
    
    case "$category" in
        "development") echo "Geliştirici Araçları" ;;
        "multimedia") echo "Multimedya Araçları" ;;
        "system") echo "Sistem Araçları" ;;
        "office") echo "Ofis Araçları" ;;
    esac
}

# Seçmeli paket seçimi
select_packages_in_category() {
    local category="$1"
    local category_name=$(get_category_name "$category")
    local packages=$(get_category_packages "$category")
    
    log_info "Paket seçim penceresi açılıyor: $category_name"
    
    local zenity_args=()
    while IFS= read -r package; do
        [[ -z "$package" ]] && continue
        local description="${PACKAGE_DESCRIPTIONS[$package]:-$package}"
        zenity_args+=(TRUE "$package" "$description")
    done <<< "$packages"
    
    local selected_packages=$(zenity --list \
        --title="$category_name - Paket Seçimi" \
        --text="🔽 $category_name kategorisinden kurmak istediğiniz programları seçin:" \
        --checklist \
        --column="Seç" \
        --column="Paket" \
        --column="Açıklama" \
        --width=700 \
        --height=500 \
        --separator="|" \
        "${zenity_args[@]}" 2>/dev/null)
    
    if [[ -z "$selected_packages" ]]; then
        show_info "❌ $category_name kategorisi için hiçbir paket seçilmedi. Bu kategori atlanıyor."
        return 1
    fi
    
    log_info "Seçilen paketler ($category_name): $selected_packages"
    echo "$selected_packages"
}

# Kategori kurulum fonksiyonu - Düzeltilmiş
install_category() {
    local category="$1"
    local preference="$2"
    local selected_packages="$3"
    local category_name=$(get_category_name "$category")
    
    # Kurulacak paketleri belirle
    local packages_to_install=()
    
    if [[ -n "$selected_packages" ]]; then
        # Seçmeli mod - seçilen paketleri kullan
        IFS='|' read -ra PACKAGE_ARRAY <<< "$selected_packages"
        for pkg in "${PACKAGE_ARRAY[@]}"; do
            [[ -n "$pkg" ]] && packages_to_install+=("$pkg")
        done
    else
        # Dolu mod - tüm paketleri al
        while IFS= read -r package; do
            [[ -n "$package" ]] && packages_to_install+=("$package")
        done <<< "$(get_category_packages "$category")"
    fi
    
    local total_packages=${#packages_to_install[@]}
    
    # Eğer kurulacak paket yoksa
    if [[ $total_packages -eq 0 ]]; then
        show_info "Bu kategoride kurulacak paket bulunamadı: $category_name"
        return 0
    fi
    
    # Kurulum onayı
    local package_list=""
    for package in "${packages_to_install[@]}"; do
        local description="${PACKAGE_DESCRIPTIONS[$package]:-$package}"
        package_list+="• $description\n"
    done
    
    if ! ask_confirmation "📦 $category_name KURULUM ONAYI

Kurulacak programlar:
$package_list
Toplam $total_packages paket kurulacak.
Devam edilsin mi?"; then
        show_info "❌ $category_name kurulumu iptal edildi."
        return 0
    fi
    
    # Kurulum sayaçları
    local success_count=0
    local skip_count=0
    local error_count=0
    local results_file="$TEMP_DIR/install_results_$"
    
    # Progress bar ile kurulum
    (
        for i in "${!packages_to_install[@]}"; do
            local current_package=$((i + 1))
            local percentage=$((current_package * 100 / total_packages))
            local package="${packages_to_install[$i]}"
            local description="${PACKAGE_DESCRIPTIONS[$package]:-$package}"
            
            echo "$percentage"
            echo "# $description kuruluyor... ($current_package/$total_packages)"
            
            # Kurulum yap ve sonucu dosyaya yaz
            local install_result
            if install_result=$(install_package "$package" "$preference" 2>&1); then
                echo "$install_result" >> "$results_file"
            else
                echo "ERROR|$package kurulumunda hata" >> "$results_file"
            fi
            
            sleep 0.5
        done
        
        echo "100"
        echo "# $category_name kurulumu tamamlandı"
        sleep 1
    ) | zenity --progress \
        --title="$category_name Kuruluyor" \
        --text="Başlatılıyor..." \
        --width=500 \
        --auto-close || true
    
    # Sonuçları oku ve say
    if [[ -f "$results_file" ]]; then
        while IFS='|' read -r status message; do
            case "$status" in
                "SUCCESS") ((success_count++)) ;;
                "SKIP") ((skip_count++)) ;;
                "ERROR") ((error_count++)) ;;
            esac
        done < "$results_file"
        rm -f "$results_file"
    fi
    
    # Sonuç raporu
    local report="$category_name Kurulum Raporu:\n\n"
    report+="✅ Başarılı: $success_count\n"
    report+="⏭️ Zaten kurulu: $skip_count\n"
    report+="❌ Hatalı: $error_count\n\n"
    report+="Toplam: $total_packages paket"
    
    show_info "$report"
    return 0
}

# Ana kurulum fonksiyonu
main_installation() {
    local selected_categories="$1"
    
    # Debug log
    log_info "Seçilen kategoriler: $selected_categories"
    
    # Kurulum tercihi seç
    local preference
    preference=$(select_installation_preference)
    if [[ -z "$preference" ]]; then
        show_info "❌ KURULUM İPTAL EDİLDİ

Kurulum tercihi seçilmediği için işlem iptal edildi.
Ana menüye dönülüyor..."
        return
    fi
    
    log_info "Kurulum tercihi: $preference"
    
    # Kurulum modu seç
    local installation_mode
    installation_mode=$(select_installation_mode)
    if [[ -z "$installation_mode" ]]; then
        show_info "❌ KURULUM İPTAL EDİLDİ

Kurulum modu seçilmediği için işlem iptal edildi.
Ana menüye dönülüyor..."
        return
    fi
    
    log_info "Kurulum modu: $installation_mode"
    
    # Kategorileri işle
    IFS='|' read -ra CATEGORY_ARRAY <<< "$selected_categories"
    
    for category in "${CATEGORY_ARRAY[@]}"; do
        if [[ -n "$category" ]]; then
            log_info "İşlenen kategori: $category"
            
            if [[ "$installation_mode" == "selective" ]]; then
                # Seçmeli mod - paket seçimi yap
                log_info "Seçmeli mod aktif, paket seçim penceresi açılıyor: $category"
                local selected_packages
                selected_packages=$(select_packages_in_category "$category")
                if [[ -n "$selected_packages" ]]; then
                    log_info "Seçilen paketler: $selected_packages"
                    install_category "$category" "$preference" "$selected_packages"
                else
                    log_info "Kategori için paket seçilmedi: $category"
                fi
            else
                # Dolu mod - tüm paketleri kur
                log_info "Dolu mod aktif, tüm paketler kurulacak: $category"
                install_category "$category" "$preference" ""
            fi
        fi
    done
    
    show_info "🎉 TÜM KURULUMLAR TAMAMLANDI!

📊 Kurulum bilgileri:
• Mod: $(case "$installation_mode" in "full") echo "⚡ Kategori Dolu";; "selective") echo "🔍 Seçmeli";; esac)
• Yöntem: $(case "$preference" in
    "auto") echo "🤖 Otomatik";;
    "apt_only") echo "📦 Sadece APT";;
    "prefer_snap") echo "🔄 Snap Öncelikli";;
    "manual") echo "⚙️ Manuel Kontrol";;
esac)

📄 Detaylı log dosyası: $LOG_FILE
💡 Programları masaüstünden veya menüden bulabilirsiniz.

🔄 Ana menüye dönülüyor..."
}

# Paket listesi bilgi
show_package_list_info() {
    zenity --info \
        --title="Paket Listesi Nedir?" \
        --width=600 \
        --height=400 \
        --text="📦 PAKET LİSTESİ NEDİR?

Bu özellik, bilgisayarınızdaki programları kaydetmenizi ve başka bir bilgisayara aynı programları kurmanızı sağlar.

🎯 NE İŞE YARAR?

✅ FORMAT SONRASI: Programlarınızı tek tek hatırlamaya gerek yok!
✅ YENİ BİLGİSAYAR: Eski bilgisayarınızdaki tüm programları yeni bilgisayara kurun
✅ YEDEKLEME: Programlarınızın listesini güvenli bir yerde saklayın
✅ EKİP ÇALIŞMASI: Aynı programları takım arkadaşlarınızla paylaşın

📝 NASIL KULLANILIR?

1. 'Oluştur' → Şu anda kurulu programların listesini kaydet
2. 'Geri Yükle' → Daha önce kaydedilen listeden programları kur

💡 ÖNERİ: Format atmadan önce mutlaka paket listesi oluşturun!"
}

# Paket listesi yönetimi
manage_package_lists() {
    while true; do
        if ask_confirmation "Paket listesi özelliği hakkında bilgi almak ister misiniz?"; then
            show_package_list_info
        fi
        
        local choice=$(zenity --list \
            --title="Paket Listesi Yönetimi" \
            --text="💾 Yapmak istediğiniz işlemi seçin:" \
            --radiolist \
            --column="Seç" \
            --column="İşlem" \
            --column="Açıklama" \
            --width=700 \
            --height=350 \
            TRUE "create" "📋 Mevcut programların listesini oluştur (Yedekleme)" \
            FALSE "restore" "📥 Paket listesinden programları kur (Geri Yükleme)" \
            FALSE "info" "ℹ️ Paket listesi hakkında detaylı bilgi" \
            FALSE "back" "🔙 Ana menüye dön" 2>/dev/null)
        
        if [[ -z "$choice" ]] || [[ "$choice" == "back" ]]; then
            return
        fi
        
        case "$choice" in
            "create")
                if ask_confirmation "📋 PAKET LİSTESİ OLUŞTURMA

Bu işlem, şu anda bilgisayarınızda kurulu olan TÜM programların listesini bir dosyaya kaydeder.

🎯 Ne zaman kullanılır?
• Format atmadan önce
• Yeni bilgisayar almadan önce
• Program yedeklemesi için

Devam edilsin mi?"; then
                    
                    local save_path=$(zenity --file-selection \
                        --title="Paket listesini nereye kaydetmek istiyorsunuz?" \
                        --save \
                        --filename="$HOME/benim-programlarim-$(date +%Y%m%d).txt" 2>/dev/null)
                    
                    if [[ -n "$save_path" ]]; then
                        (
                            echo "50" ; echo "# Kurulu programlar taranıyor..."
                            sleep 1
                            dpkg --get-selections | grep -v deinstall > "$save_path"
                            echo "100" ; echo "# Liste oluşturuldu"
                            sleep 1
                        ) | zenity --progress \
                            --title="Paket Listesi Oluşturuluyor" \
                            --text="İşlem başlatılıyor..." \
                            --width=400 \
                            --auto-close 2>/dev/null
                        
                        local file_size=$(wc -l < "$save_path")
                        show_info "✅ BAŞARILI!

📄 Dosya: $(basename "$save_path")
📍 Konum: $save_path
📊 Toplam program sayısı: $file_size

💡 Bu dosyayı güvenli bir yerde saklayın!"
                    fi
                fi
                ;;
            "restore")
                if ask_confirmation "📥 PAKET LİSTESİNDEN KURULUM

Bu işlem, daha önce kaydedilmiş bir paket listesindeki TÜM programları bilgisayarınıza kurar.

⚠️ DİKKAT:
• Bu işlem uzun sürebilir
• İnternet bağlantısı gereklidir
• Bazı programlar kurulmayabilir (artık mevcut değilse)

Devam edilsin mi?"; then
                    
                    local list_file=$(zenity --file-selection \
                        --title="Hangi paket listesi dosyasını kullanmak istiyorsunuz?" \
                        --file-filter="Metin dosyaları (*.txt) | *.txt" 2>/dev/null)
                    
                    if [[ -n "$list_file" && -f "$list_file" ]]; then
                        local package_count=$(wc -l < "$list_file")
                        
                        if ask_confirmation "📋 SEÇİLEN LİSTE BİLGİLERİ:

📄 Dosya: $(basename "$list_file")
📊 Program sayısı: $package_count

Bu listedeki tüm programlar kurulacak. 
Bu işlem uzun sürebilir.

Kuruluma başlansın mı?"; then
                            
                            (
                                echo "25" ; echo "# Paket listesi okunuyor..."
                                sleep 1
                                sudo dpkg --set-selections < "$list_file"
                                echo "50" ; echo "# Paket veritabanı güncelleniyor..."
                                sleep 1
                                update_apt_if_needed
                                echo "75" ; echo "# Programlar kuruluyor... (Bu uzun sürebilir)"
                                sudo apt-get dselect-upgrade -y >/dev/null 2>&1
                                echo "100" ; echo "# Kurulum tamamlandı"
                                sleep 1
                            ) | zenity --progress \
                                --title="Paket Listesinden Kurulum Yapılıyor" \
                                --text="İşlem başlatılıyor..." \
                                --width=450 \
                                --auto-close 2>/dev/null
                            
                            show_info "✅ KURULUM TAMAMLANDI!

📋 Liste: $(basename "$list_file")
📊 İşlenen program: $package_count

💡 Bazı programlar kurulmamış olabilir (artık mevcut değil).
Detaylar için log dosyasını kontrol edin."
                        fi
                    fi
                fi
                ;;
            "info")
                show_package_list_info
                ;;
        esac
    done
}

# Log görüntüleme
show_log() {
    if [[ -f "$LOG_FILE" ]]; then
        zenity --text-info \
            --title="Kurulum Logları" \
            --filename="$LOG_FILE" \
            --width=800 \
            --height=600 \
            --ok-label="Kapat" 2>/dev/null || true
    else
        show_info "Henüz log dosyası oluşturulmamış."
    fi
}

# Yardım
show_help() {
    zenity --info \
        --title="Ubuntu Program Kurulum Yöneticisi - Yardım" \
        --width=700 \
        --height=500 \
        --text="🚀 UBUNTU PROGRAM KURULUM YÖNETİCİSİ

Bu program, Ubuntu'ya kolayca program kurmanızı sağlar.

📦 PROGRAM KURULUMU:
• Kategoriler halinde düzenlenmiş programlar
• Geliştirici, Multimedya, Sistem, Ofis kategorileri
• İki kurulum modu: Kategori Dolu ve Seçmeli

💾 PAKET LİSTESİ ÖZELLİĞİ:
• Kurulu programlarınızı yedekleyin
• Format sonrası aynı programları geri kurun
• Takım arkadaşlarınızla program listesi paylaşın

📋 KATEGORİLER:

🔧 GELİŞTİRİCİ ARAÇLARI:
Git, VS Code, Node.js, Python, Vim

🎵 MULTİMEDYA:
VLC, GIMP, Spotify, Discord, Firefox

⚙️ SİSTEM ARAÇLARI:
Htop, GParted, UFW, Synaptic

📄 OFİS ARAÇLARI:
LibreOffice, Thunderbird, Telegram

🎯 KURULUM MODLARI:

⚡ KATEGORİ DOLU: Seçilen kategorilerdeki tüm programları kur
🔍 SEÇMELİ: Her kategoride hangi programları kuracağını seç

💡 İPUÇLARI:
• Format atmadan önce paket listesi oluşturun
• Kurulum loglarını kontrol edin
• Hata durumunda programı yeniden başlatın"
}

# Ana menü
main_menu() {
    while true; do
        local choice=$(zenity --list \
            --title="Ubuntu Program Kurulum Yöneticisi v2.2" \
            --text="🚀 Yapmak istediğiniz işlemi seçin:" \
            --radiolist \
            --column="Seç" \
            --column="İşlem" \
            --column="Açıklama" \
            --width=750 \
            --height=450 \
            TRUE "install" "📦 Program kurulumu yap" \
            FALSE "package_list" "💾 Paket listesi işlemleri (Yedekleme/Geri Yükleme)" \
            FALSE "show_log" "📄 Kurulum loglarını görüntüle" \
            FALSE "help" "❓ Yardım ve bilgilendirme" \
            FALSE "exit" "🚪 Programdan çık" 2>/dev/null)
        
        if [[ -z "$choice" ]]; then
            # Kullanıcı X butonuna bastı
            if ask_confirmation "Programdan çıkmak istediğinizden emin misiniz?"; then
                log_info "Program sonlandırıldı (X butonu)"
                exit 0
            fi
            continue
        fi
        
        case "$choice" in
            "install")
                local categories
                if categories=$(select_categories); then
                    main_installation "$categories"
                fi
                # Kurulum bittikten sonra ana menüye dön
                ;;
            "package_list")
                manage_package_lists
                ;;
            "show_log")
                show_log
                ;;
            "help")
                show_help
                ;;
            "exit")
                if ask_confirmation "Programdan çıkmak istediğinizden emin misiniz?"; then
                    log_info "Program sonlandırıldı"
                    exit 0
                fi
                ;;
        esac
    done
}

# Ana program
main() {
    # Root kontrolü
    if [[ $EUID -eq 0 ]]; then
        zenity --error --title="Hata" --text="Bu program root kullanıcısı ile çalıştırılamaz!"
        exit 1
    fi
    
    # Log dosyasını başlat
    > "$LOG_FILE"
    log_info "Program başlatıldı - v2.2"
    log_info "Sistem: $(lsb_release -d | cut -f2)"
    log_info "Kullanıcı: $USER"
    
    # Zenity kontrolü
    check_zenity
    
    # Sistem kontrolü
    check_system
    
    # Ana menüyü başlat
    main_menu
}

# Programı başlat
main "$@"