import { prisma } from "@/lib/prisma";
import { toJSONSchema } from "better-auth";
import { NextResponse } from "next/server";

// export async function POST(req: Request) {
//   try {
//     const { campaignId, name, mapData } = await req.json();

//     const map = await prisma.campaignMap.create({
//       name: name,
//       data: {
//         campaignId,
//         name,
//         data: mapData,
//       },
//     });

//     return NextResponse.json({ map, saved: true });
  
// } catch (error: any) {
//     console.error("Error saving map: ", error);

//     return NextResponse.json(
//       { error: "Failed to save map." },
//       { status: 500 }
//     );
//   }
// }

interface Params {
  campaign_id: string;
  map_name: string
}

export async function POST(req: Request, context: {params: Params}){
  try {
  const {campaign_id, map_name} = context.params;

  // Reading the JSON 
  const body = await req.json();
  const id = body.id;
  const obj_data = {
    pos: body.po_arr,
    rot: body.r_arr,
    path: body.pa_arr
  }

  let map_save; 

  if (id == -1) {  // New map save
    map_save = await prisma.campaignMap.create({
      data: {
        name: map_name,
        data: obj_data,
        campaignId: campaign_id,
      }
    })
  }

  // Overwrite existing map
  else {
  map_save = await prisma.campaignMap.update({
    where: {
      id: id
    },
    data: {
      name: map_name,
      data: obj_data
    }
  })}  
  // Return either new or given map ID
  return NextResponse.json({id: map_save.id, saved: true}, {status: 200})

} catch (error){
  console.error(error);
  return NextResponse.json(
    {error: "Failed to save map"},
    {status: 500}
  )
}
}