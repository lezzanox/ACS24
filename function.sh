#!/bin/bash

perform_system_update_and_upgrade() {
  echo -e "\n${BOLD}Memperbarui dan meningkatkan paket sistem (update & upgrade)...${NC}"
  echo "${YELLOW}Proses ini mungkin memakan waktu beberapa menit, tergantung koneksi internet dan jumlah pembaruan.${NC}"
  apt-get update -y
  apt-get upgrade -y
  echo -e "\n${GREEN}Pembaruan dan peningkatan sistem selesai.${NC}"
}

prepare_system_dependencies() {
  local packages_to_check=("gnupg" "jq" "uuid-runtime" "curl" "wget" "tar" "ca-certificates")
  local packages_to_install=()

  echo -e "\n${BOLD}Memeriksa dependensi sistem dasar...${NC}"

  for pkg in "${packages_to_check[@]}"; do
    if ! dpkg -s "$pkg" &>/dev/null; then
      packages_to_install+=("$pkg")
    fi
  done

  if [ ${#packages_to_install[@]} -gt 0 ]; then
    echo "${YELLOW}Menginstal paket: ${packages_to_install[*]}${NC}"
    apt-get update -y
    apt-get install -y "${packages_to_install[@]}" --no-install-recommends
    echo "${GREEN}Dependensi dasar telah dipenuhi.${NC}"
  else
    echo "${GREEN}Dependensi dasar sudah lengkap.${NC}"
  fi
}

run_environment_setup() {
  echo -e "\n${BOLD}Memeriksa lingkungan sistem...${NC}"
  . /etc/os-release

  detect_platform_type
  detect_system_environment

  echo "${GREEN}OS: ${ID^} ${VERSION_ID} ($VERSION_CODENAME), Arsitektur: ${ARCH}, Platform: ${PLATFORM_TYPE}.${NC}"

  case "$ID/$VERSION_CODENAME" in
    "debian/buster" | "debian/bullseye" | "ubuntu/bionic" | "ubuntu/focal" | "ubuntu/noble")
      supported=true
      ;;
    *)
      echo "${RED}OS Anda (${ID^} ${VERSION_CODENAME}) belum terverifikasi sepenuhnya. Lanjutkan dengan risiko Anda sendiri.${NC}"
      ;;
  esac

  echo -e "\n${BOLD}Menentukan versi MongoDB dan Node.js...${NC}"

  export MONGO_REPO_SERIES="7.0"
  export MONGO_INSTALL_VERSION="7.0.11"
  export NODE_REQUIRED_VERSION="20"

  echo "${GREEN}Target: Node.js v${NODE_REQUIRED_VERSION}, MongoDB v${MONGO_INSTALL_VERSION}${NC}"
}

detect_platform_type() {
  ARCH=$(uname -m | sed "s/aarch64/arm64/; s/x86_64/amd64/")
  export ARCH

  if [ "$ARCH" == "amd64" ]; then
    export PLATFORM_TYPE="amd64"
  elif [ "$ARCH" == "arm64" ] && [ -f /etc/armbian-release ] && grep -q "150balbes" /etc/armbian-release; then
    export PLATFORM_TYPE="stb_armbian"
  else
    export PLATFORM_TYPE="unsupported_arm"
  fi
}

detect_system_environment() {
  local env_type="Tidak diketahui"
  if command -v pveversion &>/dev/null; then
    env_type="Proxmox VE"
  elif command -v systemd-detect-virt &>/dev/null; then
    local virt_type
    virt_type=$(systemd-detect-virt 2>/dev/null || true)
    case "$virt_type" in
      kvm|qemu) env_type="KVM / QEMU" ;;
      vmware) env_type="VMware" ;;
      oracle) env_type="VirtualBox" ;;
      lxc|docker|rkt) env_type="Container ($virt_type)" ;;
      none|"") env_type="Mesin Fisik" ;;
      *) env_type="Virtual ($virt_type)" ;;
    esac
  fi
  export SYSTEM_ENVIRONMENT=$env_type
  echo "${GREEN}Lingkungan Sistem: ${SYSTEM_ENVIRONMENT}.${NC}"
}
