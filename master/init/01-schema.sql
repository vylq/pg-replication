CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(320) UNIQUE NOT NULL,
    password VARCHAR(256) NOT NULL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    role VARCHAR(20) DEFAULT 'customer' CHECK (role IN ('customer', 'admin')),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMPTZ
);

-- Products table
CREATE TABLE products (
    product_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
    stock INT DEFAULT 0 CHECK (stock >= 0),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Categories table
CREATE TABLE categories (
    category_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) UNIQUE NOT NULL,
    parent_category_id UUID,
    CONSTRAINT fk_parent_category
        FOREIGN KEY(parent_category_id)
        REFERENCES categories(category_id)
        ON DELETE SET NULL
);

-- Product–category association (many-to-many)
CREATE TABLE product_categories (
    product_category_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL,
    category_id UUID NOT NULL,
    CONSTRAINT fk_product
        FOREIGN KEY(product_id)
        REFERENCES products(product_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_category
        FOREIGN KEY(category_id)
        REFERENCES categories(category_id)
        ON DELETE CASCADE,
    UNIQUE (product_id, category_id)
);

-- Orders table
CREATE TABLE orders (
    order_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    order_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled')),
    total DECIMAL(10, 2) NOT NULL CHECK (total >= 0),
    CONSTRAINT fk_user
        FOREIGN KEY(user_id)
        REFERENCES users(user_id)
        ON DELETE RESTRICT
);

-- Order items table
CREATE TABLE order_items (
    order_item_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL,
    product_id UUID NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    price_at_purchase DECIMAL(10,2) NOT NULL,
    CONSTRAINT fk_order
        FOREIGN KEY(order_id)
        REFERENCES orders(order_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_product
        FOREIGN KEY(product_id)
        REFERENCES products(product_id)
        ON DELETE RESTRICT,
    UNIQUE (order_id, product_id)
);

-- Reviews table
CREATE TABLE reviews (
    review_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL,
    user_id UUID NOT NULL,
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_product
        FOREIGN KEY(product_id)
        REFERENCES products(product_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_user
        FOREIGN KEY(user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
);

-- Trigger to update products.updated_at on modification
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_product_modtime
BEFORE UPDATE ON products
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- Sample data for testing
INSERT INTO users (email, password, first_name, last_name, role) VALUES
('admin@example.com', 'securepassword123', 'Admin', 'User', 'admin'),
('customer1@example.com', 'customerpass', 'John', 'Doe', 'customer');


INSERT INTO categories (name) VALUES
('Электроника'),
('Книги');

WITH parent_cat AS (SELECT category_id FROM categories WHERE name = 'Электроника')
INSERT INTO categories (name, parent_category_id)
SELECT 'Смартфоны', category_id FROM parent_cat;


INSERT INTO products (name, description, price, stock) VALUES
('Смартфон X', 'Последняя модель с невероятными функциями', 799.99, 50),
('Книга Y', 'Захватывающий роман о приключениях', 19.99, 100);


WITH prod_smartphone AS (SELECT product_id FROM products WHERE name = 'Смартфон X'),
     cat_smartphones AS (SELECT category_id FROM categories WHERE name = 'Смартфоны')
INSERT INTO product_categories (product_id, category_id)
SELECT ps.product_id, cs.category_id FROM prod_smartphone ps, cat_smartphones cs;

WITH prod_book AS (SELECT product_id FROM products WHERE name = 'Книга Y'),
     cat_books AS (SELECT category_id FROM categories WHERE name = 'Книги')
INSERT INTO product_categories (product_id, category_id)
SELECT pb.product_id, cb.category_id FROM prod_book pb, cat_books cb;