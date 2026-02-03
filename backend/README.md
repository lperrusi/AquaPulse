# Hydration Tracker API

A Node.js/Express backend API for the Hydration Tracker Flutter app.

## Features

- **User Management**: User profiles, authentication, and data
- **Friend System**: Friend requests, relationships, and social features
- **Challenges**: Create and participate in hydration challenges
- **Leaderboards**: Global and friends leaderboards with different periods
- **SQLite Database**: Lightweight, file-based database
- **Security**: Rate limiting, CORS, and helmet security headers

## Setup

### Prerequisites

- Node.js (v14 or higher)
- npm or yarn

### Installation

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Start the development server:
   ```bash
   npm run dev
   ```

The API will be available at `http://localhost:3000`

### Production

For production deployment:

```bash
npm start
```

## API Endpoints

### Health Check
- `GET /health` - Server health status

### Friends
- `GET /users/:userId/friends` - Get user's friends
- `GET /users/:userId/friend-requests/pending` - Get pending friend requests
- `POST /friend-requests` - Send friend request
- `PUT /friend-requests/:requestId/accept` - Accept friend request
- `PUT /friend-requests/:requestId/decline` - Decline friend request
- `GET /users/search?q=query` - Search users

### Challenges
- `GET /users/:userId/challenges` - Get user's challenges
- `POST /challenges` - Create new challenge
- `GET /challenges/:challengeId/participants` - Get challenge participants

### Leaderboards
- `GET /leaderboards/global?period=1&limit=50` - Global leaderboard
- `GET /leaderboards/streak?limit=50` - Streak leaderboard
- `GET /users/:userId/leaderboards/friends?period=1` - Friends leaderboard

### Users
- `GET /users/:userId` - Get user profile

## Database

The API uses SQLite with the following tables:

- `users` - User profiles and data
- `friends` - Friend relationships
- `friend_requests` - Pending friend requests
- `challenges` - Challenge definitions
- `challenge_participants` - Challenge participation and progress
- `leaderboard_entries` - Leaderboard scores and rankings

## Sample Data

The API includes sample data for testing:

- 3 sample users (John Doe, Jane Smith, Mike Johnson)
- Sample friend relationships
- Sample friend requests
- Sample challenges with participants
- Sample leaderboard entries

## Environment Variables

Create a `.env` file for production:

```env
PORT=3000
JWT_SECRET=your-secret-key-here
NODE_ENV=production
```

## Testing

Run tests with:

```bash
npm test
```

## Deployment

### Local Development
```bash
npm run dev
```

### Production
```bash
npm start
```

### Docker (Optional)
```dockerfile
FROM node:16-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

## Integration with Flutter App

Update your Flutter app's API base URL to point to this backend:

```dart
// In your service files, change:
static const String _baseUrl = 'http://localhost:3000'; // For local development
// or
static const String _baseUrl = 'https://your-domain.com'; // For production
```

## Security Features

- **Rate Limiting**: 100 requests per 15 minutes per IP
- **CORS**: Configured for cross-origin requests
- **Helmet**: Security headers
- **Input Validation**: Basic request validation
- **SQL Injection Protection**: Parameterized queries

## Troubleshooting

### Common Issues

1. **Port already in use**: Change PORT in .env or kill existing process
2. **Database errors**: Delete database.sqlite and restart server
3. **CORS issues**: Check CORS configuration for your domain

### Logs

Check console output for detailed error messages and request logs.

## License

MIT License - see LICENSE file for details. 