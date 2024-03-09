// Assuming your business categories are as follows:
const categories = {
    'Building Materials': ['Building Materials', 'Construction Materials'],
    'Hotels': ['Hotel', 'Hotels'],
    'Government': ['Government', 'Government Agencies'],
    'Auto Spare Parts': ['Auto Spare Parts', 'Car Auto Spare Parts'],
    'Miscellaneous': ['Miscellaneous'] // You can add more tags as needed
};

let globalBusinesses = [];  // Declare this outside any function

document.addEventListener('DOMContentLoaded', () => {
    fetch('businesses.json')
        .then(response => response.json())
        .then(data => {
            globalBusinesses = data; // Store the data globally
            displayCategories(data);
        })
        .catch(error => console.error('Error loading the businesses data:', error));
});

function displayCategories(businesses) {
    const menu = document.getElementById('category-menu');
    Object.keys(categories).forEach(category => {
        const catButton = document.createElement('button');
        catButton.className = 'category-button';
        catButton.innerText = category;
        catButton.onclick = () => filterBusinessesByCategory(businesses, category);
        menu.appendChild(catButton);
    });
}

function filterBusinessesByCategory(businesses, category) {
    const filteredBusinesses = businesses.filter(business =>
        categories[category].some(tag => business['Business Tag'].includes(tag))
    );
    displayBusinesses(filteredBusinesses);
}

function displayBusinesses(businesses) {
    const list = document.getElementById('business-list');
    list.innerHTML = ''; // Clear existing list
    businessDetails = businesses; // Store all business details globally

    businesses.forEach((business, index) => {
        const item = document.createElement('div');
        item.className = 'business';

        // Generate conditional buttons HTML based on business tags
        let conditionalButtonHTML = '';
        if (business['Business Tag'].includes('Hotel')) {
            conditionalButtonHTML = `<button class="book-now-btn">Book Now</button>`;
        } else if (business['Business Tag'].includes('Auto Spare Parts')) {
            conditionalButtonHTML = `<button class="request-quote-btn">Request Quote</button>`;
        }

        // Dummy out first three characters of each field except tags
        const dummyOutText = text => 'XXX' + text.substring(3);

        // Generate HTML for each business
        item.innerHTML = `
            <h2>${dummyOutText(business['Business Name'])}</h2>
            <p>${dummyOutText(business['Category'])}</p>
            <p>${dummyOutText(business['Short Description'])}</p>
            <p>Phone: ${dummyOutText(business['Phone Number'])}</p>
            <p>Tags: ${business['Business Tag']}</p>
            <button class="details-btn" onclick="showDetails(${index})">View Details</button>
            ${conditionalButtonHTML}
        `;
        list.appendChild(item);
    });
}

function showDetails(index) {
    const business = businessDetails[index]; // Retrieve specific business details
    if (business) {
        // Function to replace first three characters with 'XXX'
        const dummyOutText = text => 'XXX' + text.substring(3);

        const modal = document.getElementById('detail-modal');
        modal.style.display = 'block';
        modal.innerHTML = `
            <div class="modal-content">
                <span class="close" onclick="closeModal()">&times;</span>
                <h2>${dummyOutText(business['Business Name'])}</h2>
                <p><strong>Category:</strong> ${dummyOutText(business['Category'])}</p>
                <p><strong>Description:</strong> ${dummyOutText(business['Long Description'])}</p>
                <p><strong>Phone:</strong> ${dummyOutText(business['Phone Number'])}</p>
                <p><strong>Tags:</strong> ${business['Business Tag']}</p>
            </div>
        `;
    }
}


function closeModal() {
    const modal = document.getElementById('detail-modal');
    modal.style.display = 'none';
}


// Make sure to add CSS for .modal and .modal-content to style your details view
