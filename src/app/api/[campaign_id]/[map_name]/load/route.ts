import { prisma } from "@/lib/prisma";
import { success } from "better-auth";
import { NextResponse } from "next/server";


export async function POST(req: Request, context: {params: Params}){
    const {campaign_id, map_name} = context.params;

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
