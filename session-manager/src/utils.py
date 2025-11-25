from .db import fetch_all, execute
from jwt.exceptions import InvalidTokenError
from fastapi import HTTPException
from datetime import datetime
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
        await execute("""
            INSERT INTO "ServerSession" ("campaignId", "awsSessionId", "pid", "port", "status", "activePlayers")
            VALUES ($1, $2, $3, $4, 'active', 0);
        """, campaign_id, session_token, pid, port)
        
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
        await execute("""
            -- 1) Try to update existing participant
            WITH updated AS (
                UPDATE "SessionParticipant"
                SET "connected" = TRUE,
                    "lastHeart" = $3
                WHERE "sessionId" = (SELECT id FROM "ServerSession" WHERE "awsSessionId" = $1)
                AND "userId" = $2
                RETURNING *
            )
            
            -- 2) If UPDATE affected 0 rows, INSERT new participant AND increment activePlayers
            INSERT INTO "SessionParticipant" ("sessionId", "userId", "connected", "joinedAt")
            SELECT 
                (SELECT id FROM "ServerSession" WHERE "awsSessionId" = $1),
                $2,
                TRUE,
                $3
            WHERE NOT EXISTS (SELECT 1 FROM updated);

            -- 3) Increment activePlayers only if this was a new participant
            UPDATE "ServerSession"
            SET "activePlayers" = "activePlayers" + 1
            WHERE "awsSessionId" = $1
            AND NOT EXISTS (SELECT 1 FROM updated);
        """, session_token, user_id, datetime.utcnow())
        return True
    except Exception as e:
        print("Problem in player_join: ", e)
        return False

async def player_left(session_token: str, user_id: str):
    try:
        await execute("""
            -- 1) Try to update participant IF they were connected before
            WITH updated AS (
                UPDATE "SessionParticipant"
                SET "connected" = FALSE,
                    "lastHeart" = $3
                WHERE "sessionId" = (SELECT id FROM "ServerSession" WHERE "awsSessionId" = $1)
                AND "userId" = $2
                AND "connected" = TRUE   -- Only disconnect if actually connected
                RETURNING *
            )

            -- 2) Only decrement activePlayers if a row was updated
            UPDATE "ServerSession"
            SET "activePlayers" = GREATEST("activePlayers" - 1, 0)
            WHERE "awsSessionId" = $1
            AND EXISTS (SELECT 1 FROM updated);
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