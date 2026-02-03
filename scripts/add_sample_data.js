const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
const serviceAccount = require('../serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'hydration-tracker-app-2024'
});

const db = admin.firestore();

async function addSampleData() {
  try {
    console.log('Adding sample data to Firebase...');

    // Add sample users
    const users = [
      {
        id: 'user_1',
        name: 'Alice Johnson',
        email: 'alice@example.com',
        age: 28,
        weight: 65.0,
        gender: 'female',
        activityLevel: 2,
        location: 'San Francisco, CA',
        latitude: 37.7749,
        longitude: -122.4194,
        customGoal: 2500.0,
        createdAt: Date.now(),
        updatedAt: Date.now()
      },
      {
        id: 'user_2',
        name: 'Bob Smith',
        email: 'bob@example.com',
        age: 32,
        weight: 80.0,
        gender: 'male',
        activityLevel: 3,
        location: 'New York, NY',
        latitude: 40.7128,
        longitude: -74.0060,
        customGoal: 3000.0,
        createdAt: Date.now(),
        updatedAt: Date.now()
      },
      {
        id: 'user_3',
        name: 'Carol Davis',
        email: 'carol@example.com',
        age: 25,
        weight: 55.0,
        gender: 'female',
        activityLevel: 1,
        location: 'Los Angeles, CA',
        latitude: 34.0522,
        longitude: -118.2437,
        customGoal: 2000.0,
        createdAt: Date.now(),
        updatedAt: Date.now()
      }
    ];

    // Add users to Firestore
    for (const user of users) {
      await db.collection('users').doc(user.id).set(user);
      console.log(`Added user: ${user.name}`);
    }

    // Add sample friend relationships
    const friends = [
      {
        userId: 'user_1',
        friendId: 'user_2',
        status: 'accepted',
        createdAt: Date.now()
      },
      {
        userId: 'user_2',
        friendId: 'user_1',
        status: 'accepted',
        createdAt: Date.now()
      },
      {
        userId: 'user_1',
        friendId: 'user_3',
        status: 'accepted',
        createdAt: Date.now()
      },
      {
        userId: 'user_3',
        friendId: 'user_1',
        status: 'accepted',
        createdAt: Date.now()
      }
    ];

    // Add friend relationships
    for (const friend of friends) {
      await db.collection('friends').add(friend);
      console.log(`Added friend relationship: ${friend.userId} -> ${friend.friendId}`);
    }

    // Add sample challenges
    const challenges = [
      {
        id: 'challenge_1',
        title: 'Weekly Hydration Challenge',
        description: 'Stay hydrated for 7 days straight!',
        type: 'dailyGoal',
        startDate: new Date('2024-01-01'),
        endDate: new Date('2024-01-08'),
        rules: {
          dailyGoal: 2000,
          streakRequired: 7
        },
        createdBy: 'user_1',
        createdByName: 'Alice Johnson',
        status: 'active',
        participants: ['user_1', 'user_2', 'user_3'],
        createdAt: Date.now()
      },
      {
        id: 'challenge_2',
        title: 'Hydration Streak',
        description: 'Build the longest hydration streak!',
        type: 'streak',
        startDate: new Date('2024-01-01'),
        endDate: new Date('2024-01-31'),
        rules: {
          minStreak: 5,
          bonusPoints: 100
        },
        createdBy: 'user_2',
        createdByName: 'Bob Smith',
        status: 'active',
        participants: ['user_1', 'user_2'],
        createdAt: Date.now()
      }
    ];

    // Add challenges
    for (const challenge of challenges) {
      await db.collection('challenges').doc(challenge.id).set(challenge);
      console.log(`Added challenge: ${challenge.title}`);
    }

    // Add challenge participants
    const participants = [
      {
        challengeId: 'challenge_1',
        userId: 'user_1',
        userName: 'Alice Johnson',
        progress: {
          daysCompleted: 5,
          currentStreak: 5,
          totalIntake: 10000
        },
        score: 500.0,
        joinedAt: Date.now()
      },
      {
        challengeId: 'challenge_1',
        userId: 'user_2',
        userName: 'Bob Smith',
        progress: {
          daysCompleted: 3,
          currentStreak: 3,
          totalIntake: 6000
        },
        score: 300.0,
        joinedAt: Date.now()
      },
      {
        challengeId: 'challenge_1',
        userId: 'user_3',
        userName: 'Carol Davis',
        progress: {
          daysCompleted: 7,
          currentStreak: 7,
          totalIntake: 14000
        },
        score: 700.0,
        joinedAt: Date.now()
      }
    ];

    // Add challenge participants
    for (const participant of participants) {
      await db.collection('challenge_participants').add(participant);
      console.log(`Added participant: ${participant.userName} to challenge ${participant.challengeId}`);
    }

    // Add sample leaderboard entries
    const leaderboardEntries = [
      {
        userId: 'user_1',
        userName: 'Alice Johnson',
        type: 'global',
        period: 1, // weekly
        score: 850.0,
        stats: {
          currentStreak: 5,
          longestStreak: 12,
          totalIntake: 15000,
          goalDays: 15,
          totalDays: 20
        },
        createdAt: Date.now()
      },
      {
        userId: 'user_2',
        userName: 'Bob Smith',
        type: 'global',
        period: 1, // weekly
        score: 720.0,
        stats: {
          currentStreak: 3,
          longestStreak: 8,
          totalIntake: 12000,
          goalDays: 12,
          totalDays: 20
        },
        createdAt: Date.now()
      },
      {
        userId: 'user_3',
        userName: 'Carol Davis',
        type: 'global',
        period: 1, // weekly
        score: 950.0,
        stats: {
          currentStreak: 7,
          longestStreak: 15,
          totalIntake: 18000,
          goalDays: 18,
          totalDays: 20
        },
        createdAt: Date.now()
      },
      {
        userId: 'user_1',
        userName: 'Alice Johnson',
        type: 'streak',
        period: 0, // all time
        score: 120.0,
        stats: {
          currentStreak: 5,
          longestStreak: 12
        },
        createdAt: Date.now()
      },
      {
        userId: 'user_2',
        userName: 'Bob Smith',
        type: 'streak',
        period: 0, // all time
        score: 80.0,
        stats: {
          currentStreak: 3,
          longestStreak: 8
        },
        createdAt: Date.now()
      },
      {
        userId: 'user_3',
        userName: 'Carol Davis',
        type: 'streak',
        period: 0, // all time
        score: 150.0,
        stats: {
          currentStreak: 7,
          longestStreak: 15
        },
        createdAt: Date.now()
      }
    ];

    // Add leaderboard entries
    for (const entry of leaderboardEntries) {
      await db.collection('leaderboard_entries').add(entry);
      console.log(`Added leaderboard entry: ${entry.userName} - ${entry.score} points`);
    }

    console.log('✅ Sample data added successfully!');
    console.log('\n📊 Summary:');
    console.log('- 3 users added');
    console.log('- 4 friend relationships added');
    console.log('- 2 challenges added');
    console.log('- 3 challenge participants added');
    console.log('- 6 leaderboard entries added');

  } catch (error) {
    console.error('Error adding sample data:', error);
  } finally {
    process.exit(0);
  }
}

addSampleData(); 