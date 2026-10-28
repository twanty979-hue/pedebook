-- ==============================================================================
-- PEDEBOOK - SUPABASE SEED DATA (Optional Test Data)
-- ==============================================================================

-- Sample Ad for over-quota free books
INSERT INTO public.ad_campaigns (
    id,
    title,
    sponsor_name,
    banner_image_url,
    target_url,
    ad_type,
    duration_seconds,
    is_active
) VALUES (
    'a0000000-0000-0000-0000-000000000001',
    'เปลี่ยน PDF เป็น Flipbook 3D เพิ่มยอดขายร้านค้า',
    'Pedebook Partner Network',
    'https://images.unsplash.com/photo-1460925895917-afdab827c52f?auto=format&fit=crop&w=1200&q=80',
    'https://www.pedebook.com/pricing',
    'countdown_overlay',
    5,
    TRUE
) ON CONFLICT DO NOTHING;
