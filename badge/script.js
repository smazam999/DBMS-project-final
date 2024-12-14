// Badge data (initial dummy data)
const badges = {
    topContributor: ["Alice", "Bob", "Charlie"],
    verifiedUser: ["John", "Jane", "Smith"],
    mentor: ["Lisa", "Tom"],
    activeParticipant: ["Emma", "Sophia", "Olivia"],
    topLearner: ["James", "Ethan", "Liam"],
    skillSharer: ["Ella", "Mason"],
    risingStar: ["Ava", "Noah", "Isabella"]
};

// Function to render badge sections
function renderBadgeSections() {
    const badgeSections = document.getElementById('badge-sections');
    badgeSections.innerHTML = '';

    Object.keys(badges).forEach(key => {
        const section = document.createElement('div');
        section.className = 'badge-section';

        section.innerHTML = `
            <h2 class="badge-title">${formatBadgeTitle(key)}</h2>
            <ul class="badge-list" id="${key}-list">
                ${badges[key].map(name => `<li>${name}</li>`).join('')}
            </ul>
        `;
        badgeSections.appendChild(section);
    });
}

// Function to format badge title
function formatBadgeTitle(key) {
    return key
        .replace(/([A-Z])/g, ' $1')
        .replace(/^./, str => str.toUpperCase());
}

// Add entry functionality
document.getElementById('add-entry-btn').addEventListener('click', () => {
    const badgeType = document.getElementById('badge-type').value;
    const newEntry = document.getElementById('new-entry').value.trim();

    if (newEntry) {
        badges[badgeType].push(newEntry); // Add to badge list
        renderBadgeSections(); // Re-render badge sections
        document.getElementById('new-entry').value = ''; // Clear input
        alert(`${newEntry} added to ${formatBadgeTitle(badgeType)}!`);
    } else {
        alert('Please enter a name.');
    }
});

// Initial render
renderBadgeSections();
