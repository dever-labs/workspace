# Sunshine/Moonlight Setup Guide

Ultra-low latency remote desktop streaming (5-15ms) - Sunshine runs IN the container.

## Quick Start

> **Windows Docker Desktop note:** Sunshine/Moonlight works on Windows with GPU encoding (NVENC). Auto-discovery can be flaky due to mDNS on bridged networks, so manual pairing is often more reliable (see Connect section below).

> **⚠️ WINDOWS DOCKER DESKTOP NETWORKING NOTE:**  
> Sunshine/Moonlight works on Windows with GPU encoding (NVENC). Auto-discovery can be flaky due to mDNS on bridged networks, so manual pairing is often more reliable (see Connect section below).
>   
> **What works:**  
> - ✅ **GPU Hardware Encoding (NVENC):** RTX GPUs can encode 5120x1440 @ 60-120 FPS  
> - ✅ **Connection establishes:** Stream starts and video appears
>   
> **This networking limitation ONLY affects Windows Docker Desktop.** Linux Docker Engine, Kubernetes, and native WSL2 Docker work perfectly.  
>   
> **For local Windows development:**  
> - **Sunshine/Moonlight:** (5-15ms latency) ✅ Works - Set `ENABLE_SUNSHINE=true` in .env 
> - **X2Go** (10-30ms latency) - ✅ Reliable - Set `ENABLE_X2GO=true` in .env  
> - **RDP** (50-150ms latency) - ✅ Works - Already enabled on port 3389  
>   
> Continue setup below. Sunshine is **fully configured with NVENC** and works great on Linux hosts!

### 1. Enable Sunshine
\\\ash
# In .env:
ENABLE_SUNSHINE=true
If you see a disconnect, check the Sunshine logs and verify ports are exposed. Try restarting the container and re-pairing from Moonlight.

# Optional: disable RDP to save resources
### 2. Start Container
\\\ash
docker compose up -d --build
\\\

### 3. Configure Sunshine
- Access: https://localhost:47990
- Create admin credentials
- Set encoder to nvenc (NVIDIA GPU)
- Save PIN for Moonlight pairing

### 4. Install Moonlight Client

**Windows:**
```powershell
# Option 1: WinGet (recommended)
winget install MoonlightGameStreamingProject.Moonlight

# Option 2: Chocolatey
choco install moonlight-qt

# Option 3: Direct download
# Download installer from: https://github.com/moonlight-stream/moonlight-qt/releases
# Install the .exe file
```

**macOS:**
```bash
# Option 1: Homebrew
brew install --cask moonlight

# Option 2: Direct download
# Download from: https://github.com/moonlight-stream/moonlight-qt/releases
```

**Linux:**
```bash
# Option 1: Flatpak (universal)
flatpak install flathub com.moonlight_stream.Moonlight

# Option 2: Snap
sudo snap install moonlight

# Option 3: AppImage
# Download from: https://github.com/moonlight-stream/moonlight-qt/releases
chmod +x Moonlight-*.AppImage
./Moonlight-*.AppImage
```

**Mobile:**
- **iOS:** App Store → Search "Moonlight Game Streaming"
- **Android:** Play Store → Search "Moonlight Game Streaming"

### 5. Connect

**Recommended: Manual Connection**
- Open Moonlight → Click **"+"** or **"Add PC"**
- Enter: **`localhost`** (or `127.0.0.1`)
- Moonlight connects and requests PIN
- Enter PIN from Sunshine UI (https://localhost:47990) → Paired!

**Why manual?** Docker bridge networks on Windows can block mDNS, so auto-discovery may not work even with Avahi enabled.

**Option B: Auto-Discovery (Linux hosts only)**
- Open Moonlight → Should auto-detect "Workspace"
- Requires Avahi daemon running and host network mode
- Check status: `docker exec workspace ps aux | grep avahi`

**Find container IP (alternative):**
```powershell
docker inspect workspace | Select-String '"IPAddress"'
```

See full guide in original SUNSHINE_SETUP.md or README.md

## GPU Acceleration Setup

### Status: ✅ WORKING on Windows Docker Desktop!

- **Software Encoding (x264):** Works out of the box, ~30-60 FPS at 1080p/1440p
- **GPU Encoding (NVENC):** ✅ **NOW ENABLED** - ~60-120 FPS at up to 5120x1440 with GPU acceleration!

### Enable NVENC GPU Encoding

**Prerequisites:**
- NVIDIA GPU with drivers installed on Windows host
- Docker Desktop with WSL2 backend enabled
- GPU settings enabled in Docker Desktop

**Critical Configuration - The `video` GPU Capability:**

The key to enabling NVENC in Docker Desktop is adding the `video` capability to the GPU configuration. This is **already configured** in `compose.override.yaml`:

```yaml
deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          count: all
          capabilities: [gpu, compute, utility, graphics, video]  # ← 'video' is required!
```

**Verification Steps:**

1. **Check GPU is accessible:**
```bash
docker exec workspace nvidia-smi
```

2. **Verify NVENC libraries are loaded:**
```bash
docker exec workspace bash -c 'ldconfig -p | grep nvidia'
```

You should see:
```
libnvidia-encode.so.1 (libc6,x86-64) => /usr/lib/x86_64-linux-gnu/libnvidia-encode.so.1
libnvidia-opticalflow.so.1 (libc6,x86-64) => /usr/lib/x86_64-linux-gnu/libnvidia-opticalflow.so.1
```

3. **Check Sunshine detects NVENC:**
```bash
docker logs workspace 2>&1 | grep -i nvenc
```

You should see:
```
[sunshine] Info: Found H.264 encoder: h264_nvenc [nvenc]
[sunshine] Info: Found HEVC encoder: hevc_nvenc [nvenc]
```

**Troubleshooting:**

If NVENC is not detected:

1. **Ensure GPU settings are enabled in Docker Desktop:**
   - Settings → Resources → GPU → Enable
   - Restart Docker Desktop

2. **Verify `video` capability is present:**
```bash
grep -A 5 "capabilities:" compose.override.yaml
```
Should show: `capabilities: [gpu, compute, utility, graphics, video]`

3. **Rebuild container:**
```bash
docker compose down
docker compose up -d --build
```

4. **Check Sunshine config uses nvenc:**
```bash
docker exec workspace cat /home/dev/.config/sunshine/sunshine.conf
```

Should show: `"encoder": "nvenc"`

**Performance Expectations:**

With NVENC enabled:
- **1920x1080 @ 120 FPS:** Smooth, minimal CPU usage (~5-10%)
- **2560x1440 @ 60-120 FPS:** Excellent performance
- **3440x1440 @ 60 FPS:** Great for ultrawide monitors
- **5120x1440 @ 60-120 FPS:** Works! Requires 100+ Mbps bitrate

Without NVENC (software encoding):
- **1920x1080 @ 60 FPS:** Works, high CPU usage (~40-60%)
- **2560x1440 @ 30 FPS:** Acceptable
- **5120x1440:** Too slow, frames arrive late, disconnects

### Troubleshooting

**Connection Error -1 / "Connection terminated":**

If you see a disconnect, check Sunshine logs and confirm the ports are exposed. Restart the container and re-pair from Moonlight.

**Connection Error 2 (Control stream failed):**

This means port 47999 wasn't accessible. Restart with correct ports:

```powershell
# Restart container with correct ports:
docker compose down
docker compose up -d
```

**Monitor connection attempts in real-time:**
```powershell
# Watch logs as you connect
docker exec workspace tail -f /home/dev/.config/sunshine/sunshine.log
```

**No encoder found:**
- Check logs: `docker compose logs | grep -i sunshine`
- Verify devices mounted: `docker exec workspace ls -la /dev/dri`
- Test GPU: `docker exec workspace nvidia-smi`

**Input devices not working:**
- Virtual input (uinput) is configured automatically  
- XTest fallback works but has higher latency
- Check permissions: `docker exec workspace ls -la /dev/uinput`

**Can't pair / No PIN shown:**
- Access web UI: https://localhost:47990
- Create username/password if not done
- PIN appears when Moonlight tries to connect
- PIN is usually 4 digits

**Performance tuning:**
- Lower resolution: Edit Sunshine config to 1080p only
- Reduce FPS: Set max FPS to 30 or 60
- Use x264 preset: `ultrafast` for lowest CPU usage

**View Sunshine logs:**
```powershell
docker exec workspace tail -100 /home/dev/.config/sunshine/sunshine.log
```
