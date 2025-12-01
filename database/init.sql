-- 电商系统数据库初始化脚本
-- 此脚本创建产品表结构并初始化数据

-- Set character set and collation
SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

-- Create database if not exists
CREATE DATABASE IF NOT EXISTS ecommerce CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE ecommerce;

-- Drop table if exists (for clean initialization)
DROP TABLE IF EXISTS products;

-- Create products table
CREATE TABLE products (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    stock_quantity INT NOT NULL DEFAULT 0,
    category VARCHAR(100),
    image_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_category (category),
    INDEX idx_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 初始化产品数据
INSERT INTO products (name, description, price, stock_quantity, category, image_url) VALUES
('笔记本电脑 Pro 15', '高性能笔记本电脑，配备15英寸显示屏、Intel i7处理器、16GB内存和512GB固态硬盘。非常适合专业人士和开发者使用。', 8999.99, 25, '电子产品', 'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=400'),
('无线鼠标', '人体工学无线鼠标，具有精准追踪、6个可编程按键和超长电池续航。兼容Windows和Mac系统。', 199.99, 150, '电子产品', 'https://images.unsplash.com/photo-1527864550417-7fd91fc51a46?w=400'),
('USB-C 扩展坞', '7合1 USB-C扩展坞，配备HDMI、USB 3.0接口、SD读卡器和电源传输功能。非常适合扩展笔记本电脑连接性。', 349.99, 80, '电子产品', 'https://images.unsplash.com/photo-1625948515291-69613efd103f?w=400'),
('机械键盘', 'RGB背光机械键盘，采用Cherry MX轴、铝合金框架和可自定义按键。非常适合游戏和打字使用。', 599.99, 60, '电子产品', 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=400'),
('降噪耳机', '高端头戴式耳机，具有主动降噪功能、30小时电池续航和卓越音质。', 1699.99, 40, '电子产品', 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400'),
('4K显示器 27英寸', '超高清4K显示器，配备IPS面板、HDR支持和99% sRGB色域覆盖。非常适合内容创作者和设计师使用。', 2799.99, 30, '电子产品', 'https://images.unsplash.com/photo-1527443224154-c4a3942d3acf?w=400'),
('高清摄像头 1080p', '全高清摄像头，具有自动对焦、内置麦克风和广角镜头。非常适合视频会议和直播使用。', 549.99, 100, '电子产品', 'https://images.unsplash.com/photo-1587825140708-dfaf72ae4b04?w=400'),
('移动固态硬盘 1TB', '便携式固态硬盘，配备USB 3.2 Gen 2接口，读取速度高达1050MB/s，抗震设计。', 899.99, 70, '电子产品', 'https://images.unsplash.com/photo-1597872200969-2b65d56bd16b?w=400');

-- 显示确认消息
SELECT '数据库初始化成功！' AS status;
SELECT COUNT(*) AS total_products FROM products;
