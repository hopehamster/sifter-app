# Admin Panel Setup Instructions

## 🔐 Setting Up Admin Authentication

### 1. Use Existing Admin User in Firebase Console

✅ **Already Complete**: You have `admin@sifter.cc` in Firebase Authentication
- Email: `admin@sifter.cc` (Chief Admin)
- Password: `Sifterwins702!`

### 2. Update Admin Document in Firestore

1. **Go to Firestore Database** in Firebase Console
2. **Find the `admins` collection**
3. **Locate/Update Document** for your admin user UID:

```json
{
  "uid": "YOUR_EXISTING_USER_UID",
  "email": "admin@sifter.cc",
  "role": "super_admin",
  "permissions": [
    "users.read",
    "users.write", 
    "users.delete",
    "chats.read",
    "chats.write",
    "chats.delete",
    "reports.read",
    "reports.write",
    "reports.resolve",
    "analytics.read",
    "settings.write",
    "admins.manage"
  ],
  "displayName": "Chief Admin",
  "createdAt": "2024-06-01T12:00:00Z",
  "lastLogin": null,
  "ipWhitelist": [],
  "isActive": true
}
```

### 3. Admin Role Permissions

#### **Super Admin** (`super_admin`)
- Full access to all features
- Can manage other admins
- Can modify system settings
- Access to all analytics and logs

#### **Moderator** (`moderator`) 
- User management (ban/unban)
- Chat room moderation
- Report resolution
- Content filtering
- Limited analytics access

#### **Viewer** (`viewer`)
- Read-only access to analytics
- View user and chat data
- Cannot modify or delete anything

### 4. Security Rules (Firestore)

Add these security rules to protect admin data:

```javascript
// Firestore Security Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Admin collection - only readable by authenticated admins
    match /admins/{adminId} {
      allow read: if request.auth != null && 
                     request.auth.uid == adminId;
      allow write: if request.auth != null && 
                      get(/databases/$(database)/documents/admins/$(request.auth.uid)).data.role == 'super_admin';
    }
    
    // Admin logs - only writable by admins
    match /admin_logs/{logId} {
      allow create: if request.auth != null && 
                       exists(/databases/$(database)/documents/admins/$(request.auth.uid));
      allow read: if request.auth != null && 
                     get(/databases/$(database)/documents/admins/$(request.auth.uid)).data.role in ['super_admin', 'moderator'];
    }
    
    // Regular app collections (accessible by admins)
    match /users/{userId} {
      allow read, write: if request.auth != null && 
                            exists(/databases/$(database)/documents/admins/$(request.auth.uid));
    }
    
    match /chatRooms/{chatId} {
      allow read, write: if request.auth != null && 
                            exists(/databases/$(database)/documents/admins/$(request.auth.uid));
    }
    
    match /reports/{reportId} {
      allow read, write: if request.auth != null && 
                            exists(/databases/$(database)/documents/admins/$(request.auth.uid));
    }
  }
}
```

### 5. First Login

1. Visit: http://localhost:3000
2. You'll see the login screen
3. Enter your admin email and password
4. The system will:
   - Verify you're in the `admins` collection
   - Load your permissions
   - Create a secure session
   - Log the login action

### 6. Adding More Admins

Once logged in as Super Admin:
1. Navigate to Settings > Admin Management
2. Add new admin email with appropriate role
3. New admin will receive email invitation
4. They create password and get access based on their role

## 🛡️ Security Features

- ✅ **Role-based access control**
- ✅ **Session timeout** (2 hours)
- ✅ **Action logging** (audit trail)
- ✅ **Email verification** required
- ✅ **IP whitelisting** (configurable)
- ✅ **Secure password** requirements
- ✅ **Multi-factor auth** (optional)

## 🚨 Important Security Notes

1. **Never share admin credentials**
2. **Use strong, unique passwords**
3. **Enable MFA when available**
4. **Regularly audit admin actions**
5. **Remove inactive admin accounts**
6. **Monitor for suspicious activity** 