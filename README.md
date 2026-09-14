# Revolutionizing Agriculture with AgriEdge Or-Mange Ltd
## A Salesforce-Driven Order Management Solution

### 📌 Project Overview

AgriEdge Or-Mange Ltd is a Salesforce-based Order Management Solution designed to streamline agricultural product ordering, inventory management, payment processing, and shipment tracking.

The solution uses Salesforce custom objects, Apex classes, Apex triggers, validation rules, and automation to manage the complete order lifecycle.

---

## 🎯 Project Objectives

- Manage customer orders efficiently
- Track agricultural product order items
- Calculate order totals automatically
- Manage inventory and stock levels
- Track shipment and delivery status
- Automate order processing
- Handle payment status changes
- Improve order management through Salesforce automation

---

## 🏗️ Salesforce Data Model

### Custom Objects

- **AgriEdge Order**
- **AgriEdge Order Item**
- **AgriEdge Inventory**
- **AgriEdge Shipment**

### Key Relationships

```text
Account
   │
   └── AgriEdge Order
          │
          ├── AgriEdge Order Item
          │        │
          │        └── Product
          │
          └── AgriEdge Shipment

Product
   │
   └── AgriEdge Inventory