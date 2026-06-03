-- CareerKit Project 2 database setup
-- Railway MySQL usually provides a default database named `railway`.
USE railway;

DROP TABLE IF EXISTS career_profiles;

CREATE TABLE career_profiles (
  id INT AUTO_INCREMENT PRIMARY KEY,
  full_name VARCHAR(100) NOT NULL,
  target_role VARCHAR(100) NOT NULL,
  skills_count INT NOT NULL DEFAULT 0,
  projects_count INT NOT NULL DEFAULT 0,
  has_contact BOOLEAN NOT NULL DEFAULT FALSE,
  has_education BOOLEAN NOT NULL DEFAULT FALSE,
  has_skills_section BOOLEAN NOT NULL DEFAULT FALSE,
  has_projects_section BOOLEAN NOT NULL DEFAULT FALSE,
  readiness_score INT NOT NULL DEFAULT 0,
  feedback TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO career_profiles (
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
) VALUES
('Ali Hassan', 'Internship', 4, 2, TRUE, TRUE, TRUE, TRUE, 100, 'Your CV looks ready.'),
('Maya Saleh', 'Junior Developer', 2, 1, TRUE, TRUE, TRUE, FALSE, 70, 'Your CV is okay but needs some improvement.'),
('Omar Khaled', 'General Career Profile', 1, 0, TRUE, FALSE, FALSE, FALSE, 20, 'Your CV needs improvement.');
