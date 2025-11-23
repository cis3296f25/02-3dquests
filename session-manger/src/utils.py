from jwt.exceptions import InvalidTokenError
from fastapi import HTTPException
from .db import db
import jwt
import dotenv
import datetime

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
    except InvalidTokenError:
        return None

async def user_can_access_campaign(user_id: int, campaign_id: str) -> bool:
    try:
        count = await db.campaignmember.count(
            where={
                "campaignId": campaign_id,
                "userId": user_id
            }
        )
        return count > 0
    except Exception as e:
        print("Error in user_can_access_campaign: ", e)
        return None

async def is_existing_session(campaign_id: str):
    try:
        return await db.serversession.find_first(
            where={
                "campaignId": campaign_id,
                "status": "active"
            }
        )
    except Exception as e:
        print("Problem in is_existing_session: ", e)
        return False

async def add_new_session(campaign_id: str, session_token: str):
    try:
        session = await db.serversession.create(
            data={
                "campaignId": campaign_id,
                "awsSessionId": session_token,
                "status": "active",
                "activePlayers": 0,
            }
        )
        return session
    except Exception as e:
        print("Problem in add_new_session: ", e)
        return None

async def player_join(session_token: str, user_id: str):
    try:
        session = await db.serversession.find_first(where={"awsSessionId": session_token})
        if not session:
            raise ValueError("Session not found")

        # Check if participant already exists
        existing = await db.sessionparticipant.find_first(
            where={"sessionId": session.id, "userId": user_id}
        )
        if existing:
            # Just mark them connected
            await db.sessionparticipant.update(
                where={"id": existing.id}, data={"connected": True, "lastHeart": datetime.utcnow()}
            )
        else:
            await db.sessionparticipant.create(
                data={
                    "sessionId": session.id,
                    "userId": user_id,
                    "connected": True,
                    "joinedAt": datetime.utcnow(),
                }
            )

        # Increment activePlayers
        await db.serversession.update(
            where={"id": session.id},
            data={"activePlayers": session.activePlayers + 1},
        )
        return True
    except Exception as e:
        print("Problem in player_join: ", e)
        return False

async def player_left(session_token: str, user_id: str):
    try:
        session = await db.serversession.find_first(where={"awsSessionId": session_token})
        if not session:
            raise ValueError("Session not found")

        participant = await db.sessionparticipant.find_first(
            where={"sessionId": session.id, "userId": user_id}
        )
        if participant and participant.connected:
            await db.session_participant.update(
                where={"id": participant.id}, data={"connected": False, "lastHeart": datetime.utcnow()}
            )

            # Decrement activePlayers but not below 0
            new_count = max(session.activePlayers - 1, 0)
            await db.server_session.update(
                where={"id": session.id},
                data={"activePlayers": new_count},
            )
            return True
    except Exception as e:
        print("Problem in player_left: ", e)
        return False
    
async def check_how_many_players(session_token: str):
    try:
        session = await db.serversession.find_first(where={"awsSessionId": session_token})
        if not session:
            print(f"No session found with token: {session_token}")
            return None

        return session.activePlayers
    except Exception as e:
        print("Problem in check_how_many_players: ", e)
        return None
    
async def update_closed_server(session_token: str):
    try:
        session = await db.serversession.find_first(
            where={
                "awsSessionId": session_token
            }
        )
        
        if session:
            await db.serversession.update(
                where={
                    "awsSessionId": session_token
                },
                data={
                    "active": False
                }
            )
            return True
    except Exception as e:
        print("Problem in update_closed_server: ", e)
        return False