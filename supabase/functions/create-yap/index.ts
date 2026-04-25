// Edge Function: create-yap
// Creates a yap post in the feed after user selects a filter

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

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

    const { mediaFileId, postId, selectedFilter, parentYapId } = await req.json();

    if (!mediaFileId || !postId || !selectedFilter) {
      return new Response(JSON.stringify({ error: 'Missing required fields' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Verify media file belongs to user
    const { data: mediaFile, error: mediaError } = await supabaseClient
      .from('media_files')
      .select('*')
      .eq('id', mediaFileId)
      .eq('user_id', user.id)
      .single();

    if (mediaError || !mediaFile) {
      return new Response(JSON.stringify({ error: 'Media file not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Check if processing is complete
    if (mediaFile.processing_status !== 'completed') {
      return new Response(JSON.stringify({ error: 'Media still processing' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Verify target post exists.
    const { data: post, error: postError } = await supabaseClient
      .from('posts')
      .select('id')
      .eq('id', postId)
      .eq('is_removed', false)
      .single();

    if (postError || !post) {
      return new Response(JSON.stringify({ error: 'Post not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Get selected filter URL. During the current audio pipeline, "normal"
    // can use the uploaded media URL directly before processed filters exist.
    const { data: filterData } = await supabaseClient
      .from('voice_filters')
      .select('processed_url')
      .eq('media_file_id', mediaFileId)
      .eq('filter_type', selectedFilter)
      .maybeSingle();

    const audioUrl = filterData?.processed_url || mediaFile.processed_url || mediaFile.raw_url;

    if (!audioUrl) {
      return new Response(JSON.stringify({ error: 'Filter not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Determine thread structure
    let threadRootId = null;
    if (parentYapId) {
      // This is a reply - get the root of the thread
      const { data: parentYap } = await supabaseClient
        .from('yaps')
        .select('thread_root_id')
        .eq('id', parentYapId)
        .single();

      threadRootId = parentYap?.thread_root_id || parentYapId;
    }

    // TODO: Auto-generate transcript using Whisper API
    // For now, transcript is null - will implement in Phase 2
    const transcript = null;
    const transcriptConfidence = null;

    // Create yap
    const { data: yap, error: yapError } = await supabaseClient
      .from('yaps')
      .insert({
        user_id: user.id,
        media_file_id: mediaFileId,
        selected_filter: selectedFilter,
        transcript,
        transcript_confidence: transcriptConfidence,
        parent_yap_id: parentYapId || null,
        thread_root_id: threadRootId,
        post_id: postId,
      })
      .select()
      .single();

    if (yapError) {
      console.error('Error creating yap:', yapError);
      return new Response(JSON.stringify({ error: 'Failed to create yap' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // If this is a reply, increment parent's reply_count
    if (parentYapId) {
      await supabaseClient.rpc('increment_reply_count', { yap_id: parentYapId });
    }

    await supabaseClient.rpc('increment_post_yap_count', { target_post_id: postId });

    return new Response(
      JSON.stringify({
        success: true,
        yap: {
          id: yap.id,
          audioUrl,
          selectedFilter,
          createdAt: yap.created_at,
        },
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );

  } catch (error) {
    console.error('Error:', error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
