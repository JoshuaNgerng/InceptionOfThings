🧠 What systemd actually is

systemd is the init system on most modern Linux distros (including Ubuntu).

👉 It is PID 1 — the first process the kernel starts.

Its job is to:

Start services at boot
Stop services at shutdown
Restart crashed services
Manage dependencies between services
Handle logs
🔧 Think of it like this
Your shell script = temporary worker
nohup = duct tape
systemd = service manager (like a supervisor/daemon controller)
⚙️ Core concept: Units

Everything in systemd is a unit.

Common types:

service → long-running processes (what you need)
target → groups of services (like runlevels)
mount → filesystems
socket → network sockets
🟢 Your case: a .service file

Example:

[Unit]
Description=Simple Python HTTP Server
After=network.target

[Service]
ExecStart=/usr/bin/python3 -m http.server 8000
WorkingDirectory=/home/vagrant
Restart=always
User=vagrant

[Install]
WantedBy=multi-user.target

Let’s break this down 👇

🔍 Section-by-section explanation
1. [Unit] — metadata + dependencies
[Unit]
Description=Simple Python HTTP Server
After=network.target
Description → just a label
After=network.target → start after network is ready

👉 Important for servers (like yours)

2. [Service] — how your app runs
[Service]
ExecStart=/usr/bin/python3 -m http.server 8000
WorkingDirectory=/home/vagrant
Restart=always
User=vagrant
🔹 ExecStart

The command to run
👉 Must be full path (/usr/bin/python3, not just python3)

🔹 WorkingDirectory

Where the command runs

👉 This is critical for your token file:

If wrong → file won’t be served
🔹 Restart

Controls failure behavior:

no → don’t restart
on-failure → restart only if crash
always → always restart ✅ (good default)
🔹 User

Which user runs the service

vagrant → safer
root → needed for privileged ports (<1024)
3. [Install] — startup behavior
[Install]
WantedBy=multi-user.target

This means:

👉 “Start this service when the system reaches normal multi-user mode”

Equivalent to:

system boot completed
network available
system ready
🚀 How systemd lifecycle works
After you create the file:
1. Reload config
sudo systemctl daemon-reload
2. Start service now
sudo systemctl start simple-http
3. Enable at boot
sudo systemctl enable simple-http

👉 Creates a symlink so it starts automatically

🧪 Useful commands
Check status
systemctl status simple-http
View logs
journalctl -u simple-http
Restart
systemctl restart simple-http
Stop
systemctl stop simple-http