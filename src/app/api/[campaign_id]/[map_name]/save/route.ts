import { prisma } from "@/lib/prisma";
import { NextResponse } from "next/server";

export async function POST(req: Request) {
  try {
    const { campaignId, map_data, map_name } = await req.json();

    const newMap = await prisma.campaignMap.upsert({
      where: {
        campaignId_name: {
          campaignId: campaignId,
          name: map_name
        },
        
      },
      update: {
        data: map_data,
      },
      create: {
        campaignId,
        data: map_data,
        name: map_name
      }
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
