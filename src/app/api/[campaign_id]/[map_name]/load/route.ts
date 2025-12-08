import { prisma } from "@/lib/prisma";
import { success } from "better-auth";
import { NextResponse } from "next/server";

interface Params {
    campaign_id: string;
    map_name: string;
}

export async function GET(req: Request, context: {params: Params}){
    const {campaign_id, map_name} = context.params;

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
        {status: 404}
    );
    }

    return NextResponse.json({
        success: true,
        map_data: map.data
    },
    {status: 200}
)
    
}
