# Windows on Railway (Dockur Windows)

Run Windows inside a Docker container on [Railway.com](https://railway.com) using the [Dockur Windows](https://github.com/dockur/windows) image. Access Windows through a web-based viewer on port **8006**.

---

## What This Project Does

This project packages the `dockurr/windows:latest` Docker image for deployment on Railway. Dockur Windows runs a Windows virtual machine inside a container using QEMU/KVM and exposes a noVNC web viewer on port 8006, allowing you to interact with a full Windows desktop from your browser.

---

## ⚠️ Critical Limitation: KVM on Railway

> **Railway does NOT guarantee access to `/dev/kvm` or privileged container features.**

Dockur Windows requires KVM hardware virtualization to run Windows at usable speeds. Without `/dev/kvm`:

- **Windows may fail to boot entirely**, or
- **Windows will fall back to software emulation (TCG)**, which is **extremely slow** and likely unusable for any practical purpose.

This project is provided as-is. It will build and deploy on Railway, but **full functionality depends on the underlying host providing KVM access to containers**. Railway's infrastructure may or may not support this depending on the plan, region, and host hardware.

**If KVM is not available**, consider:
- A dedicated/bare-metal server with Docker and KVM support
- A VPS provider that offers nested virtualization (e.g., Hetzner, OVH, Vultr bare-metal)

---

## Project Structure

```
.
├── Dockerfile        # Minimal Dockerfile based on dockurr/windows
├── railway.toml      # Railway build and deploy configuration
├── .env.example      # Example environment variables
└── README.md         # This file
```

---

## How to Deploy from GitHub to Railway

1. **Push this project to a GitHub repository.**

2. **Go to [Railway.com](https://railway.com)** and sign in.

3. **Create a New Project:**
   - Click **"New Project"** → **"Deploy from GitHub Repo"**.
   - Select your repository.

4. **Railway will detect the `Dockerfile`** and begin building automatically.

5. **Wait for the build to complete.** Check the Deploy Logs for progress.

---

## How to Set Railway Variables

Railway environment variables override the defaults in the Dockerfile.

1. Open your project on Railway.
2. Click on the service (your deployed container).
3. Go to the **"Variables"** tab.
4. Add or edit the following variables:

| Variable     | Default        | Description                          |
|-------------|----------------|--------------------------------------|
| `VERSION`   | `2022`         | Windows version (`11`, `10`, `2022`, `2019`, `2016`) |
| `USERNAME`  | `Admin`        | Windows administrator username       |
| `PASSWORD`  | `ChangeMe123`  | Windows administrator password       |
| `RAM_SIZE`  | `2G`           | RAM allocated to the VM              |
| `CPU_CORES` | `1`            | CPU cores allocated to the VM        |
| `DISK_SIZE` | `32G`          | Virtual disk size                    |
| `REGION`    | `id-ID`        | Windows region/locale                |
| `KEYBOARD`  | `id-ID`        | Keyboard layout                      |

### Overriding Credentials

**Do not leave the default password in production.** Override `USERNAME` and `PASSWORD` from the Railway Variables tab:

1. Go to your service → **Variables** tab.
2. Set `PASSWORD` to a strong, unique password.
3. Optionally change `USERNAME` to something other than `Admin`.
4. Railway will redeploy automatically with the new values.

These values are injected as environment variables at runtime — they are **not baked into the image**.

---

## How to Expose Port 8006 (Public Networking)

The web viewer runs on port **8006**. To access it from the internet:

1. Open your service on Railway.
2. Go to the **"Networking"** tab (or **"Settings" → "Networking"**).
3. Under **Public Networking**, click **"Generate Domain"** or add a custom domain.
4. Set the port to **8006** and protocol to **TCP/HTTP**.
5. Railway will assign a public URL like `https://your-service.up.railway.app`.

> **Note:** The noVNC web viewer uses HTTP/WebSocket. Railway's public domain will proxy HTTPS to port 8006 inside the container.

If you need raw TCP (e.g., for RDP on port 3389), enable **TCP Proxy** under Public Networking and Railway will assign a `*.proxy.rlwy.net` address with a random port.

---

## How to Mount a Railway Volume to /storage

Windows disk images and data are stored in `/storage`. To persist data across redeploys:

1. Open your service on Railway.
2. Go to **"Settings"** (or **"Volumes"** tab if visible).
3. Click **"Add Volume"** (or **"New Volume"**).
4. Set the **Mount Path** to:
   ```
   /storage
   ```
5. Choose a volume size appropriate for your needs (minimum **32 GB** recommended to match `DISK_SIZE`).
6. Click **"Save"** / **"Create"**.

The `railway.toml` file already declares the volume mount. If Railway prompts to confirm, accept it.

> **Important:** Without a persistent volume, all Windows data (including the virtual disk) will be **lost on every redeploy or restart**.

---

## How to Access the Windows Web Viewer

Once the container is running and port 8006 is exposed:

1. Open the public URL assigned by Railway in your browser, e.g.:
   ```
   https://your-service.up.railway.app
   ```
2. The noVNC web viewer will load, showing the Windows desktop (or installation process on first boot).
3. Use your mouse and keyboard to interact with Windows directly in the browser.

First boot will take several minutes as Windows installs. Subsequent boots are faster if the volume is persistent.

---

## How to Check Railway Logs

1. Open your project on Railway.
2. Click on the service.
3. Go to the **"Logs"** tab (or **"Deploy Logs"**).
4. View real-time logs from the container.

Look for:
- QEMU startup messages
- KVM availability notices
- Windows boot progress
- Error messages

---

## Troubleshooting

### `/dev/kvm not found` / `KVM acceleration not available`

**Cause:** The Railway host does not expose KVM to containers.

**Impact:** Windows will either fail to start or fall back to extremely slow software emulation.

**Solutions:**
- There is no user-side fix — this depends on Railway's infrastructure.
- Try redeploying to a different region.
- Consider a VPS/bare-metal provider with KVM support.

---

### `operation not permitted`

**Cause:** The container requires privileged capabilities (e.g., `--privileged`, `--cap-add`, `--device`) that Railway does not provide.

**Impact:** QEMU/KVM cannot access required kernel features.

**Solutions:**
- Railway does not support `--privileged` or `--device` flags.
- This is a platform limitation. No workaround is available on Railway.

---

### Windows stuck on boot

**Cause:** Insufficient RAM, no KVM, or disk I/O bottleneck.

**Solutions:**
- Increase `RAM_SIZE` to `4G` or higher.
- Increase `CPU_CORES` to `2` or higher.
- Wait longer — first boot can take 10–30+ minutes, especially without KVM.
- Check logs for QEMU errors.

---

### Storage full

**Cause:** The Railway volume is smaller than `DISK_SIZE`, or Windows consumed all disk space.

**Solutions:**
- Increase the Railway volume size.
- Reduce `DISK_SIZE` in Railway Variables.
- Ensure `DISK_SIZE` does not exceed the volume capacity.

---

### Port 8006 not opening

**Cause:** Public networking is not enabled or the container hasn't started yet.

**Solutions:**
- Confirm port 8006 is exposed under **Networking** → **Public Networking**.
- Wait for the container to fully start (check logs).
- Verify the service is not in a restart loop.

---

### Container restarting repeatedly

**Cause:** QEMU crashes on startup, usually due to missing KVM or insufficient resources.

**Solutions:**
- Check deploy logs for the exact error.
- Increase `RAM_SIZE` and `CPU_CORES`.
- If logs show KVM errors, the platform does not support this workload.

---

### Railway volume not mounted correctly

**Cause:** Volume was not attached or the mount path is wrong.

**Solutions:**
- In Railway, verify the volume mount path is exactly `/storage`.
- Redeploy after attaching the volume.
- Check logs for disk-related errors.

---

## Recommended Railway Resource Settings

| Resource    | Minimum    | Recommended |
|------------|------------|-------------|
| RAM        | 2 GB       | 4–8 GB      |
| CPU        | 1 vCPU     | 2–4 vCPUs   |
| Disk/Volume| 32 GB      | 64+ GB      |

> Railway's resource limits depend on your plan. The **Pro plan** or higher is recommended for running a Windows VM.

---

## Notes About KVM and Performance

- **KVM** (Kernel-based Virtual Machine) provides hardware-accelerated virtualization. It is **essential** for running Windows at usable speeds.
- Without KVM, QEMU falls back to **TCG** (software emulation), which can be **10–50x slower**.
- Railway runs containers on shared infrastructure. KVM device passthrough (`/dev/kvm`) is **not guaranteed**.
- If you need reliable Windows VM hosting, use a provider that explicitly supports nested virtualization or bare-metal Docker hosts.
- Dockur Windows supports multiple Windows versions: `11`, `10`, `2022`, `2019`, `2016`. Set the `VERSION` variable accordingly.

---

## Links

- [Dockur Windows GitHub](https://github.com/dockur/windows)
- [Railway Documentation](https://docs.railway.com)
- [Railway Volumes](https://docs.railway.com/reference/volumes)
- [Railway Public Networking](https://docs.railway.com/reference/public-networking)