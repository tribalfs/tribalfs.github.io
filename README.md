# tribalfs — Landing Page & Unified `app-ads.txt` Automation

Personal website and centralized `app-ads.txt` hosting for all **tribalfs** mobile applications and open-source projects.

- **Live Landing Page**: [https://tribalfs.github.io](https://tribalfs.github.io)
- **Unified app-ads.txt**: [https://tribalfs.github.io/app-ads.txt](https://tribalfs.github.io/app-ads.txt)
- **Tagline**: *"GAAP certified, API curious"*

---

## 📁 Project Structure

```text
tribalfs.github.io/
├── index.html              # Modern OneUI 9 responsive developer portfolio & app showcase
├── publish.sh              # Master build, sync, and GitHub Pages publishing script
├── update-ads.sh           # Backward-compatible forwarding alias script
├── README.md               # Project documentation
├── .github/
│   └── workflows/
│       └── update-ads.yml  # GitHub Actions automated weekly sync workflow
├── assets/                 # High-resolution PNGs and vector SVGs (brand logos & icons)
├── app-ads.txt             # Compiled unified app-ads.txt file (GitHub Pages root)
├── shared/
│   └── unity-ads.txt       # Shared master Unity Ads seller list
└── public/
    └── app-ads.txt         # Mirror build output for Firebase compatibility
```

---

## 🚀 Usage

### 1. Build & Publish to GitHub Pages
Compiles `app-ads.txt` and automatically commits and pushes all site updates to GitHub Pages:
```bash
./publish.sh
# Or using the alias:
./update-ads.sh
```

### 2. Auto-fetch Liftoff and Publish
Opens `https://publisher.vungle.com/vungleAdsTxt` in your default browser, waits for `vungle.txt` to download, compiles, commits, and pushes:
```bash
./publish.sh --fetch-liftoff
```

### 3. Local Test (No Git Push)
```bash
./publish.sh --no-deploy
```

---

## 🤖 Automated Weekly GitHub Actions Workflow

This repository includes a scheduled GitHub Actions workflow at [`.github/workflows/update-ads.yml`](.github/workflows/update-ads.yml):
- **Schedule**: Runs automatically every Sunday at `00:00 UTC`.
- **Manual Trigger**: Can be triggered on-demand via the **Actions** tab on GitHub (`workflow_dispatch`).
- **Function**: Automatically fetches live Mintegral data, compiles `app-ads.txt`, and commits changes to GitHub Pages.

---

## 🌐 Showcase Apps & Open Source Libraries

### Google Play Apps
- **Pixels: Resolution & DPI Changer**
- **Galaxy MaxHz** (Samsung Refresh Rate Mod)
- **Real-time FPS Monitor**
- **Box Score: Score Tracker Pro**
- **Display Checker & Refresh Rate**
- **Mobile Ledger / Accountant** *(Coming Soon)*

### Open Source Android Frameworks
- **oneui-design**
- **sesl-androidx**
- **sesl-material-components-android**
