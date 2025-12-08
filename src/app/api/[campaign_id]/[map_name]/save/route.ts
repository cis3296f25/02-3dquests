import { prisma } from "@/lib/prisma";
import { NextResponse } from "next/server";

export async function POST(req: Request) {
  try {
    const { campaignId, map_data } = await req.json();

    const newMap = await prisma.campaignMap.create({
      data: {
        campaignId,
        data: map_data,
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
