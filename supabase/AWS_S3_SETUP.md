# AWS S3 Setup Guide for Yapp

## Overview
This guide walks through setting up AWS S3 (Mumbai region) for Yapp's media storage.

---

## Phase 1: Create S3 Bucket (Mumbai Region)

### Step 1: Switch Region
- Top-right corner → Select "Asia Pacific (Mumbai) ap-south-1"

### Step 2: Create Bucket
1. Go to S3 service (search "S3" in search bar)
2. Click "Create bucket"
3. **Bucket name:** `yapp-media-production` (must be globally unique)
4. **Region:** Asia Pacific (Mumbai) ap-south-1
5. **Block Public Access:** Keep ALL boxes checked (we'll use presigned URLs)
6. **Bucket Versioning:** Disabled
7. **Encryption:** Enable (default SSE-S3)
8. Click "Create bucket"

### Step 3: Configure CORS
1. Click on your bucket name
2. Go to "Permissions" tab
3. Scroll to "Cross-origin resource sharing (CORS)"
4. Click "Edit"
5. Paste this:

```json
[
  {
    "AllowedHeaders": ["*"],
    "AllowedMethods": ["GET", "PUT", "POST"],
    "AllowedOrigins": ["*"],
    "ExposeHeaders": ["ETag"]
  }
]
```

6. Save changes

---

## Phase 2: Create IAM User for API Access

### Step 1: Create IAM User
1. Search for "IAM" service
2. Click "Users" in left sidebar
3. Click "Create user"
4. **User name:** `yapp-backend-user`
5. Click "Next"

### Step 2: Set Permissions
1. Select "Attach policies directly"
2. Search for: `AmazonS3FullAccess`
3. Check the box
4. Click "Next" → "Create user"

### Step 3: Create Access Keys
1. Click on the newly created user (`yapp-backend-user`)
2. Go to "Security credentials" tab
3. Scroll to "Access keys"
4. Click "Create access key"
5. Select "Application running outside AWS"
6. Click "Next" → "Create access key"
7. **IMPORTANT:** Copy both:
   - Access key ID
   - Secret access key
   (You'll never see the secret again!)

---

## Phase 3: Store Credentials in Supabase

### Option A: Environment Variables (Recommended)
1. Go to Supabase Dashboard
2. Project Settings → Edge Functions → Secrets
3. Add these secrets:
   - `AWS_ACCESS_KEY_ID` = your access key ID
   - `AWS_SECRET_ACCESS_KEY` = your secret access key
   - `AWS_REGION` = `ap-south-1`
   - `AWS_BUCKET_NAME` = `yapp-media-production`

### Option B: Store in Vault (Alternative)
1. Supabase Dashboard → Project Settings → Vault
2. Create new secrets for each credential

---

## Phase 4: Folder Structure in S3

Our bucket will have this structure:

```
yapp-media-production/
├── raw/
│   ├── audio/
│   │   └── {user_id}/
│   │       └── {timestamp}_{uuid}.ogg
│   ├── video/
│   └── images/
│
└── processed/
    ├── audio/
    │   └── {user_id}/
    │       ├── {timestamp}_{uuid}_normal.ogg
    │       ├── {timestamp}_{uuid}_chipmunk.ogg
    │       ├── {timestamp}_{uuid}_deep.ogg
    │       └── {timestamp}_{uuid}_robot.ogg
    ├── video/
    └── images/
```

---

## Phase 5: Integration with Yapp

### Upload Flow:
1. Flutter app → Supabase Edge Function: `generate-upload-url`
2. Edge Function → Generates S3 presigned URL (valid 5 min)
3. Flutter app → Uploads directly to S3 using presigned URL
4. Flutter app → Supabase Edge Function: `process-audio`
5. Edge Function → Processes audio (4 filters) → Saves to S3 `processed/` folder
6. Edge Function → Updates `media_files` and `voice_filters` tables in DB
7. Flutter app → Shows preview with filter options
8. User selects filter → Flutter app → Supabase Edge Function: `create-yap`
9. Edge Function → Creates yap in DB, returns success

---

## Cost Estimation (First Month - MVP)

**Storage:** ~1 GB = $0.02  
**Bandwidth:** ~10 GB = $0.90  
**Requests:** ~1000 = $0.01  
**Total:** ~$1/month during testing

---

## Next Steps After Setup:
1. ✓ Bucket created
2. ✓ IAM user created
3. ✓ Credentials stored in Supabase
4. → Write Edge Functions (3 functions)
5. → Update Flutter app to use Edge Functions
6. → Test upload flow
