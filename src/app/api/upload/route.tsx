import { NextResponse } from 'next/server';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';

// Initialize S3 client
const s3Client = new S3Client({
  region: process.env.AWS_REGION!,
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY!,
    secretAccessKey: process.env.AWS_USER_SECRET!,
  },
});

export async function POST(request: Request) {
  try {
    // Validate environment variables
    if (!process.env.AWS_REGION || !process.env.AWS_BUCKET_NAME || !process.env.AWS_ACCESS_KEY || !process.env.AWS_USER_SECRET) {
      console.error('Server configuration error: Missing AWS environment variables.');
      return NextResponse.json({ error: 'Server configuration error' }, { status: 500 });
    }

    const formData = await request.formData();
    const file = formData.get('image') as File | null;

    if (!file) {
      return NextResponse.json({ error: 'No file provided' }, { status: 400 });
    }

    // Security validation (Type & Size)
    const allowedTypes = ['image/jpeg', 'image/png'];
    if (!allowedTypes.includes(file.type)) {
      return NextResponse.json({ error: `Invalid file type. Only JPEG, and PNG allowed.` }, { status: 400 });
    }

    // File size limit (10MB)
    const maxSize = 10 * 1024 * 1024;
    if (file.size > maxSize) {
      return NextResponse.json({ error: 'File too large. Maximum size is 10MB.' }, { status: 400 });
    }

    // Process file
    const buffer = Buffer.from(await file.arrayBuffer());
    // Filename sanitization
    const fileName = `images/${Date.now()}-${file.name.replace(/[^a-zA-Z0-9.-]/g, '_')}`;

    // Upload to S3
    await s3Client.send(new PutObjectCommand({
      Bucket: process.env.AWS_BUCKET_NAME!,
      Key: fileName,
      Body: buffer,
      ContentType: file.type,
    }));

    // Construct object key URL (NOTE: This URL will only work if the object is retrieved via a pre-signed URL)
    const imageUrl = `https://${process.env.AWS_BUCKET_NAME}.s3.${process.env.AWS_REGION}.amazonaws.com/${fileName}`;

    // TODO: Figure out how to Save to database with user association
    

    return NextResponse.json({
      success: true,
      url: imageUrl,
      message: 'Image uploaded successfully'
    });

  } catch (error) {
    console.error('Upload error:', error);
    return NextResponse.json({ error: 'Upload failed. Please try again.' }, { status: 500 });
  }
}