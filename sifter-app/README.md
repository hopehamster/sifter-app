# 🎯 Sifter Admin Panel

A comprehensive web-based administration panel for the Sifter location-based chat application. Built with React Admin, Firebase, and Material-UI for powerful chat room management, user moderation, and real-time analytics.

## ✨ Features

### 👥 User Management
- **Advanced Filtering**: Search users by email, status, violations, activity
- **User Profiles**: Complete profile editing with activity tracking
- **Moderation Tools**: Ban/unban users with audit logging
- **Real-time Status**: Live user activity and location tracking

### 💬 Chat Room Management
- **Live Monitoring**: Real-time chat message streaming
- **Room Controls**: Close/reopen rooms, manage settings
- **Location Tracking**: Geographic distribution of active rooms
- **Content Moderation**: Message-level moderation tools

### ⚠️ Reports & Moderation
- **Priority System**: Critical, high, medium, low priority reports
- **Content Filtering**: AI-powered profanity and NSFW detection
- **Bulk Actions**: Process multiple reports simultaneously
- **Automated Workflows**: Smart moderation triggers

### 📊 Analytics Dashboard
- **Real-time Metrics**: Active users, chats, messages, reports
- **Activity Trends**: 24-hour usage patterns and peak times
- **Geographic Insights**: Usage by location and demographics
- **System Health**: Database performance and API monitoring

### 🔧 System Configuration
- **App Settings**: Global configuration management
- **Content Filters**: Configurable moderation parameters
- **Admin Management**: Role-based access control
- **Database Tools**: Backup, cleanup, and maintenance

## 🚀 Quick Start

### Prerequisites
- Node.js 18+ installed
- Firebase project with Firestore enabled
- GitHub account for deployment

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/sifter-admin-panel.git
   cd sifter-admin-panel
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Configure environment variables**
   Create a `.env.local` file in the project root:
   ```env
   REACT_APP_FIREBASE_API_KEY=your_firebase_api_key
   REACT_APP_FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com
   REACT_APP_FIREBASE_PROJECT_ID=your_project_id
   REACT_APP_FIREBASE_STORAGE_BUCKET=your_project.appspot.com
   REACT_APP_FIREBASE_MESSAGING_SENDER_ID=your_sender_id
   REACT_APP_FIREBASE_APP_ID=your_app_id
   REACT_APP_FIREBASE_MEASUREMENT_ID=your_measurement_id
   ```

4. **Start development server**
   ```bash
   npm start
   ```

5. **Open your browser**
   Navigate to `http://localhost:3000`

## 📦 Tech Stack

### Core Framework
- **React 18** - Modern React with hooks and concurrent features
- **TypeScript** - Type-safe development
- **React Admin** - Powerful admin interface framework
- **Material-UI (MUI) v5** - Professional component library

### Data & Backend
- **Firebase Admin SDK** - Backend integration
- **React Query** - Advanced server state management
- **Firebase Auth** - Authentication and authorization
- **Firestore** - Real-time NoSQL database

### UI/UX Enhancement
- **Framer Motion** - Smooth animations and transitions
- **React Hot Toast** - Beautiful notifications
- **Recharts** - Interactive charts and analytics
- **React Hook Form** - Optimized form handling

### Development Tools
- **Sentry** - Error tracking and monitoring
- **React Window** - Virtual scrolling for large datasets
- **ESLint + Prettier** - Code quality and formatting

## 🔧 Development

### Project Structure
```
src/
├── components/           # React Admin components
│   ├── Users.tsx        # User management interface
│   ├── Chats.tsx        # Chat room management
│   ├── Reports.tsx      # Reports and moderation
│   ├── Dashboard.tsx    # Analytics dashboard
│   └── Layout.tsx       # Custom layout and theming
├── firebaseConfig.ts    # Firebase configuration
└── App.tsx             # Main application entry point
```

### Available Scripts
- `npm start` - Start development server
- `npm run build` - Build for production
- `npm test` - Run test suite
- `npm run lint` - Run ESLint
- `npm run format` - Format code with Prettier

### Firebase Collections
The admin panel expects these Firestore collections:
- `users` - User profiles and authentication data
- `chatRooms` - Chat room information and settings
- `reports` - Moderation reports and resolutions
- `messages` - Chat messages (for monitoring)

## 🚀 Deployment

### GitHub Pages (Recommended)

1. **Push to GitHub**
   ```bash
   git add .
   git commit -m "Initial admin panel setup"
   git push origin main
   ```

2. **Configure GitHub Secrets**
   Go to Settings > Secrets and add:
   - `REACT_APP_FIREBASE_API_KEY`
   - `REACT_APP_FIREBASE_AUTH_DOMAIN`
   - `REACT_APP_FIREBASE_PROJECT_ID`
   - `REACT_APP_FIREBASE_STORAGE_BUCKET`
   - `REACT_APP_FIREBASE_MESSAGING_SENDER_ID`
   - `REACT_APP_FIREBASE_APP_ID`
   - `REACT_APP_FIREBASE_MEASUREMENT_ID`

3. **Enable GitHub Pages**
   - Go to Settings > Pages
   - Source: GitHub Actions
   - The workflow will automatically deploy on push to main

4. **Custom Domain (Optional)**
   - Add CNAME record: `admin.sifter.app` → `your-username.github.io`
   - The workflow includes CNAME configuration

### Alternative Hosting
- **Vercel**: `vercel --prod`
- **Netlify**: Drag and drop `build` folder
- **Firebase Hosting**: `firebase deploy`

## 🔐 Security

### Authentication
- Firebase Admin Auth for secure login
- Role-based access control (Super Admin, Moderator, Viewer)
- Session management with auto-timeout

### Data Protection
- Environment variables for sensitive configuration
- HTTPS enforced on all endpoints
- Firebase security rules for data access

### Monitoring
- Sentry integration for error tracking
- Real-time performance monitoring
- Audit logging for all admin actions

## 📊 Performance

### Optimization Features
- **Code Splitting**: Lazy loading of components
- **Virtual Scrolling**: Handle thousands of records efficiently
- **Caching**: Intelligent data caching with React Query
- **Bundle Analysis**: Optimized build size

### Performance Targets
- **Load Time**: < 2 seconds
- **Time to Interactive**: < 3 seconds
- **Lighthouse Score**: > 90
- **Bundle Size**: < 1MB gzipped

## 🤝 Contributing

1. **Fork the repository**
2. **Create feature branch**: `git checkout -b feature/amazing-feature`
3. **Commit changes**: `git commit -m 'Add amazing feature'`
4. **Push to branch**: `git push origin feature/amazing-feature`
5. **Open Pull Request**

### Development Guidelines
- Follow TypeScript best practices
- Write meaningful commit messages
- Add tests for new features
- Update documentation as needed

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation**: Check this README and inline code comments
- **Issues**: Create GitHub issue for bugs or feature requests
- **Discussions**: Use GitHub Discussions for questions

## 🎯 Roadmap

### Phase 1 (Current)
- ✅ User management interface
- ✅ Chat room monitoring
- ✅ Reports and moderation
- ✅ Real-time dashboard

### Phase 2 (Planned)
- 🔄 Advanced analytics with ML insights
- 🔄 Mobile app for admin tasks
- 🔄 Automated content moderation
- 🔄 Third-party integrations

### Phase 3 (Future)
- 🔄 Multi-language support
- 🔄 Advanced reporting tools
- 🔄 API documentation portal
- 🔄 White-label customization

---

**Built with ❤️ for the Sifter community**
