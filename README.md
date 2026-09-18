# ☕ PREEM COFFEE

> A modern QR-based café ordering system built with Flutter and Supabase.

PREEM COFFEE is a full-stack café ordering platform designed to make
ordering simple for customers and menu/order management easy for café owners.

## ✨ Features

### 👤 Customer

- 🌍 English, French and Arabic
- 📱 Mobile-friendly web interface
- 🔎 Menu search
- ☕ Product categories
- 🛒 Shopping cart
- ➕ Quantity management
- 📦 Real-time order creation
- 🔢 Order number confirmation
- ⭐ Popular products

### 💻 Admin Dashboard

- 🔐 Admin authentication
- 📊 Dashboard
- 🔔 New order notifications
- 📋 Pending orders
- ✅ Accept orders
- 🍔 Product management
- ➕ Add products
- ✏️ Edit products
- 🗑️ Delete products
- 💰 Change prices
- 📝 Change descriptions
- 🖼️ Product image management
- 🟢 Available / unavailable products
- ⭐ Popular product management

## 🏗️ Architecture

```text
                    PREEM COFFEE
                         │
              ┌──────────┴──────────┐
              │                     │
          CUSTOMER                ADMIN
             📱                      💻
              │                     │
        Browse Menu           Manage Products
        Add to Cart            Manage Orders
        Place Order            Accept Orders
              │                     │
              └──────────┬──────────┘
                         │
                      SUPABASE
                         ☁️
                  Database + Storage
