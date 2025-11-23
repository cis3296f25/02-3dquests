import dotenv
dotenv.load_dotenv()
from prisma import Prisma
import asyncio

db = Prisma()

async def main():
    await db.connect()
    campaign = await db.campaign.find_first()
    if campaign:
        print(campaign.__dict__)
    print()
    campaignmember = await db.campaignmember.find_first()
    if campaignmember:
        print(campaignmember.__dict__)
    await db.disconnect()

if __name__ == "__main__":
    asyncio.run(main())