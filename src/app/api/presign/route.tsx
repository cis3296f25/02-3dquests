import { NextResponse, NextRequest } from 'next/server';
import { S3Client, GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

// Initialize S3 client
const s3Client = new S3Client({
  region: process.env.AWS_REGION!,
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY!,
    secretAccessKey: process.env.AWS_USER_SECRET!,
  },
});

const EXPIRATION_SECS = 300;

export async function GET(request: NextRequest) {
  try {
    // Get S3 object key
    const { searchParams } = new URL(request.url);
    const key = searchParams.get('key');

    if (!key) {
      return NextResponse.json({ error: 'Missing object key parameter' }, { status: 400 });
    }

    if (!process.env.AWS_BUCKET_NAME) {
      return NextResponse.json({ error: 'Server configuration error: S3 bucket not defined' }, { status: 500 });
    }

    // Create a command to get private object
    const command = new GetObjectCommand({
      Bucket: process.env.AWS_BUCKET_NAME,
      Key: key,
    });

    // Generate pre-signed URL valid for EXPIRATION_SECS
    const presignedUrl = await getSignedUrl(s3Client, command, {
      expiresIn: EXPIRATION_SECS,
    });

    // Return temp URL to Godot
    return NextResponse.json({
      success: true,
      presignedUrl: presignedUrl,
      expiration: EXPIRATION_SECS,
    });

  } catch (error) {
    console.error('Presign URL generation error:', error);
    return NextResponse.json({ error: 'Failed to generate signed URL.' }, { status: 500 });
  }
}