import { DataProvider } from 'react-admin';

// Mock data provider for development
const dataProvider: DataProvider = {
  getList: (resource) => {
    // Mock data for different resources
    const mockData = {
      users: [
        { id: '1', username: 'john_doe', email: 'john@example.com', status: 'active', score: 150, violations: 0 },
        { id: '2', username: 'jane_smith', email: 'jane@example.com', status: 'banned', score: 85, violations: 3 }
      ],
      chatRooms: [
        { id: '1', name: 'Coffee Shop', creator: 'john_doe', memberCount: 5, location: 'SF Bay Area' },
        { id: '2', name: 'Study Group', creator: 'jane_smith', memberCount: 8, location: 'NYC' }
      ],
      reports: [
        { id: '1', type: 'content', reason: 'inappropriate', status: 'pending', priority: 'high' },
        { id: '2', type: 'user', reason: 'spam', status: 'resolved', priority: 'medium' }
      ]
    };

    const data = mockData[resource as keyof typeof mockData] || [];
    return Promise.resolve({
      data,
      total: data.length,
    });
  },

  getOne: (resource, params) => {
    return Promise.resolve({
      data: { id: params.id, name: `Mock ${resource}` },
    });
  },

  getMany: (resource, params) => {
    return Promise.resolve({
      data: params.ids.map(id => ({ id, name: `Mock ${resource} ${id}` })),
    });
  },

  getManyReference: (resource, params) => {
    return Promise.resolve({
      data: [],
      total: 0,
    });
  },

  create: (resource, params) => {
    return Promise.resolve({
      data: { ...params.data, id: Date.now().toString() },
    });
  },

  update: (resource, params) => {
    return Promise.resolve({
      data: { ...params.data, id: params.id },
    });
  },

  updateMany: (resource, params) => {
    return Promise.resolve({
      data: params.ids,
    });
  },

  delete: (resource, params) => {
    return Promise.resolve({
      data: { id: params.id },
    });
  },

  deleteMany: (resource, params) => {
    return Promise.resolve({
      data: params.ids,
    });
  },
};

export default dataProvider;

// Explicit export to fix TypeScript module resolution
export {}; 