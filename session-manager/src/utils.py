from .db import fetch_all, execute
from jwt.exceptions import InvalidTokenError
from fastapi import HTTPException
from datetime import datetime
from uuid import uuid4
import jwt
import dotenv


JWT_SECRET = dotenv.get_key(".env", "JWT_SECRET")
JWT_ALGO = "HS256"

def get_auth_jwt(auth_header):
    if not auth_header:
        raise HTTPException(status_code=401, detail="Missing Authorization header")
    
    parts = auth_header.split()

    if len(parts) != 2 or parts[0].lower() != "bearer":
        raise HTTPException(status_code=401, detail="Invalid Authorization header format")

    return parts[1]


def verify_jwt(token: str):
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGO])
        if not payload or "userId" not in payload:
            raise HTTPException(status_code=401, detail="Invalid token")
        return payload
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid token")

async def is_existing_session(campaign_id: str):
    try:
        session = await fetch_all("""
            SELECT * FROM "ServerSession"
            WHERE "campaignId" = $1 AND "status" = 'active';         
        """, campaign_id)
        if not session:
            return None
        row = dict(session[0])
        return row
    except Exception as e:
        print("Problem in is_existing_session: ", e)
        return None

async def add_new_session(campaign_id: str, session_token: str, pid: int, port: int):
    try:
        new_id = str(uuid4())
        await execute("""
            INSERT INTO "ServerSession" ("id", "campaignId", "awsSessionId", "pid", "port", "status", "activePlayers")
            VALUES ($1, $2, $3, $4, $5, 'active', 0);
        """, new_id, campaign_id, session_token, pid, port)
        
        session = await fetch_all("""
            SELECT * FROM "ServerSession"
            WHERE "campaignId" = $1 AND "awsSessionId" = $2 AND "status" = 'active';
        """, campaign_id, session_token)
        
        row = dict(session[0])
        return row
        
    except Exception as e:
        print("Problem in add_new_session: ", e)
        return None

async def player_join(session_token: str, user_id: str):
    try:
        new_id = str(uuid4())
        await execute("""
            WITH
            -- 1) Try to update existing participant
            updated AS (
                UPDATE "SessionParticipant"
                SET "connected" = TRUE,
                    "lastHeart" = $4
                WHERE "sessionId" = (
                        SELECT id FROM "ServerSession" WHERE "awsSessionId" = $2
                    )
                  AND "userId" = $3
                RETURNING id
            ),

            -- 2) Insert new participant if no update happened
            inserted AS (
                INSERT INTO "SessionParticipant"
                    ("id", "sessionId", "userId", "connected", "joinedAt")
                SELECT
                    $1,
                    (SELECT id FROM "ServerSession" WHERE "awsSessionId" = $2),
                    $3,
                    TRUE,
                    $4
                WHERE NOT EXISTS (SELECT 1 FROM updated)
                RETURNING id
            ),

            -- 3) Increment activePlayers only if a new participant was inserted
            inc AS (
                UPDATE "ServerSession"
                SET "activePlayers" = "activePlayers" + 1
                WHERE "awsSessionId" = $2
                  AND EXISTS (SELECT 1 FROM inserted)
                RETURNING id
            )

            SELECT 1;  -- dummy SELECT to make it a valid single statement
        """, new_id, session_token, user_id, datetime.utcnow())
        return True
    except Exception as e:
        print("Problem in player_join: ", e)
        return False

async def player_left(session_token: str, user_id: str):
    try:
        await execute("""
            WITH
            -- 1) Update the participant ONLY if they were connected
            updated AS (
                UPDATE "SessionParticipant"
                SET "connected" = FALSE,
                    "lastHeart" = $3
                WHERE "sessionId" = (
                        SELECT id FROM "ServerSession"
                        WHERE "awsSessionId" = $1
                    )
                AND "userId" = $2
                AND "connected" = TRUE
                RETURNING id
            ),

            -- 2) Decrement activePlayers only if a row was updated
            dec AS (
                UPDATE "ServerSession"
                SET "activePlayers" = GREATEST("activePlayers" - 1, 0)
                WHERE "awsSessionId" = $1
                AND EXISTS (SELECT 1 FROM updated)
                RETURNING id
            )

            SELECT 1;  -- makes the whole thing a single valid SQL statement
        """, session_token, user_id, datetime.utcnow())

        return True
    except Exception as e:
        print("Problem in player_left: ", e)
        return False
    
async def check_how_many_players(session_token: str):
    try:
        session = await fetch_all("""
            SELECT "activePlayers" FROM "ServerSession"
            WHERE "awsSessionId" = $1;
        """, session_token)
        if not session:
            return None
        row = session[0]
        return int(row["activePlayers"])
    except Exception as e:
        print("Problem in check_how_many_players: ", e)
        return None
    
async def close_session(session_token: str):
    try:
        await execute("""
            UPDATE "ServerSession"
            SET "status" = 'closed'
            WHERE "awsSessionId" = $1;
        """, session_token)
        return True
    except Exception as e:
        print("Problem in update_closed_server: ", e)
        return False
    
async def get_all_active_sessions():
    try:
        sessions = await fetch_all("""
            SELECT * FROM "ServerSession"
            WHERE "status" = 'active';
        """)
        sessions = [dict(row) for row in sessions]
        session_dict = {
            row["campaignId"]: {
                "pid": row["pid"],
                "port": row["port"],
                "session_token": row["awsSessionId"]
            }
            for row in sessions
        }
        return session_dict
    except Exception as e:
        print("Problem in get_all_active_sessions: ", e)
        return []

async def map_saved(campaign_id: str, map_name: str, map_data: str):
    try:
        await execute("""
            INSERT INTO "CampaignMap" ("id", "name", "description", "data", "campaignId")
            VALUES ($1, $2, $3, $4, $5)
            ON CONFLICT ("campaignId", "name")
            DO UPDATE SET data = EXCLUDED.data;
        """, str(uuid4()), map_name, "Placeholder", map_data, campaign_id)
        return True
    except Exception as e:
        print("Problem in map_saved: ", e)
        return False
    
    
async def maps_loaded(campaign_id: str):
    try:
        maps = await fetch_all("""
            SELECT "name" FROM "CampaignMap"
            WHERE "campaignId" = $1;
        """, campaign_id)
        maps = [row["name"] for row in maps]
        return maps
    except Exception as e:
        print("Problem in maps_loaded: ", e)
        return []

async def map_objects(campaign_id: str, map_name: str):
    try:
        map_obj = await fetch_all("""
            SELECT "data" FROM "CampaignMap"
            WHERE "campaignId" = $1 AND "mapName" = $2;
        """, campaign_id, map_name)
        if not map_obj:
            return None
        row = dict(map_obj[0])
        return row["objects"]
    except Exception as e:
        print("Problem in map_objects: ", e)
        return None