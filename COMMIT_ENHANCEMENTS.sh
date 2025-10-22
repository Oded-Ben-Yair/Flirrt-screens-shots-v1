#!/bin/bash

cd /home/ubuntu/Flirrt-screens-shots-v1

git add Backend/migrations/001_conversation_context.sql
git add Backend/SUPABASE_SETUP.md
git add iOS/FIX_IOS17_DEPRECATIONS.md
git add Backend/services/abTestingService.js
git add Backend/routes/abTesting.js
git add Backend/AB_TESTING_GUIDE.md

git commit -m "feat: Add optional enhancements (Supabase, iOS 17 fixes, A/B testing)"

git push origin main

