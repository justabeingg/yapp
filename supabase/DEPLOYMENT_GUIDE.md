# Deploying Edge Functions to Supabase

## Prerequisites
- Supabase CLI installed
- AWS S3 credentials stored in Supabase secrets

---

## Step 1: Install Supabase CLI

### Windows (PowerShell):
```powershell
scoop install supabase
```

Or download from: https://github.com/supabase/cli/releases

### Verify installation:
```bash
supabase --version
```

---

## Step 2: Login to Supabase

```bash
supabase login
```

This will open a browser window. Login with your Supabase account.

---

## Step 3: Link Your Project

```bash
cd D:\yapp
supabase link --project-ref YOUR_PROJECT_REF
```

**How to find YOUR_PROJECT_REF:**
1. Go to Supabase Dashboard
2. Project Settings → General
3. Copy "Reference ID"

---

## Step 4: Set Environment Secrets

```bash
supabase secrets set AWS_ACCESS_KEY_ID=your_access_key_id
supabase secrets set AWS_SECRET_ACCESS_KEY=your_secret_access_key  
supabase secrets set AWS_REGION=ap-south-1
supabase secrets set AWS_BUCKET_NAME=yapp-media-production
```

**Replace** `your_access_key_id` and `your_secret_access_key` with your actual AWS credentials from Phase 2.

---

## Step 5: Deploy Functions

Deploy all 3 functions at once:

```bash
supabase functions deploy generate-upload-url
supabase functions deploy process-audio
supabase functions deploy create-yap
```

Each command will output a URL like:
```
Deployed Function generate-upload-url
URL: https://YOUR_PROJECT_REF.supabase.co/functions/v1/generate-upload-url
```

**Save these URLs** - you'll need them in your Flutter app.

---

## Step 6: Add Helper SQL Function

1. Go to Supabase Dashboard → SQL Editor
2. Paste contents of `supabase/increment_reply_count.sql`
3. Click "Run"

---

## Step 7: Test Functions

### Test generate-upload-url:
```bash
curl -X POST \
  'https://yclrizfepzfutwusgheu.supabase.co/functions/v1/generate-upload-url' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{"fileExtension": "ogg", "contentType": "audio/ogg", "durationSeconds": 15}'
```

**Expected response:**
```json
{
  "uploadUrl": "https://yapp-media-production.s3.ap-south-1.amazonaws.com/...",
  "fileKey": "raw/audio/USER_ID/...",
  "mediaFileId": "..."
}
```

---

## Function URLs

After deployment, your function URLs will be:

1. **generate-upload-url:**  
   `https://YOUR_PROJECT_REF.supabase.co/functions/v1/generate-upload-url`

2. **process-audio:**  
   `https://YOUR_PROJECT_REF.supabase.co/functions/v1/process-audio`

3. **create-yap:**  
   `https://YOUR_PROJECT_REF.supabase.co/functions/v1/create-yap`

---

## Important Notes

### Current Limitations (Phase 1):

1. **No actual FFmpeg processing yet** - `process-audio` currently just copies the raw audio for all 4 filters
   - This is intentional for MVP
   - Actual filter processing will be added in Phase 2
   
2. **No transcript generation yet** - Whisper API integration comes in Phase 2

3. **S3 URLs are direct** - CloudFront CDN will be added later for faster delivery

### What Works Right Now:

✓ User can record audio in Flutter
✓ Get presigned S3 URL
✓ Upload directly to S3
✓ Trigger processing (creates 4 filter versions)
✓ Create yap post with selected filter
✓ Database properly tracks everything

---

## Troubleshooting

### "Function not found" error:
- Make sure you ran `supabase link` first
- Check project ref is correct

### "Unauthorized" error:
- Check your Authorization header includes Bearer token
- Verify user is logged in

### AWS S3 errors:
- Verify secrets are set correctly: `supabase secrets list`
- Check AWS credentials have S3 access
- Verify bucket name matches

---

## Next Steps After Deployment:

1. Update Flutter app with function URLs
2. Implement recording → upload → preview flow
3. Test end-to-end
4. Add actual FFmpeg processing (Phase 2)
5. Add Whisper transcription (Phase 2)
