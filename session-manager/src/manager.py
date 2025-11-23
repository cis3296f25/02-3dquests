import subprocess
import asyncio
import signal
from typing import Dict
import os
import json
import psutil

BASE_PORT = 9000
SESSIONS_FILE = "/home/ubuntu/session-manager/src/sessions.json"


class ServerManager:
    def __init__(self):
        # campaign_id -> process info
        self.active_sessions: Dict[str, Dict] = self.load_sessions()

    async def start_server(self, campaign_id: str, session_token: str):
        # If server already running but the process died → restart
        if campaign_id in self.active_sessions:
            session = self.active_sessions[campaign_id]
            if self._process_alive(session["pid"]):
                print(f"[Manager] Server for campaign {campaign_id} already running")
                return session
            else:
                print(f"[Manager] Stale process detected, restarting server for {campaign_id}")
                await self.stop_server(campaign_id)

        port = self.get_available_port()
        print(port)
        # Launch Godot server
        cmd = [
            "/home/ubuntu/server/3DQuestsServer.x86_64",
            "--campaign-id=" + campaign_id,
            "--session-token=" + session_token,
            "--port=" + str(port),
            "--headless"
        ]
        try:
            process = subprocess.Popen(cmd, cwd="/home/ubuntu/server", preexec_fn=os.setsid)
        except Exception as e:
            print(f"[Manager] Failed to start server: {e}")
            raise

        self.active_sessions[campaign_id] = {
            "pid": process.pid,
            "port": port,
            "session_token": session_token
        }
        self.save_sessions()
        print(f"Started server for campaign {campaign_id} with PID {process.pid}")
        return process

    async def stop_server(self, campaign_id: str):
        if campaign_id not in self.active_sessions:
            print(f"No active server for campaign {campaign_id}")
            return

        pid = self.active_sessions[campaign_id]["pid"]
        os.kill(pid, signal.SIGTERM)

        print(f"Stopped server for campaign {campaign_id}")
        del self.active_sessions[campaign_id]
        self.save_sessions()

    def list_active_sessions(self):
        return list(self.active_sessions.keys())

    def get_available_port(self):
        used_ports = [s["port"] for s in self.active_sessions.values()]
        port = BASE_PORT
        while port in used_ports:
            port += 1
        return port

    def save_sessions(self):
        if os.path.exists(SESSIONS_FILE):
            with open(SESSIONS_FILE, "w") as file:
                json.dump(self.active_sessions, file, indent=4)

    def load_sessions(self):
        if os.path.exists(SESSIONS_FILE):
            with open(SESSIONS_FILE, "r") as file:
                try:
                    return json.load(file)
                except:
                    return {}

    def _process_alive(self, pid):
        return psutil.pid_exists(pid)