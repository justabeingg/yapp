// Edge Function: process-audio
// Downloads raw audio from S3, applies filters, uploads processed versions

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { S3Client, GetObjectCommand, PutObjectCommand } from "https://esm.sh/@aws-sdk/client-s3@3";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const FILTERS = ['normal', 'chipmunk', 'deep_voice', 'robot'];

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Auth
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    );

    const { data: { user }, error: authError } = await supabaseClient.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { mediaFileId } = await req.json();

    if (!mediaFileId) {
      return new Response(JSON.stringify({ error: 'Missing mediaFileId' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Get media file record
    const { data: mediaFile, error: fetchError } = await supabaseClient
      .from('media_files')
      .select('*')
      .eq('id', mediaFileId)
      .eq('user_id', user.id)
      .single();

    if (fetchError || !mediaFile) {
      return new Response(JSON.stringify({ error: 'Media file not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Update status to processing
    await supabaseClient
      .from('media_files')
      .update({
        processing_status: 'processing',
        processing_started_at: new Date().toISOString(),
      })
      .eq('id', mediaFileId);

    // Configure S3
    const s3Client = new S3Client({
      region: Deno.env.get('AWS_REGION') ?? 'ap-south-1',
      credentials: {
        accessKeyId: Deno.env.get('AWS_ACCESS_KEY_ID') ?? '',
        secretAccessKey: Deno.env.get('AWS_SECRET_ACCESS_KEY') ?? '',
      },
    });

    const bucketName = Deno.env.get('AWS_BUCKET_NAME') ?? '';

    // Download raw audio from S3
    const getCommand = new GetObjectCommand({
      Bucket: bucketName,
      Key: mediaFile.raw_file_key,
    });

    const rawAudioResponse = await s3Client.send(getCommand);
    const rawAudioBytes = await rawAudioResponse.Body?.transformToByteArray();

    if (!rawAudioBytes) {
      throw new Error('Failed to download raw audio');
    }

    // Process each filter
    const filterResults = [];

    for (const filterType of FILTERS) {
      try {
        // Apply audio processing (FFmpeg would go here)
        // For now, we'll use the raw audio as placeholder
        // TODO: Implement actual FFmpeg processing with pitch/formant shifts
        
        let processedAudio = rawAudioBytes;
        
        // Generate processed file key
        const processedKey = mediaFile.raw_file_key
          .replace('raw/', 'processed/')
          .replace('.ogg', `_${filterType}.ogg`);

        // Upload processed audio to S3
        const putCommand = new PutObjectCommand({
          Bucket: bucketName,
          Key: processedKey,
          Body: processedAudio,
          ContentType: 'audio/ogg',
        });

        await s3Client.send(putCommand);

        // Generate public URL (CloudFront URL would go here in production)
        const processedUrl = `https://${bucketName}.s3.${Deno.env.get('AWS_REGION')}.amazonaws.com/${processedKey}`;

        // Insert voice_filters record
        const { data: filterRecord, error: filterError } = await supabaseClient
          .from('voice_filters')
          .insert({
            media_file_id: mediaFileId,
            filter_type: filterType,
            processed_file_key: processedKey,
            processed_url: processedUrl,
            file_size_bytes: processedAudio.length,
            processing_status: 'completed',
          })
          .select()
          .single();

        if (filterError) {
          console.error(`Error inserting filter ${filterType}:`, filterError);
          continue;
        }

        filterResults.push({
          filterType,
          url: processedUrl,
          id: filterRecord.id,
        });

      } catch (filterError) {
        console.error(`Error processing filter ${filterType}:`, filterError);
        // Continue with other filters even if one fails
      }
    }

    // Update media_files record
    await supabaseClient
      .from('media_files')
      .update({
        processing_status: 'completed',
        processing_completed_at: new Date().toISOString(),
        file_size_bytes: rawAudioBytes.length,
      })
      .eq('id', mediaFileId);

    return new Response(
      JSON.stringify({
        success: true,
        mediaFileId,
        filters: filterResults,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );

  } catch (error) {
    console.error('Processing error:', error);
    
    // Try to update status to failed
    try {
      const { mediaFileId } = await req.json();
      const supabaseClient = createClient(
        Deno.env.get('SUPABASE_URL') ?? '',
        Deno.env.get('SUPABASE_ANON_KEY') ?? ''
      );
      
      await supabaseClient
        .from('media_files')
        .update({
          processing_status: 'failed',
          processing_error: error.message,
        })
        .eq('id', mediaFileId);
    } catch {}

    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
