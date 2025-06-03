import React from 'react';
import { Admin, Resource, Layout, AppBar, List, Datagrid, TextField, EmailField } from 'react-admin';
import { Box, Typography, Card, CardContent, Grid } from '@mui/material';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import dataProvider from './dataProvider';
import authProvider from './authProvider';
import { AdminLogin } from './components/AdminLogin';
import { LogoutButton } from './components/LogoutButton';
import { EmergencyLogout } from './components/EmergencyLogout';

// Check if we're on the emergency logout route
const isEmergencyLogout = window.location.pathname === '/emergency-logout';

// Custom AppBar with our logout button
const CustomAppBar = (props: any) => (
  <AppBar {...props}>
    <Typography variant="h6" sx={{ flex: 1 }}>
      Sifter Admin Panel
    </Typography>
    <LogoutButton />
  </AppBar>
);

// Custom Layout
const CustomLayout = (props: any) => (
  <Layout {...props} appBar={CustomAppBar} />
);

// Dashboard component
const Dashboard = () => (
  <Box sx={{ p: 3 }}>
    <Typography variant="h4" gutterBottom>
      Sifter Admin Dashboard
    </Typography>
    <Grid container spacing={3}>
      <Grid item xs={12} md={4}>
        <Card>
          <CardContent>
            <Typography variant="h6" color="primary">
              Total Users
            </Typography>
            <Typography variant="h3">
              1,247
            </Typography>
          </CardContent>
        </Card>
      </Grid>
      <Grid item xs={12} md={4}>
        <Card>
          <CardContent>
            <Typography variant="h6" color="primary">
              Active Chats
            </Typography>
            <Typography variant="h3">
              89
            </Typography>
          </CardContent>
        </Card>
      </Grid>
      <Grid item xs={12} md={4}>
        <Card>
          <CardContent>
            <Typography variant="h6" color="primary">
              Pending Reports
            </Typography>
            <Typography variant="h3">
              12
            </Typography>
          </CardContent>
        </Card>
      </Grid>
      <Grid item xs={12}>
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Quick Actions
            </Typography>
            <Typography variant="body2">
              Welcome to the Sifter Admin Panel. Use the navigation menu to manage users, chat rooms, and moderation reports.
            </Typography>
          </CardContent>
        </Card>
      </Grid>
    </Grid>
  </Box>
);

// Simple list components for each resource
const UserList = () => (
  <List>
    <Datagrid>
      <TextField source="id" />
      <TextField source="username" />
      <EmailField source="email" />
      <TextField source="status" />
      <TextField source="score" />
      <TextField source="violations" />
    </Datagrid>
  </List>
);

const ChatRoomList = () => (
  <List>
    <Datagrid>
      <TextField source="id" />
      <TextField source="name" />
      <TextField source="creator" />
      <TextField source="memberCount" />
      <TextField source="location" />
    </Datagrid>
  </List>
);

const ReportsList = () => (
  <List>
    <Datagrid>
      <TextField source="id" />
      <TextField source="type" />
      <TextField source="reason" />
      <TextField source="status" />
      <TextField source="priority" />
    </Datagrid>
  </List>
);

const AdminApp: React.FC = () => (
  <Admin
    dataProvider={dataProvider}
    authProvider={authProvider}
    title="Sifter Admin Panel"
    loginPage={AdminLogin}
    layout={CustomLayout}
    dashboard={Dashboard}
    requireAuth
  >
    <Resource name="users" list={UserList} />
    <Resource name="chatRooms" list={ChatRoomList} />
    <Resource name="reports" list={ReportsList} />
  </Admin>
);

const App: React.FC = () => {
  // If accessing emergency logout, show that immediately
  if (isEmergencyLogout) {
    return <EmergencyLogout />;
  }

  return (
    <BrowserRouter>
      <Routes>
        <Route path="/emergency-logout" element={<EmergencyLogout />} />
        <Route path="/*" element={<AdminApp />} />
      </Routes>
    </BrowserRouter>
  );
};

export default App; 