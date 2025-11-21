import { prisma } from "@/lib/prisma"
import { auth } from "@/lib/auth" 
import { headers } from "next/headers"
import Link from "next/link"

export default async function CampaignHome() {

    const session = await auth.api.getSession({
        headers: await headers() 
    })

    if (!session) {
        return <h1>Oops</h1>
    }

    const userId = parseInt(session.user.id);

    const playerCampaigns = await prisma.campaign.findMany({
        where: {
            members: {
                some: { userId },
            },
        },
    });

    const gmCampaigns = await prisma.campaign.findMany({
        where: {
            gmId: userId, 
        },
    });

    return (
        <div className="flex items-center justify-center min-h-screen">
            <div className="flex flex-col space-y-4 bg-grey p-4 rounded-lg shadow max-w-sm mx-auto">
                <Link href="/dashboard/campaigns/add-campaign">+Add a Campaign</Link>

                <h1 className="">My GM Campaigns</h1>
                {gmCampaigns.map((c) => (
                    <Link href={`/dashboard/campaigns/${c.id}`} key={c.id}>{c.name}</Link>
                ))}

                <h1 className="">My Player Campaigns</h1>
                {playerCampaigns.map((c) => (
                    <Link href={`/dashboard/campaigns/${c.id}`} key={c.id}>{c.name}</Link>
                ))}
            </div>
        </div>
    );
}