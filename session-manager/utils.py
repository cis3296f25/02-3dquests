import jwt
from jwt import InvalidTokenError
import dotenv
import asyncpg

JWT_SECRET = dotenv.get_key(".env, JWT_SECRET")
DATABASE_URL = dotenv.get_key(".env", "DATABASE_URL")
JWT_ALGO = "HS256"

def verify_jwt(token: str):
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGO])
        return payload
    except InvalidTokenError:
        return None
    
async def user_can_access_campaign(user: dict, campaign_id: str) -> bool:
    conn = await asyncpg.connect(DATABASE_URL)
    query = """
        SELECT COUNT(*) FROM campaign_users
        WHERE campaign_id = $1 AND user_id = $2
    """
    count = await conn.fetchval(query, campaign_id, user["sub"])
    await conn.close()
    return count > 0
