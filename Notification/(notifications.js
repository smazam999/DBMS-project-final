// Example to dynamically add a new notification
const notifications = {
    courseNotifications: [
        { course: 'Web Development', update: 'Final project submission date announced.', date: '30 November 2024' }
    ],
    upcomingCourses: [
        { course: 'Cloud Computing', startDate: '10 December 2024' }
    ],
    newUpdates: [
        { update: 'New dashboard feature launched.' }
    ],
    newCourses: [
        { course: 'Machine Learning Advanced', addedOn: '1 December 2024' }
    ]
};

// Example function to add a new course notification
function addCourseNotification(course, update, date) {
    const section = document.querySelector('.notification-section ul');
    const li = document.createElement('li');
    li.innerHTML = `<p><strong>Course:</strong> ${course}</p><p><strong>Update:</strong> ${update}</p><p><strong>Date:</strong> ${date}</p>`;
    section.appendChild(li);
}
