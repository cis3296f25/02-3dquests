from fastapi import FastAPI, Request
import asyncio
from .manager import ServerManager

app = FastAPI()
manager = ServerManager()

@app.post("/start")
async def start_session(request: Request):
    data = await request.json()
    campaign_id = data["campaignId"]
    jwt = data["token"]
    process = await manager.start_server(campaign_id, jwt)
    return {"status": "started", "pid": process.pid}

@app.post("/stop")
async def stop_session(request: Request):
    data = await request.json()
    campaign_id = data["campaignId"]
    await manager.stop_server(campaign_id)
    return {"status": "stopped"}

@app.get("/active-sessions")
async def active_sessions():
    return {"active": manager.list_active_sessions()}
