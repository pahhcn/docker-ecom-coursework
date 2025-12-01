// API Configuration
const API_BASE_URL = '/api';
const API_ENDPOINTS = {
    products: `${API_BASE_URL}/products`,
    productById: (id) => `${API_BASE_URL}/products/${id}`
};

// Retry configuration
const RETRY_CONFIG = {
    maxRetries: 3,
    initialDelay: 1000,
    backoffMultiplier: 2
};

// Utility Functions
function showElement(elementId) {
    const element = document.getElementById(elementId);
    if (element) {
        element.classList.remove('hidden');
    }
}

function hideElement(elementId) {
    const element = document.getElementById(elementId);
    if (element) {
        element.classList.add('hidden');
    }
}

function showLoading() {
    hideElement('error');
    hideElement('product-grid');
    hideElement('product-detail');
    showElement('loading');
}

function showError(message) {
    hideElement('loading');
    hideElement('product-grid');
    hideElement('product-detail');
    
    const errorElement = document.getElementById('error');
    const errorMessageElement = errorElement?.querySelector('.error-message');
    
    if (errorMessageElement) {
        errorMessageElement.textContent = message;
    }
    
    showElement('error');
}

function showContent(contentId) {
    hideElement('loading');
    hideElement('error');
    showElement(contentId);
}

// API Functions with retry logic
async function fetchWithRetry(url, options = {}, retryCount = 0) {
    try {
        const response = await fetch(url, {
            ...options,
            headers: {
                'Content-Type': 'application/json',
                ...options.headers
            }
        });

        if (!response.ok) {
            if (response.status >= 500 && retryCount < RETRY_CONFIG.maxRetries) {
                // Retry on server errors
                const delay = RETRY_CONFIG.initialDelay * Math.pow(RETRY_CONFIG.backoffMultiplier, retryCount);
                await sleep(delay);
                return fetchWithRetry(url, options, retryCount + 1);
            }
            
            // Handle client errors
            const errorData = await response.json().catch(() => ({}));
            throw new Error(errorData.message || `HTTP ${response.status}: ${response.statusText}`);
        }

        return response;
    } catch (error) {
        if (error.name === 'TypeError' && retryCount < RETRY_CONFIG.maxRetries) {
            // Network error, retry
            const delay = RETRY_CONFIG.initialDelay * Math.pow(RETRY_CONFIG.backoffMultiplier, retryCount);
            await sleep(delay);
            return fetchWithRetry(url, options, retryCount + 1);
        }
        throw error;
    }
}

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function fetchProducts() {
    try {
        const response = await fetchWithRetry(API_ENDPOINTS.products);
        const products = await response.json();
        return products;
    } catch (error) {
        console.error('获取产品列表出错:', error);
        throw new Error(`加载产品失败：${error.message}`);
    }
}

async function fetchProductById(id) {
    try {
        const response = await fetchWithRetry(API_ENDPOINTS.productById(id));
        const product = await response.json();
        return product;
    } catch (error) {
        console.error(`获取产品 ${id} 出错:`, error);
        throw new Error(`加载产品详情失败：${error.message}`);
    }
}

// Formatting Functions
function formatPrice(price) {
    return new Intl.NumberFormat('zh-CN', {
        style: 'currency',
        currency: 'CNY'
    }).format(price);
}

function formatDate(dateString) {
    const date = new Date(dateString);
    return new Intl.DateTimeFormat('zh-CN', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    }).format(date);
}

function getStockStatus(quantity) {
    if (quantity === 0) {
        return { text: '缺货', class: 'out-of-stock' };
    } else if (quantity < 10) {
        return { text: `库存不足（剩余 ${quantity} 件）`, class: 'low-stock' };
    } else {
        return { text: `有货（${quantity} 件可用）`, class: 'in-stock' };
    }
}

function truncateText(text, maxLength) {
    if (!text) return '';
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength) + '...';
}

// Product List Page Functions
function createProductCard(product) {
    const card = document.createElement('div');
    card.className = 'product-card';
    card.onclick = () => navigateToProduct(product.id);

    const stockStatus = getStockStatus(product.stockQuantity);
    const imageUrl = product.imageUrl || 'https://via.placeholder.com/280x200?text=暂无图片';
    const description = product.description || '暂无描述';

    card.innerHTML = `
        <img src="${imageUrl}" alt="${product.name}" class="product-card-image" onerror="this.src='https://via.placeholder.com/280x200?text=暂无图片'">
        <div class="product-card-content">
            <h3 class="product-card-name">${escapeHtml(product.name)}</h3>
            <p class="product-card-category">${escapeHtml(product.category || '未分类')}</p>
            <p class="product-card-description">${escapeHtml(truncateText(description, 100))}</p>
            <div class="product-card-footer">
                <span class="product-card-price">${formatPrice(product.price)}</span>
                <span class="product-card-stock ${stockStatus.class}">${stockStatus.text}</span>
            </div>
        </div>
    `;

    return card;
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function navigateToProduct(productId) {
    window.location.href = `product-detail.html?id=${productId}`;
}

async function loadProducts() {
    showLoading();

    try {
        const products = await fetchProducts();
        
        if (!products || products.length === 0) {
            showError('暂无可用产品。');
            return;
        }

        const productGrid = document.getElementById('product-grid');
        productGrid.innerHTML = '';

        products.forEach(product => {
            const card = createProductCard(product);
            productGrid.appendChild(card);
        });

        showContent('product-grid');
    } catch (error) {
        showError(error.message);
    }
}

// Product Detail Page Functions
function displayProductDetail(product) {
    document.getElementById('product-id').textContent = product.id;
    document.getElementById('product-name').textContent = product.name;
    document.getElementById('product-category').textContent = product.category || '未分类';
    document.getElementById('product-price').textContent = formatPrice(product.price);
    document.getElementById('product-description').textContent = product.description || '暂无描述';
    document.getElementById('product-created').textContent = formatDate(product.createdAt);
    document.getElementById('product-updated').textContent = formatDate(product.updatedAt);

    const stockStatus = getStockStatus(product.stockQuantity);
    const stockElement = document.getElementById('product-stock');
    stockElement.textContent = stockStatus.text;
    stockElement.className = stockStatus.class;

    const imageElement = document.getElementById('product-image');
    imageElement.src = product.imageUrl || 'https://via.placeholder.com/500x500?text=暂无图片';
    imageElement.alt = product.name;
    imageElement.onerror = function() {
        this.src = 'https://via.placeholder.com/500x500?text=暂无图片';
    };

    showContent('product-detail');
}

async function loadProductDetail() {
    showLoading();

    const urlParams = new URLSearchParams(window.location.search);
    const productId = urlParams.get('id');

    if (!productId) {
        showError('未指定产品编号。请返回产品列表。');
        return;
    }

    try {
        const product = await fetchProductById(productId);
        displayProductDetail(product);
    } catch (error) {
        showError(error.message);
    }
}

// Page Initialization
function initProductListPage() {
    if (document.getElementById('product-grid')) {
        loadProducts();
    }
}

function initProductDetailPage() {
    if (document.getElementById('product-detail')) {
        loadProductDetail();
    }
}

// Initialize appropriate page on load
document.addEventListener('DOMContentLoaded', () => {
    initProductListPage();
    initProductDetailPage();
});
