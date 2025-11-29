from fastapi import FastAPI, Request, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from .manager import ServerManager
from .utils import (
    get_auth_jwt,
    verify_jwt,
    is_existing_session,
    player_join,
    player_left,
    check_how_many_players,
    close_session,
    map_saved,
    maps_loaded,
    map_objects
)
from .db import pool, get_pool
import secrets
import asyncio
import websockets

manager = ServerManager()

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    global manager
    await manager.load_active_sessions()
    await get_pool()
    print("Database connected")
    try:
        yield
    finally:
        # Shutdown
        if pool is not None:
            await pool.close()
        print("Database disconnected")

app = FastAPI(lifespan=lifespan)



origins = [
    "http://localhost:3000",
    "https://3dquests.com",
    "https://www.3dquests.com",
    "https://02-3dquests.vercel.app"
]


app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"]
)

@app.get("/")
def root():
    return {"status": "ok"}

@app.post("/start")
async def start_session(request: Request):
    data = await request.json()
    auth_header = request.headers.get("Authorization")
    
    jwt = get_auth_jwt(auth_header)
    payload = verify_jwt(jwt)
    campaign_id = data["campaignId"]
    user_id = payload["userId"]
        
    if not campaign_id or not jwt:
        raise HTTPException(status_code=400, detail="Missing campaignId or token")
    
    
    if not user_id:
        raise HTTPException(status_code=401, detail="Invalid token")
    
    existing_session = await is_existing_session(campaign_id)
    if existing_session:
        if manager._process_alive(existing_session["pid"]):
            return {"status": "existing", "session_token": existing_session.awsSessionId}
        else:
            await manager.stop_server(campaign_id)

    session_token = secrets.token_hex(32)
    
    process = await manager.start_server(campaign_id, session_token)
    return {"status": "started", "pid": process.pid, "session_token": session_token}

@app.post("/stop")
async def stop_session(request: Request):
    data = await request.json()
    campaign_id = data["campaignId"]
    session_token = data["session_token"]
    if not campaign_id:
        raise HTTPException(status_code=400, detail="Missing campaign_id")
    await manager.stop_server(campaign_id)
    await close_session(session_token)
    return {"status": "stopped"}

@app.post("/join")
async def join(request: Request):
    data = await request.json()
    session_token = data.get("session_token")
    auth_header = request.headers.get("Authorization")
    jwt = get_auth_jwt(auth_header)
    payload = verify_jwt(jwt)
    user_id = payload["userId"]

    if not session_token or not user_id:
        raise HTTPException(status_code=400, detail="Missing session_id or user_id")

    ok = await player_join(session_token, user_id)
    if not ok:
        raise HTTPException(status_code=500, detail="Join failed")

    return {"status": "joined"}

@app.post("/leave")
async def leave(request: Request):
    data = await request.json()
    session_token = data.get("session_token")
    campaign_id = data.get("campaignId")
    auth_header = request.headers.get("Authorization")
    jwt = get_auth_jwt(auth_header)
    payload = verify_jwt(jwt)
    user_id = payload["userId"]

    if not session_token or not user_id:
        raise HTTPException(status_code=400, detail="Missing session_token or user_id")

    ok = await player_left(session_token, user_id)
    if not ok:
        raise HTTPException(status_code=500, detail="Leave failed")

    # If empty = stop server
    count = await check_how_many_players(session_token)
    if count == 0:
        await manager.stop_server(campaign_id)
        await close_session(session_token)

    return {"status": "left"}

@app.get("/active-sessions")
async def active_sessions():
    return {"active": manager.list_active_sessions()}

async def forward_ws(ws_client: WebSocket, ws_server_uri: str):
    """
    Forward messages bidirectionally between client and Godot server
    """
    async with websockets.connect(ws_server_uri) as ws_server:
        async def client_to_server():
            try:
                while True:
                    data = await ws_client.receive_text()
                    await ws_server.send(data)
            except WebSocketDisconnect:
                pass
            except Exception:
                pass

        async def server_to_client():
            try:
                async for message in ws_server:
                    await ws_client.send_text(message)
            except Exception:
                pass

        await asyncio.gather(client_to_server(), server_to_client())

@app.websocket("/server/{campaign_id}/{session_token}")
async def ws_proxy(websocket: WebSocket, campaign_id: str, session_token: str):
    # Accept the client connection
    await websocket.accept()

    # Find Godot port
    session = manager.active_sessions.get(campaign_id)
    if not session or session["session_token"] != session_token:
        await websocket.close(code=4003, reason="Invalid campaign or session token")
        return

    godot_port = session["port"]
    ws_server_uri = f"ws://127.0.0.1:{godot_port}"

    try:
        await forward_ws(websocket, ws_server_uri)
    except Exception as e:
        print(f"WebSocket proxy error: {e}")
        await websocket.close()

@app.post("/get-active-session")
async def get_active_session(request: Request):
    data = await request.json()
    campaign_id = data.get("campaignId")
    session = manager.active_sessions.get(campaign_id)
    print(session)
    return {"session_token": session["session_token"]}

@app.post("/save_map")
async def save_map(request: Request):
    data = await request.json()
    campaign_id = data.get("campaignId")
    map_name = data.get("name")
    map_data = data.get("data")
    if not campaign_id or not map_name or not map_data:
        raise HTTPException(status_code=400, detail="Missing campaignId or map name or map data")
    
    map_saved(campaign_id, map_name, map_data)
    print(f"Saving {map_name} for campaig: {campaign_id}")  
    
    return {"status": "map saved"}

@app.get("/load_maps")
async def load_maps(campaign_id: str):
    if not campaign_id:
        raise HTTPException(status_code=400, detail="Missing campaignId")
    
    map_data = maps_loaded(campaign_id)
    if not map_data:
        raise HTTPException(status_code=404, detail="Map not found")
    
    return {"maps": map_data}

@app.get("/load_map_objects")
async def load_map_objects(campaign_id: str, map_name: str):
    if not campaign_id or not map_name:
        raise HTTPException(status_code=400, detail="Missing campaignId or map name")
    
    object_data = map_objects(campaign_id, map_name)
    if object_data is None:
        raise HTTPException(status_code=404, detail="Map objects not found")
    
    return {"objects": object_data}