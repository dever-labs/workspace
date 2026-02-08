# Sunshine/Moonlight Setup Guide

Ultra-low latency remote desktop streaming (5-15ms) - Sunshine runs IN the container.

## Quick Start

> **⚠️ WINDOWS DOCKER DESKTOP NETWORKING NOTE:**  
> Sunshine/Moonlight streaming **WORKS** on Windows Docker Desktop with GPU encoding (NVENC)! However, the Docker bridge networking has a ping verification limitation that causes automatic disconnection after ~10 seconds.  
>   
> **What works:**  
> - ✅ **GPU Hardware Encoding (NVENC):** RTX GPUs can encode 5120x1440 @ 60-120 FPS  
> - ✅ **Connection establishes:** Stream starts and video appears  
> - ❌ **Ping timeout:** Disconnects after ~10 seconds due to Docker bridge networking  
>   
> **This networking limitation ONLY affects Windows Docker Desktop.** Linux Docker Engine, Kubernetes, and native WSL2 Docker work perfectly.  
>   
> **For local Windows development:**  
> - **Sunshine/Moonlight:** ⚠️ Works for ~10 seconds, then disconnects (networking issue)  
> - **X2Go** (10-30ms latency) - ✅ Reliable - Set `ENABLE_X2GO=true` in .env  
> - **RDP** (50-150ms latency) - ✅ Works - Already enabled on port 3389  
>   
> Continue setup below. Sunshine is **fully configured with NVENC** and works great on Linux hosts!

### 1. Enable Sunshine
\\\ash
# In .env:
ENABLE_SUNSHINE=true
ENABLE_SSH=true

# Optional: disable RDP to save resources
# ENABLE_RDP=false
\\\

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

**Why manual?** Docker bridge networks on Windows don't support mDNS properly, so auto-discovery won't work even with Avahi enabled.

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

**Connection Error -1 / "Connection terminated" (WINDOWS DOCKER DESKTOP ONLY):**

**What's happening:**
1. Moonlight connects successfully ✅
2. Desktop streaming starts ✅  
3. Sunshine waits for ping response from client (to verify low latency)
4. Docker bridge network blocks the ping ❌
5. After 10 seconds, Sunshine times out and disconnects
6. "Connection terminated Error -1" appears

This is caused by Docker bridge networking on Windows. Sunshine's ping verification cannot reach back through the Docker bridge. **This is a fundamental incompatibility between Sunshine and Windows Docker Desktop networking.**

**Status:**
- ❌ **Broken:** Windows Docker Desktop (bridge network blocks ping)
- ✅ **Works:** Linux Docker Engine, Kubernetes, native WSL2 Docker
- ✅ **Works:** Sunshine installed directly on Windows (not containerized)

**Temporary Workaround (extends session to 60 seconds):**

```powershell
# Create config with 60-second timeout
@"
{
   "sunshine_name": "Workspace",
  "output_name": 0,
  "origin_pin_allowed": "pc",
  "origin_web_ui_allowed": "pc",
  "address_family": "ipv4",
  "ping_timeout": 60000,
  "channels": 2,
  "fps": [30, 60],
  "resolutions": ["1920x1080", "2560x1440"],
  "min_log_level": 2,
  "encoder": "software",
  "sw_preset": "ultrafast"
}
"@ | Out-File -Encoding utf8 sunshine_temp.conf

docker cp sunshine_temp.conf workspace:/home/dev/.config/sunshine/sunshine.conf
docker exec workspace chown dev:dev /home/dev/.config/sunshine/sunshine.conf  
docker exec workspace pkill sunshine
Start-Sleep -Seconds 2
docker exec workspace bash -c 'sudo -u dev DISPLAY=:10 sunshine &'
Remove-Item sunshine_temp.conf
```

This gives you 60 seconds before timeout instead of 10. Still not a real solution.

**Proper Solutions for Windows local development:**

1. **Use X2Go instead** (Recommended - 10-30ms latency, no timeouts):
   ```bash
   # In .env:
   ENABLE_X2GO=true
   ENABLE_SUNSHINE=false
   ```
   Restart container, then connect with X2Go Client to `localhost:2222`

2. **Use RDP** (Already enabled - 50-150ms latency):
   ```
   Connect to: localhost:3389
   Username: dev
   Password: (from DEV_PASSWORD in .env)
   ```

3. **Deploy to Linux VM for Sunshine** (remote access only):
   ```bash
   # On Linux host with Docker:
   docker compose -f compose.yaml -f compose.remote.yaml up -d
   # Sunshine will work properly on Linux
   ```

4. **Install Docker in WSL2 natively** (advanced):
   - Install Docker inside WSL2 distribution directly (not Docker Desktop)
   - Run container from within WSL2
   - Docker networking will work correctly

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
