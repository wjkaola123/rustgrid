CREATE TABLE verification_items (
    id INTEGER PRIMARY KEY,
    label TEXT NOT NULL,
    score REAL,
    note TEXT
);
WITH RECURSIVE seq(n) AS (
    SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < 205
)
INSERT INTO verification_items (id, label, score, note)
SELECT n, printf('item-%03d', n), n * 1.25,
       CASE WHEN n % 2 = 0 THEN '' ELSE NULL END
FROM seq;
SELECT COUNT(*) AS total, MIN(id) AS first_id, MAX(id) AS last_id
FROM verification_items;
