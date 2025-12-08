import { prisma } from "@/lib/prisma";
<<<<<<< HEAD
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
=======
import { NextResponse } from "next/server";

export async function POST(req: Request) {
  try {
    const { campaignId, mapData } = await req.json();

    const newMap = await prisma.campaignMap.create({
      data: {
        campaignId,
        data: mapData,
      },
    });

    return NextResponse.json({ newMap, saved: true });
  
} catch (error: any) {
    console.error("Error saving map: ", error);

    return NextResponse.json(
      { error: "Failed to save map." },
      { status: 500 }
    );
  }
}
>>>>>>> cd0f542dabf2f5714b28b0e6fcbefbb37aee99fd
