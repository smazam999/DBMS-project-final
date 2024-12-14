const sqlite3 = require("sqlite3").verbose();
const db = new sqlite3.Database("./db/courses.db");

// Example: Fetch all courses
app.get("/api/courses", (req, res) => {
    db.all("SELECT * FROM courses", [], (err, rows) => {
        if (err) {
            res.status(500).json({ error: err.message });
            return;
        }
        res.json(rows);
    });
});
