from fastapi import FastAPI, Request, HTTPException
from .manager import ServerManager
from .utils import verify_jwt, user_can_access_campaign
import secrets


app = FastAPI()
manager = ServerManager()

@app.post("/start")
async def start_session(request: Request):
    data = await request.json()
    campaign_id = data["campaignId"]
    jwt = data["token"]
    
    if not campaign_id or not jwt:
        raise HTTPException(status_code=400, detail="Missing campaignId or token")
    
    user = verify_jwt(jwt)
    if not user:
        raise HTTPException(status_code=401, detail="Invalid token")
    
    if not user_can_access_campaign(user, campaign_id):
        raise HTTPException(status_code=403, detail="Access denied to campaign")

    session_token = secrets.token_hex(32)
    
    process = await manager.start_server(campaign_id, session_token)
    return {"status": "started", "pid": process.pid, "session_token": session_token}

@app.post("/stop")
async def stop_session(request: Request):
    data = await request.json()
    campaign_id = data["campaignId"]
    await manager.stop_server(campaign_id)
    return {"status": "stopped"}

@app.get("/active-sessions")
async def active_sessions():
    return {"active": manager.list_active_sessions()}
