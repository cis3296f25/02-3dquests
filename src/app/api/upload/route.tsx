import { NextApiRequest, NextApiResponse } from 'next';
import { getServerSession } from 'next-auth';
import { authOptions } from '../auth/[...nextauth]';
import { prisma } from '../lib/prisma';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { v4 as uuidv4 } from 'uuid'; //generates unique IDs for images

const s3Client = new S3Client({
  region: process.env.AWS_REGION!,
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY!,
    secretAccessKey: process.env.AWS_USER_SECRET!,
  },
});

export const config = {
  api: {
    bodyParser: false,
  },
};

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const session = await getServerSession(req, res, authOptions);
    
    if (!session?.user?.id) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    // Parse multipart form data
    const formData = await req.formData();
    const file = formData.get('image') as File;
    
    if (!file) {
      return res.status(400).json({ error: 'No file provided' });
    }

    // Validate file type, note: only jpeg, jpg, png (Godot doesn’t work well with gif)
    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png'];
    if (!allowedTypes.includes(file.type)) {
      return res.status(400).json({ error: 'Invalid file type' });
    }

    // Validate file size (5MB max)
    const maxSize = 5 * 1024 * 1024;
    if (file.size > maxSize) {
      return res.status(400).json({ error: 'File is too large' });
    }

    const bytes = await file.arrayBuffer();
    const buffer = Buffer.from(bytes);

    // Generate unique filename
    const fileExtension = file.name.split('.').pop();
    const s3Key = `users/${session.user.id}/${uuidv4()}.${fileExtension}`;

    // Upload to S3
    const uploadParams = {
      Bucket: process.env.AWS_BUCKET_NAME!,
      Key: s3Key,
      Body: buffer,
      ContentType: file.type,
      ACL: 'public-read' as const,
    };

    await s3Client.send(new PutObjectCommand(uploadParams));
    
    const s3Url = `https://${process.env.AWS_BUCKET_NAME}.s3.${process.env.AWS_REGION}.amazonaws.com/${s3Key}`;

    // Save to database
    const image = await prisma.image.create({
      data: {
        filename: file.name,
        s3Key,
        url: s3Url,
        mimeType: file.type,
        size: file.size,
        userId: session.user.id,
      },
    });

    res.status(200).json({ 
      success: true, 
      image: {
        id: image.id,
        url: image.url,
        filename: image.filename
      }
    });

  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}
