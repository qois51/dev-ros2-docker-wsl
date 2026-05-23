# Panduan Lengkap & Komprehensif: Pengembangan VTOL Autonomous (Untuk Pemula)

Selamat datang di repositori pengembangan **Autonomous Vertical Take-Off and Landing (VTOL)**! Repositori ini dirancang khusus untuk memfasilitasi Anda yang baru memulai belajar pemrograman drone autonomous menggunakan **ROS2**, **Docker**, dan **WSL2** di sistem operasi Windows.

Dengan metode kontainerisasi (Docker), Anda tidak perlu khawatir merusak sistem komputer Anda atau pusing menginstal puluhan dependensi robotika yang rumit. Semuanya sudah dikemas rapi dan siap dijalankan.

---

## Daftar Isi
1. [Konsep Dasar Bagi Pemula](#1-konsep-dasar-bagi-pemula)
2. [Prasyarat & Persiapan Sistem Windows](#2-prasyarat--persiapan-sistem-windows)
3. [Arsitektur Sistem (Bagaimana Semua Saling Terhubung)](#3-arsitektur-sistem-bagaimana-semua-saling-terhubung)
4. [Panduan Instalasi Langkah-demi-Langkah (Zero to Hero)](#4-panduan-instalasi-langkah-demi-langkah-zero-to-hero)
   - [Langkah 1: Setup WSL2 & WSLg](#langkah-1-setup-wsl2--wslg)
   - [Langkah 2: Instalasi Docker Engine (Native di WSL)](#langkah-2-instalasi-docker-engine-native-di-wsl)
   - [Langkah 3: Instalasi NVIDIA Container Toolkit](#langkah-3-instalasi-nvidia-container-toolkit)
   - [Langkah 4: Membangun & Menjalankan Kontainer (dev_lite / dev_full)](#langkah-4-membangun--menjalankan-kontainer-dev_lite--dev_full)
   - [Langkah 5: Eksekusi dan Verifikasi](#langkah-5-eksekusi-dan-verifikasi)
5. [Alur Kerja Harian (Daily Workflow)](#5-alur-kerja-harian-daily-workflow)
6. [Struktur Direktori & Mekanisme Berbagi File (Volume Mount)](#6-struktur-direktori--mekanisme-berbagi-file-volume-mount)
7. [Panduan Manajemen Perintah Docker (Laptop vs Drone SBC)](#7-panduan-manajemen-perintah-docker-laptop-vs-drone-sbc)
8. [Koneksi dengan Autopilot SITL & Mission Planner](#8-koneksi-dengan-autopilot-sitl--mission-planner)
9. [Penyelesaian Masalah Umum (Troubleshooting FAQ)](#9-penyelesaian-masalah-umum-troubleshooting-faq)

---

## 1. Konsep Dasar Bagi Pemula

Sebelum masuk ke instalasi teknis, mari kita pahami istilah-istilah utama yang akan sering Anda gunakan:

*   **WSL2 (Windows Subsystem for Linux 2):** Fitur Windows yang memungkinkan Anda menjalankan sistem operasi Linux (Ubuntu) secara native di dalam Windows tanpa perlu dual-boot atau menggunakan VirtualBox yang lambat.
*   **WSLg (WSL GUI):** Subsistem WSL yang otomatis meneruskan tampilan grafis aplikasi Linux ke Windows. Berkat ini, simulator 3D seperti Gazebo bisa tampil di Windows Anda.
*   **Docker:** Bayangkan Docker seperti "kotak bekal" yang sudah berisi makanan lengkap. Di dunia software, Docker mengemas sistem operasi Linux mini beserta semua library ROS2 dan Gazebo ke dalam satu paket (**Image**). Saat dijalankan, paket ini menjadi **Container** yang terisolasi dari sistem utama PC Anda.
*   **ROS2 (Robot Operating System 2):** Bukan sistem operasi seperti Windows atau Linux, melainkan sebuah framework/middleware. ROS2 menyediakan pipa komunikasi (disebut **Topics**, **Services**, dan **Actions**) agar program-program kecil (disebut **Nodes**) seperti program sensor, kamera, dan kontrol motor dapat saling bertukar data dengan mudah.
*   **MAVLink & MAVROS:** 
    *   *MAVLink* adalah bahasa protokol komunikasi standar yang digunakan oleh Flight Controller drone (seperti Pixhawk dengan firmware ArduPilot atau PX4).
    *   *MAVROS* adalah program penerjemah di ROS2 yang menerjemahkan bahasa MAVLink menjadi bahasa ROS2 (Topics), sehingga Anda bisa mengontrol drone lewat script ROS2.
*   **SITL (Software In The Loop):** Simulator autopilot drone yang berjalan di komputer. Autopilot mengira ia sedang terbang di drone asli, padahal ia hanya menerima sensor buatan dan mengirim perintah motor ke lingkungan simulasi.

---

## 2. Prasyarat & Persiapan Sistem Windows

Untuk memastikan simulasi 3D berjalan dengan lancar, pastikan PC/Laptop Anda memenuhi spesifikasi berikut:

### Spesifikasi Perangkat Keras (Minimum & Rekomendasi)
| Komponen | Spesifikasi Minimum (Versi Lite) | Spesifikasi Rekomendasi (Versi Full + Gazebo) |
| :--- | :--- | :--- |
| **CPU** | Intel Core i5 / AMD Ryzen 5 (Generasi 8+) | Intel Core i7 / AMD Ryzen 7 |
| **RAM** | 8 GB | 16 GB atau lebih |
| **GPU** | VGA Terintegrasi (Intel HD/AMD Radeon) | NVIDIA Dedicated GPU (GTX 1050 / RTX Series+) |
| **Storage** | 10 GB ruang kosong (SSD sangat disarankan) | 30 GB ruang kosong (SSD) |

### Langkah Persiapan di Windows (Sebelum Mulai)
1.  **Aktifkan Virtualisasi Hardware di BIOS:**
    *   Saat PC baru menyala, masuk ke BIOS (biasanya tekan tombol `F2`, `F12`, atau `Del`).
    *   Cari menu **Virtualization Technology**, **Intel VT-x**, atau **AMD-V**, lalu ubah statusnya menjadi **Enabled**.
    *   *Cara cek di Windows:* Buka Task Manager (`Ctrl + Shift + Esc`) -> Tab **Performance** -> Lihat tulisan **Virtualization: Enabled** di bagian bawah kanan.
2.  **Update Driver VGA NVIDIA (Khusus pengguna NVIDIA):**
    *   Unduh dan instal driver resmi terbaru melalui aplikasi NVIDIA GeForce Experience atau website resmi NVIDIA.
    *   **Catatan Kritis:** Cukup instal driver di Windows. Jangan pernah mengunduh/menginstal driver NVIDIA untuk Linux di dalam terminal Ubuntu WSL Anda! WSL akan otomatis menjembatani akses ke driver Windows tersebut.

---

## 3. Arsitektur Sistem (Bagaimana Semua Saling Terhubung)

Diagram berikut menjelaskan bagaimana komponen perangkat lunak di Windows, WSL2, dan di dalam kontainer Docker saling berkomunikasi:

```mermaid
graph TD
    subgraph Windows Host (PC/Laptop)
        MP[Mission Planner / SITL Autopilot]
        NV_Win[Driver NVIDIA GPU Windows]
    end

    subgraph WSL2 Environment (Ubuntu 24.04)
        Docker[Docker Engine Native] <--> NV_WSL[NVIDIA Container Toolkit]
        WSLg[WSLg - Server Antarmuka Grafis]
    end

    subgraph Docker Container
        subgraph dev_full (Container dengan Gazebo & GPU)
            ROS2[ROS 2 Jazzy] <--> MAVROS[Node MAVROS]
            GZ[Simulator Gazebo Harmonic] <--> GPU[Akses GPU Passthrough]
        end
    end

    MP <-->|Komunikasi Jaringan TCP: WIN_IP| MAVROS
    NV_Win --> NV_WSL
    NV_WSL --> GPU
    WSLg <-->|Meneruskan Tampilan Grafis 3D| GZ
```

---

## 4. Panduan Instalasi Langkah-demi-Langkah (Zero to Hero)

Silakan buka komputer Anda dan ikuti panduan instalasi di bawah ini secara perlahan.

### Langkah 1: Setup WSL2 & WSLg
1.  Buka **Windows Search**, ketik `powershell`, klik kanan pada **Windows PowerShell**, lalu pilih **Run as Administrator**.
2.  Ketik perintah berikut untuk menginstal WSL2 secara otomatis (secara default akan mengunduh Ubuntu):
    ```powershell
    wsl --install
    ```
3.  Setelah selesai, lakukan pembaruan sistem WSL untuk memastikan sistem grafis (WSLg) terbaru telah terpasang:
    ```powershell
    wsl --update
    ```
4.  **Restart PC/Laptop Anda.**
5.  Setelah PC menyala kembali, buka menu Start Windows, cari dan jalankan aplikasi bernama **Ubuntu**.
6.  Terminal Ubuntu pertama kali akan meminta Anda memasukkan **Username** dan **Password** baru untuk sistem Linux Anda. Catat password ini karena akan digunakan saat menjalankan perintah `sudo`!

---

### Langkah 2: Instalasi Docker Engine (Native di WSL)
> [!NOTE]
> Kami sengaja tidak menggunakan **Docker Desktop** karena aplikasi tersebut cukup berat dan sering menimbulkan konflik routing jaringan dengan WSL2. Kita akan menginstal Docker Engine asli Linux langsung di dalam terminal Ubuntu Anda agar performanya jauh lebih cepat.

Buka terminal **Ubuntu (WSL)** Anda, lalu salin dan jalankan perintah-perintah berikut (Anda akan diminta memasukkan password Linux yang Anda buat di Langkah 1):

```bash
# 1. Perbarui daftar paket aplikasi & instal peralatan dasar
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# 2. Buat folder untuk menyimpan kunci keamanan Docker
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 3. Daftarkan repositori resmi Docker ke dalam sistem Ubuntu Anda
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 4. Instal Docker Engine dan plugin Docker Compose
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 5. Beri izin user Anda agar bisa menjalankan Docker tanpa harus mengetik 'sudo' terus-menerus
sudo usermod -aG docker $USER
```

> [!IMPORTANT]
> **Tutup terminal Ubuntu Anda (ketik `exit` atau klik tombol X), lalu buka kembali aplikasi Ubuntu.** Langkah ini wajib dilakukan agar izin grup docker yang baru saja kita tambahkan aktif.

Untuk memastikan Docker sudah berjalan dengan benar, ketik:
```bash
docker ps
```
If tidak muncul pesan error dan terminal menampilkan daftar tabel kosong, berarti Docker Anda telah aktif!

---

### Langkah 3: Instalasi NVIDIA Container Toolkit
*(Langkah ini khusus untuk laptop yang memiliki kartu grafis diskrit **NVIDIA**. Jika laptop Anda hanya menggunakan Intel HD atau AMD Radeon terintegrasi, Anda bisa melewati langkah ini).*

Langkah ini diperlukan agar kontainer Docker Anda dapat mendeteksi dan menggunakan kekuatan GPU NVIDIA Anda untuk rendering 3D di Gazebo.

Di dalam terminal **Ubuntu (WSL)**, jalankan:

```bash
# 1. Unduh dan daftarkan kunci keamanan repositori NVIDIA
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

# 2. Daftarkan repositori toolkit NVIDIA ke sistem Ubuntu
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# 3. Instal NVIDIA Container Toolkit
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# 4. Konfigurasi runtime Docker agar mengenali kartu grafis NVIDIA
sudo nvidia-ctk runtime configure --runtime=docker

# 5. Mulai ulang layanan Docker di WSL Anda
sudo service docker restart
```

---

### Langkah 4: Membangun & Menjalankan Kontainer (dev_lite / dev_full)
Kembali ke terminal **Ubuntu (WSL)**. Masuk ke folder project tempat file `Dockerfile` dan `docker-compose.yml` berada (misal `~/vtol_dev`).

Anda dapat memilih membangun salah satu jenis kontainer yang sesuai dengan PC Anda:
*   **Jika PC Anda High-End (Gunakan dev_full untuk simulator Gazebo 3D + GPU Passthrough):**
    ```bash
    cd ~/vtol_dev
    docker compose build dev_full
    ```
*   **Jika PC Anda berspesifikasi rendah/Laptop Kentang (Gunakan dev_lite untuk visualisasi RViz saja):**
    ```bash
    cd ~/vtol_dev
    docker compose build dev_lite
    ```

Setelah proses build selesai, jalankan kontainer di latar belakang dengan perintah:
```bash
docker compose up -d
```
*Catatan: Proses build pertama kali ini mungkin memakan waktu 5-15 menit tergantung kecepatan internet Anda, karena Docker perlu mengunduh aset ROS2 Jazzy yang cukup besar.*

---

### Langkah 5: Eksekusi dan Verifikasi
Untuk memverifikasi bahwa kontainer berhasil terpasang dan siap digunakan:

1.  **Masuk ke dalam kontainer yang menyala:**
    *   Jika Anda menggunakan kontainer **FULL**:
        ```bash
        docker exec -it vtol_full bash
        ```
    *   Jika Anda menggunakan kontainer **LITE**:
        ```bash
        docker exec -it vtol_lite bash
        ```
2.  **Cek Konektivitas GUI & GPU (Khusus versi FULL):**
    Di dalam kontainer `vtol_full`, jalankan perintah:
    ```bash
    gazebo
    ```
    *Jika jendela Gazebo terbuka secara mulus di desktop Windows Anda, instalasi GUI & GPU passthrough berhasil! Tekan `Ctrl+C` di terminal untuk menutup Gazebo kembali.*
3.  **Cek Deteksi IP Windows Host:**
    Di dalam kontainer, jalankan:
    ```bash
    echo $WIN_IP
    ```
    *Terminal harus mencetak alamat IP Gateway Windows Anda (misal: `172.x.x.x`).*

---

## 5. Alur Kerja Harian (Daily Workflow)

Bagaimana cara menggunakan lingkungan pengembangan ini setiap harinya? Ini adalah urutan langkah yang perlu Anda lakukan saat ingin mulai bekerja:

1.  **Buka Terminal Ubuntu WSL.**
2.  **Pastikan Service Docker Menyala:**
    WSL2 terkadang tidak otomatis menyalakan Docker saat Windows baru menyala. Jalankan perintah ini untuk memastikan layanan Docker aktif:
    ```bash
    sudo service docker start
    ```
3.  **Masuk ke Folder Project:**
    ```bash
    cd ~/vtol_dev
    ```
4.  **Nyalakan Kontainer:**
    ```bash
    docker compose up -d
    ```
5.  **Masuk ke Dalam Lingkungan Kontainer Linux ROS2:**
    *   Untuk kontainer **FULL**: `docker exec -it vtol_full bash`
    *   Untuk kontainer **LITE**: `docker exec -it vtol_lite bash`
6.  **Setelah Selesai Bekerja:**
    Keluar dari kontainer dengan mengetik `exit`, lalu matikan kontainer Docker Anda agar tidak memakan memori RAM laptop Anda di latar belakang:
    ```bash
    docker compose down
    ```

---

## 6. Struktur Direktori & Mekanisme Berbagi File (Volume Mount)

Bagi pemula, konsep penyimpanan Docker terkadang membingungkan. Jika Anda menghapus kontainer, apakah file kode Anda akan hilang? **Jawabannya: Tidak!**

Kami menggunakan fitur bernama **Volume Mount** (atau bind mount) yang menjembatani folder di komputer asli Anda dengan folder di dalam kontainer.

### Pemetaan Folder
*   Folder fisik di komputer Anda: `~/vtol_dev/workspace`
*   Terhubung langsung ke folder di dalam kontainer: `/home/pilot/workspace`

```
  KOMPUTER ANDA (WSL)                 KONTAINER DOCKER
 ┌──────────────────────┐            ┌──────────────────────┐
 │ ~/vtol_dev/          │            │ /home/pilot/         │
 │  ├── Dockerfile      │            │                      │
 │  ├── docker-compose  │            │                      │
 │  └── workspace/  ◄───┼──(Jembatan)┼───► workspace/       │
 │       └── main.py    │            │       └── main.py    │
 └──────────────────────┘            └──────────────────────┘
```

### Keuntungan Utama:
Anda bisa membuka VS Code di Windows, mengedit file python di dalam folder `~/vtol_dev/workspace`, dan seketika itu juga file tersebut akan terupdate di dalam kontainer Docker Anda untuk dijalankan menggunakan ROS2! Anda tidak perlu mengetik kode menggunakan editor terminal yang menyulitkan seperti `nano` atau `vi`.

---

## 7. Panduan Manajemen Perintah Docker (Laptop vs Drone SBC)

Ketika Anda melakukan pengodean di laptop, Anda tentu ingin melihat visualisasi 3D yang megah di Gazebo. Namun, saat kode tersebut dimasukkan ke dalam komputer penerbangan drone asli (misal Raspberry Pi atau NVIDIA Jetson), kita harus membuang simulator Gazebo agar performa drone tetap stabil dan ringan.

Di sinilah keunggulan sistem **Multi-stage Build** yang kita miliki.

### Skenario A: Pengembangan di Laptop/PC (Docker Compose)
Gunakan perintah Docker Compose untuk memilih lingkungan simulasi:

*   **Untuk Build versi FULL (Simulasi Lengkap + Gazebo + GPU Passthrough):**
    ```bash
    docker compose build dev_full
    ```
*   **Untuk Build versi LITE (Laptop Tanpa GPU / Hanya Ingin Visualisasi Data Ringan):**
    ```bash
    docker compose build dev_lite
    ```
*   **Untuk Menjalankan:**
    ```bash
    docker compose up -d
    ```

---

### Skenario B: Deployment ke Komputer Drone Fisik (SBC ARM64)
SBC (Single Board Computer) seperti Raspberry Pi menggunakan arsitektur prosesor **ARM64**, berbeda dengan laptop yang menggunakan **x86_64**. Oleh karena itu, **Anda wajib melakukan build image langsung di dalam SBC tersebut.**

1.  Salin file `Dockerfile` ke dalam penyimpanan Raspberry Pi / Jetson Anda.
2.  Buka terminal di SBC Anda, lalu jalankan perintah pemotongan target ini:
    ```bash
    docker build --target sbc -t vtol_drone_sbc:latest .
    ```

> [!TIP]
> **Mengapa perintah ini penting bagi pemula?**
> Bendera `--target sbc` menginstruksikan Docker untuk **berhenti** menginstal program tepat setelah *Stage 1 (SBC)* selesai. Semua perintah instalasi simulator Gazebo 3D yang sangat berat di baris-baris bawah `Dockerfile` akan diabaikan sepenuhnya. Hasilnya, Anda mendapatkan sistem container terbang yang sangat kecil dan ringan (kurang dari 1 GB), menghemat RAM serta ruang kartu SD drone Anda!

---

## 8. Koneksi dengan Autopilot SITL & Mission Planner

Untuk menguji simulasi terbang drone VTOL Anda secara autonomous, kita dapat menyambungkan ROS2 di dalam Docker langsung dengan simulator internal di **Mission Planner**.

```
+----------------------------------------+          +-----------------------------------------+
|              WINDOWS HOST              |          |            DOCKER CONTAINER             |
|                                        |          |                                         |
|  [ Mission Planner (SITL Otomatis) ]  ◄┼──────────┼────► [ MAVROS Node (tcp://$WIN_IP:5762) ] |
|                                        | Jaringan |                                         |
|                                        |  WSL2    |                                         |
+----------------------------------------+          +-----------------------------------------+
```

Langkah-langkah koneksi:

1.  **Nyalakan SITL di Mission Planner (Windows):**
    *   Buka aplikasi **Mission Planner** di Windows Anda.
    *   Masuk ke tab menu **Simulation** di bagian atas.
    *   Klik tombol ikon wahana **Plane** atau **QuadPlane** (VTOL).
    *   Mission Planner akan mengunduh firmware secara otomatis, memulai simulator penerbangan SITL secara mandiri, dan langsung tersambung secara otomatis (*Auto-connect*). Anda **tidak perlu menginput IP address manual** di langkah ini karena semuanya sudah ditangani langsung oleh antarmuka Mission Planner.
2.  **Jalankan Jembatan MAVROS di Kontainer Docker (WSL):**
    *   Buka terminal Ubuntu WSL Anda dan masuk ke kontainer (contoh `vtol_full`):
        ```bash
        docker exec -it vtol_full bash
        ```
    *   Jalankan node MAVROS untuk tersambung ke simulator di Windows menggunakan port MAVLink TCP bawaan (biasanya `5762` atau `5760`):
        ```bash
        ros2 run mavros mavros_node --ros-args -p fcu_url:="tcp://$WIN_IP:5762"
        ```
3.  **Verifikasi Konektivitas Topik ROS2:**
    *   Buka tab terminal Ubuntu WSL baru (biarkan MAVROS tetap menyala di terminal pertama).
    *   Masuk kembali ke dalam kontainer:
        ```bash
        docker exec -it vtol_full bash
        ```
    *   Tampilkan semua topik aktif yang sedang diterbitkan oleh MAVROS:
        ```bash
        ros2 topic list
        ```
    *   Jika data sensor autopilot berhasil tersambung, Anda akan melihat puluhan topik terdaftar (seperti `/mavros/state`, `/mavros/global_position/local`, dll.). Anda bisa membaca status koneksi dengan perintah:
        ```bash
        ros2 topic echo /mavros/state
        ```
        Jika baris log terminal menampilkan `connected: True`, berarti program kontrol ROS2 Anda di Docker sudah tersambung sepenuhnya dengan simulasi drone di Windows!

---

## 9. Penyelesaian Masalah Umum (Troubleshooting FAQ)

Berikut adalah daftar solusi jika Anda mengalami kendala saat mengikuti panduan ini:

### Q1: Error `NVIDIA driver not found` atau kegagalan saat menjalankan `docker compose build dev_full`
*   **Penyebab:** NVIDIA Container Toolkit belum terinstal dengan benar atau driver VGA di Windows belum terupdate.
*   **Solusi:** 
    1.  Ulangi langkah-langkah di **Langkah 3** secara teliti.
    2.  Pastikan layanan docker di-restart: `sudo service docker restart`.
    3.  Gunakan target `dev_lite` jika laptop Anda tidak memiliki kartu grafis NVIDIA diskrit.

### Q2: Perintah `docker` atau `docker-compose` memunculkan pesan error `Cannot connect to the Docker daemon`
*   **Penyebab:** Layanan Docker di dalam WSL2 belum menyala secara otomatis.
*   **Solusi:** 
    Jalankan perintah berikut di terminal Ubuntu WSL Anda sebelum memulainya:
    ```bash
    sudo service docker start
    ```

### Q3: Saat menjalankan perintah `gazebo` atau aplikasi GUI lainnya di dalam kontainer, aplikasi tidak muncul di Windows
*   **Penyebab:** WSLg (sistem grafis WSL) gagal menjembatani display ke Windows host, atau Windows Anda menggunakan versi WSL lama.
*   **Solusi:**
    1.  Keluar dari WSL, buka PowerShell Windows, lalu ketik `wsl --shutdown` untuk merestart subsistem WSL sepenuhnya.
    2.  Buka kembali Ubuntu WSL Anda dan ketik `xclock`. Jika muncul jendela jam analog kecil, berarti sistem GUI Anda sudah normal.
    3.  Pastikan variabel `$DISPLAY` di dalam kontainer terisi dengan benar (sudah dikonfigurasi otomatis di `docker-compose.yml` Anda).

### Q4: MAVROS memunculkan status `FCU Connection Lost` atau gagal menyambung ke IP Windows
*   **Penyebab:** Windows Firewall memblokir akses atau simulator SITL belum berjalan sempurna di port TCP `5762`.
*   **Solusi:**
    1.  Pastikan Anda telah mengaktifkan aturan masuk pada Windows Firewall. Coba nonaktifkan sementara Windows Defender Firewall untuk memastikannya.
    2.  Di terminal kontainer, coba cek apakah IP Windows `$WIN_IP` terdeteksi secara valid dengan mengetik `echo $WIN_IP`.
    3.  Ganti port parameter `fcu_url` menjadi `5760` (contoh: `tcp://$WIN_IP:5760`) jika port simulasi default Mission Planner Anda dialokasikan ke port `5760`.

---
