# CareerKit Project 2 Report

## Project Description

CareerKit helps users manage career/CV readiness profiles. Each profile stores the user's name, target role, number of skills, number of projects, checklist items, readiness score, and feedback.

## Technologies Used

- Flutter for the mobile frontend
- Node.js and Express for the REST API
- mysql2/promise for MySQL access
- Railway MySQL as the online database
- cors and dotenv for API configuration

## Database

The database uses one main table: `career_profiles`.

Fields:

- `id`
- `full_name`
- `target_role`
- `skills_count`
- `projects_count`
- `has_contact`
- `has_education`
- `has_skills_section`
- `has_projects_section`
- `readiness_score`
- `feedback`
- `created_at`

The SQL setup and sample data are stored in `database/careerkit_db.sql`.

## CRUD Operations

| Operation | Endpoint | Description |
|---|---|---|
| Create | `POST /api/profiles` | Adds a new career profile |
| Read | `GET /api/profiles` | Returns all profiles |
| Read | `GET /api/profiles/:id` | Returns one profile by id |
| Update | `PUT /api/profiles/:id` | Updates a profile |
| Delete | `DELETE /api/profiles/:id` | Deletes a profile |

## API Routes

- `GET /api/health`
- `GET /api/profiles`
- `GET /api/profiles/:id`
- `POST /api/profiles`
- `PUT /api/profiles/:id`
- `DELETE /api/profiles/:id`

## Readiness Score

The backend calculates the score automatically:

- Contact information: 20 points
- Education section: 20 points
- Skills section: 20 points
- Projects section: 20 points
- At least 3 skills: 10 points
- At least 1 project: 10 points

The maximum score is 100. The backend also returns feedback based on the final score.

## Flutter API Connection

The Flutter frontend uses the `http` package and a single configurable API base URL in `lib/main.dart`:

```dart
const String apiBaseUrl = 'https://YOUR-DEPLOYED-BACKEND-URL/api';
```

For Android emulator local testing:

```dart
const String apiBaseUrl = 'http://10.0.2.2:3000/api';
```

## Conclusion

CareerKit satisfies Project 2 requirements by providing a Node.js/Express backend, an online MySQL database schema, public REST API routes, CRUD operations, Flutter API integration, setup instructions, and a short project report.
