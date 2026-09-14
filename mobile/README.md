# App mobile Flutter — Hôm nay ăn gì?

Giao diện cùng phong cách bản web: hòm quay, ảnh món từ sprite, tab Mở hòm / Đã ăn, chat Doraemon.

## Xem thử trên máy (Chrome)

API phải đang chạy (`npm --prefix server run dev`).

```bash
cd mobile
flutter pub get
flutter run -d chrome
```

## Chạy trên iPhone

Máy Mac hiện **chưa cài đủ Xcode**, nên bước 1 là bắt buộc.

### 1. Cài Xcode

1. App Store → cài **Xcode** (nặng, mất một lúc).
2. Mở Xcode một lần, đồng ý license.
3. Trong Terminal:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

4. Kiểm tra: `flutter doctor` — mục Xcode phải có dấu ✓.

### 2. Chuẩn bị iPhone

1. iPhone và Mac **cùng Wi‑Fi**.
2. Cáp USB nối iPhone ↔ Mac, bấm **Trust**.
3. iOS 16+: Settings → Privacy & Security → **Developer Mode** → bật, khởi động lại.
4. Mở Xcode → Settings → Accounts → thêm **Apple ID** (free developer).

### 3. Bật API trên Mac

Ở thư mục gốc repo:

```bash
docker compose up -d db
npm --prefix server run dev
```

IP LAN máy Mac hiện tại: **192.168.1.138**  
(Đổi Wi‑Fi thì chạy `ipconfig getifaddr en0` để lấy IP mới.)

### 4. Cài app lên iPhone

```bash
cd mobile
flutter devices
flutter run -d <id-iphone> --dart-define=API_BASE=http://192.168.1.138:3001
```

Lần đầu Xcode hỏi signing: chọn Team = Apple ID của bạn. Trên iPhone có thể hiện “Untrusted Developer” → Settings → General → VPN & Device Management → Trust.

Lúc app hỏi tên, ô API nên là `http://192.168.1.138:3001` (không dùng localhost — localhost trên iPhone là chính điện thoại).

Cho phép **Local Network** nếu iOS hỏi.
