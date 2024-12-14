// Course data
const courses = [
    { id: 1, title: "Web Development", tokens: 2 },
    { id: 2, title: "Cyber Security", tokens: 2 },
    { id: 3, title: "JAVA Programming", tokens: 2 },
    { id: 4, title: "C++ Programming", tokens: 2 },
    { id: 5, title: "C Programming", tokens: 2 },
    { id: 6, title: "SEO", tokens: 2 },
    { id: 7, title: "Social Media Management", tokens: 2 },
    { id: 8, title: "Conetent Writer", tokens: 2 }
];

// User's token balance
let userTokens = 10;

// Rendering courses
function renderCourses() {
    const courseContainer = document.getElementById('courses');
    courseContainer.innerHTML = '';

    courses.forEach(course => {
        const courseDiv = document.createElement('div');
        courseDiv.className = 'course';

        courseDiv.innerHTML = `
            <span class="course-title">${course.title}</span>
            <button class="token-button" id="btn-${course.id}" onclick="exchangeCourse(${course.id})" 
                ${course.tokens > userTokens ? 'disabled' : ''}>
                ${course.tokens} Token
            </button>
        `;

        courseContainer.appendChild(courseDiv);
    });
}

// Exchange course
function exchangeCourse(courseId) {
    const course = courses.find(c => c.id === courseId);
    if (course && userTokens >= course.tokens) {
        userTokens -= course.tokens;
        alert(`You have exchanged "${course.title}" for ${course.tokens} tokens. Remaining tokens: ${userTokens}`);
        renderCourses();
    }
}

// Initial render
renderCourses();
