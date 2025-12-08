import subprocess
import signal
from typing import Dict
import os
import psutil
from .utils import add_new_session, close_session, get_all_active_sessions
from fastapi import HTTPException

BASE_PORT = 9000

class ServerManager:
    def __init__(self):
        # campaign_id -> process info
        self.active_sessions: Dict[str, Dict] = {}
        
    async def load_active_sessions(self):
        sessions = await get_all_active_sessions()
        self.active_sessions = {
            k: v for k, v in sessions.items() if self._process_alive(v["pid"])
        }

    async def start_server(self, campaign_id: str, session_token: str):
        # If server already running but the process died → restart
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
        
        created = await add_new_session(campaign_id, session_token, process.pid, port)
        if not created:
            if self._process_alive(process.pid):
                os.kill(process.pid, signal.SIGTERM)
            raise HTTPException(status_code=500, detail="Failed to create session in db")

        self.active_sessions[campaign_id] = {
            "pid": process.pid,
            "port": port,
            "session_token": session_token
        }
        print(f"Started server for campaign {campaign_id} with PID {process.pid}")
        return process

    async def stop_server(self, campaign_id: str):
        pid = self.active_sessions[campaign_id]["pid"]
        session_token = self.active_sessions[campaign_id]["session_token"]
        try:
            if self._process_alive(pid):
                os.kill(pid, signal.SIGTERM)
        except Exception as e:
            print(f"No process with PID {pid} found: {e}")
            
        print(f"Stopped server for campaign {campaign_id}")
        del self.active_sessions[campaign_id]
        await close_session(session_token)

    def list_active_sessions(self):
        return list(self.active_sessions.keys())

    def get_available_port(self):
        used_ports = [s["port"] for s in self.active_sessions.values()]
        port = BASE_PORT
        while port in used_ports:
            port += 1
        return port

    def _process_alive(self, pid):
        return psutil.pid_exists(pid)