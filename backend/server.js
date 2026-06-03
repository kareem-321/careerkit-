require('dotenv').config();

const cors = require('cors');
const express = require('express');
const mysql = require('mysql2/promise');

const app = express();
const PORT = Number(process.env.PORT) || 3000;

app.use(cors());
app.use(express.json());

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
});

const profileColumns = `
  id,
  full_name,
  target_role,
  skills_count,
  projects_count,
  has_contact,
  has_education,
  has_skills_section,
  has_projects_section,
  readiness_score,
  feedback,
  created_at
`;

function parseId(rawId) {
  const id = Number(rawId);
  return Number.isInteger(id) && id > 0 ? id : null;
}

function toBoolean(value) {
  return value === true || value === 1 || value === '1' || value === 'true';
}

function toNonNegativeInt(value) {
  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed < 0) {
    return null;
  }
  return parsed;
}

function calculateReadiness(profile) {
  let score = 0;

  if (profile.has_contact) score += 20;
  if (profile.has_education) score += 20;
  if (profile.has_skills_section) score += 20;
  if (profile.has_projects_section) score += 20;
  if (profile.skills_count >= 3) score += 10;
  if (profile.projects_count >= 1) score += 10;

  let feedback = 'Your CV needs improvement.';
  if (score >= 80) {
    feedback = 'Your CV looks ready.';
  } else if (score >= 50) {
    feedback = 'Your CV is okay but needs some improvement.';
  }

  return { readiness_score: score, feedback };
}

function buildProfilePayload(body) {
  const fullName = String(body.full_name || '').trim();
  const targetRole = String(body.target_role || '').trim();
  const skillsCount = toNonNegativeInt(body.skills_count ?? 0);
  const projectsCount = toNonNegativeInt(body.projects_count ?? 0);
  const errors = [];

  if (fullName.length < 2) {
    errors.push('full_name is required and must contain at least 2 characters.');
  }

  if (targetRole.length < 2) {
    errors.push('target_role is required and must contain at least 2 characters.');
  }

  if (skillsCount === null) {
    errors.push('skills_count must be a non-negative integer.');
  }

  if (projectsCount === null) {
    errors.push('projects_count must be a non-negative integer.');
  }

  if (errors.length > 0) {
    return { errors };
  }

  const profile = {
    full_name: fullName,
    target_role: targetRole,
    skills_count: skillsCount,
    projects_count: projectsCount,
    has_contact: toBoolean(body.has_contact),
    has_education: toBoolean(body.has_education),
    has_skills_section: toBoolean(body.has_skills_section),
    has_projects_section: toBoolean(body.has_projects_section),
  };

  return {
    profile: {
      ...profile,
      ...calculateReadiness(profile),
    },
    errors: [],
  };
}

async function getProfileById(id) {
  const [rows] = await pool.execute(
    `SELECT ${profileColumns} FROM career_profiles WHERE id = ?`,
    [id]
  );
  return rows[0] || null;
}

app.get('/', (req, res) => {
  res.json({
    app: 'CareerKit',
    message: 'CareerKit API is running.',
    health: '/api/health',
    profiles: '/api/profiles',
  });
});

app.get('/api', (req, res) => {
  res.json({
    app: 'CareerKit',
    message: 'Use one of the CareerKit API routes.',
    routes: [
      'GET /api/health',
      'GET /api/profiles',
      'GET /api/profiles/:id',
      'POST /api/profiles',
      'DELETE /api/profiles/:id',
    ],
  });
});

app.get('/api/health', async (req, res, next) => {
  try {
    await pool.execute('SELECT 1');
    res.json({
      status: 'ok',
      api: 'CareerKit',
      database: 'connected',
    });
  } catch (error) {
    next(error);
  }
});

app.get('/api/profiles', async (req, res, next) => {
  try {
    const [rows] = await pool.execute(
      `SELECT ${profileColumns}
       FROM career_profiles
       ORDER BY id DESC`
    );
    res.json(rows);
  } catch (error) {
    next(error);
  }
});

app.get('/api/profiles/:id', async (req, res, next) => {
  try {
    const id = parseId(req.params.id);
    if (!id) {
      return res.status(400).json({ message: 'Invalid profile id.' });
    }

    const profile = await getProfileById(id);
    if (!profile) {
      return res.status(404).json({ message: 'Profile not found.' });
    }

    res.json(profile);
  } catch (error) {
    next(error);
  }
});

app.post('/api/profiles', async (req, res, next) => {
  try {
    const { profile, errors } = buildProfilePayload(req.body);
    if (errors.length > 0) {
      return res.status(400).json({ message: 'Validation failed.', errors });
    }

    const [result] = await pool.execute(
      `INSERT INTO career_profiles (
        full_name,
        target_role,
        skills_count,
        projects_count,
        has_contact,
        has_education,
        has_skills_section,
        has_projects_section,
        readiness_score,
        feedback
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        profile.full_name,
        profile.target_role,
        profile.skills_count,
        profile.projects_count,
        profile.has_contact,
        profile.has_education,
        profile.has_skills_section,
        profile.has_projects_section,
        profile.readiness_score,
        profile.feedback,
      ]
    );

    const createdProfile = await getProfileById(result.insertId);
    res.status(201).json(createdProfile);
  } catch (error) {
    next(error);
  }
});

app.delete('/api/profiles/:id', async (req, res, next) => {
  try {
    const id = parseId(req.params.id);
    if (!id) {
      return res.status(400).json({ message: 'Invalid profile id.' });
    }

    const [result] = await pool.execute('DELETE FROM career_profiles WHERE id = ?', [id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Profile not found.' });
    }

    res.json({ message: 'Profile deleted successfully.' });
  } catch (error) {
    next(error);
  }
});

app.use((req, res) => {
  res.status(404).json({ message: 'Route not found.' });
});

app.use((error, req, res, next) => {
  console.error(error);
  res.status(500).json({
    message: 'Server error.',
    details: process.env.NODE_ENV === 'production' ? undefined : error.message,
  });
});

app.listen(PORT, () => {
  console.log(`CareerKit API running on port ${PORT}`);
});
