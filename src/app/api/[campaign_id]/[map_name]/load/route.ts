import { prisma } from "@/lib/prisma";
import { success } from "better-auth";
import { NextResponse } from "next/server";


export async function POST(req: Request) {
    try {

        const { campaign_id, map_name } = await req.json();;

        const map = await prisma.campaignMap.findFirst({
            where: {
                campaignId: campaign_id,
                name: map_name
            }
        })

        if (!map) {
            return NextResponse.json({
                success: false,
                error: "Map not found"
            },
                { status: 404 }
            );
        }

        return NextResponse.json({
            success: true,
            map_data: map.data
        },
            { status: 200 }
        )
    } catch (error: any) {
        console.error(error);
    }


}
