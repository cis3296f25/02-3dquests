'use client';

import React, { useState, useCallback, useMemo } from 'react';

import { Upload, XCircle, CheckCircle, Loader2, Image as ImageIcon } from 'lucide-react';

type UploadStatus = 'idle' | 'pending' | 'success' | 'error';

//function to format file sizes
const formatFileSize = (bytes: number, decimalPoint: number = 2): string => {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const dm = decimalPoint < 0 ? 0 : decimalPoint;
  const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
};

const MAX_FILE_SIZE_MB = 10;
const API_ENDPOINT = '/api/upload';

export default function AddMap() {
  const [file, setFile] = useState<File | null>(null);
  const [status, setStatus] = useState<UploadStatus>('idle');
  const [message, setMessage] = useState('');
  const [uploadProgress, setUploadProgress] = useState(0);

  // select image files from user device
  const handleFileChange = useCallback((event: React.ChangeEvent<HTMLInputElement>) => {
    const selectedFile = event.target.files?.[0] || null;

    setFile(null); // Reset file and state on new selection
    setStatus('idle');
    setMessage('');
    setUploadProgress(0);

    if (selectedFile) {
      // Validate file type and size
      if (!['image/jpeg', 'image/png'].includes(selectedFile.type)) {
        setMessage('Only JPEG or PNG files are allowed.');
        setStatus('error');
        return;
      }
      if (selectedFile.size > MAX_FILE_SIZE_MB * 1024 * 1024) {
        setMessage(`File size exceeds ${MAX_FILE_SIZE_MB}MB.`);
        setStatus('error');
        return;
      }
      setFile(selectedFile);
      setMessage(`Ready for uploading: ${selectedFile.name}`);
    }
  }, []);

  // Simulates upload process to AWS server.
  const handleUpload = useCallback(async () => {
    if (!file) {
      setMessage('Please select a file first.');
      setStatus('error');
      return;
    }

    setStatus('pending');
    setMessage(`Uploading "${file.name}"...`);
    setUploadProgress(0);

    //  Simulating The Upload Progress
    const progressInterval = setInterval(() => {
      setUploadProgress(prev => {
        if (prev < 90) return prev + 5;
        // Don't clear the interval here, let the fetch success/error do it
        return prev;
      });
    }, 200);
    // Prepare form data
    const formData = new FormData();
    formData.append('image', file);
    formData.append('fileName', file.name);

    try {
      // This is the API call
      const response = await fetch(API_ENDPOINT, {
        method: 'POST',
        body: formData,
      });

      // Clear the progress simulation
      clearInterval(progressInterval);

      if (response.ok) {
        const result = await response.json();
        setUploadProgress(100);
        setStatus('success');
        setMessage(`File Upload successful! URL: ${result.url}`);
      } else {
        const errorText = await response.text();
        throw new Error(`Server error: ${response.statusText}. Detail: ${errorText.substring(0, 100)}`);
      }
    } catch (error) {
      clearInterval(progressInterval);
      setUploadProgress(0);
      setStatus('error');
      setMessage(`Upload failed. ${error instanceof Error ? error.message : 'Unknown error.'}`);
    }
  }, [file]);

  const buttonDisabled = status === 'pending' || !file;
  const isImageSelected = useMemo(() => file && file.type.startsWith('image/'), [file]);

  const statusColors = useMemo(() => {
    switch (status) {
      case 'success':
        return { icon: CheckCircle, className: 'text-green-500 border-green-300 bg-green-50' };
      case 'error':
        return { icon: XCircle, className: 'text-red-500 border-red-300 bg-red-50' };
      case 'pending':
        return { icon: Loader2, className: 'text-blue-500 border-blue-300 bg-blue-50 animate-spin' };
      default:
        return { icon: ImageIcon, className: 'text-gray-500 border-gray-300 bg-gray-100' };
    }
  }, [status]);

  return (
    <div className="flex items-center justify-center min-h-screen">
      <div className="w-full flex flex-col bg-gray-100 p-4 rounded-lg shadow max-w-sm mx-auto">
        <h1 className="text-3xl font-extrabold text-gray-900 mb-2 flex items-center">
          <Upload className="w-8 h-8 mr-3 text-indigo-600" />
          Upload Image to Game
        </h1>
        <p className="text-gray-600 mb-8">
          Select an image (JPEG, or PNG) to upload. Max size: {MAX_FILE_SIZE_MB}MB.
        </p>

        <div className="mb-8">
          <label
            htmlFor="file-upload"
            className={`flex flex-col items-center justify-center p-8 rounded-xl cursor-pointer transition-all duration-200 ease-in-out
              ${isImageSelected ? 'border-2 border-dashed border-indigo-400 bg-indigo-50 hover:bg-indigo-100' : 'border-2 border-dashed border-gray-300 bg-white hover:bg-gray-50'}
              ${status === 'error' ? 'border-red-500 bg-red-50 hover:bg-red-100' : ''}
              ${status === 'pending' ? 'pointer-events-none' : ''}
            `}
          >
            <input
              id="file-upload"
              type="file"
              accept="image/png, image/jpeg"
              onChange={handleFileChange}
              className="sr-only"
              disabled={status === 'pending'}
            />
            <ImageIcon className={`w-10 h-10 ${isImageSelected ? 'text-indigo-600' : 'text-gray-400'} mb-2 transition-colors`} />
            <p className="text-lg font-semibold text-gray-700 text-center">
              {file ? file.name : 'Click to select image or drag and drop'}
            </p>
            {file && (
              <p className="text-sm text-gray-500 mt-1">
                Size: {formatFileSize(file.size)}
              </p>
            )}
          </label>
        </div>

        <button
          onClick={handleUpload}
          disabled={buttonDisabled}
          className={`w-full py-3 px-4 rounded-xl font-bold text-white transition-all duration-300 ease-in-out shadow-md
            ${buttonDisabled
              ? 'bg-indigo-300 cursor-not-allowed'
              : 'bg-indigo-600 hover:bg-indigo-700 active:bg-indigo-800 shadow-indigo-500/50 hover:shadow-lg'
            }
            flex items-center justify-center
          `}
        >
          {status === 'pending' ? (
            <>
              <Loader2 className="w-5 h-5 mr-2 animate-spin" />
              Uploading...
            </>
          ) : (
            <>
              <Upload className="w-5 h-5 mr-2" />
              Start Upload
            </>
          )}
        </button>

        {message && (
          <div className={`mt-6 p-4 rounded-xl border flex items-start text-sm ${statusColors.className}`}>
            <statusColors.icon className={`w-5 h-5 mr-3 flex-shrink-0 ${statusColors.className.split(' ')[0]}`} />
            <p className="font-medium whitespace-pre-wrap">{message}</p>
          </div>
        )}

        {status === 'pending' && (
          <div className="w-full mt-4">
            <div className="flex justify-between mb-1 text-sm font-medium text-indigo-700">
              <span>Upload Progress</span>
              <span>{uploadProgress}%</span>
            </div>
            <div className="w-full bg-gray-200 rounded-full h-2.5">
              <div
                className="bg-indigo-600 h-2.5 rounded-full transition-all duration-500"
                style={{ width: `${uploadProgress}%` }}
              ></div>
            </div>
          </div>
        )}

      </div>
    </div>
  );
};
