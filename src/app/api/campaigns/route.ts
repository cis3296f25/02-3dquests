import { prisma } from "@/lib/prisma";
import { auth } from "@/lib/auth";
import { NextResponse } from "next/server";
import { headers } from "next/headers"

export async function POST(req: Request) {
    const session = await auth.api.getSession({headers: await headers()});
    if (!session) {
        return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const userId = parseInt(session.user.id);

    try {
        const { name, description } = await req.json();

        const campaign = await prisma.campaign.create({
            data: {
            name,
            description,
            gmId: userId,
            maps: {
                create: {
                link: "/maps/default_map.png"
                },
            },
            members: {
                create: [
                    {
                        userId,
                        role: "GM"
                    },
                ],
            },
            },
        });

        return NextResponse.json(campaign, { status: 201 });
    } catch (error: any) {
        console.error(error);
        return NextResponse.json(
            { error: "Failed to create campaign" },
            { status: 500 }
        );
    }
}
