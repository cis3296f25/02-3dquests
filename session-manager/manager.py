import subprocess
import asyncio
import signal
from typing import Dict

BASE_PORT = 9000

class ServerManager:
    def __init__(self):
        # campaign_id -> process info
        self.active_sessions: Dict[str, subprocess.Popen] = {}

    async def start_server(self, campaign_id: str, jwt: str):
        if campaign_id in self.active_sessions:
            print(f"Server for campaign {campaign_id} is already running")
            return self.active_sessions[campaign_id]

        port = self.get_available_port()
        # Launch Godot server
        # Assumes you have exported the server as `GodotServer.x86_64` in /servers/
        cmd = [
            "./GodotServer.x86_64",
            "--campaign_id", campaign_id,
            "--port", port,
            "--token", jwt,
            "--headless"
        ]
        process = subprocess.Popen(cmd)
        self.active_sessions[campaign_id] = {
            "process": process,
            "port": port
        }
        print(f"Started server for campaign {campaign_id} with PID {process.pid}")
        return process

    async def stop_server(self, campaign_id: str):
        if campaign_id not in self.active_sessions:
            print(f"No active server for campaign {campaign_id}")
            return

        process = self.active_sessions[campaign_id]
        process.send_signal(signal.SIGINT)
        await asyncio.sleep(1)
        process.terminate()
        process.wait()
        print(f"Stopped server for campaign {campaign_id}")
        del self.active_sessions[campaign_id]

    def list_active_sessions(self):
        return list(self.active_sessions.keys())
    
    def get_available_port(self):
        used_ports = [s["port"] for s in self.active_sessions.values()]
        port = BASE_PORT
        while port in used_ports:
            port += 1
        return port
