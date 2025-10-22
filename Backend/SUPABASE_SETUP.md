## Supabase Setup Guide for Flirrt.AI

**Based on expert recommendations from Gemini 2.5 Pro and Perplexity Sonar Pro (October 2025)**

This guide walks you through setting up Supabase for conversation persistence, A/B testing, and user preferences with graceful degradation when the database is unavailable.

---

### Why Supabase?

- **Managed PostgreSQL**: Production-ready database with automatic backups
- **Real-time subscriptions**: Potential for live updates (future feature)
- **Row Level Security (RLS)**: Built-in privacy and security controls
- **Generous free tier**: Perfect for MVP and early growth
- **Excellent Node.js SDK**: First-class integration with our Express backend

---

### Phase 1: Create Supabase Project (5 minutes)

1. **Sign up at [supabase.com](https://supabase.com)**
   - Use your `office@flirrt.ai` email
   - Choose a strong password

2. **Create a new project**
   - Project name: `flirrt-production`
   - Database password: Generate a strong password (save it securely!)
   - Region: Choose closest to your Render deployment (e.g., `us-east-1`)
   - Pricing plan: Start with **Free tier** (500MB database, 2GB bandwidth)

3. **Wait for provisioning** (2-3 minutes)
   - Supabase will set up your PostgreSQL database
   - You'll get a project dashboard URL like: `https://app.supabase.com/project/abcdefghijk`

---

### Phase 2: Get Connection Credentials (2 minutes)

1. **Navigate to Project Settings**
   - Click the gear icon (⚙️) in the sidebar
   - Go to **Database** section

2. **Copy connection details**
   - **Host**: `db.abcdefghijk.supabase.co`
   - **Database name**: `postgres`
   - **Port**: `5432`
   - **User**: `postgres`
   - **Password**: The password you set during project creation

3. **Get the connection string**
   - Scroll to **Connection string** section
   - Copy the **URI** format (not the transaction pooler)
   - It looks like: `postgresql://postgres:[YOUR-PASSWORD]@db.abcdefghijk.supabase.co:5432/postgres`

4. **Get the API keys**
   - Go to **Settings** > **API**
   - Copy the **`anon` public key** (for client-side, if needed in future)
   - Copy the **`service_role` secret key** (for server-side admin operations)

---

### Phase 3: Run Database Migrations (5 minutes)

You have two options for running migrations:

#### Option A: Using Supabase SQL Editor (Recommended for first-time setup)

1. **Open SQL Editor**
   - In your Supabase dashboard, click **SQL Editor** in the sidebar
   - Click **New query**

2. **Run migrations in order**
   - Copy the content of each migration file and run them sequentially:
     1. `Backend/migrations/003_conversation_sessions.sql`
     2. `Backend/migrations/004_account_deletions.sql`
     3. `Backend/migrations/005_gamification.sql`
     4. `Backend/migrations/006_abtesting_schema.sql`
   
3. **Verify tables were created**
   - Click **Table Editor** in the sidebar
   - You should see: `conversation_sessions`, `account_deletions`, `events`, `user_experiment_assignments`

#### Option B: Using the provided setup script

1. **Make the script executable**
   ```bash
   chmod +x Backend/setup-supabase.sh
   ```

2. **Run the script**
   ```bash
   ./Backend/setup-supabase.sh postgresql://postgres:[YOUR-PASSWORD]@db.abcdefghijk.supabase.co:5432/postgres
   ```

---

### Phase 4: Configure Render Environment Variables (3 minutes)

1. **Go to your Render dashboard**
   - Navigate to your `flirrt-api-production` service
   - Click **Environment** in the sidebar

2. **Add Supabase environment variables**
   ```
   DATABASE_URL=postgresql://postgres:[YOUR-PASSWORD]@db.abcdefghijk.supabase.co:5432/postgres
   SUPABASE_URL=https://abcdefghijk.supabase.co
   SUPABASE_ANON_KEY=[YOUR-ANON-KEY]
   SUPABASE_SERVICE_KEY=[YOUR-SERVICE-ROLE-KEY]
   ```

3. **Save and redeploy**
   - Click **Save Changes**
   - Render will automatically redeploy your service with the new variables

---

### Phase 5: Update Backend Code (Already Done!)

The backend code already supports graceful degradation:

- **`config/database.js`**: Handles connection pooling and error recovery
- **`services/conversationContext.js`**: Falls back to in-memory storage if DB unavailable
- **`services/abTestingService.js`**: Uses in-memory cache when DB is down

No code changes needed! The system will automatically use Supabase once `DATABASE_URL` is set.

---

### Phase 6: Test the Integration (5 minutes)

1. **Test database connection**
   ```bash
   curl https://flirrt-api-production.onrender.com/api/health
   ```
   
   Expected response:
   ```json
   {
     "status": "healthy",
     "database": "connected",
     "timestamp": "2025-10-22T..."
   }
   ```

2. **Test A/B testing config endpoint**
   ```bash
   curl "https://flirrt-api-production.onrender.com/api/abtesting/config?userId=550e8400-e29b-41d4-a716-446655440000"
   ```
   
   Expected response:
   ```json
   {
     "success": true,
     "userId": "550e8400-e29b-41d4-a716-446655440000",
     "config": {
       "features": {
         "promptStyle": "playful",
         "primaryModel": "gpt-4o",
         ...
       },
       "experiments": [...]
     }
   }
   ```

3. **Test conversation context persistence**
   - Use the existing test scenarios in `Backend/test-scenarios/`
   - Run the validation script: `python validate_conversation_context.py`

---

### Phase 7: Enable Row Level Security (RLS) - Optional but Recommended

For production, enable RLS to ensure users can only access their own data:

1. **Open SQL Editor in Supabase**

2. **Run RLS policies**
   ```sql
   -- Enable RLS on all tables
   ALTER TABLE conversation_sessions ENABLE ROW LEVEL SECURITY;
   ALTER TABLE events ENABLE ROW LEVEL SECURITY;
   ALTER TABLE user_experiment_assignments ENABLE ROW LEVEL SECURITY;
   
   -- Policy: Users can only read/write their own data
   CREATE POLICY "Users can access own conversation sessions"
       ON conversation_sessions
       FOR ALL
       USING (user_id = auth.uid());
   
   CREATE POLICY "Users can access own events"
       ON events
       FOR ALL
       USING (user_id = auth.uid());
   
   CREATE POLICY "Users can access own experiment assignments"
       ON user_experiment_assignments
       FOR ALL
       USING (user_id = auth.uid());
   
   -- Allow service role to bypass RLS (for backend operations)
   -- This is automatic when using the service_role key
   ```

---

### Monitoring and Maintenance

#### Check Database Usage

- **Dashboard**: Supabase dashboard shows real-time usage
- **Free tier limits**:
  - 500 MB database storage
  - 2 GB bandwidth per month
  - 50,000 monthly active users

#### Backup Strategy

- **Automatic backups**: Supabase automatically backs up your database daily (on paid plans)
- **Manual backup**: Use `pg_dump` to create local backups
  ```bash
  pg_dump "postgresql://postgres:[PASSWORD]@db.abcdefghijk.supabase.co:5432/postgres" > backup.sql
  ```

#### Scaling Considerations

When you outgrow the free tier:

1. **Upgrade to Pro plan** ($25/month)
   - 8 GB database storage
   - 250 GB bandwidth
   - Daily backups
   - Point-in-time recovery

2. **Optimize queries**
   - Use the Supabase **Performance** tab to identify slow queries
   - Add indexes where needed (already included in migrations)

3. **Consider read replicas** (for high traffic)
   - Supabase supports read replicas on higher-tier plans

---

### Troubleshooting

#### "Connection refused" error

- **Cause**: Firewall or incorrect connection string
- **Solution**: Verify the connection string and ensure Render's IP is not blocked

#### "Too many connections" error

- **Cause**: Connection pool exhausted
- **Solution**: Adjust `max` in `config/database.js` (currently set to 10)

#### Graceful degradation not working

- **Cause**: Error handling not catching DB failures
- **Solution**: Check logs in Render dashboard, ensure try-catch blocks are in place

#### Slow queries

- **Cause**: Missing indexes or large dataset
- **Solution**: Use Supabase **Performance** tab to identify slow queries, add indexes

---

### Security Best Practices

✅ **Never commit credentials to Git**
- Use environment variables for all secrets
- Add `.env` to `.gitignore`

✅ **Use service_role key only on backend**
- Never expose service_role key to clients
- Use anon key for client-side operations (if needed)

✅ **Enable RLS in production**
- Protects against unauthorized data access
- Essential for GDPR/CCPA compliance

✅ **Rotate credentials regularly**
- Change database password every 90 days
- Regenerate API keys if compromised

---

### Next Steps

Once Supabase is set up:

1. ✅ **Monitor usage**: Check Supabase dashboard weekly
2. ✅ **Analyze A/B test results**: Use the `/api/abtesting/stats/:experimentId` endpoint
3. ✅ **Optimize database**: Add indexes based on query patterns
4. ✅ **Plan for scale**: Upgrade to Pro plan when approaching free tier limits

---

### Resources

- [Supabase Documentation](https://supabase.com/docs)
- [PostgreSQL Best Practices](https://wiki.postgresql.org/wiki/Don't_Do_This)
- [Node.js Supabase SDK](https://supabase.com/docs/reference/javascript/introduction)
- [Render + Supabase Integration Guide](https://render.com/docs/databases)

---

**Questions or issues?** Check the Supabase community forum or open an issue in the GitHub repository.

