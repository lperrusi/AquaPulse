const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { v4: uuidv4 } = require('uuid');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use(limiter);

// Database setup
const db = new sqlite3.Database('./database.sqlite', (err) => {
  if (err) {
    console.error('Error opening database:', err);
  } else {
    console.log('Connected to SQLite database');
    initializeDatabase();
  }
});

// Handle database errors
db.on('error', (err) => {
  console.error('Database error:', err);
});

// Initialize database tables
function initializeDatabase() {
  // Users table
  db.run(`CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    name TEXT,
    age INTEGER,
    weight REAL NOT NULL,
    gender TEXT,
    activityLevel INTEGER NOT NULL,
    location TEXT,
    latitude REAL,
    longitude REAL,
    createdAt INTEGER NOT NULL,
    updatedAt INTEGER NOT NULL,
    customGoal REAL
  )`);

  // Friends table
  db.run(`CREATE TABLE IF NOT EXISTS friends (
    id TEXT PRIMARY KEY,
    userId TEXT NOT NULL,
    friendId TEXT NOT NULL,
    status TEXT NOT NULL,
    createdAt INTEGER NOT NULL,
    FOREIGN KEY (userId) REFERENCES users (id),
    FOREIGN KEY (friendId) REFERENCES users (id)
  )`);

  // Friend requests table
  db.run(`CREATE TABLE IF NOT EXISTS friend_requests (
    id TEXT PRIMARY KEY,
    fromUserId TEXT NOT NULL,
    fromUserName TEXT NOT NULL,
    toUserId TEXT NOT NULL,
    message TEXT,
    status TEXT NOT NULL,
    createdAt INTEGER NOT NULL,
    FOREIGN KEY (fromUserId) REFERENCES users (id),
    FOREIGN KEY (toUserId) REFERENCES users (id)
  )`);

  // Challenges table
  db.run(`CREATE TABLE IF NOT EXISTS challenges (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    type INTEGER NOT NULL,
    startDate TEXT NOT NULL,
    endDate TEXT NOT NULL,
    rules TEXT NOT NULL,
    createdBy TEXT NOT NULL,
    createdByName TEXT NOT NULL,
    status TEXT NOT NULL,
    createdAt INTEGER NOT NULL,
    FOREIGN KEY (createdBy) REFERENCES users (id)
  )`);

  // Challenge participants table
  db.run(`CREATE TABLE IF NOT EXISTS challenge_participants (
    id TEXT PRIMARY KEY,
    challengeId TEXT NOT NULL,
    userId TEXT NOT NULL,
    userName TEXT NOT NULL,
    progress TEXT,
    score REAL DEFAULT 0,
    joinedAt INTEGER NOT NULL,
    FOREIGN KEY (challengeId) REFERENCES challenges (id),
    FOREIGN KEY (userId) REFERENCES users (id)
  )`);

  // Leaderboard entries table
  db.run(`CREATE TABLE IF NOT EXISTS leaderboard_entries (
    id TEXT PRIMARY KEY,
    userId TEXT NOT NULL,
    userName TEXT NOT NULL,
    type TEXT NOT NULL,
    period TEXT NOT NULL,
    score REAL NOT NULL,
    stats TEXT,
    createdAt INTEGER NOT NULL,
    FOREIGN KEY (userId) REFERENCES users (id)
  )`);

  // Insert some sample data
  insertSampleData();
}

function insertSampleData() {
  const now = Date.now();
  
  // Sample users
  const sampleUsers = [
    {
      id: 'user_1',
      email: 'john.doe@example.com',
      name: 'John Doe',
      age: 28,
      weight: 75.0,
      gender: 'male',
      activityLevel: 2,
      location: 'New York, NY',
      latitude: 40.7128,
      longitude: -74.0060,
      createdAt: now,
      updatedAt: now,
      customGoal: 2500.0
    },
    {
      id: 'user_2',
      email: 'jane.smith@example.com',
      name: 'Jane Smith',
      age: 25,
      weight: 60.0,
      gender: 'female',
      activityLevel: 3,
      location: 'Los Angeles, CA',
      latitude: 34.0522,
      longitude: -118.2437,
      createdAt: now,
      updatedAt: now,
      customGoal: 2000.0
    },
    {
      id: 'user_3',
      email: 'mike.johnson@example.com',
      name: 'Mike Johnson',
      age: 32,
      weight: 80.0,
      gender: 'male',
      activityLevel: 4,
      location: 'Chicago, IL',
      latitude: 41.8781,
      longitude: -87.6298,
      createdAt: now,
      updatedAt: now,
      customGoal: 3000.0
    }
  ];

  sampleUsers.forEach(user => {
    db.run(`INSERT OR IGNORE INTO users (id, email, name, age, weight, gender, activityLevel, location, latitude, longitude, createdAt, updatedAt, customGoal) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [user.id, user.email, user.name, user.age, user.weight, user.gender, user.activityLevel, user.location, user.latitude, user.longitude, user.createdAt, user.updatedAt, user.customGoal]
    );
  });

  // Sample friend relationships
  db.run(`INSERT OR IGNORE INTO friends (id, userId, friendId, status, createdAt) VALUES (?, ?, ?, ?, ?)`,
    [uuidv4(), 'user_1', 'user_2', 'accepted', now]
  );
  db.run(`INSERT OR IGNORE INTO friends (id, userId, friendId, status, createdAt) VALUES (?, ?, ?, ?, ?)`,
    [uuidv4(), 'user_2', 'user_1', 'accepted', now]
  );

  // Sample friend requests
  db.run(`INSERT OR IGNORE INTO friend_requests (id, fromUserId, fromUserName, toUserId, message, status, createdAt) VALUES (?, ?, ?, ?, ?, ?, ?)`,
    [uuidv4(), 'user_1', 'John Doe', 'user_3', 'Hey! Let\'s stay hydrated together!', 'pending', now]
  );

  // Sample challenges
  const sampleChallenge = {
    id: 'challenge_1',
    title: 'Weekly Hydration Challenge',
    description: 'Stay hydrated for 7 days straight!',
    type: 0, // dailyGoal
    startDate: new Date().toISOString(),
    endDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
    rules: JSON.stringify({ goalDays: 7, targetIntake: 2000 }),
    createdBy: 'user_1',
    createdByName: 'John Doe',
    status: 'active',
    createdAt: now
  };

  db.run(`INSERT OR IGNORE INTO challenges (id, title, description, type, startDate, endDate, rules, createdBy, createdByName, status, createdAt) 
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [sampleChallenge.id, sampleChallenge.title, sampleChallenge.description, sampleChallenge.type, sampleChallenge.startDate, sampleChallenge.endDate, sampleChallenge.rules, sampleChallenge.createdBy, sampleChallenge.createdByName, sampleChallenge.status, sampleChallenge.createdAt]
  );

  // Sample challenge participants
  db.run(`INSERT OR IGNORE INTO challenge_participants (id, challengeId, userId, userName, progress, score, joinedAt) VALUES (?, ?, ?, ?, ?, ?, ?)`,
    [uuidv4(), 'challenge_1', 'user_1', 'John Doe', JSON.stringify({ daysCompleted: 3, goalMet: true }), 300.0, now]
  );
  db.run(`INSERT OR IGNORE INTO challenge_participants (id, challengeId, userId, userName, progress, score, joinedAt) VALUES (?, ?, ?, ?, ?, ?, ?)`,
    [uuidv4(), 'challenge_1', 'user_2', 'Jane Smith', JSON.stringify({ daysCompleted: 2, goalMet: true }), 200.0, now]
  );

  // Sample leaderboard entries
  const leaderboardEntries = [
    { userId: 'user_1', userName: 'John Doe', type: 'global', period: 'weekly', score: 850.0, stats: JSON.stringify({ currentStreak: 5, longestStreak: 12 }) },
    { userId: 'user_2', userName: 'Jane Smith', type: 'global', period: 'weekly', score: 720.0, stats: JSON.stringify({ currentStreak: 3, longestStreak: 8 }) },
    { userId: 'user_3', userName: 'Mike Johnson', type: 'global', period: 'weekly', score: 650.0, stats: JSON.stringify({ currentStreak: 2, longestStreak: 5 }) }
  ];

  leaderboardEntries.forEach(entry => {
    db.run(`INSERT OR IGNORE INTO leaderboard_entries (id, userId, userName, type, period, score, stats, createdAt) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [uuidv4(), entry.userId, entry.userName, entry.type, entry.period, entry.score, entry.stats, now]
    );
  });
}

// Authentication middleware
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key', (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Invalid token' });
    }
    req.user = user;
    next();
  });
}

// Routes

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Friend routes
app.get('/users/:userId/friends', (req, res) => {
  const { userId } = req.params;
  
  db.all(`SELECT u.id, u.name, u.email, f.status, f.createdAt 
           FROM friends f 
           JOIN users u ON f.friendId = u.id 
           WHERE f.userId = ? AND f.status = 'accepted'`, 
    [userId], (err, rows) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      res.json(rows);
    });
});

app.get('/users/:userId/friend-requests/pending', (req, res) => {
  const { userId } = req.params;
  
  db.all(`SELECT * FROM friend_requests WHERE toUserId = ? AND status = 'pending'`, 
    [userId], (err, rows) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      res.json(rows);
    });
});

app.post('/friend-requests', (req, res) => {
  const { fromUserId, fromUserName, toUserId, message } = req.body;
  
  db.run(`INSERT INTO friend_requests (id, fromUserId, fromUserName, toUserId, message, status, createdAt) 
          VALUES (?, ?, ?, ?, ?, ?, ?)`,
    [uuidv4(), fromUserId, fromUserName, toUserId, message, 'pending', Date.now()],
    function(err) {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      res.status(201).json({ id: this.lastID, message: 'Friend request sent' });
    });
});

app.put('/friend-requests/:requestId/accept', (req, res) => {
  const { requestId } = req.params;
  
  db.get(`SELECT * FROM friend_requests WHERE id = ?`, [requestId], (err, request) => {
    if (err || !request) {
      return res.status(404).json({ error: 'Friend request not found' });
    }
    
    const now = Date.now();
    db.run(`UPDATE friend_requests SET status = 'accepted' WHERE id = ?`, [requestId]);
    db.run(`INSERT INTO friends (id, userId, friendId, status, createdAt) VALUES (?, ?, ?, ?, ?)`,
      [uuidv4(), request.fromUserId, request.toUserId, 'accepted', now]);
    db.run(`INSERT INTO friends (id, userId, friendId, status, createdAt) VALUES (?, ?, ?, ?, ?)`,
      [uuidv4(), request.toUserId, request.fromUserId, 'accepted', now]);
    
    res.json({ message: 'Friend request accepted' });
  });
});

app.put('/friend-requests/:requestId/decline', (req, res) => {
  const { requestId } = req.params;
  
  db.run(`UPDATE friend_requests SET status = 'declined' WHERE id = ?`, [requestId], function(err) {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res.json({ message: 'Friend request declined' });
  });
});

app.get('/users/search', (req, res) => {
  const { q } = req.query;
  
  db.all(`SELECT id, name, email FROM users WHERE name LIKE ? OR email LIKE ?`, 
    [`%${q}%`, `%${q}%`], (err, rows) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      res.json(rows);
    });
});

// Challenge routes
app.get('/users/:userId/challenges', (req, res) => {
  const { userId } = req.params;
  
  db.all(`SELECT c.*, cp.userId as participantId 
           FROM challenges c 
           JOIN challenge_participants cp ON c.id = cp.challengeId 
           WHERE cp.userId = ?`, 
    [userId], (err, rows) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      res.json(rows);
    });
});

app.post('/challenges', (req, res) => {
  const { title, description, type, startDate, endDate, rules, participants, createdBy, createdByName } = req.body;
  
  const challengeId = uuidv4();
  const now = Date.now();
  
  db.run(`INSERT INTO challenges (id, title, description, type, startDate, endDate, rules, createdBy, createdByName, status, createdAt) 
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [challengeId, title, description, type, startDate, endDate, JSON.stringify(rules), createdBy, createdByName, 'active', now],
    function(err) {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      
      // Add participants
      participants.forEach(participantId => {
        db.run(`INSERT INTO challenge_participants (id, challengeId, userId, userName, progress, score, joinedAt) 
                VALUES (?, ?, ?, ?, ?, ?, ?)`,
          [uuidv4(), challengeId, participantId, 'User', '{}', 0, now]);
      });
      
      res.status(201).json({ 
        id: challengeId, 
        title, 
        description, 
        type, 
        startDate, 
        endDate, 
        rules, 
        createdBy, 
        createdByName, 
        status: 'active',
        createdAt: now
      });
    });
});

app.get('/challenges/:challengeId/participants', (req, res) => {
  const { challengeId } = req.params;
  
  db.all(`SELECT * FROM challenge_participants WHERE challengeId = ? ORDER BY score DESC`, 
    [challengeId], (err, rows) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      res.json(rows);
    });
});

// Leaderboard routes
app.get('/leaderboards/global', (req, res) => {
  const { period = 1, limit = 50 } = req.query;
  
  db.all(`SELECT userId, userName, score, stats, createdAt 
           FROM leaderboard_entries 
           WHERE type = 'global' AND period = ? 
           ORDER BY score DESC 
           LIMIT ?`, 
    [period, limit], (err, rows) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      res.json({
        type: 'global',
        period: parseInt(period),
        entries: rows,
        totalEntries: rows.length
      });
    });
});

app.get('/leaderboards/streak', (req, res) => {
  const { limit = 50 } = req.query;
  
  db.all(`SELECT userId, userName, score, stats, createdAt 
           FROM leaderboard_entries 
           WHERE type = 'streak' 
           ORDER BY score DESC 
           LIMIT ?`, 
    [limit], (err, rows) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      res.json({
        type: 'streak',
        entries: rows,
        totalEntries: rows.length
      });
    });
});

app.get('/users/:userId/leaderboards/friends', (req, res) => {
  const { userId } = req.params;
  const { period = 1 } = req.query;
  
  db.all(`SELECT le.userId, le.userName, le.score, le.stats, le.createdAt 
           FROM leaderboard_entries le 
           JOIN friends f ON le.userId = f.friendId 
           WHERE f.userId = ? AND le.type = 'global' AND le.period = ? 
           ORDER BY le.score DESC`, 
    [userId, period], (err, rows) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      res.json({
        type: 'friends',
        period: parseInt(period),
        entries: rows,
        totalEntries: rows.length
      });
    });
});

// User routes
app.get('/users/:userId', (req, res) => {
  const { userId } = req.params;
  
  db.get(`SELECT * FROM users WHERE id = ?`, [userId], (err, row) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    if (!row) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.json(row);
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

app.listen(PORT, () => {
  console.log(`Hydration Tracker API server running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
}); 