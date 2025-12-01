// API Configuration
const API_BASE_URL = '/api';
const API_ENDPOINTS = {
    products: `${API_BASE_URL}/products`,
    productById: (id) => `${API_BASE_URL}/products/${id}`
};

let currentProducts = [];
let editingProductId = null;
let deletingProductId = null;

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
    hideElement('product-table-container');
    showElement('loading');
}

function showError(message) {
    hideElement('loading');
    hideElement('product-table-container');
    
    const errorElement = document.getElementById('error');
    const errorMessageElement = errorElement?.querySelector('.error-message');
    
    if (errorMessageElement) {
        errorMessageElement.textContent = message;
    }
    
    showElement('error');
}

function showContent() {
    hideElement('loading');
    hideElement('error');
    showElement('product-table-container');
}

// API Functions
async function fetchProducts() {
    try {
        const response = await fetch(API_ENDPOINTS.products);
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }
        const products = await response.json();
        return products;
    } catch (error) {
        console.error('获取产品列表出错:', error);
        throw new Error(`加载产品失败：${error.message}`);
    }
}

async function createProduct(productData) {
    try {
        const response = await fetch(API_ENDPOINTS.products, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(productData)
        });
        
        if (!response.ok) {
            const errorData = await response.json().catch(() => ({}));
            throw new Error(errorData.message || `HTTP ${response.status}`);
        }
        
        return await response.json();
    } catch (error) {
        console.error('创建产品出错:', error);
        throw error;
    }
}

async function updateProduct(id, productData) {
    try {
        const response = await fetch(API_ENDPOINTS.productById(id), {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(productData)
        });
        
        if (!response.ok) {
            const errorData = await response.json().catch(() => ({}));
            throw new Error(errorData.message || `HTTP ${response.status}`);
        }
        
        return await response.json();
    } catch (error) {
        console.error('更新产品出错:', error);
        throw error;
    }
}

async function deleteProduct(id) {
    try {
        const response = await fetch(API_ENDPOINTS.productById(id), {
            method: 'DELETE'
        });
        
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }
        
        return true;
    } catch (error) {
        console.error('删除产品出错:', error);
        throw error;
    }
}

// Formatting Functions
function formatPrice(price) {
    return new Intl.NumberFormat('zh-CN', {
        style: 'currency',
        currency: 'CNY'
    }).format(price);
}

function getStockBadge(quantity) {
    if (quantity === 0) {
        return { text: '缺货', class: 'out-of-stock' };
    } else if (quantity < 10) {
        return { text: `库存不足 (${quantity})`, class: 'low-stock' };
    } else {
        return { text: `有货 (${quantity})`, class: 'in-stock' };
    }
}

// Table Functions
function createTableRow(product) {
    const row = document.createElement('tr');
    const stockStatus = getStockBadge(product.stockQuantity);
    const imageUrl = product.imageUrl || 'https://via.placeholder.com/60?text=暂无图片';
    
    row.innerHTML = `
        <td>${product.id}</td>
        <td><img src="${imageUrl}" alt="${product.name}" class="product-thumbnail" onerror="this.src='https://via.placeholder.com/60?text=暂无图片'"></td>
        <td>${escapeHtml(product.name)}</td>
        <td>${escapeHtml(product.category || '未分类')}</td>
        <td>${formatPrice(product.price)}</td>
        <td><span class="stock-badge ${stockStatus.class}">${stockStatus.text}</span></td>
        <td>
            <div class="action-buttons">
                <button class="btn btn-success btn-small" onclick="editProduct(${product.id})">编辑</button>
                <button class="btn btn-danger btn-small" onclick="showDeleteModal(${product.id}, '${escapeHtml(product.name)}')">删除</button>
            </div>
        </td>
    `;
    
    return row;
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function renderProductTable() {
    const tbody = document.getElementById('product-table-body');
    tbody.innerHTML = '';
    
    if (currentProducts.length === 0) {
        tbody.innerHTML = '<tr><td colspan="7" style="text-align: center; padding: 2rem; color: #7f8c8d;">暂无产品数据</td></tr>';
        return;
    }
    
    currentProducts.forEach(product => {
        const row = createTableRow(product);
        tbody.appendChild(row);
    });
}

async function loadProducts() {
    showLoading();
    
    try {
        currentProducts = await fetchProducts();
        renderProductTable();
        showContent();
    } catch (error) {
        showError(error.message);
    }
}

// Modal Functions
function openModal(title = '添加产品') {
    document.getElementById('modal-title').textContent = title;
    showElement('product-modal');
    document.body.style.overflow = 'hidden';
}

function closeModal() {
    hideElement('product-modal');
    document.body.style.overflow = 'auto';
    resetForm();
}

function resetForm() {
    document.getElementById('product-form').reset();
    document.getElementById('product-id').value = '';
    editingProductId = null;
}

function showDeleteModal(productId, productName) {
    deletingProductId = productId;
    document.getElementById('delete-product-name').textContent = productName;
    showElement('delete-modal');
    document.body.style.overflow = 'hidden';
}

function closeDeleteModal() {
    hideElement('delete-modal');
    document.body.style.overflow = 'auto';
    deletingProductId = null;
}

// Product Operations
window.editProduct = function(productId) {
    const product = currentProducts.find(p => p.id === productId);
    if (!product) {
        alert('产品未找到');
        return;
    }
    
    editingProductId = productId;
    
    document.getElementById('product-id').value = product.id;
    document.getElementById('product-name').value = product.name;
    document.getElementById('product-category').value = product.category || '';
    document.getElementById('product-price').value = product.price;
    document.getElementById('product-stock').value = product.stockQuantity;
    document.getElementById('product-image-url').value = product.imageUrl || '';
    document.getElementById('product-description').value = product.description || '';
    
    openModal('编辑产品');
};

window.confirmDelete = async function() {
    if (!deletingProductId) return;
    
    try {
        await deleteProduct(deletingProductId);
        closeDeleteModal();
        await loadProducts();
        alert('产品删除成功！');
    } catch (error) {
        alert('删除产品失败：' + error.message);
    }
};

// Form Submission
document.addEventListener('DOMContentLoaded', () => {
    // Load products on page load
    loadProducts();
    
    // Add product button
    document.getElementById('add-product-btn').addEventListener('click', () => {
        openModal('添加产品');
    });
    
    // Form submission
    document.getElementById('product-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        
        const productData = {
            name: document.getElementById('product-name').value.trim(),
            category: document.getElementById('product-category').value.trim() || null,
            price: parseFloat(document.getElementById('product-price').value),
            stockQuantity: parseInt(document.getElementById('product-stock').value),
            imageUrl: document.getElementById('product-image-url').value.trim() || null,
            description: document.getElementById('product-description').value.trim() || null
        };
        
        try {
            if (editingProductId) {
                await updateProduct(editingProductId, productData);
                alert('产品更新成功！');
            } else {
                await createProduct(productData);
                alert('产品创建成功！');
            }
            
            closeModal();
            await loadProducts();
        } catch (error) {
            alert('操作失败：' + error.message);
        }
    });
    
    // Close modal when clicking outside
    document.getElementById('product-modal').addEventListener('click', (e) => {
        if (e.target.id === 'product-modal') {
            closeModal();
        }
    });
    
    document.getElementById('delete-modal').addEventListener('click', (e) => {
        if (e.target.id === 'delete-modal') {
            closeDeleteModal();
        }
    });
});
