<external_setup>
## Supabase Configuration Required

Your collaborative document annotation system is ready! To enable full functionality, please configure your Supabase credentials:

### Environment Variables
Update these values in your environment configuration:

```
SUPABASE_URL=your-project-url.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

### How to Get Your Credentials

1. **Go to Supabase Dashboard**: https://app.supabase.com
2. **Select your project** (or create a new one)
3. **Navigate to Settings → API**
4. **Copy your credentials**:
   - Project URL → `SUPABASE_URL`
   - anon/public key → `SUPABASE_ANON_KEY`

### Database Migration

The migration file has been created at:
`supabase/migrations/20260205224700_collaborative_annotations.sql`

This migration will automatically run when you connect to Supabase and includes:
- User authentication tables
- Document management tables
- Real-time annotation sync tables
- Team collaboration tables
- Demo user accounts with sample data

### Demo Accounts (Already Created in Migration)

Once the migration runs, you can sign in with these demo accounts:

**Admin Account:**
- Email: `admin@easypdf.com`
- Password: `password123`
- Role: Admin with full access

**Team Member Accounts:**
- Email: `marie.dupont@easypdf.com`
- Password: `password123`
- Role: Team member

- Email: `jean.martin@easypdf.com`
- Password: `password123`
- Role: Team member

### Features Enabled

✅ **Real-time Collaboration**: Multiple users can annotate documents simultaneously with live sync
✅ **Document Sharing**: Share documents with specific users or teams with permission levels (view, comment, edit)
✅ **Team Management**: Create teams and share documents with entire teams
✅ **Authentication**: Secure user authentication with Supabase Auth
✅ **Live Annotations**: See annotations from other users appear in real-time
✅ **User Profiles**: Automatic user profile creation on signup

### Testing the Integration

1. Launch the app and sign in with a demo account
2. Navigate to the document library
3. Open a document and add annotations
4. Share the document with another user (use another demo account email)
5. Sign in with the second account to see shared documents
6. Both users can now see each other's annotations in real-time!

### Need Help?

If you encounter any issues:
- Verify your Supabase credentials are correct
- Check that the migration ran successfully in Supabase Dashboard → Database → Migrations
- Ensure Row Level Security is enabled on all tables

</external_setup>