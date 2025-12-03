import { NextApiRequest, NextApiResponse } from 'next';
import { getServerSession } from 'next-auth';
import { authOptions } from '../../auth/[...nextauth]';
import { prisma } from '@/lib/prisma;

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  const { userId } = req.query;

  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    // Optional: Add authentication if you want to secure this endpoint
    const session = await getServerSession(req, res, authOptions);
    
    // If you want to make sure users can only see their own images:
    // if (!session || session.user.id !== userId) {
    //   return res.status(403).json({ error: 'Forbidden' });
    // }

    const images = await prisma.image.findMany({
      where: { userId: userId as string },
      select: {
        id: true,
        url: true,
        filename: true,
        mimeType: true,
        createdAt: true,
      },
      orderBy: { createdAt: 'desc' },
    });

    res.status(200).json({ images });
  } catch (error) {
    console.error('Error fetching images:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}
